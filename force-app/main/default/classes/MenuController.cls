global class MenuController extends AccessControl {
  public Integer contadorAnotacoes { get; set; }
  public Integer contadorDespesaRevisao { get; set; }
  public Integer contadorQuiz { get; set; }
  public Integer contadorContratacoes { get; set; }
  public Integer contadorDivulgacao { get; set; }
  public Boolean temContratacoesAcompanhadas { get; private set; }
  public String nome { get; set; }
  public String empresa { get; set; }
  public Boolean canAccessPatrimonio {
    get {
      return isSuporteTi || isManutencao;
    }
    set;
  }

  public MenuController() {
    init();
  }

  private void init() {
    carregarMural();
    temContratacoesAcompanhadas = empregado != null &&
      ContratacaoAccessService.temSolicitacoesAcompanhadas(empregado.Id);
    nome = Session.getValue('nameLogin');
    empresa = Session.getValue('empresaLogin');
  }

  private void carregarMural() {
    contadorAnotacoes = 0;
    contadorDespesaRevisao = 0;
    contadorContratacoes = 0;
    contadorDivulgacao = 0;
    if (empregado == null)
      return;
    carregarContadorContratacoes();
    List<Mural__c> mural = [SELECT Visualizacoes__c FROM Mural__c];
    for (Mural__c m : mural) {
      if (
        (!String.isEmpty(m.Visualizacoes__c) && !m.Visualizacoes__c.contains(empregado.Name)) ||
        String.isEmpty(m.Visualizacoes__c)
      ) {
        contadorAnotacoes++;
      }
    }

    contadorQuiz = [
      SELECT COUNT()
      FROM EnvioQuiz__c
      WHERE Empregado__c = :empregado.Id AND Data_Conclusao__c = NULL
    ];

    if (isUserFinanceiro) {
      contadorDespesaRevisao = [
        SELECT COUNT()
        FROM Despesa_de_Revisao__c
        WHERE Revisao_concluida__c = FALSE AND Devolvida__c = FALSE AND Excluido__c = FALSE
      ];
    }
  }

  /**
   * Calcula solicitações de contratação pendentes de ação do usuário autenticado.
   * RH conta etapas em Análise do RH; gestor conta suas etapas de Cadastro abertas.
   * Marketing conta vagas pendentes de divulgação.
   */
  private void carregarContadorContratacoes() {
    try {
      if (isRhDp) {
        contadorContratacoes = [
          SELECT COUNT()
          FROM ProcessoEtapa__c
          WHERE
            Name = 'Análise do RH'
            AND Concluido__c = FALSE
            AND Processo__r.Status__c = 'Em andamento'
            AND Processo__r.Tipo__c = 'Solicitação de Contratação'
        ];
      } else if (isGestor) {
        contadorContratacoes = [
          SELECT COUNT()
          FROM ProcessoEtapa__c
          WHERE
            Name = 'Cadastro'
            AND Empregado__c = :empregado.Id
            AND Concluido__c = FALSE
            AND Processo__r.Status__c = 'Em andamento'
            AND Processo__r.Tipo__c = 'Solicitação de Contratação'
        ];
      }
      if (isMarketing) {
        contadorDivulgacao = [
          SELECT COUNT()
          FROM ProcessoEtapa__c
          WHERE
            Name = 'Divulgação da vaga'
            AND Concluido__c = FALSE
            AND Processo__r.Status__c = 'Em andamento'
            AND Processo__r.Tipo__c = 'Solicitação de Contratação'
        ];
      }
    } catch (Exception e) {
      contadorContratacoes = 0;
      contadorDivulgacao = 0;
    }
  }

  public PageReference redirectContratacoes() {
    if (isGestor || temContratacoesAcompanhadas) {
      return new PageReference('/SolicitacaoContratacaoListagem');
    }
    return null;
  }

  /**
   * Redireciona para o workspace de divulgação de vagas (Marketing).
   */
  public PageReference redirectContratacaoMarketing() {
    if (isMarketing) {
      return new PageReference('/SolicitacaoContratacaoMarketingPage');
    }
    return null;
  }

  public String getUrlCRM() {
    PageReference pr = redirectCRM();
    if (pr != null) {
      return pr.getUrl();
    }
    return '#';
  }

  public String getUrlPatrimonio() {
    PageReference pr = redirectPatrimonio();
    if (pr != null) {
      return pr.getUrl();
    }
    return '#';
  }

  //Rodapé - Logout
  public PageReference logout() {
    Session.remove('authToken');
    Session.remove('nameLogin');
    Session.remove('empresaLogin');
    return new PageReference('/SiteLogin');
  }

  public PageReference redirectApontamento() {
    if (isUserApotamento) {
      return new PageReference('/ApontamentoPage');
    } else
      return null;
  }

  public PageReference redirectApontamentoHierarquico() {
    if (isUserEmpregado) {
      return new PageReference('/ApontamentoHierarquico');
    } else
      return null;
  }

  public PageReference redirectFeriasGestor() {
    if (IsGestor || isSupervisorApontamento) {
      return new PageReference('/FeriasGestorListagem');
    } else
      return null;
  }

  public PageReference redirectFeriasRH() {
    if (isRhDp) {
      return new PageReference('/FeriasRHListagem');
    } else
      return null;
  }

  public PageReference redirectApontamentoProducao() {
    if (isUserEmpregado) {
      return new PageReference('/ApontamentoProducao');
    } else
      return null;
  }

  public PageReference redirectAssinaturaEmail() {
    if (isUserEmpregado) {
      return new PageReference('/AssinaturaEmailPage');
    } else
      return null;
  }

  public PageReference redirectBusca() {
    if (isUserEmpregado) {
      return new PageReference('/BuscaPage');
    } else
      return null;
  }

  public PageReference redirectPersonificarUsuarios() {
    if (isAdminSistema) {
      return new PageReference('/PersonificarUsuarios');
    } else
      return null;
  }

  public PageReference redirectControleHorasAero() {
    if (isAerolevantamento) {
      return new PageReference('/ControleHorasVoo');
    } else
      return null;
  }

  public PageReference redirectConvenio() {
    if (isUserEmpregado) {
      return new PageReference('/ConvenioPage');
    } else
      return null;
  }

  public PageReference redirectCRM() {
    // Se for um usuario do salesforce
    if (isUserCRM) {
      String ambiente;

      if (host != null) {
        if (Util.isSandbox()) {
          ambiente = 'test';
        } else {
          ambiente = 'grupoengemap.my';
        }
        //if (host.contains('sandbox')) ambiente = 'test';
        //else ambiente = 'login';

        host = ambiente + '.salesforce.com?startURL=/apex/SessionPage?authToken=' + Session.getValue('authToken');
        PageReference homePage = new PageReference('https://' + host);

        homePage.setRedirect(true);
        return homePage;
      }
    }
    return null;
  }

  public PageReference redirectDespesaRevisao() {
    if (isUserFinanceiro) {
      return new PageReference('/DespesaRevisaoPage');
    } else
      return null;
  }

  public PageReference redirectEngC() {
    if (isUserEngC) {
      return new PageReference('/EngCPage');
    } else
      return null;
  }

  public PageReference redirectFornecedoresServicos() {
    return new PageReference('/AvaliacaoFornecedoresServicos');
  }

  public PageReference redirectHome() {
    return new PageReference('/HomePage');
  }

  public PageReference redirectIndicadores() {
    if (isUserEmpregado && (isPreenchIndicador || isModIndicador)) {
      return new PageReference('/MapeamentoProcessosPage');
    } else {
      return null;
    }
  }

  public PageReference redirectMural() {
    if (isUserEmpregado) {
      return new PageReference('/MuralPage');
    } else {
      return null;
    }
  }

  public PageReference redirectNoticia() {
    return new PageReference('/NoticiaPage');
  }

  public PageReference redirectPatrimonio() {
    if (canAccessPatrimonio) {
      PageReference patrimonioPage = new PageReference('https://patrimonio.saapi.com.br/');
      return patrimonioPage;
    }
    return null;
  }

  public PageReference redirectPerfilUsuario() {
    return new PageReference('/ProfilePage');
  }

  public PageReference redirectPlanoTrabalho() {
    if (isUserEmpregado) {
      return new PageReference('/EPlanoTrabalhoPage');
    } else
      return null;
  }

  public PageReference redirectPlanos() {
    if (isUserEmpregado) {
      return new PageReference('/PlanoAcaoPage');
    } else {
      return null;
    }
  }

  public PageReference redirectPoliticaSeguranca() {
    if (isUserEmpregado) {
      return new PageReference('/PoliticasSegurancaPage');
    } else {
      return null;
    }
  }

  public PageReference redirectProcessos() {
    return new PageReference('/ProcessosPage');
  }

  public PageReference redirectProfile() {
    if (isUserStatus || isUserEditStatus) {
      return new PageReference('/MaoDeObraPage');
    } else {
      return null;
    }
  }

  public PageReference redirectProjetosCliente() {
    if (isUserCliente) {
      return new PageReference('/ProjetosClientePage');
    } else
      return null;
  }

  public PageReference redirectResponderQuestionario() {
    if (isUserEmpregado) {
      return new PageReference('/ResponderQuiz');
    } else {
      return null;
    }
  }

  public PageReference redirectSubstitutoTarefa() {
    if (isUserEmpregado) {
      return new PageReference('/SubstitutoTarefaPage');
    } else
      return null;
  }

  public PageReference redirectTreinamento() {
    if (isUserEmpregado) {
      return new PageReference('/TreinamentoExtranet');
    } else
      return null;
  }

  @RemoteAction
  global static Integer getContadorDespesaRevisao() {
    // Precisa ser global pois é RemoteAction em Site
    return [
      SELECT COUNT()
      FROM Despesa_de_Revisao__c
      WHERE Revisao_concluida__c = FALSE AND Devolvida__c = FALSE AND Excluido__c = FALSE
    ];
  }

  @RemoteAction
  global static Integer getContadorMural(String empregadoName) {
    Integer contador = 0;

    List<Mural__c> murais = [SELECT Visualizacoes__c FROM Mural__c];
    for (Mural__c m : murais) {
      if (String.isEmpty(m.Visualizacoes__c) || !m.Visualizacoes__c.contains(empregadoName)) {
        contador++;
      }
    }
    return contador;
  }

  @RemoteAction
  public static String getSessionId() {
    String accessToken = JwtBearerProvider.getAccessToken();
    if (String.isBlank(accessToken)) {
      throw new AuraHandledException('Falha ao obter access token para CometD.');
    }
    return accessToken;
  }
}