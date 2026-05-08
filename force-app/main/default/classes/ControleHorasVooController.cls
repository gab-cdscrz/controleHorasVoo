/*
* @description Controller para gerenciar formulários de Controle de Horas Operacionais da Aeronave
* @author Gabriel Cardoso
* @date 2025-10-03
*/
public without sharing class ControleHorasVooController {
    
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
        
        public ControleCalendarioWrapper(Controle_Horas_Voo__c c) {
            this.controle = c;
            this.totalLitrosAbast = 0;
            this.totalValorAbast = 0;
            this.qtdAbastecimentos = 0;
            this.temAbastecimento = false;
            this.todosFaturados = false;
            if (c.Abastecimentos__r != null) {
                Boolean allFaturados = true;
                for (Abastecimento__c ab : c.Abastecimentos__r) {
                    if (ab.Quantidade__c != null) this.totalLitrosAbast += ab.Quantidade__c;
                    if (ab.Custo_Total__c != null) this.totalValorAbast += ab.Custo_Total__c;
                    if (ab.Faturado__c != true) allFaturados = false;
                    this.qtdAbastecimentos++;
                }
                this.temAbastecimento = this.qtdAbastecimentos > 0;
                this.todosFaturados = this.temAbastecimento && allFaturados;
            }
        }
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
        aeronave = new Aeronave__c();
        aeronaveManutencao = new Aeronave__c();
        inspecoesAeronave = new List<Inspecao_Aeronave__c>();
        controleHoras.Data_do_Voo__c = Date.today();
        abaAtiva = 'controles';
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
                aeronaves = [SELECT Id, Name FROM Aeronave__c WHERE Ativo__c = true ORDER BY Name LIMIT 100];
            } catch (Exception e) {
                aeronaves = [SELECT Id, Name FROM Aeronave__c ORDER BY Name LIMIT 200];
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
            inspecoesAeronave = new List<Inspecao_Aeronave__c>();
            return;
        }
        
        try {
            aeronaveManutencao = [
                SELECT Id, Name, Horas_Totais_de_Voo__c
                FROM Aeronave__c 
                WHERE Id = :aeronaveIdManutencao LIMIT 1
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
                WHERE Id = :aeronaveId LIMIT 1
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
            controleHoras = [
                SELECT Id, Name, Data_do_Voo__c,
                Piloto__c, Piloto__r.Name,
                Operador__c, Operador__r.Name,
                Aeronave__c, Aeronave__r.Name,
                Horas_Voo__c, Descricao__c, Tipo__c,
                ARR__c, DEP__c, Acionamento__c, Corte__c, TOT__c,
                Notas__c, Obs__c, Faturado__c,
                Total_Horas_Voo__c,
                Usuario_Alteracao__c, Usuario_Alteracao__r.Name,
                Contato_Alteracao__c, Contato_Alteracao__r.Name
                FROM Controle_Horas_Voo__c
                WHERE Id = :controleHoras.Id LIMIT 1
            ];
        }
        calcularTotaisMes();
        // Dados técnicos agora vêm diretamente do banco
    }
    
    // Método unificado para cálculo de totais mensais
    private void calcularTotaisMes() {
        if (aeronaveId == null) return;
        
        try {
            Integer mesAtual = Date.today().month();
            Integer anoAtual = Date.today().year();
            
            Decimal totalHorasDB = 0;
            
            for (Controle_Horas_Voo__c controle : [
                SELECT Horas_Voo__c 
                FROM Controle_Horas_Voo__c 
                WHERE CALENDAR_MONTH(Data_do_Voo__c) = :mesAtual 
                AND CALENDAR_YEAR(Data_do_Voo__c) = :anoAtual
                AND Aeronave__c = :aeronaveId
                AND Tipo__c != 'AB'
            ]) {
                totalHorasDB += (controle.Horas_Voo__c != null ? controle.Horas_Voo__c : 0);
            }
            
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
        if (!validarCamposObrigatorios()) return null;
        
        try {
            // Se for somente abastecimento, definir automaticamente o Tipo como "AB"
            if (somenteAbastecimento) {
                controleHoras.Tipo__c = 'AB';
                controleHoras.Horas_Voo__c = 0;
                controleHoras.TOT__c = 0;
            }
            
            // Capturar as horas do voo antes de salvar
            Decimal horasVooAtual = controleHoras.Horas_Voo__c ?? 0;
            
            // Capturar o ID do usuário logado do sistema de sessão customizado e buscar o Empregado__c
            String loginUsuario = (String)Session.getValue('idLogin');
            
            if (String.isNotBlank(loginUsuario)) {
                List<Empregado__c> empregados = [
                    SELECT Id 
                    FROM Empregado__c 
                    WHERE Login__c = :loginUsuario 
                    LIMIT 1
                ];
                if (!empregados.isEmpty()) {
                    controleHoras.Usuario_Alteracao__c = empregados[0].Id;
                } else {
                    List<Contact> contatos = [SELECT Id FROM Contact WHERE Login__c = :loginUsuario LIMIT 1];
                    if (!contatos.isEmpty()) {
                        controleHoras.Contato_Alteracao__c = contatos[0].Id;
                    }
                }
            }
            
            sincronizarCamposCalculados();
            
            // LÓGICA DE EDIÇÃO (padrão idBackup — update direto)
            if (modoEdicao && controleOriginalId != null) {
                // MODO EDIÇÃO: restaura o Id e executa UPDATE
                controleHoras.Id = controleOriginalId;
                
                // 1. Atualizar horas da aeronave pelo diff (novas - originais)
                if (aeronave?.Id != null) {
                    Decimal diff = horasVooAtual - (horasOriginaisAeronave ?? 0);
                    if (diff != 0) {
                        aeronave.Horas_Totais_de_Voo__c = (aeronave.Horas_Totais_de_Voo__c ?? 0) + diff;
                        update aeronave;
                    }
                }
                
                // 2. Atualizar o registro existente
                update controleHoras;
                
                // 3. Salvar/atualizar abastecimento se houver dados
                salvarAbastecimento(controleHoras.Id, controleHoras.Data_do_Voo__c);
                
                // 4. Mensagem de sucesso
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.CONFIRM, 
                    '✓ Controle atualizado com sucesso!'
                ));
                
                // 5. Limpar flags de edição
                modoEdicao = false;
                controleOriginalId = null;
                horasOriginaisAeronave = null;
                
            } else {
                // FLUXO NORMAL: novo registro
                insert controleHoras;
                
                // Atualizar horas totais da aeronave (apenas para registros novos)
                if (aeronave?.Id != null && horasVooAtual > 0) {
                    aeronave.Horas_Totais_de_Voo__c = (aeronave.Horas_Totais_de_Voo__c ?? 0) + horasVooAtual;
                    update aeronave;
                }
                
                // Salvar abastecimento se houver dados
                salvarAbastecimento(controleHoras.Id, controleHoras.Data_do_Voo__c);
                
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.CONFIRM, 
                    '✓ Controle salvo com sucesso!'
                ));
            }
            
            registroSalvo = true;
            
            // CONSOLIDADO: Atualizar tudo em um só lugar
            atualizarDadosAposGravacao();
            return null;
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao salvar: ' + e.getMessage()));
            return null;
        }
    }
    
    // Salva ou atualiza o registro de Abastecimento__c vinculado ao voo
    private void salvarAbastecimento(Id vooId, Date dataVoo) {
        Boolean temDados = abastecimentoAtual.Quantidade__c != null || abastecimentoAtual.Custo_Unitario__c != null;
        if (!temDados) return;
        
        abastecimentoAtual.Voo__c = vooId;
        abastecimentoAtual.Data_Voo__c = dataVoo;
        
        if (abastecimentoOriginalId != null) {
            // Padrão idBackup: restaura o Id antes do UPDATE
            abastecimentoAtual.Id = abastecimentoOriginalId;
            update abastecimentoAtual;
            abastecimentoOriginalId = null;
        } else {
            insert abastecimentoAtual;
        }
    }
    
    // Validação de campos obrigatórios
    private Boolean validarCamposObrigatorios() {
        List<String> erros = new List<String>();
        
        if (controleHoras.Piloto__c == null) {
            erros.add('O campo Piloto é obrigatório.');
        }
        if (controleHoras.Data_do_Voo__c == null) {
            erros.add('O campo Data do Voo é obrigatório.');
        }
        
        for (String erro : erros) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, erro));
        }
        return erros.isEmpty();
    }
    
    // Atualiza os dados após salvar - MÉTODO CONSOLIDADO ÚNICO
    private void atualizarDadosAposGravacao() {
        // Recarregar os dados do controle com os campos de relacionamento
        if (controleHoras.Id != null) {
            controleHoras = [
                SELECT Id, Name, Data_do_Voo__c,
                Piloto__c, Piloto__r.Name,
                Operador__c, Operador__r.Name,
                Aeronave__c, Aeronave__r.Name,
                Horas_Voo__c, Descricao__c, Tipo__c,
                ARR__c, DEP__c, Acionamento__c, Corte__c, TOT__c,
                Notas__c, Obs__c, Faturado__c,
                Total_Horas_Voo__c,
                Usuario_Alteracao__c, Usuario_Alteracao__r.Name,
                Contato_Alteracao__c, Contato_Alteracao__r.Name
                FROM Controle_Horas_Voo__c 
                WHERE Id = :controleHoras.Id LIMIT 1
            ];
        }
        
        // CONSOLIDADO: Todos os cálculos em um só lugar
        calcularTotaisMes();
        // Dados técnicos vêm do banco, não são calculados
    }
    
    // Método auxiliar para sincronizar campos calculados
    private void sincronizarCamposCalculados() {
        if (totField != null) {
            controleHoras.TOT__c = totField;
        }
        if (!registroSalvo) {
            controleHoras.Total_Horas_Voo__c = totalHorasVooMes + (controleHoras.Horas_Voo__c ?? 0);
        } else {
            controleHoras.Total_Horas_Voo__c = totalHorasVooMes;
        }
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
    public void trocarAba() {
        abaAtiva = ApexPages.currentPage().getParameters().get('aba') ?? abaAtiva;
        if (abaAtiva == 'manutencao') {
            // Manter a aeronave selecionada se houver
            if (String.isNotBlank(aeronaveIdManutencao)) {
                selecionarAeronaveManutencao();
            }
        }
    }
    
    // =============================================================================
    // MÉTODOS PARA CALENDÁRIO
    // =============================================================================
    
    // Inicializar calendário
    private void inicializarCalendario() {
        if (String.isBlank(filtroAeronaveIdCalendario)) {
            diasCalendario = new List<DiaCalendario>();
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
    public List<Inspecao_Aeronave__c> inspecoesAeronave { get; set; }
    public List<Inspecao_Aeronave__c> inspecoesProximasCalendario { get; set; }
    
    public void carregarInspecoesAeronave() {
        if (String.isBlank(aeronaveIdManutencao)) {
            inspecoesAeronave = new List<Inspecao_Aeronave__c>();
            return;
        }
        
        inspecoesAeronave = [
            SELECT Id, Name, Nome_Inspecao__c, Inicio_Horas__c, Data_Proxima__c,
                   Horas_Proxima__c, Data_Execucao__c, Horas_Execucao__c,
                   Responsavel_Execucao__c, Ativa__c,
                   Status_Inspecao__c, Ultima_Sincronizacao__c,
                   Aeronave__r.Name, Aeronave__r.Horas_Totais_de_Voo__c
            FROM Inspecao_Aeronave__c
            WHERE Aeronave__c = :aeronaveIdManutencao
            AND Ativa__c = true
            ORDER BY Horas_Proxima__c ASC NULLS LAST, Data_Proxima__c ASC NULLS LAST
        ];
    }
    
    /**
     * @description Verifica se há inspeções carregadas
     */
    public Boolean temInspecoes {
        get { return inspecoesAeronave != null && !inspecoesAeronave.isEmpty(); }
        set;
    }
    
    // Aplicar filtros do calendário
    public void aplicarFiltrosCalendario() {
        if (String.isBlank(filtroAeronaveIdCalendario)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Selecione uma aeronave para visualizar o calendário.'));
            diasCalendario = new List<DiaCalendario>();
            return;
        }
        carregarCalendario();
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
            
            // ALTERAÇÃO: Buscar TODOS os controles ATIVOS do dia
            controlesDetalhes = [
                SELECT Id, Aeronave__c, Aeronave__r.Name, Data_do_Voo__c, 
                Piloto__c, Piloto__r.Name, Operador__c, Operador__r.Name,
                Tipo__c, Descricao__c, DEP__c, ARR__c, 
                Acionamento__c, Corte__c, TOT__c, Horas_Voo__c,
                Notas__c, Obs__c, Faturado__c,
                CreatedDate, Usuario_Alteracao__c, Usuario_Alteracao__r.Name,
                Contato_Alteracao__c, Contato_Alteracao__r.Name,
                (SELECT Id, Local__c, Origem_Destino__c, Tipo_Combustivel__c,
                        Quantidade__c, Unidade__c, Custo_Unitario__c, Custo_Total__c,
                        Documento_Referencia__c, Faturado__c
                 FROM Abastecimentos__r
                 ORDER BY Id_Abastecimento_Planeit__c ASC NULLS LAST)
                FROM Controle_Horas_Voo__c 
                WHERE Aeronave__c = :filtroAeronaveIdCalendario 
                AND Data_do_Voo__c = :dataVoo
                ORDER BY CreatedDate
            ];
            
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
            // 1. Buscar o registro original completo 
            Controle_Horas_Voo__c controleOriginal = [
                SELECT Id, Name, Data_do_Voo__c,
                       Piloto__c, Piloto__r.Name,
                       Operador__c, Operador__r.Name,
                       Aeronave__c, Aeronave__r.Name,
                       Horas_Voo__c, Descricao__c, Tipo__c,
                       ARR__c, DEP__c, Acionamento__c, Corte__c, TOT__c,
                       Notas__c, Obs__c, Faturado__c,
                       Total_Horas_Voo__c, Id_Voo_Planeit__c
                FROM Controle_Horas_Voo__c 
                WHERE Id = :controleIdParam
                LIMIT 1
            ];
            
            // 2. Armazenar Id e horas originais (padrão idBackup — sem delete/insert)
            controleOriginalId = controleOriginal.Id;
            horasOriginaisAeronave = controleOriginal.Horas_Voo__c ?? 0;
            
            // 3. Atribuir o registro ao form e remover o Id (sem permissão de UPDATE no Site)
            controleHoras = controleOriginal;
            controleHoras.Id = null;
            
            // 4. Limpar campo totalizador calc para ser recalculado
            controleHoras.Total_Horas_Voo__c = null;
            
            // 5. Carregar o Abastecimento__c filho (se existir)
            List<Abastecimento__c> absFilho = [
                SELECT Id, Quantidade__c, Custo_Unitario__c, Custo_Total__c,
                       Tipo_Combustivel__c, Local__c, Origem_Destino__c,
                       Documento_Referencia__c, Observacoes__c, Faturado__c
                FROM Abastecimento__c
                WHERE Voo__c = :controleOriginalId
                LIMIT 1
            ];
            abastecimentoAtual = absFilho.isEmpty() ? new Abastecimento__c() : absFilho[0];
            // Padrão idBackup para o filho: guarda o Id e remove do form
            if (abastecimentoAtual.Id != null) {
                abastecimentoOriginalId = abastecimentoAtual.Id;
                abastecimentoAtual.Id = null;
            } else {
                abastecimentoOriginalId = null;
            }
            
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
            // Buscar o registro para obter informações antes de excluir
            Controle_Horas_Voo__c controleParaExcluir = [
                SELECT Id, Data_do_Voo__c, Aeronave__c, Aeronave__r.Name, Horas_Voo__c
                FROM Controle_Horas_Voo__c 
                WHERE Id = :controleIdParaExcluir
                LIMIT 1
            ];
            
            // Atualizar horas totais da aeronave (subtrair as horas do voo excluído)
            if (controleParaExcluir.Horas_Voo__c != null && controleParaExcluir.Horas_Voo__c > 0) {
                Aeronave__c aeronave = [
                    SELECT Id, Horas_Totais_de_Voo__c
                    FROM Aeronave__c
                    WHERE Id = :controleParaExcluir.Aeronave__c
                    LIMIT 1
                ];
                
                if (aeronave.Horas_Totais_de_Voo__c != null) {
                    aeronave.Horas_Totais_de_Voo__c -= controleParaExcluir.Horas_Voo__c;
                    update aeronave;
                }
            }
            
            // Excluir o registro
            delete controleParaExcluir;
            
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
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao excluir voo: ' + e.getMessage()));
        }
    }
    
    // Carregar dados do calendário
    private void carregarCalendario() {
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
            Aeronave__c aeronaveAtual = [SELECT Name, Horas_Totais_de_Voo__c FROM Aeronave__c WHERE Id = :filtroAeronaveIdCalendario LIMIT 1];
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
        if (String.isBlank(tipo)) return '#6c757d';
        
        switch on tipo {
            when 'TR' { return '#007bff'; } // Azul para Treinamento
            when 'SA' { return '#28a745'; } // Verde para Serviço Aéreo
            when 'EX' { return '#ffc107'; } // Amarelo para Experimental
            when 'TT' { return '#dc3545'; } // Vermelho para Teste
            when 'AB' { return '#ff9800'; } // Laranja para Abastecimento
            when else { return '#6c757d'; } // Cinza para outros
        }
    }
    
    // Obter nome do dia da semana
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
                LIMIT 1
            ];
            
            controle.Faturado__c = !controle.Faturado__c;
            update controle;
            
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
                LIMIT 1
            ];
            
            ab.Faturado__c = !ab.Faturado__c;
            update ab;
            
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

            controlesDetalhes = [
                SELECT Id, Aeronave__c, Aeronave__r.Name, Data_do_Voo__c,
                       Piloto__c, Piloto__r.Name, Operador__c, Operador__r.Name,
                       Tipo__c, Descricao__c, DEP__c, ARR__c,
                       Acionamento__c, Corte__c, TOT__c, Horas_Voo__c,
                       Notas__c, Obs__c, Faturado__c,
                       CreatedDate, Usuario_Alteracao__c, Usuario_Alteracao__r.Name,
                       Contato_Alteracao__c, Contato_Alteracao__r.Name,
                       (SELECT Id, Local__c, Origem_Destino__c, Tipo_Combustivel__c,
                               Quantidade__c, Unidade__c, Custo_Unitario__c, Custo_Total__c,
                               Documento_Referencia__c, Faturado__c
                        FROM Abastecimentos__r
                        ORDER BY Id_Abastecimento_Planeit__c ASC NULLS LAST)
                FROM Controle_Horas_Voo__c
                WHERE Aeronave__c = :filtroAeronaveIdCalendario
                AND Data_do_Voo__c = :dataVoo
                ORDER BY CreatedDate
            ];
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
            inspecoesProximasCalendario = new List<Inspecao_Aeronave__c>();
            return;
        }
        
        try {
            // Buscar inspeções ativas da aeronave selecionada no calendário
            // Ordenar por horas e data da próxima inspeção (cálculo de restantes é feito no frontend)
            inspecoesProximasCalendario = [
                SELECT Id, Name, Nome_Inspecao__c, 
                       Horas_Proxima__c, Data_Proxima__c, 
                       Horas_Execucao__c, Data_Execucao__c,
                       Status_Inspecao__c,
                       Aeronave__r.Horas_Totais_de_Voo__c
                FROM Inspecao_Aeronave__c
                WHERE Aeronave__c = :filtroAeronaveIdCalendario
                AND Ativa__c = true
                ORDER BY Horas_Proxima__c ASC NULLS LAST, Data_Proxima__c ASC NULLS LAST
                LIMIT 6
            ];
        } catch (Exception e) {
            inspecoesProximasCalendario = new List<Inspecao_Aeronave__c>();
        }
    }
}