/**
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
    public Decimal totalLitrosAvgasMes { get; set; }
    public Decimal valorTotalAvgasMes { get; set; }
    
    public Decimal totField { get; set; }
    public Decimal totalField { get; set; }
    public Decimal mediaField { get; set; }
    
    public String abaAtiva { get; set; }
    public Boolean registroSalvo { get; set; }
    
    // Propriedade para controlar modo "Somente Abastecimento"
    public Boolean somenteAbastecimento { get; set; }
    
    // Propriedades para modo edição (wrapper com re-inserção)
    public Boolean modoEdicao { get; set; }
    public Id controleOriginalId { get; set; }
    public Id controleIdParaExcluir { get; set; } // ID do controle a ser excluído
    public Decimal horasOriginaisAeronave { get; set; } // Armazena horas totais antes da edição
    
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
    
    // Controle de visualização e filtros
    public List<ControlesPorAeronave> controlesOrganizados { get; set; }
    public String filtroAeronaveId { get; set; }
    public Integer filtroAno { get; set; }
    public Integer filtroMes { get; set; }
    
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
    
    // Classes internas para organização hierárquica dos dados
    public class ControlesPorAeronave {
        public String aeronaveId { get; set; }
        public String aeronaveNome { get; set; }
        public List<ControlesPorAno> anos { get; set; }
        
        public ControlesPorAeronave() {
            anos = new List<ControlesPorAno>();
        }
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
        public List<Controle_Horas_Voo__c> controles { get; set; }
        public String nomeDiaSemana { get; set; }
        
        // Propriedades para compatibilidade (primeiro voo do dia)
        public Controle_Horas_Voo__c controle { 
            get { 
                return (controles != null && !controles.isEmpty()) ? controles[0] : null; 
            } 
            set; 
        }
        public String pilotoNome { 
            get { 
                return (controles != null && !controles.isEmpty() && controles[0].Piloto__r != null) ? 
                    controles[0].Piloto__r.Name : null; 
            } 
            set; 
        }
        public String operadorNome { 
            get { 
                return (controles != null && !controles.isEmpty() && controles[0].Operador__r != null) ? 
                    controles[0].Operador__r.Name : null; 
            } 
            set; 
        }
        public String horasFormatadas { 
            get { 
                if (controles == null || controles.isEmpty()) return '';
                Decimal totalHoras = 0;
                for (Controle_Horas_Voo__c ctrl : controles) {
                    totalHoras += (ctrl.Horas_Voo__c != null ? ctrl.Horas_Voo__c : 0);
                }
                return totalHoras > 0 ? String.valueOf(totalHoras) + 'h' : '';
            } 
            set; 
        }
        public String rota { 
            get { 
                if (controles == null || controles.isEmpty()) return '';
                Controle_Horas_Voo__c primeiro = controles[0];
                return (String.isNotBlank(primeiro.DEP__c) && String.isNotBlank(primeiro.ARR__c)) ? 
                    primeiro.DEP__c + '  ' + primeiro.ARR__c : '';
            } 
            set; 
        }
        public String tipoVoo { 
            get { 
                return (controles != null && !controles.isEmpty()) ? controles[0].Tipo__c : null; 
            } 
            set; 
        }
        public String corTipo { 
            get { 
                return (controles != null && !controles.isEmpty()) ? 
                    ControleHorasVooController.obterCorTipo(controles[0].Tipo__c) : '#6c757d'; 
            } 
            set; 
        }
        
        public DiaCalendario() {
            temVoo = false;
            doMesAtual = true;
            ehHoje = false;
            ehFimSemana = false;
            cssClass = 'dia-sem-voo';
            controles = new List<Controle_Horas_Voo__c>();
        }
    }
    
    public class ControlesPorAno {
        public Integer ano { get; set; }
        public List<ControlesPorMes> meses { get; set; }
        public Decimal totalHorasAno { get; set; }
        public Decimal totalLitrosAno { get; set; }
        public Decimal totalValorAno { get; set; }
        
        public ControlesPorAno() {
            meses = new List<ControlesPorMes>();
            totalHorasAno = 0;
            totalLitrosAno = 0;
            totalValorAno = 0;
        }
    }
    
    public class ControlesPorMes {
        public Integer mes { get; set; }
        public String nomesMes { get; set; }
        public List<Controle_Horas_Voo__c> controles { get; set; }
        public Decimal totalHorasMes { get; set; }
        public Decimal totalLitrosMes { get; set; }
        public Decimal totalValorMes { get; set; }
        
        public ControlesPorMes() {
            controles = new List<Controle_Horas_Voo__c>();
            totalHorasMes = 0;
            totalLitrosMes = 0;
            totalValorMes = 0;
        }
    }
    
    // Constructor
    public ControleHorasVooController() {
        inicializarObjetos();
        carregarOpcoes();
        carregarControlesExistentes();
        inicializarCalendario();
    }
    
    // Inicialização de objetos e variáveis
    private void inicializarObjetos() {
        controleHoras = new Controle_Horas_Voo__c();
        aeronave = new Aeronave__c();
        aeronaveManutencao = new Aeronave__c();
        inspecoesAeronave = new List<Inspecao_Aeronave__c>();
        controleHoras.Data_do_Voo__c = Date.today();
        abaAtiva = 'controles';
        registroSalvo = false;
        somenteAbastecimento = false;
        filtroAno = Date.today().year();
        filtroMes = Date.today().month();
        
        // Inicializar flags de edição
        modoEdicao = false;
        controleOriginalId = null;
        horasOriginaisAeronave = null;
        
        // Inicializar campos calculados
        totalHorasVooMes = 0;
        totalLitrosAvgasMes = 0;
        valorTotalAvgasMes = 0;
        totField = 0;
        totalField = 0;
        mediaField = 0;
        
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
    
    // Método auxiliar para obter total de horas do mês atual para uma aeronave
    private Decimal obterTotalHorasMesAtual(Id aeronaveId) {
        Integer mesAtual = Date.today().month();
        Integer anoAtual = Date.today().year();
        
        Decimal totalHoras = 0;
        
        try {
            for(Controle_Horas_Voo__c controle : [
                SELECT Horas_Voo__c 
                FROM Controle_Horas_Voo__c 
                WHERE CALENDAR_MONTH(Data_do_Voo__c) = :mesAtual 
                AND CALENDAR_YEAR(Data_do_Voo__c) = :anoAtual
                AND Aeronave__c = :aeronaveId
                AND Tipo__c != 'AB'
            ]) {
                totalHoras += (controle.Horas_Voo__c != null ? controle.Horas_Voo__c : 0);
            }
        } catch (Exception e) {
            // Silenciar erro - continuar com totalHoras = 0
        }
        
        return totalHoras;
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
                Litros_AVGAS__c, Media__c, Valor_R_L__c, Total__c,
                Notas__c, Obs__c, Faturado__c,
                Total_avgas_mes__c, Total_mes_R__c, Total_Horas_Voo__c, Sub_Total_AvgasMes__c,
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
            // Obter o mês e ano atual
            Integer mesAtual = Date.today().month();
            Integer anoAtual = Date.today().year();
            
            // Cálculo de totais já existentes no banco de dados
            Decimal totalHorasDB = 0;
            Decimal totalLitrosDB = 0;
            Decimal totalValorDB = 0;
            
            // Buscar registros do mês atual para a aeronave selecionada
            for(Controle_Horas_Voo__c controle : [
                SELECT Horas_Voo__c, Litros_AVGAS__c, Total__c 
                FROM Controle_Horas_Voo__c 
                WHERE CALENDAR_MONTH(Data_do_Voo__c) = :mesAtual 
                AND CALENDAR_YEAR(Data_do_Voo__c) = :anoAtual
                AND Aeronave__c = :aeronaveId
                AND Tipo__c != 'AB'
            ]) {
                // Acumular os valores existentes
                totalHorasDB += (controle.Horas_Voo__c != null ? controle.Horas_Voo__c : 0);
                totalLitrosDB += (controle.Litros_AVGAS__c != null ? controle.Litros_AVGAS__c : 0);
                totalValorDB += (controle.Total__c != null ? controle.Total__c : 0);
            }
            
            // Adicionar valores do formulário atual se não forem nulos e o registro não estiver salvo
            if (!registroSalvo) {
                totalHorasVooMes = totalHorasDB + (controleHoras.Horas_Voo__c != null ? controleHoras.Horas_Voo__c : 0);
                totalLitrosAvgasMes = totalLitrosDB + (controleHoras.Litros_AVGAS__c != null ? controleHoras.Litros_AVGAS__c : 0);
                
                // Cálculo do valor total
                Decimal valorAtual = 0;
                if (controleHoras.Total__c != null) {
                    valorAtual = controleHoras.Total__c;
                } else if (controleHoras.Litros_AVGAS__c != null && controleHoras.Valor_R_L__c != null) {
                    valorAtual = controleHoras.Litros_AVGAS__c * controleHoras.Valor_R_L__c;
                }
                
                valorTotalAvgasMes = totalValorDB + valorAtual;
            } else {
                // Se o registro já foi salvo, apenas exibir os totais do banco
                totalHorasVooMes = totalHorasDB;
                totalLitrosAvgasMes = totalLitrosDB;
                valorTotalAvgasMes = totalValorDB;
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
            
            // LÓGICA DE EDIÇÃO COM WRAPPER (RE-INSERÇÃO)
            if (modoEdicao && controleOriginalId != null) {
                // MODO EDIÇÃO: Deletar original e inserir nova versão (wrapper)
                // Isso permite edição em Sites sem permissão de UPDATE
                
                // 1. Buscar dados completos do registro original para reverter
                Controle_Horas_Voo__c registroOriginal = [
                    SELECT Horas_Voo__c, Litros_AVGAS__c, Total__c
                    FROM Controle_Horas_Voo__c 
                    WHERE Id = :controleOriginalId
                    LIMIT 1
                ];
                
                // 2. Reverter horas da aeronave (subtrair valores do registro original)
                if (aeronave?.Id != null && horasOriginaisAeronave != null) {
                    Decimal horasOriginais = registroOriginal.Horas_Voo__c ?? 0;
                    aeronave.Horas_Totais_de_Voo__c = horasOriginaisAeronave - horasOriginais;
                }
                
                // 3. Deletar registro original
                delete new Controle_Horas_Voo__c(Id = controleOriginalId);
                
                // 4. RECALCULAR totais mensais SEM o registro antigo (foi deletado)
                // Isso é crítico para evitar duplicação de valores
                calcularTotaisMes();
                
                // 5. Sincronizar novamente os campos calculados com totais corretos
                sincronizarCamposCalculados();
                
                // 6. Inserir novo registro (com novos valores)
                insert controleHoras;
                
                // 7. Adicionar novas horas à aeronave
                if (aeronave?.Id != null && horasVooAtual > 0) {
                    aeronave.Horas_Totais_de_Voo__c = (aeronave.Horas_Totais_de_Voo__c ?? 0) + horasVooAtual;
                    update aeronave;
                }
                
                // 5. Mensagem de sucesso
                ApexPages.addMessage(new ApexPages.Message(
                    ApexPages.Severity.CONFIRM, 
                    '✓ Controle atualizado com sucesso!'
                ));
                
                // 6. Limpar flags de edição
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
    
    // Validação mínima de campos obrigatórios
    private Boolean validarCamposObrigatorios() {
        List<String> erros = new List<String>();
        
        // Validação mínima: apenas verificar se pelo menos um campo relevante foi preenchido
        Boolean temAlgumCampo = false;
        
        if (controleHoras.Data_do_Voo__c != null) temAlgumCampo = true;
        if (controleHoras.Piloto__c != null) temAlgumCampo = true;
        if (String.isNotBlank(controleHoras.Tipo__c)) temAlgumCampo = true;
        if (String.isNotBlank(controleHoras.Descricao__c)) temAlgumCampo = true;
        if (controleHoras.Horas_Voo__c != null) temAlgumCampo = true;
        if (String.isNotBlank(controleHoras.ARR__c)) temAlgumCampo = true;
        if (String.isNotBlank(controleHoras.DEP__c)) temAlgumCampo = true;
        
        if (!temAlgumCampo) {
            erros.add('Preencha pelo menos um campo para salvar o controle de horas.');
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
                Litros_AVGAS__c, Media__c, Valor_R_L__c, Total__c,
                Notas__c, Obs__c, Faturado__c,
                Total_avgas_mes__c, Total_mes_R__c, Total_Horas_Voo__c, Sub_Total_AvgasMes__c,
                Usuario_Alteracao__c, Usuario_Alteracao__r.Name,
                Contato_Alteracao__c, Contato_Alteracao__r.Name
                FROM Controle_Horas_Voo__c 
                WHERE Id = :controleHoras.Id LIMIT 1
            ];
        }
        
        // CONSOLIDADO: Todos os cálculos em um só lugar
        calcularTotaisMes();
        // Dados técnicos vêm do banco, não são calculados
        
        carregarControlesExistentes();
    }
    
    // Método auxiliar para sincronizar campos calculados
    private void sincronizarCamposCalculados() {
        if (totField != null) {
            controleHoras.TOT__c = totField;
        }
        controleHoras.Total__c = totalField;
        controleHoras.Media__c = mediaField;
        
        // CORREÇÃO: Calcular totais mensais corretamente
        // Se o registro já está salvo, usar apenas os totais mensais existentes
        // Se é um novo registro, incluir os valores atuais nos totais
        if (registroSalvo) {
            // Registro já salvo: usar apenas os totais calculados
            controleHoras.Total_Horas_Voo__c = totalHorasVooMes;
            controleHoras.Total_avgas_mes__c = totalLitrosAvgasMes;
            controleHoras.Sub_Total_AvgasMes__c = valorTotalAvgasMes;
        } else {
            // Novo registro: incluir valores atuais nos totais mensais
            controleHoras.Total_Horas_Voo__c = totalHorasVooMes + (controleHoras.Horas_Voo__c ?? 0);
            controleHoras.Total_avgas_mes__c = totalLitrosAvgasMes + (controleHoras.Litros_AVGAS__c ?? 0);
            controleHoras.Sub_Total_AvgasMes__c = valorTotalAvgasMes + (controleHoras.Total__c ?? 0);
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
        controleHoras.Data_do_Voo__c = Date.today();
        registroSalvo = false;
        
        // Limpar flags de edição
        modoEdicao = false;
        controleOriginalId = null;
        horasOriginaisAeronave = null;
        
        // Recalcular totais se há aeronave selecionada
        if (aeronave?.Id != null) {
            calcularTotaisMes();
            // Dados técnicos vêm do banco
        }
        
        // Voltar para a aba de controles
        abaAtiva = 'controles';
    }
    
    // MÉTODOS PARA VISUALIZAÇÃO E FILTROS
    
    // Carrega os controles existentes de forma hierárquica
    public void carregarControlesExistentes() {
        controlesOrganizados = new List<ControlesPorAeronave>();
        
        try {
            List<Controle_Horas_Voo__c> controles = Database.query(construirQueryControles());
            Map<String, ControlesPorAeronave> aeronaveMap = new Map<String, ControlesPorAeronave>();
            
            for (Controle_Horas_Voo__c controle : controles) {
                processarControle(controle, aeronaveMap);
            }
            
            controlesOrganizados = aeronaveMap.values();
            
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Erro ao carregar controles: ' + e.getMessage()));
        }
    }
    
    // Constrói a query para buscar controles
    private String construirQueryControles() {
        String query = 
            'SELECT Id, Name, Data_do_Voo__c, Piloto__r.Name, Operador__r.Name, ' +
            'Horas_Voo__c, Descricao__c, Tipo__c, ARR__c, DEP__c, Acionamento__c, Corte__c, TOT__c, ' +
            'Litros_AVGAS__c, Media__c, Valor_R_L__c, Total__c, Notas__c, Obs__c, Faturado__c, ' +
            'Total_avgas_mes__c, Total_mes_R__c, Total_Horas_Voo__c, Sub_Total_AvgasMes__c, ' +
            'Aeronave__c, Aeronave__r.Name ' +
            'FROM Controle_Horas_Voo__c ';
        
        List<String> whereConditions = new List<String>();
        
        if (String.isNotBlank(filtroAeronaveId)) {
            whereConditions.add('Aeronave__c = \'' + String.escapeSingleQuotes(filtroAeronaveId) + '\'');
        }
        
        if (filtroAno != null) {
            whereConditions.add('CALENDAR_YEAR(Data_do_Voo__c) = ' + filtroAno);
        }
        
        if (filtroMes != null) {
            whereConditions.add('CALENDAR_MONTH(Data_do_Voo__c) = ' + filtroMes);
        }
        
        if (!whereConditions.isEmpty()) {
            query += 'WHERE ' + String.join(whereConditions, ' AND ') + ' ';
        }
        
        return query + 'ORDER BY Aeronave__r.Name, Data_do_Voo__c DESC LIMIT 1000';
    }
    
    // Processa um controle para a visualização hierárquica
    private void processarControle(Controle_Horas_Voo__c controle, Map<String, ControlesPorAeronave> aeronaveMap) {
        String aeronaveKey = controle.Aeronave__c;
        
        if (!aeronaveMap.containsKey(aeronaveKey)) {
            ControlesPorAeronave aeronaveWrapper = new ControlesPorAeronave();
            aeronaveWrapper.aeronaveId = controle.Aeronave__c;
            aeronaveWrapper.aeronaveNome = controle.Aeronave__r.Name;
            aeronaveMap.put(aeronaveKey, aeronaveWrapper);
        }
        
        ControlesPorAeronave aeronaveWrapper = aeronaveMap.get(aeronaveKey);
        Integer ano = controle.Data_do_Voo__c.year();
        Integer mes = controle.Data_do_Voo__c.month();
        
        ControlesPorAno anoWrapper = obterOuCriarAnoWrapper(aeronaveWrapper, ano);
        ControlesPorMes mesWrapper = obterOuCriarMesWrapper(anoWrapper, mes);
        
        mesWrapper.controles.add(controle);
        
        Decimal horas = controle.Horas_Voo__c ?? 0;
        Decimal litros = controle.Litros_AVGAS__c ?? 0;
        Decimal valor = controle.Total__c ?? 0;
        
        mesWrapper.totalHorasMes += horas;
        mesWrapper.totalLitrosMes += litros;
        mesWrapper.totalValorMes += valor;
        
        anoWrapper.totalHorasAno += horas;
        anoWrapper.totalLitrosAno += litros;
        anoWrapper.totalValorAno += valor;
    }
    
    // Obtém ou cria um wrapper de ano
    private ControlesPorAno obterOuCriarAnoWrapper(ControlesPorAeronave aeronaveWrapper, Integer ano) {
        for (ControlesPorAno existingAno : aeronaveWrapper.anos) {
            if (existingAno.ano == ano) {
                return existingAno;
            }
        }
        
        ControlesPorAno anoWrapper = new ControlesPorAno();
        anoWrapper.ano = ano;
        aeronaveWrapper.anos.add(anoWrapper);
        return anoWrapper;
    }
    
    // Obtém ou cria um wrapper de mês
    private ControlesPorMes obterOuCriarMesWrapper(ControlesPorAno anoWrapper, Integer mes) {
        for (ControlesPorMes existingMes : anoWrapper.meses) {
            if (existingMes.mes == mes) {
                return existingMes;
            }
        }
        
        ControlesPorMes mesWrapper = new ControlesPorMes();
        mesWrapper.mes = mes;
        mesWrapper.nomesMes = obterNomeMes(mes);
        anoWrapper.meses.add(mesWrapper);
        return mesWrapper;
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
        if (abaAtiva == 'controles') {
            carregarControlesExistentes();
        } else if (abaAtiva == 'manutencao') {
            // Manter a aeronave selecionada se houver
            if (String.isNotBlank(aeronaveIdManutencao)) {
                selecionarAeronaveManutencao();
            }
        }
    }
    
    // Método para recalcular os valores quando há alteração nos campos relevantes
    public void recalcularValores() {
        calcularTotaisMes();
        // Dados técnicos de manutenção vêm do banco/API, não são calculados
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
                Litros_AVGAS__c, Valor_R_L__c, Total__c, Media__c, Notas__c, Obs__c, Faturado__c,
                CreatedDate, Usuario_Alteracao__c, Usuario_Alteracao__r.Name,
                Contato_Alteracao__c, Contato_Alteracao__r.Name
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
                       Litros_AVGAS__c, Media__c, Valor_R_L__c, Total__c,
                       Notas__c, Obs__c, Faturado__c,
                       Total_avgas_mes__c, Total_mes_R__c, Total_Horas_Voo__c, Sub_Total_AvgasMes__c,
                       Id_Voo_Planeit__c
                FROM Controle_Horas_Voo__c 
                WHERE Id = :controleIdParam
                LIMIT 1
            ];
            
            // 2. Armazenar ID do original (será deletado após novo insert)
            controleOriginalId = controleOriginal.Id;
            
            // 3. Buscar aeronave para armazenar horas atuais (para reverter se necessário)
            Aeronave__c aeronaveOriginal = [
                SELECT Id, Horas_Totais_de_Voo__c
                FROM Aeronave__c
                WHERE Id = :controleOriginal.Aeronave__c
                LIMIT 1
            ];
            horasOriginaisAeronave = aeronaveOriginal.Horas_Totais_de_Voo__c;
            
            // 4. Criar clone do registro (SEM ID - para re-inserção)
            controleHoras = controleOriginal.clone(false, true, false, false);
            controleHoras.Id = null; // Garantir que é um novo registro
            
            // CRÍTICO: Preservar Id_Voo_Planeit__c para evitar duplicatas na sincronização
            controleHoras.Id_Voo_Planeit__c = controleOriginal.Id_Voo_Planeit__c;
            
            // 5. Limpar campos calculados/automáticos
            controleHoras.Total_Horas_Voo__c = null;
            controleHoras.Total_avgas_mes__c = null;
            controleHoras.Sub_Total_AvgasMes__c = null;
            controleHoras.Total_mes_R__c = null;
            
            // 6. Ativar modo edição
            modoEdicao = true;
            registroSalvo = false;
            
            // 7. Ir para aba de edição
            abaAtiva = 'novo';
            
            // 8. Carregar contexto da aeronave
            aeronaveId = controleHoras.Aeronave__c;
            selecionarAeronave();
            
            // 9. Mensagem informativa
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.INFO, 
                '✏️ Modo de edição ativado. Faça as alterações e salve. O registro original será substituído.'
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
                Litros_AVGAS__c, Media__c, Valor_R_L__c, Total__c,
                Notas__c, Obs__c, Faturado__c,
                Total_avgas_mes__c, Total_mes_R__c, Total_Horas_Voo__c, Sub_Total_AvgasMes__c
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
                    dia.controles = controlesData;
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
            // Mas sempre contabilizar combustível e valor
            totalCombustivelMes += (controle.Litros_AVGAS__c ?? 0);
            totalValorMesCalendario += (controle.Total__c ?? 0);
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