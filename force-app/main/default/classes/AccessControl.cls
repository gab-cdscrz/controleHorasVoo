public virtual without sharing class AccessControl {

    protected String host {get;set;}
    protected String redirect {get;set;}
    public Contact contato {get;set;}
    public Empregado__c empregado {get;set;}
    public String idLogin {get;set;}

    public Boolean isUserCliente { get; set; }
    public Boolean isUserEmpregado { get; set; }
    public Boolean isUserApotamento { get; set; }
    public Boolean isUserCRM { get; set; }
    public Boolean isUserEngC { get; set; }
    public Boolean isUserRedator { get; set; }
    public Boolean isUserStatus { get; set; }
    public Boolean isUserEditStatus { get; set; }
    public Boolean isUserFinanceiro {get; set;}
    public Boolean isGerenteProjeto { get; set; }
    public Boolean isPreenchIndicador { get; set; }
    public Boolean isModIndicador { get; set; }
    public Boolean isGestorQualidade { get; set; }
    public Boolean isGestor {get; set;}
    public Boolean isSupervisorApontamento {get; set;}
    public Boolean isRecepcaoAssis{get;set;}
    public Boolean isManutencao{get; set;}
    public Boolean isSuporteTi {get; set;} // 2025/04/29 usado para garantir que o gestor do suporte de ti aprove suas solicitações. by welton
    public Boolean isGestorTi { get; set; } //2025/05/06 usado para garantir que o gestor do suporte de ti aprove suas solicitações. by Gabriel Cardoso
    public Boolean isAerolevantamento { get; set; } //2025/09/22 usado para garantir que o usuario de aerolevantamento tenha acesso a pagina. by Gabriel Cardoso
    public Boolean isRhDp { get; set; }
    public Boolean isMembroTi { get; set; }
    public Boolean isMarketing { get; set; }
    public Boolean isAdminSistema {get; set;}

    /** Público temporário: Faixa de Domínio, Gestão da Informação e gestores ativos. */
    public Boolean podeOperarControleProducao {
        get {
            return isUserEmpregado
                && ControleProducaoAcessoService.podeAcessarModuloWebdesk(empregado);
        }
    }

    /** Gestores e Gestão da Informação têm as mesmas ações gerenciais neste módulo. */
    public Boolean podeGerenciarControleProducao {
        get {
            return isUserEmpregado
                && ControleProducaoAcessoService.podeGerenciarModulo(empregado);
        }
    }

    /** Token assinado repassado somente ao componente carregado dentro do Webdesk. */
    public String controleProducaoToken {
        get { return podeOperarControleProducao ? Session.getValue('authToken') : null; }
    }

    public Integer qtdeAptosPendentes { get; set; }

    public AccessControl() {
        String path = URL.getCurrentRequestUrl().getPath();
        LIST<String> sPath = path.split('/');
        String query = URL.getCurrentRequestUrl().getQuery();
        query = query == null ? '' : '?'+EncodingUtil.urlEncode(query,'UTF-8');
        redirect = '/SiteLogin?redirect=/' + sPath.get(sPath.size()-1) + query;

        host = ApexPages.currentPage().getHeaders().get('host');
        isUserEmpregado = false;
        isUserApotamento = false;
        isUserCRM = false;
        isUserCliente = false;
        isUserEngC = false;
        isUserRedator = false;
        isUserStatus = false;
        isUserEditStatus = false;
        isUserFinanceiro = false;
        isGerenteProjeto = false;
        isPreenchIndicador = false;
        isModIndicador = false;
        isGestorQualidade = false;
        isGestor = false;
        isSupervisorApontamento = false;
        isManutencao = false;
        isGestorTi = false;
        isAerolevantamento = false;
        isRecepcaoAssis = false;
        isSuporteTi = false;
        isRhDp = false;
        isMembroTi = false;
        isAdminSistema = false;
        isMarketing = FeatureManagement.checkPermission('Publicar_Vagas');
        qtdeAptosPendentes = 0;
        idLogin = Session.getLoginId();

        if (idLogin != null) {
            System.debug('idLogin: ' + idLogin);
            List<Empregado__c> empregados = [
                SELECT
                Id,
                Codigo_externo__c,
                Name,
                Nome__c,
                Data_de_nascimento__c,
                Data_admissao__c,
                Ramal__c,
                email__c,
                Funcao__c,
                Funcao__r.name,
                Gestor_Deste_Funcionario__c,
                Gestor_Deste_Funcionario__r.Name,
                Turno__c,
                Qtde_horas_semanais__c,
                Telefone__c,
                Celular__c,
                Realiza_apontamentos__c,
                Usuario_salesforce__c,
                Criar_EngC__c,
                Redator__c,
                Usuario_salesforce__r.Username,
                Usuario_salesforce__r.Password__c,
                Centro_custo__r.Name,
                Acervo_de_HD_Total__c,
                Status_funcionario__c,
                Edita_status_funcionario__c,
                Perfil_de_Gerente_de_Projetos__c,
                Gestao_indicadores__c,
                Gestao_Qualidade__c,
                Indicadores__c,
                Visualiza_Processos__c,
                Gestor_checkbox__c,
                isActive__c,
                Setor_Principal__c,
                Setor_Principal__r.Name,
                Cidade_UF_Trabalho__c
                FROM Empregado__c
                WHERE Login__c = :idLogin AND isActive__c = TRUE
                WITH SYSTEM_MODE
                ORDER BY Id
                LIMIT 2
            ];

            if (empregados.size() == 1) {
                empregado = empregados.get(0);
                Session.add('nameLogin', empregado.Nome__c);
                isUserEmpregado = true;
                isUserApotamento = empregado.Realiza_apontamentos__c;
                isUserCRM = empregado.Usuario_salesforce__c != null ? true : false;
                isUserEngC = empregado.Criar_EngC__c;
                isUserRedator = empregado.Redator__c;
                isUserStatus = empregado.Status_funcionario__c;
                isUserEditStatus = empregado.Edita_status_funcionario__c;
                isGerenteProjeto = empregado.Perfil_de_Gerente_de_Projetos__c;
                isModIndicador = empregado.Gestao_indicadores__c;
                isPreenchIndicador = empregado.Indicadores__c;
                isGestorQualidade = empregado.Gestao_Qualidade__c && empregado.Gestao_Indicadores__c;
                isGestor = empregado.Gestor_checkbox__c;
                Map<String, Boolean> gruposMap = new Map<String, Boolean>();
                for (Grupo_Funcionarios__c g : [
                    SELECT Grupo__r.Name
                    FROM Grupo_Funcionarios__c
                    WHERE Empregado__c = :empregado.Id
                    WITH SYSTEM_MODE
                ]) {
                    gruposMap.put(g.Grupo__r.Name, true);
                }
                this.isSupervisorApontamento = gruposMap.containsKey('Supervisores de apontamento');
                this.isManutencao = gruposMap.containsKey('Manutenção');
                this.isGestorTi = gruposMap.containsKey('Gestores de TI') ? true : false; //2025/05/06 usado para garantir que o gestor do suporte de ti aprove suas solicitações. @autor: Gabriel Cardoso
                this.isAerolevantamento = gruposMap.containsKey('Aerolevantamento') ? true : false; //2025/09/22 usado para garantir que o usuario de aerolevantamento tenha acesso a pagina. by Gabriel Cardoso
                this.isUserFinanceiro = gruposMap.containsKey('Financeiro');
                this.isMembroTi = gruposMap.containsKey('TI');
                this.isMarketing = this.isMarketing || gruposMap.containsKey('Divulgação de Vagas');
                this.isAdminSistema = gruposMap.containsKey('Administradores Sistema');

                this.isRecepcaoAssis = (empregado.Funcao__r.name == 'RECEPCIONISTA' && empregado.Cidade_UF_Trabalho__c == 'Assis/SP') ? true : false;
                // 2025/04/29 usado para garantir que o gestor do suporte de ti aprove suas solicitações. by welton
                this.isSuporteTi = (empregado.Funcao__r.name == 'ASSISTENTE DE SUPORTE DE T.I.' && empregado.Cidade_UF_Trabalho__c == 'Assis/SP') ? true : false;

                this.isRhDp = (empregado.Centro_custo__r.Name.toUpperCase() == 'GESTÃO DE PESSOAS') ? true : false;

                // Apontamentos pendentes do funcionario
                List<AggregateResult> result = [SELECT COUNT(Id) qtdeAptosPendentes
							                        FROM Recurso_Disponivel__c
							                        WHERE Empregado__c = :empregado.Id
						                        AND Quantidade_de_horas_pendente__c > 0.25
						                        AND Data__c >= :Date.newInstance(2015, 1, 1)
						                        AND Data__c <= :date.today()
                                                    WITH SYSTEM_MODE];

                qtdeAptosPendentes = (Integer) result.get(0).get('qtdeAptosPendentes');
            }

            List<Contact> contatos = [
                SELECT Id, Name, AccountId, Account.Name, Email
                FROM Contact
                WHERE Login__c = :idLogin
                WITH SYSTEM_MODE
            ];

            if(!contatos.isEmpty()){
                contato = contatos.get(0);
                Session.add('nameLogin', contato.Name);
                Session.add('empresaLogin', contato.Account.Name);
                isUserCliente = true;
                Map<String, Boolean> gruposContatoMap = new Map<String, Boolean>();
                for (Grupo_Funcionarios__c g : [
                    SELECT Grupo__r.Name
                    FROM Grupo_Funcionarios__c
                    WHERE Contato__c = :contato.Id
                    WITH SYSTEM_MODE
                ]) {
                    gruposContatoMap.put(g.Grupo__r.Name, true);
                }
                this.isAerolevantamento = gruposContatoMap.containsKey('Aerolevantamento');
                this.isGestorTi        = gruposContatoMap.containsKey('Gestores de TI');
                this.isManutencao      = gruposContatoMap.containsKey('Manutenção');
            }
        }
    }

    // Extraído da checagem já feita no construtor (linha ~127) para permitir reuso
    // fora do contexto de página VF (ex.: controllers LWC via RequestRouter).
    public static Boolean isSupervisorApontamento(Id empregadoId) {
        if (empregadoId == null) {
            return false;
        }
        for (Grupo_Funcionarios__c g : [
            SELECT Grupo__r.Name
            FROM Grupo_Funcionarios__c
            WHERE Empregado__c = :empregadoId AND Grupo__r.Name = 'Supervisores de apontamento'
            WITH SYSTEM_MODE
            LIMIT 1
        ]) {
            return true;
        }
        return false;
    }

    public virtual PageReference validate() {

        // verifica se a pessoa esta logada, caso não redireciona ela para a pagina do redirect
        if (idLogin == null) {
            String username = ApexPages.currentPage().getParameters().get('username');
            String password = ApexPages.currentPage().getParameters().get('password');

            if (username != null && password != null) {
                return LoginController.loginQueryString(username, password, redirect);
            } else {
                return new PageReference(redirect);
            }
        }

        // Detecta a página antes da autorização específica de cada módulo.
        String pageUrl = ApexPages.currentPage().getUrl();
        if (String.isBlank(pageUrl)) return null;
        if (pageUrl.contains('?')) pageUrl = pageUrl.substringBefore('?');
        List<String> sPath = pageUrl.split('/');
        String paginaAtual = sPath.get(sPath.size() - 1).toLowerCase();

        // Preserva a política de Contratações já vigente em produção.
        // Consultá-la só nessas páginas evita acoplar os demais módulos.
        Boolean podeAcessarContratacoes = false;
        if (
            paginaAtual == 'solicitacaocontratacaolistagem' ||
            paginaAtual == 'solicitacaocontratacaopage'
        ) {
            podeAcessarContratacoes = ContratacaoAccessService.podeAcessarModulo();
        }

        // ── Controle de acesso por página ──────────────────────────────
        // Map: Nome da página (lowercase) → Boolean de permissão do usuário
        Map<String, Boolean> acessoPorPagina = new Map<String, Boolean>{
            'despesarevisaopage'                   => isUserFinanceiro,
            'controlehorasvoo'                     => isAerolevantamento,
            'manutencaopage'                       => isManutencao,
            'gestortipage'                         => isGestorTi,
            'qualidadepage'                        => isGestorQualidade,
            'rhpage'                               => isRhDp,
            'feriasrhlistagem'                     => isRhDp,
            'feriasgestorlistagem'                 => isGestor,
            'feriassolicitacaoform'                => isGestor || isRhDp,
            'solicitacaocontratacaolistagem'        => podeAcessarContratacoes,
            'solicitacaocontratacaopage'            => podeAcessarContratacoes,
            'solicitacaocontratacaomarketingpage'   => isMarketing,
            'controleproducao'                      => podeOperarControleProducao
        };

        // Verifica se a página está no map e se o usuário tem acesso
        if (acessoPorPagina.containsKey(paginaAtual)) {
            Boolean temAcesso = acessoPorPagina.get(paginaAtual);
            if (temAcesso == null || !temAcesso) {
                System.debug('Usuário não tem acesso a página');
                return new PageReference('/Unauthorized');
            }
        }

        return null; // acesso liberado
    }
}