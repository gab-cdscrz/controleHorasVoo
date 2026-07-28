/*
* @description Controller para gerenciar formulários de Controle de Horas Operacionais da Aeronave
* @author Gabriel Cardoso
* @date 2025-10-03
*/
public without sharing class ControleHorasVooController {
    private static final Set<String> VALID_TABS = new Set<String>{
        'controles', 'calendario', 'novo', 'manutencao', 'aeronaves'
    };
    
    // Propriedades para os objetos principais
    public Controle_Horas_Voo__c controleHoras { get; set; }
    public Aeronave__c aeronave { get; set; }
    public Id aeronaveId { get; set; }
    
    // Propriedades específicas para a aba de manutenção/inspeções
    public Aeronave__c aeronaveManutencao { get; set; }
    public Id aeronaveIdManutencao { get; set; }
    
    // Listas para campos de seleção
    public List<SelectOption> pilotoOptions { get; set; }
    public List<SelectOption> operadorOptions { get; set; }
    
    private List<SelectOption> aeronaveOptionsPrivate;
    public List<SelectOption> aeronaveOptions { 
        get {
            if (aeronaveOptionsPrivate == null) {
                carregarOpcoesAeronave();
            }
            return aeronaveOptionsPrivate;
        } 
        set {
            aeronaveOptionsPrivate = value;
        }
    }
    
    // Variáveis para cálculos e exibição
    public Decimal totalHorasVooMes { get; set; }
    
    public Decimal totField { get; set; }
    
    public String abaAtiva { get; set; }
    public Boolean registroSalvo { get; set; }
    
    // Propriedade para controlar modo "Somente Abastecimento"
    public Boolean somenteAbastecimento { get; set; }
    
    // Propriedades para modo edição (padrão idBackup)
    public Boolean modoEdicao { get; set; }
    public Id controleOriginalId { get; set; }       // backup do Id (removido do form, restaurado no save)
    public Id controleIdParaExcluir { get; set; }    // ID do controle a ser excluído (exclusão direta)
    public Decimal horasOriginaisAeronave { get; set; } // Horas_Voo__c originais do registro (para calcular diff na aeronave)
    
    // Propriedade para o registro filho de Abastecimento
    public Abastecimento__c abastecimentoAtual { get; set; }
    public Id abastecimentoOriginalId { get; set; }  // backup do Id (padrão idBackup)
    // Lista de abastecimentos para edição (suporta múltiplos registros)
    public List<Abastecimento__c> abastecimentosEdicao { get; set; }
    public List<Id> abastecimentoIdsBackup;
    
    // Propriedades calculadas
    public Boolean camposHabilitados { 
        get { return String.isNotBlank(aeronaveId) && aeronave != null; }
        set;
    }
    
    public Boolean camposEditaveis {
        get { return camposHabilitados && !registroSalvo; }
        set;
    }
    
    public String tituloFormulario { 
        get { 
            if (modoEdicao) {
                return '✏️ Editando Voo - ' + (controleHoras.Data_do_Voo__c != null ? controleHoras.Data_do_Voo__c.format() : '');
            }
            return '✈️ Registrar Novo Voo';
        }
        set;
    }
    
    public Boolean camposManutencaoHabilitados {
        get { return String.isNotBlank(aeronaveIdManutencao) && aeronaveManutencao != null; }
        set;
    }
    
    public String mensagemCampoDesabilitado {
        get { return '-- Selecione a aeronave primeiro --'; }
        set;
    }

    // =============================================================================
    // PROPRIEDADES PARA A ABA DE CADASTRO DE AERONAVES (FROTA PRÓPRIA/LOCADA)
    // =============================================================================
    public List<Aeronave__c> listaAeronaves { get; set; }
    public String filtroTipoFrotaAeronaves { get; set; }  // '', 'Propria', 'Locada'
    public String filtroStatusAeronaves { get; set; }     // '', 'ativas', 'inativas'

    public Aeronave__c aeronaveForm { get; set; }
    public Id aeronaveFormOriginalId { get; set; }         // backup do Id (padrão idBackup)
    public Boolean modoEdicaoAeronave { get; set; }

    public String tituloFormularioAeronave {
        get {
            if (aeronaveFormOriginalId != null) {
                return '✏️ Editando Aeronave' + (String.isNotBlank(aeronaveForm.Name) ? ' - ' + aeronaveForm.Name : '');
            }
            return '✈️ Nova Aeronave';
        }
        set;
    }

    // Propriedades para calendário
    public String filtroAeronaveIdCalendario { get; set; }
    public String filtroAnoCalendario { get; set; }
    public String filtroMesCalendario { get; set; }
    public List<DiaCalendario> diasCalendario { get; set; }
    public String nomeAeronaveAtual { get; set; }
    public String nomeMesAtual { get; set; }
    public Integer totalVoosMes { get; set; }
    public Decimal totalHorasMesCalendario { get; set; }
    public Decimal totalCombustivelMes { get; set; }
    public Decimal totalValorMesCalendario { get; set; }
    public Decimal horasTotaisAeronaveAtual { get; set; }
    public Boolean exibirModal { get; set; }
    public List<Controle_Horas_Voo__c> controlesDetalhes { get; set; }
    public String diaSelecionado { get; set; }
    public String nomeDiaSemana { get; set; }
    public List<ControleHorasVooDashboardService.AircraftSummary> dashboardAeronaves { get; set; }
    public Decimal totalHorasDashboard { get; set; }
    public Integer totalVoosDashboard { get; set; }
    public String periodoDashboard { get; set; }

    public Boolean temDashboardAeronaves {
        get { return dashboardAeronaves != null && !dashboardAeronaves.isEmpty(); }
        set;
    }

    /**
     * Returns the canonical flight types used by the calendar and charts.
     */
    public List<ControleHorasVooDashboardService.FlightTypeDefinition> getLegendaTiposVoo() {
        return ControleHorasVooDashboardService.getFlightTypes();
    }
    
    // Classe wrapper para dias do calendário
    public class DiaCalendario {
        public Integer numero { get; set; }
        public String dataCompleta { get; set; }
        public Date dataDate { get; set; }
        public Boolean temVoo { get; set; }
        public Boolean doMesAtual { get; set; }
        public Boolean ehHoje { get; set; }
        public Boolean ehFimSemana { get; set; }
        public String cssClass { get; set; }
        public List<ControleCalendarioWrapper> controles { get; set; }
        public String nomeDiaSemana { get; set; }
        
        public DiaCalendario() {
            temVoo = false;
            doMesAtual = true;
            ehHoje = false;
            ehFimSemana = false;
            cssClass = 'dia-sem-voo';
            controles = new List<ControleCalendarioWrapper>();
        }
    }
    
    // Wrapper que agrega totais dos Abastecimento__c filhos para exibição no calendário
    public class ControleCalendarioWrapper {
        public Controle_Horas_Voo__c controle { get; set; }
        public Decimal totalLitrosAbast { get; set; }
        public Decimal totalValorAbast { get; set; }
        public Integer qtdAbastecimentos { get; set; }
        public Boolean temAbastecimento { get; set; }
        // true somente quando há pelo menos 1 abastecimento E todos têm Faturado__c = true
        public Boolean todosFaturados { get; set; }
        public List<Abastecimento__c> abastecimentos { get; set; }
        
        public ControleCalendarioWrapper(Controle_Horas_Voo__c c) {
            this.controle = c;
            this.totalLitrosAbast = 0;
            this.totalValorAbast = 0;
            this.qtdAbastecimentos = 0;
            this.temAbastecimento = false;
            this.todosFaturados = false;
            this.abastecimentos = new List<Abastecimento__c>();
            if (c.Abastecimentos__r != null) {
                Boolean allFaturados = true;
                for (Abastecimento__c ab : c.Abastecimentos__r) {
                    if (ab.Quantidade__c != null) this.totalLitrosAbast += ab.Quantidade__c;
                    if (ab.Custo_Total__c != null) this.totalValorAbast += ab.Custo_Total__c;
                    if (ab.Faturado__c != true) allFaturados = false;
                    this.qtdAbastecimentos++;
                    this.abastecimentos.add(ab);
                }
                this.temAbastecimento = this.qtdAbastecimentos > 0;
                this.todosFaturados = this.temAbastecimento && allFaturados;
            }
        }
    }

    public class InspecaoViewModel {
        public Inspecao_Aeronave__c registro { get; private set; }
        private InspecaoStatusService.StatusResult calculatedStatus;

        public InspecaoViewModel(
            Inspecao_Aeronave__c inspectionValue,
            Decimal aircraftHours
        ) {
            registro = inspectionValue;
            calculatedStatus = InspecaoStatusService.calculate(
                inspectionValue,
                aircraftHours
            );
        }

        public String status { get { return calculatedStatus.status; } }
        public String nivelStatus { get { return calculatedStatus.level; } }
        public Decimal horasRestantes { get { return calculatedStatus.remainingHours; } }
        public Integer diasRestantes { get { return calculatedStatus.remainingDays; } }
    }
    
    // Constructor
    public ControleHorasVooController() {
        inicializarObjetos();
        carregarOpcoes();
        inicializarCalendario();
    }
    
    // Inicialização de objetos e variáveis
    private void inicializarObjetos() {
        controleHoras = new Controle_Horas_Voo__c();
        abastecimentoAtual = new Abastecimento__c();
        abastecimentosEdicao = new List<Abastecimento__c>();
        abastecimentoIdsBackup = new List<Id>();
        aeronave = new Aeronave__c();
        aeronaveManutencao = new Aeronave__c();
        inspecoesAeronave = new List<InspecaoViewModel>();
        inspecoesProximasCalendario = new List<InspecaoViewModel>();
        controleHoras.Data_do_Voo__c = Date.today();
        abaAtiva = 'controles';

        // Inicializar aba de cadastro de aeronaves
        listaAeronaves = new List<Aeronave__c>();
        filtroTipoFrotaAeronaves = '';
        filtroStatusAeronaves = '';
        aeronaveForm = new Aeronave__c(Tipo_Frota__c = 'Locada', Ativo__c = true);
        aeronaveFormOriginalId = null;
        modoEdicaoAeronave = false;
        registroSalvo = false;
        somenteAbastecimento = false;
        
        // Inicializar flags de edição
        modoEdicao = false;
        controleOriginalId = null;
        horasOriginaisAeronave = null;
        
        // Inicializar campos calculados
        totalHorasVooMes = 0;
        totField = 0;
        
        // Inicializar calendário
        exibirModal = false;
        controlesDetalhes = new List<Controle_Horas_Voo__c>();
        filtroAnoCalendario = String.valueOf(Date.today().year());
        filtroMesCalendario = String.valueOf(Date.today().month());
        diasCalendario = new List<DiaCalendario>();
        totalVoosMes = 0;
        totalHorasMesCalendario = 0;
        totalCombustivelMes = 0;
        totalValorMesCalendario = 0;
        dashboardAeronaves =
            new List<ControleHorasVooDashboardService.AircraftSummary>();
        totalHorasDashboard = 0;
        totalVoosDashboard = 0;
        periodoDashboard = '';
    }
    
    // Método unificado para carregar todas as opções
    private void carregarOpcoes() {
        carregarOpcoesPiloto();
        carregarOpcoesOperador();
        carregarOpcoesAeronave();
    }
    
    // Método auxiliar para criar SelectOptions
    private List<SelectOption> criarSelectOptions(String labelPadrao, List<SObject> objetos, String nomeField) {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', labelPadrao));
        
        for (SObject obj : objetos) {
            String nome = (String)obj.get(nomeField);
            options.add(new SelectOption(obj.Id, nome));
        }
        return options;
    }
    
    private void carregarOpcoesPiloto() {
        pilotoOptions = new List<SelectOption>();
        pilotoOptions.add(new SelectOption('', '-- Selecione um Piloto --'));
        
        try {
            List<Empregado__c> pilotos = [
                SELECT Id, Name
                FROM Empregado__c 
                WHERE isActive__c = true 
                AND (Funcao__r.Name = 'PILOTO')
                WITH SYSTEM_MODE
                ORDER BY Name 
                LIMIT 100
            ];
            pilotoOptions = criarSelectOptions('-- Selecione um Piloto --', pilotos, 'Name');
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar pilotos: ' + e.getMessage()));
        }
    }
    
    private void carregarOpcoesOperador() {
        try {
            List<Empregado__c> operadores = [
                SELECT Id, Name
                FROM Empregado__c
                WHERE isActive__c = true
                AND Funcao__r.Name LIKE 'OPERADOR DE EQUIP ESPECIAIS%' 
                WITH SYSTEM_MODE
                ORDER BY Name
                LIMIT 100
            ];
            operadorOptions = criarSelectOptions('-- Selecione um Operador --', operadores, 'Name');
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar operadores: ' + e.getMessage()));
            operadorOptions = new List<SelectOption>{new SelectOption('', '-- Selecione um Operador --')};
                }
    }
    
    private void carregarOpcoesAeronave() {
        try {
            List<Aeronave__c> aeronaves;
            try {
                aeronaves = [
                    SELECT Id, Name
                    FROM Aeronave__c
                    WHERE Ativo__c = true
                    WITH SYSTEM_MODE
                    ORDER BY Name
                    LIMIT 100
                ];
            } catch (Exception e) {
                aeronaves = [
                    SELECT Id, Name
                    FROM Aeronave__c
                    WITH SYSTEM_MODE
                    ORDER BY Name
                    LIMIT 200
                ];
            }
            
            if (aeronaves.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Nenhuma aeronave foi encontrada no sistema.'));
                aeronaveOptionsPrivate = new List<SelectOption>{new SelectOption('', '-- Selecione uma Aeronave --')};
                    } else {
                        aeronaveOptionsPrivate = criarSelectOptions('-- Selecione uma Aeronave --', aeronaves, 'Name');
                    }
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar aeronaves: ' + e.getMessage()));
            aeronaveOptionsPrivate = new List<SelectOption>{new SelectOption('', '-- Selecione uma Aeronave --')};
                }
    }
    
    // MÉTODOS PARA CONTROLE DE AERONAVE (INSPEÇÕES)
    
    // Quando uma aeronave é selecionada para visualizar inspeções
    public void selecionarAeronaveManutencao() {
        if (String.isBlank(aeronaveIdManutencao)) {
            inspecoesAeronave = new List<InspecaoViewModel>();
            return;
        }
        
        try {
            aeronaveManutencao = [
                SELECT Id, Name, Horas_Totais_de_Voo__c
                FROM Aeronave__c 
                WHERE Id = :aeronaveIdManutencao
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            carregarInspecoesAeronave();
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar dados da aeronave: ' + e.getMessage()));
        }
    }
    
    // MÉTODOS PARA CONTROLE DE HORAS
    
    // Quando uma aeronave é selecionada
    public void selecionarAeronave() {
        if (String.isBlank(aeronaveId)) return;
        
        try {
            aeronave = [
                SELECT Id, Name, Horas_Totais_de_Voo__c
                FROM Aeronave__c 
                WHERE Id = :aeronaveId
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            controleHoras.Aeronave__c = aeronaveId;
            carregarDadosComplementares();
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar dados da aeronave: ' + e.getMessage()));
        }
    }
    
    // Carrega dados complementares após seleção da aeronave
    private void carregarDadosComplementares() {
        // Carregar dados do controle se já foi salvo
        if (registroSalvo && controleHoras.Id != null) {
            controleHoras = ControleHorasVooSelector.selectById(controleHoras.Id);
        }
        calcularTotaisMes();
        // Dados técnicos agora vêm diretamente do banco
    }
    
    // Método unificado para cálculo de totais mensais
    private void calcularTotaisMes() {
        if (aeronaveId == null) return;
        
        try {
            Date referenceDate = controleHoras?.Data_do_Voo__c ?? Date.today();
            Decimal totalHorasDB = ControleHorasVooSelector.selectMonthlyHours(
                aeronaveId,
                referenceDate
            );
            
            if (!registroSalvo) {
                totalHorasVooMes = totalHorasDB + (controleHoras.Horas_Voo__c != null ? controleHoras.Horas_Voo__c : 0);
            } else {
                totalHorasVooMes = totalHorasDB;
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao calcular totais mensais: ' + e.getMessage()));
        }
    }
    
    // Método para salvar o controle de horas
    public PageReference salvarControleHoras() {
        try {
            atribuirUsuarioAlteracao();

            ControleHorasVooService.SaveRequest request =
                new ControleHorasVooService.SaveRequest();
            request.controle = controleHoras;
            request.controleOriginalId = modoEdicao ? controleOriginalId : null;
            request.somenteAbastecimento = somenteAbastecimento;
            request.abastecimentoAtual = abastecimentoAtual;
            request.abastecimentoOriginalId = abastecimentoOriginalId;
            request.abastecimentos = abastecimentosEdicao;
            request.abastecimentoIds = abastecimentoIdsBackup;

            ControleHorasVooService.SaveResult result =
                ControleHorasVooService.save(request);
            controleHoras.Id = result.controleId;
            abastecimentoIdsBackup = new List<Id>();
            
            registroSalvo = true;
            atualizarDadosAposGravacao();
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.CONFIRM,
                result.updated
                    ? 'Controle atualizado com sucesso!'
                    : 'Controle salvo com sucesso!'
            ));
            return null;
        } catch (ControleHorasVooService.ControleHorasVooException exceptionValue) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                exceptionValue.getMessage()
            ));
            return null;
        }
    }

    private void atribuirUsuarioAlteracao() {
        String loginUsuario = (String) Session.getValue('idLogin');
        if (String.isBlank(loginUsuario)) return;

        List<Empregado__c> empregados = [
            SELECT Id
            FROM Empregado__c
            WHERE Login__c = :loginUsuario
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        if (!empregados.isEmpty()) {
            controleHoras.Usuario_Alteracao__c = empregados[0].Id;
            controleHoras.Contato_Alteracao__c = null;
            return;
        }

        List<Contact> contatos = [
            SELECT Id
            FROM Contact
            WHERE Login__c = :loginUsuario
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        if (!contatos.isEmpty()) {
            controleHoras.Contato_Alteracao__c = contatos[0].Id;
            controleHoras.Usuario_Alteracao__c = null;
        }
    }
    
    // Atualiza os dados após salvar - MÉTODO CONSOLIDADO ÚNICO
    private void atualizarDadosAposGravacao() {
        // Recarregar os dados do controle com os campos de relacionamento
        if (controleHoras.Id != null) {
            controleHoras = ControleHorasVooSelector.selectById(controleHoras.Id);
        }
        
        // Recarregar abastecimentos do banco após salvar em modo edição
        if (modoEdicao && controleHoras.Id != null) {
            abastecimentosEdicao = [
                SELECT Id, Quantidade__c, Custo_Unitario__c, Custo_Total__c,
                       Tipo_Combustivel__c, Local__c, Origem_Destino__c,
                       Documento_Referencia__c, Observacoes__c
                FROM Abastecimento__c
                WHERE Voo__c = :controleHoras.Id
                WITH SYSTEM_MODE
                ORDER BY Id ASC
            ];
        }
        
        // CONSOLIDADO: Todos os cálculos em um só lugar
        calcularTotaisMes();
        // Dados técnicos vêm do banco, não são calculados
    }
    
    // Limpa o formulário
    public PageReference limparFormulario() {
        inicializarObjetos();
        aeronaveId = null;
        aeronaveIdManutencao = null;
        return null;
    }
    
    // Cancela a criação de novo controle
    public void cancelarNovoControle() {
        // Limpar apenas os dados do controle, mantendo a aeronave selecionada se houver
        controleHoras = new Controle_Horas_Voo__c();
        abastecimentoAtual = new Abastecimento__c();
        abastecimentoOriginalId = null;
        abastecimentosEdicao = new List<Abastecimento__c>();
        abastecimentoIdsBackup = new List<Id>();
        controleHoras.Data_do_Voo__c = Date.today();
        registroSalvo = false;
        somenteAbastecimento = false;
        
        // Limpar flags de edição
        modoEdicao = false;
        controleOriginalId = null;
        horasOriginaisAeronave = null;
        
        // Recalcular totais se há aeronave selecionada
        if (aeronave?.Id != null) {
            calcularTotaisMes();
        }
        
        // Voltar para a aba de controles
        abaAtiva = 'controles';
    }
    
    // Retorna o nome do mês pelo número
    private String obterNomeMes(Integer mes) {
        Map<Integer, String> nomesMeses = new Map<Integer, String>{
            1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
                5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
                9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro'
                };
                    return nomesMeses.get(mes) ?? 'Mês ' + mes;
    }
    
    // MÉTODOS DE INTERFACE
    
    // Troca a aba ativa
    @SuppressWarnings('PMD.ApexXSSFromURLParam')
    public void trocarAba() {
        String requestedTab = ApexPages.currentPage().getParameters().get('aba');
        if (VALID_TABS.contains(requestedTab)) {
            abaAtiva = requestedTab;
        }
        if (abaAtiva == 'manutencao') {
            // Manter a aeronave selecionada se houver
            if (String.isNotBlank(aeronaveIdManutencao)) {
                selecionarAeronaveManutencao();
            }
        } else if (abaAtiva == 'aeronaves') {
            carregarListaAeronaves();
        } else if (
            abaAtiva == 'controles' &&
            String.isBlank(filtroAeronaveIdCalendario)
        ) {
            carregarDashboardCalendario();
        }
    }
    
    // =============================================================================
    // MÉTODOS PARA CALENDÁRIO
    // =============================================================================
    
    // Inicializar calendário
    private void inicializarCalendario() {
        if (String.isBlank(filtroAeronaveIdCalendario)) {
            diasCalendario = new List<DiaCalendario>();
            carregarDashboardCalendario();
            return;
        }
        carregarCalendario();
    }

    /**
     * @description Sincroniza voos do Planeit para a aeronave selecionada no filtro
     * Requer que aeronave, ano e mês estejam selecionados
     */
    public void sincronizarVoosPlaneit() {
        try {
            // Validar se os filtros foram aplicados
            if (String.isBlank(filtroAeronaveIdCalendario)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
                    '⚠️ Selecione uma aeronave e clique em "Aplicar" antes de sincronizar.'));
                return;
            }
            
            if (String.isBlank(filtroAnoCalendario) || String.isBlank(filtroMesCalendario)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
                    '⚠️ Selecione o ano e mês e clique em "Aplicar" antes de sincronizar.'));
                return;
            }
            
            // Configurar período de sincronização
            Integer ano = Integer.valueOf(filtroAnoCalendario);
            Integer mes = Integer.valueOf(filtroMesCalendario);
            
            // Data início: primeiro dia do mês selecionado
            Date dataInicio = Date.newInstance(ano, mes, 1);
            // Data fim: último dia do mês selecionado
            Date dataFim = Date.newInstance(ano, mes, Date.daysInMonth(ano, mes));
            
            // Buscar apenas a aeronave selecionada no filtro
            List<Aeronave__c> aeronaveSelecionada = [
                SELECT Id, Id_Planeit__c, Name 
                FROM Aeronave__c 
                WHERE Id = :filtroAeronaveIdCalendario
                AND Id_Planeit__c != null
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            if (aeronaveSelecionada.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
                    '⚠️ A aeronave selecionada não possui ID do Planeit configurado.'));
                return;
            }
            
            Aeronave__c aeronave = aeronaveSelecionada[0];
            
            // Montar request para o serviço de sincronização
            PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
            request.idsAeronavesPlaneit = new List<Decimal>{ aeronave.Id_Planeit__c };
            request.idsAeronavesRecords = new List<String>{ aeronave.Id };
            request.dataInicio = dataInicio;
            request.dataFim = dataFim;
            
            // Executar sincronização de voos
            List<SincronizarVoosResponse> respostas = PlaneitAPIService.sincronizarVoosDoPlaneit(new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request });
            
            // Exibir resultado
            if (!respostas.isEmpty()) {
                SincronizarVoosResponse resp = respostas[0];
                if (resp.sucesso) {
                    String msgSucesso = '✅ Sincronização concluída para ' + aeronave.Name + ' (' + obterNomeMes(mes) + '/' + ano + ')! ';
                    if (resp.totalImportados > 0 || resp.totalAtualizados > 0) {
                        msgSucesso += 'Novos: ' + resp.totalImportados + ', Atualizados: ' + resp.totalAtualizados + '.';
                    } else {
                        msgSucesso += 'Nenhum voo novo encontrado no período.';
                    }
                    
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, msgSucesso));
                    
                    // Recarregar calendário com os novos dados
                    carregarCalendario();
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '❌ Erro na sincronização de voos: ' + resp.mensagem));
                }
            }
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '❌ Erro ao sincronizar: ' + e.getMessage()));
            System.debug(LoggingLevel.ERROR, 'Erro sincronizarVoosPlaneit: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    /**
     * @description Sincroniza as inspeções da aeronave selecionada na aba Manutenção
     * Usa o novo serviço InspecaoAeronaveService que armazena cada inspeção individualmente
     */
    public void sincronizarControleTecnicoAeronave() {
        if (String.isBlank(aeronaveIdManutencao)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Selecione uma aeronave primeiro.'));
            return;
        }
        
        try {
            // Usar o novo serviço de inspeções
            InspecaoAeronaveService.ResultadoSincronizacao resultado = 
                InspecaoAeronaveService.sincronizarInspecoesAeronave(aeronaveIdManutencao);
            
            if (resultado.sucesso) {
                String msgSucesso = '✅ Inspeções sincronizadas com sucesso! ';
                msgSucesso += 'Inseridas: ' + resultado.totalInseridos + ', ';
                msgSucesso += 'Atualizadas: ' + resultado.totalAtualizados;
                if (resultado.totalInativos > 0) {
                    msgSucesso += ', Inativadas: ' + resultado.totalInativos;
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, msgSucesso));
                
                // Recarregar inspeções
                carregarInspecoesAeronave();
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '❌ Erro: ' + resultado.mensagem));
            }
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '❌ Erro ao sincronizar: ' + e.getMessage()));
            System.debug(LoggingLevel.ERROR, 'Erro sincronizarControleTecnicoAeronave: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }
    
    /**
     * @description Carrega as inspeções da aeronave selecionada
     */
    public List<InspecaoViewModel> inspecoesAeronave { get; set; }
    public List<InspecaoViewModel> inspecoesProximasCalendario { get; set; }
    
    public void carregarInspecoesAeronave() {
        if (String.isBlank(aeronaveIdManutencao)) {
            inspecoesAeronave = new List<InspecaoViewModel>();
            return;
        }
        
        List<Inspecao_Aeronave__c> inspections = [
            SELECT Id, Name, Nome_Inspecao__c, Inicio_Horas__c, Data_Proxima__c,
                   Horas_Proxima__c, Data_Execucao__c, Horas_Execucao__c,
                   Responsavel_Execucao__c, Ativa__c,
                   Status_Inspecao__c, Ultima_Sincronizacao__c,
                   Aeronave__r.Name, Aeronave__r.Horas_Totais_de_Voo__c
            FROM Inspecao_Aeronave__c
            WHERE Aeronave__c = :aeronaveIdManutencao
            AND Ativa__c = true
            WITH SYSTEM_MODE
            ORDER BY Horas_Proxima__c ASC NULLS LAST, Data_Proxima__c ASC NULLS LAST
        ];
        inspecoesAeronave = wrapInspections(
            inspections,
            aeronaveManutencao?.Horas_Totais_de_Voo__c
        );
    }
    
    /**
     * @description Verifica se há inspeções carregadas
     */
    public Boolean temInspecoes {
        get { return inspecoesAeronave != null && !inspecoesAeronave.isEmpty(); }
        set;
    }

    private static List<InspecaoViewModel> wrapInspections(
        List<Inspecao_Aeronave__c> inspections,
        Decimal aircraftHours
    ) {
        List<InspecaoViewModel> results = new List<InspecaoViewModel>();
        for (Inspecao_Aeronave__c inspection : inspections) {
            results.add(new InspecaoViewModel(inspection, aircraftHours));
        }
        return results;
    }
    
    // Aplicar filtros do calendário
    public void aplicarFiltrosCalendario() {
        if (String.isBlank(filtroAeronaveIdCalendario)) {
            diasCalendario = new List<DiaCalendario>();
            carregarDashboardCalendario();
            return;
        }
        carregarCalendario();
    }

    /**
     * Opens the selected aircraft calendar from the fleet dashboard.
     */
    public void abrirCalendarioDashboard() {
        String aircraftIdParameter =
            ApexPages.currentPage().getParameters().get('aeronaveDashboardId');
        if (String.isBlank(aircraftIdParameter)) return;

        try {
            filtroAeronaveIdCalendario = String.valueOf(
                Id.valueOf(aircraftIdParameter)
            );
            carregarCalendario();
        } catch (Exception exceptionValue) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Não foi possível abrir o calendário da aeronave selecionada.'
            ));
        }
    }

    /**
     * Loads one monthly distribution per active aircraft using a single
     * aggregate query. The already-loaded aircraft options are reused.
     */
    private void carregarDashboardCalendario() {
        dashboardAeronaves =
            new List<ControleHorasVooDashboardService.AircraftSummary>();
        totalHorasDashboard = 0;
        totalVoosDashboard = 0;

        try {
            Integer yearValue = Integer.valueOf(filtroAnoCalendario);
            Integer monthValue = Integer.valueOf(filtroMesCalendario);
            Date startDate = Date.newInstance(yearValue, monthValue, 1);
            Date endDate = startDate.addMonths(1);
            periodoDashboard = obterNomeMes(monthValue) + ' ' + yearValue;

            if (aeronaveOptionsPrivate == null) {
                carregarOpcoesAeronave();
            }

            List<ControleHorasVooDashboardService.AircraftReference>
                aircraftReferences =
                    new List<ControleHorasVooDashboardService.AircraftReference>();

            for (SelectOption aircraftOption : aeronaveOptionsPrivate) {
                if (String.isBlank(aircraftOption.getValue())) {
                    continue;
                }
                aircraftReferences.add(
                    new ControleHorasVooDashboardService.AircraftReference(
                        Id.valueOf(aircraftOption.getValue()),
                        aircraftOption.getLabel()
                    )
                );
            }

            ControleHorasVooDashboardService.DashboardResult dashboardResult =
                ControleHorasVooDashboardService.build(
                    aircraftReferences,
                    startDate,
                    endDate
                );
            dashboardAeronaves = dashboardResult.aircraft;
            totalHorasDashboard = dashboardResult.totalHours;
            totalVoosDashboard = dashboardResult.totalFlights;
        } catch (Exception exceptionValue) {
            dashboardAeronaves =
                new List<ControleHorasVooDashboardService.AircraftSummary>();
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Não foi possível carregar o resumo mensal da frota.'
            ));
        }
    }

    // Visualizar detalhes do dia
    public void visualizarDia() {
        String diaParam = ApexPages.currentPage().getParameters().get('dia');
        if (String.isBlank(diaParam)) return;
        
        try {
            Integer dia = Integer.valueOf(diaParam);
            Integer mes = Integer.valueOf(filtroMesCalendario);
            Integer ano = Integer.valueOf(filtroAnoCalendario);
            
            Date dataVoo = Date.newInstance(ano, mes, dia);
            diaSelecionado = String.valueOf(dia);
            nomeDiaSemana = obterNomeDiaSemana(dataVoo);
            
            controlesDetalhes =
                ControleHorasVooSelector.selectDetailsByAircraftAndDate(
                    filtroAeronaveIdCalendario,
                    dataVoo
                );
            
            exibirModal = true;
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao visualizar dia: ' + e.getMessage()));
        }
    }
    
    // Editar controle existente
    public void editarControle() {
        String controleIdParam = ApexPages.currentPage().getParameters().get('controleId');
        if (String.isBlank(controleIdParam)) return;
        
        try {
            Id controleId = Id.valueOf(controleIdParam);
            Controle_Horas_Voo__c controleOriginal =
                ControleHorasVooSelector.selectById(controleId);
            
            // 2. Armazenar Id e horas originais (padrão idBackup — sem delete/insert)
            controleOriginalId = controleOriginal.Id;
            horasOriginaisAeronave = controleOriginal.Horas_Voo__c ?? 0;
            
            // 3. Atribuir o registro ao form e remover o Id (sem permissão de UPDATE no Site)
            controleHoras = controleOriginal;
            controleHoras.Id = null;
            
            // 4. Limpar campo totalizador calc para ser recalculado
            controleHoras.Total_Horas_Voo__c = null;
            
            // 5. Carregar todos os Abastecimento__c filhos (sem LIMIT)
            List<Abastecimento__c> absFilhos = [
                SELECT Id, Quantidade__c, Custo_Unitario__c, Custo_Total__c,
                       Tipo_Combustivel__c, Local__c, Origem_Destino__c,
                       Documento_Referencia__c, Observacoes__c, Faturado__c
                FROM Abastecimento__c
                WHERE Voo__c = :controleOriginalId
                WITH SYSTEM_MODE
                ORDER BY Id ASC
            ];
            // Padrão idBackup para múltiplos filhos
            abastecimentosEdicao = new List<Abastecimento__c>();
            abastecimentoIdsBackup = new List<Id>();
            for (Abastecimento__c ab : absFilhos) {
                abastecimentoIdsBackup.add(ab.Id);
                ab.Id = null;
                abastecimentosEdicao.add(ab);
            }
            // Manter abastecimentoAtual para compatibilidade (aponta para o primeiro item)
            abastecimentoAtual = abastecimentosEdicao.isEmpty() ? new Abastecimento__c() : abastecimentosEdicao[0];
            abastecimentoOriginalId = abastecimentoIdsBackup.isEmpty() ? null : abastecimentoIdsBackup[0];
            
            // 6. Ativar modo edição e flags
            modoEdicao = true;
            registroSalvo = false;
            somenteAbastecimento = (controleOriginal.Tipo__c == 'AB');
            
            // 7. Ir para aba de edição
            abaAtiva = 'novo';
            
            // 8. Carregar contexto da aeronave
            aeronaveId = controleHoras.Aeronave__c;
            selecionarAeronave();
            
            // 9. Mensagem informativa
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.INFO, 
                '✏️ Modo de edição ativado. Faça as alterações e salve.'
            ));
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar controle: ' + e.getMessage()));
        }
    }
    
    // Criar novo voo para dia específico
    public void novoVooDia() {
        String diaParam = ApexPages.currentPage().getParameters().get('dia');
        if (String.isBlank(diaParam)) return;
        
        try {
            Integer dia = Integer.valueOf(diaParam);
            Integer mes = Integer.valueOf(filtroMesCalendario);
            Integer ano = Integer.valueOf(filtroAnoCalendario);
            
            Date dataVoo = Date.newInstance(ano, mes, dia);
            
            controleHoras = new Controle_Horas_Voo__c();
            controleHoras.Data_do_Voo__c = dataVoo;
            controleHoras.Aeronave__c = filtroAeronaveIdCalendario;
            
            aeronaveId = filtroAeronaveIdCalendario;
            selecionarAeronave();
            registroSalvo = false;
            abaAtiva = 'novo';
            fecharModal();
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao criar novo voo: ' + e.getMessage()));
        }
    }
    
    // Fechar modal
    public void fecharModal() {
        exibirModal = false;
        controlesDetalhes = new List<Controle_Horas_Voo__c>();
        diaSelecionado = '';
        nomeDiaSemana = '';
    }
    
    // Excluir controle de horas de voo
    public void excluirControle() {
        if (controleIdParaExcluir == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'ID do controle não informado.'));
            return;
        }
        
        try {
            Controle_Horas_Voo__c controleParaExcluir = [
                SELECT Id, Data_do_Voo__c, Aeronave__c, Aeronave__r.Name
                FROM Controle_Horas_Voo__c
                WHERE Id = :controleIdParaExcluir
                WITH SYSTEM_MODE
                LIMIT 1
            ];

            ControleHorasVooService.deleteFlight(controleParaExcluir.Id);
            
            // Fechar o modal
            exibirModal = false;
            controlesDetalhes = new List<Controle_Horas_Voo__c>();
            
            // Recarregar calendário para refletir a exclusão
            carregarCalendario();
            
            // Mensagem de sucesso
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.CONFIRM, 
                '✅ Voo do dia ' + controleParaExcluir.Data_do_Voo__c.format() + 
                ' da aeronave ' + controleParaExcluir.Aeronave__r.Name + ' excluído com sucesso.'
            ));
            
        } catch (ControleHorasVooService.ControleHorasVooException exceptionValue) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                exceptionValue.getMessage()
            ));
        }
    }
    
    // Carregar dados do calendário
    private void carregarCalendario() {
        dashboardAeronaves =
            new List<ControleHorasVooDashboardService.AircraftSummary>();
        if (String.isBlank(filtroAeronaveIdCalendario) || 
            String.isBlank(filtroMesCalendario) || 
            String.isBlank(filtroAnoCalendario)) {
                diasCalendario = new List<DiaCalendario>();
                return;
            }
        
        try {
            Integer mes = Integer.valueOf(filtroMesCalendario);
            Integer ano = Integer.valueOf(filtroAnoCalendario);
            
            // Atualizar nome da aeronave atual
            Aeronave__c aeronaveAtual = [
                SELECT Name, Horas_Totais_de_Voo__c
                FROM Aeronave__c
                WHERE Id = :filtroAeronaveIdCalendario
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            nomeAeronaveAtual = aeronaveAtual.Name;
            nomeMesAtual = obterNomeMes(mes) + ' ' + ano;
            horasTotaisAeronaveAtual = aeronaveAtual.Horas_Totais_de_Voo__c;
            
            // Buscar controles do mês
            Date primeiroDia = Date.newInstance(ano, mes, 1);
            Date ultimoDia = Date.newInstance(ano, mes, Date.daysInMonth(ano, mes));
            
            // ALTERAÇÃO: Usar Map para agrupar múltiplos voos por data
            Map<Date, List<Controle_Horas_Voo__c>> controlesPorData = new Map<Date, List<Controle_Horas_Voo__c>>();
            
            // Buscar controles do mês (incluindo abastecimentos para visualização)
            for (Controle_Horas_Voo__c controle : [
                SELECT Id, Name, Data_do_Voo__c,
                Piloto__c, Piloto__r.Name,
                Operador__c, Operador__r.Name,
                Aeronave__c, Aeronave__r.Name,
                Horas_Voo__c, Descricao__c, Tipo__c,
                ARR__c, DEP__c, Acionamento__c, Corte__c, TOT__c,
                Notas__c, Obs__c, Faturado__c, Total_Horas_Voo__c,
                (SELECT Quantidade__c, Custo_Total__c, Faturado__c FROM Abastecimentos__r ORDER BY Id_Abastecimento_Planeit__c ASC NULLS LAST)
                FROM Controle_Horas_Voo__c 
                WHERE Aeronave__c = :filtroAeronaveIdCalendario
                AND Data_do_Voo__c >= :primeiroDia
                AND Data_do_Voo__c <= :ultimoDia
                WITH SYSTEM_MODE
                ORDER BY Data_do_Voo__c, CreatedDate
            ]) {
                // Agrupar controles por data
                if (!controlesPorData.containsKey(controle.Data_do_Voo__c)) {
                    controlesPorData.put(controle.Data_do_Voo__c, new List<Controle_Horas_Voo__c>());
                }
                controlesPorData.get(controle.Data_do_Voo__c).add(controle);
            }
            
            // Gerar dias do calendário
            diasCalendario = new List<DiaCalendario>();
            
            // Calcular primeiro domingo da semana
            Date inicioCalendario = primeiroDia;
            while (obterDiaSemanaNumero(inicioCalendario) != 1) { // 1 = Domingo
                inicioCalendario = inicioCalendario.addDays(-1);
            }
            
            // Gerar 42 dias (6 semanas x 7 dias)
            Date dataAtual = inicioCalendario;
            Date hoje = Date.today();
            
            for (Integer i = 0; i < 42; i++) {
                DiaCalendario dia = new DiaCalendario();
                dia.numero = dataAtual.day();
                dia.dataCompleta = String.valueOf(dataAtual);
                dia.dataDate = dataAtual;
                dia.doMesAtual = (dataAtual.month() == mes && dataAtual.year() == ano);
                dia.ehHoje = dataAtual.isSameDay(hoje);
                Integer diaSemanaNum = obterDiaSemanaNumero(dataAtual);
                dia.ehFimSemana = (diaSemanaNum == 1 || diaSemanaNum == 7); // Domingo ou Sábado
                dia.nomeDiaSemana = obterNomeDiaSemana(dataAtual);
                
                // ALTERAÇÃO: Verificar se tem voos (pode ter múltiplos)
                if (controlesPorData.containsKey(dataAtual)) {
                    List<Controle_Horas_Voo__c> controlesData = controlesPorData.get(dataAtual);
                    dia.temVoo = true;
                    dia.controles = new List<ControleCalendarioWrapper>();
                    for (Controle_Horas_Voo__c c : controlesData) {
                        dia.controles.add(new ControleCalendarioWrapper(c));
                    }
                    dia.cssClass = 'dia-com-voo';
                } else {
                    dia.cssClass = dia.doMesAtual ? 'dia-sem-voo' : 'dia-outro-mes';
                }
                
                // Adicionar classes especiais
                if (dia.ehHoje) dia.cssClass += ' dia-hoje';
                if (dia.ehFimSemana) dia.cssClass += ' fim-semana';
                
                diasCalendario.add(dia);
                dataAtual = dataAtual.addDays(1);
            }
            
            // Calcular resumo mensal com todos os controles
            List<Controle_Horas_Voo__c> todosControles = new List<Controle_Horas_Voo__c>();
            for (List<Controle_Horas_Voo__c> controlesData : controlesPorData.values()) {
                todosControles.addAll(controlesData);
            }
            calcularResumoMensal(todosControles);
            
            // Carregar inspeções próximas para exibir no calendário
            carregarInspecoesProximasCalendario();
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar calendário: ' + e.getMessage()));
            diasCalendario = new List<DiaCalendario>();
        }
    }
    
    // Calcular resumo mensal
    private void calcularResumoMensal(List<Controle_Horas_Voo__c> controles) {
        totalVoosMes = 0;
        totalHorasMesCalendario = 0;
        totalCombustivelMes = 0;
        totalValorMesCalendario = 0;
        
        for (Controle_Horas_Voo__c controle : controles) {
            // Não contar abastecimentos como voos nas estatísticas
            if (controle.Tipo__c != 'AB') {
                totalVoosMes++;
                totalHorasMesCalendario += (controle.Horas_Voo__c ?? 0);
            }
            // Contabilizar combustível e valor a partir dos registros Abastecimento__c
            for (Abastecimento__c ab : controle.Abastecimentos__r) {
                totalCombustivelMes += (ab.Quantidade__c ?? 0);
                totalValorMesCalendario += (ab.Custo_Total__c ?? 0);
            }
        }
    }
    
    // Obter cor do tipo de voo
    public static String obterCorTipo(String tipo) {
        return ControleHorasVooDashboardService.getFlightTypeColor(tipo);
    }
    
    // Obter nome do dia da semana
    public static String obterNomeTipo(String tipo) {
        return ControleHorasVooDashboardService.getFlightTypeLabel(tipo);
    }

    private String obterNomeDiaSemana(Date data) {
        Integer diaSemana = obterDiaSemanaNumero(data);
        switch on diaSemana {
            when 1 { return 'Domingo'; }
            when 2 { return 'Segunda'; }
            when 3 { return 'Terça'; }
            when 4 { return 'Quarta'; }
            when 5 { return 'Quinta'; }
            when 6 { return 'Sexta'; }
            when 7 { return 'Sábado'; }
            when else { return 'Desconhecido'; }
        }
    }
    
    // Método auxiliar para obter número do dia da semana (1=Domingo, 7=Sábado)
    private Integer obterDiaSemanaNumero(Date data) {
        // Usar DateTime para ter acesso a métodos de formatação
        DateTime dt = DateTime.newInstance(data.year(), data.month(), data.day());
        String diaSemanaString = dt.format('EEEE');
        
        switch on diaSemanaString {
            when 'Sunday' { return 1; }
            when 'Monday' { return 2; }
            when 'Tuesday' { return 3; }
            when 'Wednesday' { return 4; }
            when 'Thursday' { return 5; }
            when 'Friday' { return 6; }
            when 'Saturday' { return 7; }
            when else { return 1; } // Default para domingo
        }
    }
    
    // Retorna os meses disponíveis para o filtro do calendário
    public List<SelectOption> getMesesDisponiveis() {
        List<SelectOption> meses = new List<SelectOption>();
        Map<Integer, String> nomesMeses = new Map<Integer, String>{
            1 => 'Janeiro', 2 => 'Fevereiro', 3 => 'Março', 4 => 'Abril',
                5 => 'Maio', 6 => 'Junho', 7 => 'Julho', 8 => 'Agosto',
                9 => 'Setembro', 10 => 'Outubro', 11 => 'Novembro', 12 => 'Dezembro'
                };
                    
                    for (Integer i = 1; i <= 12; i++) {
                        meses.add(new SelectOption(String.valueOf(i), nomesMeses.get(i)));
                    }
        return meses;
    }
    
    // Retorna os anos disponíveis para o calendário
    public List<SelectOption> getAnosDisponiveisCalendario() {
        List<SelectOption> anos = new List<SelectOption>();
        Integer anoAtual = Date.today().year();
        for (Integer i = anoAtual; i >= (anoAtual - 5); i--) {
            anos.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
        }
        return anos;
    }
    
    // =============================================================================
    // MÉTODO PARA CONTROLE DE FATURAMENTO
    // =============================================================================
    
    // Alternar status de faturamento do voo
    public void alternarFaturamento() {
        String controleIdParam = ApexPages.currentPage().getParameters().get('controleId');
        if (String.isBlank(controleIdParam)) return;
        
        try {
            Controle_Horas_Voo__c controle = [
                SELECT Id, Faturado__c 
                FROM Controle_Horas_Voo__c 
                WHERE Id = :controleIdParam 
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            controle.Faturado__c = !controle.Faturado__c;
            Database.update(controle, AccessLevel.SYSTEM_MODE);
            
            // Recarregar calendário
            carregarCalendario();
            
            String mensagem = controle.Faturado__c ? 
                'Voo marcado como faturado!' : 
                'Voo desmarcado como faturado!';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, mensagem));
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Erro ao atualizar status de faturamento: ' + e.getMessage()
            ));
        }
    }
    
    public void alternarFaturamentoAbastecimento() {
        String abastecimentoIdParam = ApexPages.currentPage().getParameters().get('abastecimentoId');
        if (String.isBlank(abastecimentoIdParam)) return;
        
        try {
            Abastecimento__c ab = [
                SELECT Id, Faturado__c 
                FROM Abastecimento__c 
                WHERE Id = :abastecimentoIdParam 
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            
            ab.Faturado__c = !ab.Faturado__c;
            Database.update(ab, AccessLevel.SYSTEM_MODE);
            
            String mensagem = ab.Faturado__c ? 
                'Abastecimento marcado como faturado!' : 
                'Abastecimento desmarcado como faturado!';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, mensagem));

            // Recarregar dados do modal e calendário para refletir a mudança imediatamente
            recarregarControlesDetalhes();
            carregarCalendario();
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Erro ao atualizar faturamento do abastecimento: ' + e.getMessage()
            ));
        }
    }

    // Recarrega controlesDetalhes com base no diaSelecionado atual (para atualizar o modal)
    private void recarregarControlesDetalhes() {
        if (String.isBlank(diaSelecionado) || String.isBlank(filtroMesCalendario) ||
            String.isBlank(filtroAnoCalendario) || String.isBlank(filtroAeronaveIdCalendario)) {
            return;
        }
        try {
            Integer dia = Integer.valueOf(diaSelecionado);
            Integer mes = Integer.valueOf(filtroMesCalendario);
            Integer ano = Integer.valueOf(filtroAnoCalendario);
            Date dataVoo = Date.newInstance(ano, mes, dia);

            controlesDetalhes =
                ControleHorasVooSelector.selectDetailsByAircraftAndDate(
                    filtroAeronaveIdCalendario,
                    dataVoo
                );
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Erro ao recarregar detalhes do voo: ' + e.getMessage()
            ));
        }
    }
    
    // =============================================================================
    // MÉTODO PARA CARREGAR INSPEÇÕES PRÓXIMAS NO CALENDÁRIO
    // =============================================================================
    
    /**
     * @description Carrega as 4 inspeções mais próximas para exibir no calendário
     */
    public void carregarInspecoesProximasCalendario() {
        if (String.isBlank(filtroAeronaveIdCalendario)) {
            inspecoesProximasCalendario = new List<InspecaoViewModel>();
            return;
        }
        
        try {
            // Buscar inspeções ativas da aeronave selecionada no calendário
            // Ordenar por horas e data da próxima inspeção (cálculo de restantes é feito no frontend)
            List<Inspecao_Aeronave__c> inspections = [
                SELECT Id, Name, Nome_Inspecao__c, 
                       Horas_Proxima__c, Data_Proxima__c, 
                       Horas_Execucao__c, Data_Execucao__c,
                       Status_Inspecao__c, Ativa__c,
                       Aeronave__r.Horas_Totais_de_Voo__c
                FROM Inspecao_Aeronave__c
                WHERE Aeronave__c = :filtroAeronaveIdCalendario
                AND Ativa__c = true
                WITH SYSTEM_MODE
                ORDER BY Horas_Proxima__c ASC NULLS LAST, Data_Proxima__c ASC NULLS LAST
                LIMIT 6
            ];
            inspecoesProximasCalendario = wrapInspections(
                inspections,
                horasTotaisAeronaveAtual
            );
        } catch (Exception e) {
            inspecoesProximasCalendario = new List<InspecaoViewModel>();
            System.debug(
                LoggingLevel.ERROR,
                'Erro ao carregar próximas inspeções: ' + e.getMessage()
            );
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR,
                'Não foi possível carregar as próximas inspeções.'
            ));
        }
    }

    // =============================================================================
    // MÉTODOS PARA CADASTRO DE AERONAVES (FROTA PRÓPRIA / LOCADA)
    // =============================================================================

    /**
     * @description Carrega a lista de aeronaves da aba "Aeronaves", aplicando os
     * filtros de tipo de frota e status atualmente selecionados.
     */
    private void carregarListaAeronaves() {
        try {
            String query = 'SELECT Id, Name, Modelo__c, Fabricante__c, Ano_de_Fabricacao__c, ' +
                'Tipo_Frota__c, Empresa_Locadora__c, Ativo__c, Horas_Totais_de_Voo__c, ' +
                'Id_Planeit__c, Consumo__c, Consumo_translado__c, ' +
                'Velocidade_media__c, Velocidade_media_translado__c ' +
                'FROM Aeronave__c';

            List<String> condicoes = new List<String>();
            Map<String, Object> binds = new Map<String, Object>();
            if (filtroTipoFrotaAeronaves == 'Propria' || filtroTipoFrotaAeronaves == 'Locada') {
                condicoes.add('Tipo_Frota__c = :tipoFrota');
                binds.put('tipoFrota', filtroTipoFrotaAeronaves);
            }
            if (filtroStatusAeronaves == 'ativas') {
                condicoes.add('Ativo__c = true');
            } else if (filtroStatusAeronaves == 'inativas') {
                condicoes.add('Ativo__c = false');
            }
            if (!condicoes.isEmpty()) {
                query += ' WHERE ' + String.join(condicoes, ' AND ');
            }
            query += ' ORDER BY Name LIMIT 500';

            listaAeronaves = Database.queryWithBinds(
                query,
                binds,
                AccessLevel.SYSTEM_MODE
            );
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar aeronaves: ' + e.getMessage()));
            listaAeronaves = new List<Aeronave__c>();
        }
    }

    /**
     * @description Action do botão "Aplicar" dos filtros da aba Aeronaves.
     */
    public void aplicarFiltrosAeronaves() {
        carregarListaAeronaves();
    }

    /**
     * @description Abre o formulário para cadastrar uma nova aeronave.
     * Default "Locada", já que é o caso de uso principal desta aba —
     * cadastro de frota própria segue raro/feito via Setup.
     */
    public void novaAeronave() {
        aeronaveForm = new Aeronave__c(Tipo_Frota__c = 'Locada', Ativo__c = true);
        aeronaveFormOriginalId = null;
        modoEdicaoAeronave = true;
    }

    /**
     * @description Carrega uma aeronave existente para edição, seguindo o
     * padrão idBackup (nunca delete+insert).
     */
    public void editarAeronave() {
        String aeronaveIdParam = ApexPages.currentPage().getParameters().get('aeronaveId');
        if (String.isBlank(aeronaveIdParam)) return;

        try {
            Id aeronaveRegistroId = Id.valueOf(aeronaveIdParam);
            Aeronave__c registro = [
                SELECT Id, Name, Modelo__c, Fabricante__c, Ano_de_Fabricacao__c,
                       Tipo_Frota__c, Empresa_Locadora__c, Ativo__c,
                       Consumo__c, Consumo_translado__c,
                       Velocidade_media__c, Velocidade_media_translado__c
                FROM Aeronave__c
                WHERE Id = :aeronaveRegistroId
                WITH SYSTEM_MODE
                LIMIT 1
            ];

            aeronaveFormOriginalId = registro.Id;
            registro.Id = null;
            aeronaveForm = registro;
            modoEdicaoAeronave = true;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar aeronave: ' + e.getMessage()));
        }
    }

    /**
     * @description Salva a aeronave em edição (nova ou existente), seguindo o
     * padrão idBackup. Invalida o cache de aeronaveOptions ao final para que
     * os pickers de aeronave (calendário, novo voo, manutenção) reflitam a
     * mudança na mesma sessão.
     */
    public void salvarAeronave() {
        if (String.isBlank(aeronaveForm.Name)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'O campo Matrícula é obrigatório.'));
            return;
        }

        try {
            // Aeronaves cadastradas por esta aba nunca devem ter Id_Planeit__c —
            // garante que fiquem fora da sincronização automática do Planeit
            aeronaveForm.Id_Planeit__c = null;

            if (aeronaveFormOriginalId != null) {
                aeronaveForm.Id = aeronaveFormOriginalId;
                Database.update(aeronaveForm, AccessLevel.SYSTEM_MODE);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, '✓ Aeronave atualizada com sucesso!'));
            } else {
                Database.insert(aeronaveForm, AccessLevel.SYSTEM_MODE);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, '✓ Aeronave cadastrada com sucesso!'));
            }

            aeronaveOptionsPrivate = null; // invalida cache dos pickers de aeronave

            modoEdicaoAeronave = false;
            aeronaveFormOriginalId = null;
            carregarListaAeronaves();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao salvar aeronave: ' + e.getMessage()));
        }
    }

    /**
     * @description Ativa/desativa uma aeronave diretamente na listagem.
     */
    public void alternarAtivoAeronave() {
        String aeronaveIdParam = ApexPages.currentPage().getParameters().get('aeronaveId');
        if (String.isBlank(aeronaveIdParam)) return;

        try {
            Aeronave__c registro = [
                SELECT Id, Ativo__c
                FROM Aeronave__c
                WHERE Id = :aeronaveIdParam
                WITH SYSTEM_MODE
                LIMIT 1
            ];
            registro.Ativo__c = !registro.Ativo__c;
            Database.update(registro, AccessLevel.SYSTEM_MODE);

            aeronaveOptionsPrivate = null; // invalida cache dos pickers de aeronave

            String mensagem = registro.Ativo__c ? 'Aeronave ativada com sucesso!' : 'Aeronave desativada com sucesso!';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, mensagem));

            carregarListaAeronaves();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao alternar status da aeronave: ' + e.getMessage()));
        }
    }

    /**
     * @description Fecha o formulário de aeronave sem salvar.
     */
    public void cancelarEdicaoAeronave() {
        modoEdicaoAeronave = false;
        aeronaveFormOriginalId = null;
        aeronaveForm = new Aeronave__c(Tipo_Frota__c = 'Locada', Ativo__c = true);
    }
}
