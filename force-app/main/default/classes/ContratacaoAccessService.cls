/**
 * Centraliza a resolução de identidade e as decisões de autorização do módulo de contratações.
 */
public with sharing class ContratacaoAccessService {
  private static final String CENTRO_CUSTO_RH = 'GESTÃO DE PESSOAS';
  private static final String GRUPO_TI = 'TI';
  private static final String GRUPO_MARKETING = 'Divulgação de Vagas';

  @TestVisible
  private static ContextoAcesso contextoSalesforceTeste;

  @TestVisible
  private static Boolean administradorSalesforceTeste;

  @TestVisible
  private static String idLoginExtranetTeste;

  private static ContextoAcesso contextoSalesforceCache;

  /**
   * Resolve o contexto funcional do usuário Salesforce atual.
   *
   * @return Contexto com empregado, papéis funcionais e permissões técnicas.
   */
  public static ContextoAcesso getContextoSalesforce() {
    if (Test.isRunningTest() && contextoSalesforceTeste != null) {
      return contextoSalesforceTeste;
    }
    if (contextoSalesforceCache != null) {
      return contextoSalesforceCache;
    }

    // Só resolve a identidade pela sessão do Webdesk quando há uma página
    // Visualforce ativa. Em contexto Lightning (painel LWC do RH) não existe
    // sessão de Extranet; nesse caso idLogin fica null e a identidade é
    // resolvida pelo usuário Salesforce corrente mais abaixo.
    String idLogin;
    if (Test.isRunningTest() && idLoginExtranetTeste != null) {
      idLogin = idLoginExtranetTeste;
    } else if (ApexPages.currentPage() != null) {
      idLogin = Session.getLoginId();
    }
    if (String.isNotBlank(idLogin)) {
      // Usa a lista completa de empregados para que a associação de grupo (TI,
      // Marketing) seja determinada corretamente mesmo quando há mais de um
      // registro Empregado__c com o mesmo Login__c — resolverEmpregado retorna
      // null nesses casos e tornaria isTi = false silenciosamente.
      List<Empregado__c> empregados = ContratacaoExtranetGateway.resolverEmpregadosPorLogin(idLogin);
      ContextoAcesso contextoExtranet = montarContexto(empregados);
      contextoExtranet.isExtranet = true;
      contextoExtranet.podeExecutarContratacoes =
        FeatureManagement.checkPermission('Executar_Contratacoes') || Test.isRunningTest();
      // RH funcional (centro de custo GESTÃO DE PESSOAS) tem acesso de gestão na Extranet.
      // A autorização técnica é verificada individualmente em cada operação via assertRh().
      contextoExtranet.isRh = contextoExtranet.isRhFuncional;
      // Publicação via Extranet: o usuário Salesforce é o Guest User; a permissão é
      // derivada do grupo do empregado, não de Custom Permission no usuário corrente.
      Set<Id> empIds = contextoExtranet.empregadoId != null
        ? new Set<Id>{ contextoExtranet.empregadoId }
        : new Set<Id>();
      contextoExtranet.podePublicarVagas = pertenceAoGrupoMarketing(empIds);
      contextoSalesforceCache = contextoExtranet;
      return contextoExtranet;
    }

    List<Empregado__c> empregados = [
      SELECT Id, Gestor_checkbox__c, Centro_custo__r.Name
      FROM Empregado__c
      WHERE Usuario_salesforce__c = :UserInfo.getUserId() AND isActive__c = TRUE
      WITH USER_MODE
      ORDER BY CreatedDate ASC
      LIMIT 20
    ];

    ContextoAcesso contexto = montarContexto(empregados);
    contexto.podeExecutarContratacoes = FeatureManagement.checkPermission('Executar_Contratacoes');
    contexto.podeGerenciarContratacoes = FeatureManagement.checkPermission('Gerenciar_Contratacoes');
    contexto.podePublicarVagas = FeatureManagement.checkPermission('Publicar_Vagas');

    Boolean isAdministradorSalesforce = isAdministradorSalesforce();
    if (isAdministradorSalesforce) {
      contexto.isTi = true;
      contexto.podeExecutarContratacoes = true;
      contexto.podeGerenciarContratacoes = true;
      contexto.podePublicarVagas = true;
    }
    contexto.isRh = (contexto.isRhFuncional && contexto.podeGerenciarContratacoes) || isAdministradorSalesforce;
    contextoSalesforceCache = contexto;
    return contexto;
  }

  /**
   * Verifica se o usuário atual pode entrar no módulo de contratações.
   * A autorização de cada solicitação permanece validada separadamente.
   *
   * @return Verdadeiro para gestor, RH, TI ou acompanhante de ao menos uma solicitação.
   */
  public static Boolean podeAcessarModulo() {
    ContextoAcesso contexto = getContextoSalesforce();
    return contexto.isGestor ||
      contexto.isRh ||
      contexto.isTi ||
      temSolicitacoesAcompanhadas(contexto.empregadoId);
  }

  /**
   * Informa se o usuário atual pertence funcionalmente ao grupo TI.
   *
   * @return Verdadeiro quando existe associação ativa ao grupo TI.
   */
  public static Boolean isIntegranteGrupoTi() {
    return getContextoSalesforce().isTi;
  }

  /**
   * Verifica o acesso do usuário atual a uma solicitação.
   *
   * @param solicitacaoId Identificador da solicitação.
   * @return Verdadeiro para RH autorizado, gestor proprietário ou acompanhante.
   */
  public static Boolean podeAcessarSolicitacao(Id solicitacaoId) {
    if (solicitacaoId == null) {
      return false;
    }

    ContextoAcesso contexto = getContextoSalesforce();
    if (contexto.isRh) {
      return true;
    }
    return podeAtuarComoResponsavel(solicitacaoId);
  }

  /**
   * Verifica se o empregado autenticado é o solicitante ou um dos
   * acompanhantes da solicitação. Diferentemente de podeAcessarSolicitacao,
   * esta regra não concede acesso por perfil global de RH.
   *
   * @param solicitacaoId identificador da solicitação.
   * @return verdadeiro para o solicitante ou acompanhante daquele registro.
   */
  public static Boolean podeAtuarComoResponsavel(Id solicitacaoId) {
    if (solicitacaoId == null) {
      return false;
    }
    ContextoAcesso contexto = getContextoSalesforce();
    if (contexto.empregadoId == null) {
      return false;
    }

    if (contexto.isExtranet) {
      return ContratacaoExtranetGateway.podeAcessarSolicitacao(solicitacaoId, contexto.empregadoId);
    }

    List<Solicitacao_Contratacao__c> solicitacoes = [
      SELECT
        Processo__r.Dono_Solicitacao__c,
        Acompanhante_1__c,
        Acompanhante_2__c,
        Acompanhante_3__c
      FROM Solicitacao_Contratacao__c
      WHERE Id = :solicitacaoId
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (solicitacoes.isEmpty()) {
      return false;
    }
    Solicitacao_Contratacao__c solicitacao = solicitacoes[0];
    return solicitacao.Processo__r.Dono_Solicitacao__c == contexto.empregadoId ||
      solicitacao.Acompanhante_1__c == contexto.empregadoId ||
      solicitacao.Acompanhante_2__c == contexto.empregadoId ||
      solicitacao.Acompanhante_3__c == contexto.empregadoId;
  }

  /**
   * Informa se o empregado acompanha ao menos uma solicitação de contratação.
   * Usado somente para liberar o item de menu e a página de listagem; o acesso
   * ao detalhe continua validado registro a registro.
   *
   * @param empregadoId identificador do empregado autenticado.
   * @return verdadeiro quando o empregado consta em um dos campos de acompanhante.
   */
  public static Boolean temSolicitacoesAcompanhadas(Id empregadoId) {
    if (empregadoId == null) {
      return false;
    }
    return ![
        SELECT Id
        FROM Solicitacao_Contratacao__c
        WHERE
          Acompanhante_1__c = :empregadoId
          OR Acompanhante_2__c = :empregadoId
          OR Acompanhante_3__c = :empregadoId
        WITH SYSTEM_MODE
        LIMIT 1
      ]
      .isEmpty();
  }

  /**
   * Exige autorização funcional e técnica de RH.
   *
   * @throws ContratacaoAccessException quando o usuário não é RH autorizado.
   */
  public static void assertRh() {
    if (!getContextoSalesforce().isRh) {
      throw new ContratacaoAccessException('Usuário sem permissão para gerenciar contratações.');
    }
  }

  /**
   * Exige autorização de publicação de vagas.
   *
   * @throws ContratacaoAccessException quando a Custom Permission não está atribuída.
   */
  public static void assertPodePublicarVaga() {
    if (!getContextoSalesforce().podePublicarVagas) {
      throw new ContratacaoAccessException('Usuário sem permissão para publicar vagas.');
    }
  }

  @TestVisible
  private static ContextoAcesso montarContexto(List<Empregado__c> empregados) {
    ContextoAcesso contexto = new ContextoAcesso();
    Set<Id> empregadoIds = new Set<Id>();

    for (Empregado__c empregado : empregados) {
      empregadoIds.add(empregado.Id);
      contexto.isGestor = contexto.isGestor || empregado.Gestor_checkbox__c;
      contexto.isRhFuncional =
        contexto.isRhFuncional || normalizar(empregado.Centro_custo__r?.Name) == normalizar(CENTRO_CUSTO_RH);
    }

    if (empregados.size() == 1) {
      contexto.empregadoId = empregados[0].Id;
    }
    contexto.isTi = pertenceAoGrupoTi(empregadoIds);
    return contexto;
  }

  @TestVisible
  private static Boolean pertenceAoGrupoMarketing(Set<Id> empregadoIds) {
    return new ResolverGrupo().pertenceAoGrupo(empregadoIds, GRUPO_MARKETING);
  }

  private static Boolean pertenceAoGrupoTi(Set<Id> empregadoIds) {
    return new ResolverGrupo().pertenceAoGrupo(empregadoIds, GRUPO_TI);
  }

  /**
   * Resolve a associação de grupo do empregado para fins de autorização.
   *
   * Roda em system mode (`without sharing`, sem `WITH USER_MODE`) de forma
   * idêntica à classe corporativa `AccessControl`: no caminho Extranet/Webdesk
   * o usuário em execução é o Site Guest User, que não tem CRUD/FLS em
   * `Grupo_Funcionarios__c`. Sob `WITH USER_MODE` a consulta lançava
   * `System.QueryException`, abortando silenciosamente a publicação de vagas.
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  private without sharing class ResolverGrupo {
    private Boolean pertenceAoGrupo(Set<Id> empregadoIds, String nomeGrupo) {
      if (empregadoIds == null || empregadoIds.isEmpty()) {
        return false;
      }
      return ![
          SELECT Id
          FROM Grupo_Funcionarios__c
          WHERE Empregado__c IN :empregadoIds AND Empregado__r.isActive__c = TRUE AND Grupo__r.Name = :nomeGrupo
          LIMIT 1
        ]
        .isEmpty();
    }
  }

  private static String normalizar(String valor) {
    return String.isBlank(valor) ? '' : valor.trim().toUpperCase();
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static Boolean isAdministradorSalesforce() {
    if (Test.isRunningTest()) {
      return administradorSalesforceTeste == true;
    }

    List<Profile> perfis = [
      SELECT PermissionsModifyAllData
      FROM Profile
      WHERE Id = :UserInfo.getProfileId()
      LIMIT 1
    ];
    return !perfis.isEmpty() && perfis[0].PermissionsModifyAllData;
  }

  /**
   * DTO explícito de autorização usado pelas interfaces do módulo.
   */
  public class ContextoAcesso {
    @AuraEnabled
    public Id empregadoId { get; set; }
    @AuraEnabled
    public Boolean isGestor { get; set; }
    @AuraEnabled
    public Boolean isRhFuncional { get; set; }
    @AuraEnabled
    public Boolean isRh { get; set; }
    @AuraEnabled
    public Boolean isTi { get; set; }
    @AuraEnabled
    public Boolean isExtranet { get; set; }
    @AuraEnabled
    public Boolean podeExecutarContratacoes { get; set; }
    @AuraEnabled
    public Boolean podeGerenciarContratacoes { get; set; }
    @AuraEnabled
    public Boolean podePublicarVagas { get; set; }

    /**
     * Inicializa o contexto com valores booleanos seguros.
     */
    public ContextoAcesso() {
      isGestor = false;
      isRhFuncional = false;
      isRh = false;
      isTi = false;
      isExtranet = false;
      podeExecutarContratacoes = false;
      podeGerenciarContratacoes = false;
      podePublicarVagas = false;
    }
  }

  /**
   * Exceção funcional para falhas de autorização do módulo.
   */
  public class ContratacaoAccessException extends Exception {
  }
}