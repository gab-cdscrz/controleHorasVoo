@isTest
public class ControleHorasVooTest {

    // Helpers utilitários para padronização dos testes
    private static Date baseDate() {
        return Date.today();
    }
    // Configura PageReference e parâmetros antes de criar o controller
    private static ControleHorasVooController newControllerWithPage(Map<String, String> params) {
        PageReference p = Page.ControleHorasVoo;
        if (params != null) {
            for (String k : params.keySet()) {
                p.getParameters().put(k, params.get(k));
            }
        }
        Test.setCurrentPage(p);
        return new ControleHorasVooController();
    }
    public static void addParameterPage(String paramKey, String paramValue) {
        ApexPages.currentPage().getParameters().put(paramKey, paramValue);
    }
    public static void setParameterPage(String paramKey, String paramValue) {
        Map<String,String> params = ApexPages.currentPage().getParameters();
        params.clear(); // limpa todos os parametros atuais da pagina
        params.put(paramKey, paramValue);
    }
    public static void setSession(id login) {
        Session.add('idLogin', login);
    }
    
    // Fluxo completo: salvar voo + carregar controles
    @isTest
    public static void testCriarControleCompleto(){
        Date base = baseDate();
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        empregado__c empregadoOperador = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        Test.startTest();
        ControleHorasVooController controller01 = new ControleHorasVooController();
        controller01.aeronaveId = aeronave.Id;
        controller01.selecionarAeronave();
        controller01.controleHoras.Data_do_Voo__c = base;
        controller01.controleHoras.Piloto__c = empregadoPiloto.Id;
        controller01.controleHoras.Operador__c = empregadoOperador.Id;
        controller01.controleHoras.Acionamento__c = Time.newInstance(8, 0, 0, 0);
        controller01.controleHoras.Corte__c = Time.newInstance(9, 15, 0, 0);
        controller01.controleHoras.Tipo__c = 'SA';
        controller01.controleHoras.Litros_AVGAS__c = 50;
        controller01.controleHoras.Valor_R_L__c = 7.25;
        controller01.salvarControleHoras();
        Test.stopTest();
        
        System.assert(controller01.registroSalvo);
        System.assert(controller01.controleHoras.Id != null);
    }
    
    @isTest
    public static void testCriarControleCompletoCancelar(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.aeronaveId = aeronave.Id;
        controller.selecionarAeronave();
        controller.controleHoras.Data_do_Voo__c = baseDate();
        controller.controleHoras.Acionamento__c = Time.newInstance(8, 0, 0, 0);
        controller.controleHoras.Corte__c = Time.newInstance(9, 15, 0, 0);
        controller.cancelarNovoControle();
        System.assertEquals('controles', controller.abaAtiva);
        System.assertEquals(false, controller.registroSalvo);
    }
    
    // Cobertura do calendário com dados + modal
    @isTest
    public static void testCalendarioBasico(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        empregado__c empregadoOperador = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        Date base = baseDate();
        insert new List<Controle_Horas_Voo__c>{
            new Controle_Horas_Voo__c(Aeronave__c = aeronave.Id, Data_do_Voo__c = base, Piloto__c = empregadoPiloto.Id, Tipo__c = 'SA', Horas_Voo__c = 1.5, TOT__c = 1.5),
            new Controle_Horas_Voo__c(Aeronave__c = aeronave.Id, Data_do_Voo__c = base.addDays(-1), Piloto__c = empregadoPiloto.Id, Tipo__c = 'TR', Horas_Voo__c = 1.75, TOT__c = 1.75)
        };
        
        ControleHorasVooController controller = newControllerWithPage(new Map<String,String>{ 'dia' => String.valueOf(base.day()) });
        controller.abaAtiva = 'calendario';
        controller.filtroAeronaveIdCalendario = aeronave.Id;
        controller.filtroAnoCalendario = String.valueOf(base.year());
        controller.filtroMesCalendario = String.valueOf(base.month());
        controller.aplicarFiltrosCalendario();
        
        System.assert(controller.diasCalendario != null);
        System.assertEquals(42, controller.diasCalendario.size());
        
        controller.visualizarDia();
        System.assert(controller.exibirModal);
        controller.fecharModal();
        System.assert(!controller.exibirModal);
        
        // cor do tipo
        System.assertEquals('#28a745', ControleHorasVooController.obterCorTipo('SA'));
    }
    
    // Edição via wrapper (delete+insert) e flags de edição
    @isTest
    public static void testEdicaoControleExistente(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        // Criar um registro original
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.aeronaveId = aeronave.Id;
        controller.selecionarAeronave();
        controller.controleHoras.Data_do_Voo__c = baseDate();
        controller.controleHoras.Acionamento__c = Time.newInstance(8, 0, 0, 0);
        controller.controleHoras.Corte__c = Time.newInstance(9, 0, 0, 0);
        controller.controleHoras.Piloto__c = empregadoPiloto.Id;
        controller.controleHoras.Tipo__c = 'SA';
        controller.controleHoras.Horas_Voo__c = 1;
        controller.salvarControleHoras();
        
        Id controleId = controller.controleHoras.Id;
        PageReference pageRef = Page.ControleHorasVoo;
        pageRef.getParameters().put('controleId', String.valueOf(controleId));
        Test.setCurrentPage(pageRef);
        
        ControleHorasVooController controller2 = new ControleHorasVooController();
        controller2.editarControle();
        
        System.assert(controller2.modoEdicao);
        System.assertEquals(controleId, controller2.controleOriginalId);
        
        // efetivamente salvar a edição (novo insert) mudando horas
        controller2.controleHoras.Horas_Voo__c = 2;
        controller2.salvarControleHoras();
        
        System.assertEquals(true, controller2.modoEdicao);
        System.assert(controller2.controleHoras.Id != null);
    }
    
    // Faturamento de abastecimento e reload de detalhes do modal
    @isTest
    public static void testFiltrosEVisualizacaoHierarquica(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        Date base = baseDate();
        
        Controle_Horas_Voo__c voo = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id, Data_do_Voo__c = base,
            Piloto__c = empregadoPiloto.Id, Tipo__c = 'SA',
            Horas_Voo__c = 1.5, TOT__c = 1.5
        );
        insert voo;
        
        Abastecimento__c ab = new Abastecimento__c(
            Voo__c = voo.Id, Data_Voo__c = base,
            Quantidade__c = 150, Custo_Unitario__c = 6.50,
            Faturado__c = false
        );
        insert ab;
        
        PageReference p = Page.ControleHorasVoo;
        p.getParameters().put('dia', String.valueOf(base.day()));
        p.getParameters().put('abastecimentoId', ab.Id);
        Test.setCurrentPage(p);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.filtroAeronaveIdCalendario = aeronave.Id;
        controller.filtroAnoCalendario = String.valueOf(base.year());
        controller.filtroMesCalendario = String.valueOf(base.month());
        controller.aplicarFiltrosCalendario();
        controller.visualizarDia();
        System.assert(controller.exibirModal);
        
        // Cobre alternarFaturamentoAbastecimento + recarregarControlesDetalhes (privado)
        controller.alternarFaturamentoAbastecimento();
        Abastecimento__c abAtualizado = [SELECT Faturado__c FROM Abastecimento__c WHERE Id = :ab.Id];
        System.assertEquals(true, abAtualizado.Faturado__c);
        
        // Cobre temInspecoes e selecionarAeronaveManutencao
        controller.aeronaveIdManutencao = aeronave.Id;
        controller.selecionarAeronaveManutencao();
        System.assertNotEquals(null, controller.inspecoesAeronave);
        System.assertEquals(false, controller.temInspecoes);
    }
    
    // Validações mínimas e comportamento ao aplicar filtros de calendário sem aeronave
    @isTest
    public static void testValidacoesEErros(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.controleHoras = new Controle_Horas_Voo__c();
        PageReference result = controller.salvarControleHoras();
        System.assert(!controller.registroSalvo);
        
        controller.abaAtiva = 'calendario';
        // sem filtro de aeronave calendário -> mensagem e lista vazia
        controller.aplicarFiltrosCalendario();
        System.assert(controller.diasCalendario != null && controller.diasCalendario.isEmpty());
    }
    
    // Limpeza de formulário
    @isTest
    public static void testLimparFormulario(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.aeronaveId = aeronave.Id;
        controller.selecionarAeronave();
        controller.controleHoras.Data_do_Voo__c = Date.today();
        controller.controleHoras.Tipo__c = 'SA';
        controller.controleHoras.Acionamento__c = Time.newInstance(8, 0, 0, 0);
        controller.controleHoras.Corte__c = Time.newInstance(10, 0, 0, 0);
        controller.salvarControleHoras();
        
        controller.limparFormulario();
        System.assert(controller.controleHoras.Id == null);
        System.assert(!controller.registroSalvo);
        System.assertEquals(null, controller.aeronaveId);
        System.assertEquals(null, controller.aeronaveIdManutencao);
    }
    
    // Modo somente abastecimento (Tipo AB)
    @isTest
    public static void testModoSomenteAbastecimento(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        Test.startTest();
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.aeronaveId = aeronave.Id;
        controller.selecionarAeronave();
        controller.somenteAbastecimento = true;
        controller.controleHoras.Data_do_Voo__c = baseDate();
        controller.controleHoras.Aeronave__c = aeronave.Id;
        controller.controleHoras.Piloto__c = empregadoPiloto.Id;
        controller.controleHoras.Litros_AVGAS__c = 100;
        controller.controleHoras.Valor_R_L__c = 7.00;
        controller.controleHoras.Descricao__c = 'Abastecimento teste';
        controller.salvarControleHoras();
        Test.stopTest();
        
        System.assertEquals('AB', controller.controleHoras.Tipo__c, 'Tipo deveria ser AB para abastecimento');
        System.assertEquals(0, controller.controleHoras.Horas_Voo__c, 'Horas de voo deveriam ser 0 para abastecimento');
        System.assertEquals(0, controller.controleHoras.TOT__c, 'TOT deveria ser 0 para abastecimento');
    }
    
    // Getters de opções e anos/meses
    @isTest
    public static void testGettersSelectOptions(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        
        System.assertEquals(12, controller.getMesesDisponiveis().size());
        System.assert(controller.getAnosDisponiveisCalendario().size() >= 3);
        System.assert(controller.aeronaveOptions.size() > 0);
    }
    
    // Flags/propriedades calculadas
    @isTest
    public static void testPropriedadesCalculadas(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        
        System.assert(!controller.camposHabilitados);
        
        controller.aeronaveId = aeronave.Id;
        controller.selecionarAeronave();
        
        System.assert(controller.camposHabilitados);
        System.assertEquals('✈️ Registrar Novo Voo', controller.tituloFormulario);
    }
    
    // Troca de abas
    @isTest
    public static void testAbasENavegacao(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        
        System.assertEquals('controles', controller.abaAtiva);
        
        controller.abaAtiva = 'calendario';
        controller.trocarAba();
        
        System.assertEquals('calendario', controller.abaAtiva);
    }
    
    // Interações do calendário e cores
    @isTest
    public static void testCalendarioInteracoes(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        insert new Controle_Horas_Voo__c(Aeronave__c = aeronave.Id, Data_do_Voo__c = Date.today(), Piloto__c = empregadoPiloto.Id, Tipo__c = 'SA', Horas_Voo__c = 2.0, TOT__c = 2.0);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.abaAtiva = 'calendario';
        controller.filtroAeronaveIdCalendario = aeronave.Id;
        controller.filtroAnoCalendario = String.valueOf(baseDate().year());
        controller.filtroMesCalendario = String.valueOf(baseDate().month());
        controller.aplicarFiltrosCalendario();
        
        System.assert(controller.diasCalendario != null);
        System.assertEquals(42, controller.diasCalendario.size());
        System.assertEquals('#28a745', ControleHorasVooController.obterCorTipo('SA'));
    }
    
    // Rotas de erro defensivas
    @isTest
    public static void testTratamentoErros(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.visualizarDia();   // sem parâmetro 'dia'
        controller.editarControle();  // sem parâmetro 'controleId'
        controller.novoVooDia();      // sem parâmetro 'dia'
        controller.alternarFaturamento(); // sem parâmetro 'controleId'
    }
    
    // Alternar faturamento com parâmetro
    @isTest
    public static void testAlternarFaturamento(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        // criar um voo
        Controle_Horas_Voo__c c = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Data_do_Voo__c = Date.today(),
            Piloto__c = empregadoPiloto.Id,
            Tipo__c = 'SA',
            Horas_Voo__c = 1,
            TOT__c = 1,
            Faturado__c = false
        );
        insert c;
        
        PageReference p = Page.ControleHorasVoo;
        p.getParameters().put('controleId', c.Id);
        Test.setCurrentPage(p);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.alternarFaturamento();
        
        Controle_Horas_Voo__c atualizado = [SELECT Faturado__c FROM Controle_Horas_Voo__c WHERE Id = :c.Id];
        System.assertEquals(true, atualizado.Faturado__c);
    }
    
    @isTest
    public static void testBotaoSincronizar(){
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.sincronizarVoosPlaneit();
    }
    
    // Teste de exclusão de voo via modal do calendário
    @isTest
    public static void testExcluirControle(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        // Criar um voo para excluir
        Controle_Horas_Voo__c voo = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Data_do_Voo__c = Date.today(),
            Piloto__c = empregadoPiloto.Id,
            Tipo__c = 'SA',
            Horas_Voo__c = 2.5,
            TOT__c = 2.5
        );
        insert voo;
        
        // Atualizar horas totais da aeronave manualmente para simular estado real
        aeronave.Horas_Totais_de_Voo__c = 100;
        update aeronave;
        
        Test.startTest();
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.filtroAeronaveIdCalendario = aeronave.Id;
        controller.filtroAnoCalendario = String.valueOf(Date.today().year());
        controller.filtroMesCalendario = String.valueOf(Date.today().month());
        controller.aplicarFiltrosCalendario();
        
        // Atribuir o ID do controle a excluir (simula actionFunction)
        controller.controleIdParaExcluir = voo.Id;
        controller.excluirControle();
        Test.stopTest();
        
        // Verificar que o voo foi excluído
        List<Controle_Horas_Voo__c> voosRestantes = [SELECT Id FROM Controle_Horas_Voo__c WHERE Id = :voo.Id];
        System.assertEquals(0, voosRestantes.size(), 'Voo deveria ter sido excluído');
        
        // Verificar que as horas foram subtraídas da aeronave
        Aeronave__c aeronaveAtualizada = [SELECT Horas_Totais_de_Voo__c FROM Aeronave__c WHERE Id = :aeronave.Id];
        System.assertEquals(
            0,
            aeronaveAtualizada.Horas_Totais_de_Voo__c,
            'O total deve ser recalculado a partir dos voos restantes'
        );
    }
    
    // Teste de exclusão sem ID (caminho de erro)
    @isTest
    public static void testExcluirControleSemId(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.controleIdParaExcluir = null;
        controller.excluirControle();
        
        // Deve adicionar mensagem de erro
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR));
    }
    
    // Teste de sincronização de controle técnico
    @isTest
    public static void testSincronizarControleTecnicoAeronave(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        
        // Teste sem aeronave selecionada
        controller.sincronizarControleTecnicoAeronave();
        
        // Teste com aeronave selecionada
        controller.aeronaveIdManutencao = aeronave.Id;
        controller.sincronizarControleTecnicoAeronave();
    }
    
    // Teste de novo voo para dia específico via calendário
    @isTest
    public static void testNovoVooDiaComParametro(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        Date base = baseDate();
        
        PageReference p = Page.ControleHorasVoo;
        p.getParameters().put('dia', String.valueOf(base.day()));
        Test.setCurrentPage(p);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.filtroAeronaveIdCalendario = aeronave.Id;
        controller.filtroAnoCalendario = String.valueOf(base.year());
        controller.filtroMesCalendario = String.valueOf(base.month());
        controller.aplicarFiltrosCalendario();
        
        controller.novoVooDia();
        
        System.assertEquals('novo', controller.abaAtiva);
        System.assertEquals(base, controller.controleHoras.Data_do_Voo__c);
        System.assertEquals(aeronave.Id, controller.controleHoras.Aeronave__c);
    }
    
    // Teste de múltiplos voos no mesmo dia (calendário)
    @isTest
    public static void testMultiplosVoosMesmoDia(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        Date base = baseDate();
        
        // Inserir múltiplos voos no mesmo dia
        insert new List<Controle_Horas_Voo__c>{
            new Controle_Horas_Voo__c(Aeronave__c = aeronave.Id, Data_do_Voo__c = base, Piloto__c = empregadoPiloto.Id, Tipo__c = 'SA', Horas_Voo__c = 1.0, TOT__c = 1.0),
            new Controle_Horas_Voo__c(Aeronave__c = aeronave.Id, Data_do_Voo__c = base, Piloto__c = empregadoPiloto.Id, Tipo__c = 'TR', Horas_Voo__c = 1.5, TOT__c = 1.5),
            new Controle_Horas_Voo__c(Aeronave__c = aeronave.Id, Data_do_Voo__c = base, Piloto__c = empregadoPiloto.Id, Tipo__c = 'AB', Litros_AVGAS__c = 50, Horas_Voo__c = 0, TOT__c = 0)
        };
        
        PageReference p = Page.ControleHorasVoo;
        p.getParameters().put('dia', String.valueOf(base.day()));
        Test.setCurrentPage(p);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.filtroAeronaveIdCalendario = aeronave.Id;
        controller.filtroAnoCalendario = String.valueOf(base.year());
        controller.filtroMesCalendario = String.valueOf(base.month());
        controller.aplicarFiltrosCalendario();
        
        // Visualizar dia com múltiplos voos
        controller.visualizarDia();
        
        System.assert(controller.exibirModal);
        System.assertEquals(3, controller.controlesDetalhes.size(), 'Deveria ter 3 voos no dia');
    }
    
    // Teste de cores de tipos de voo
    @isTest
    public static void testCoresTiposVoo(){
        System.assertEquals('#007bff', ControleHorasVooController.obterCorTipo('TR')); // Treinamento
        System.assertEquals('#28a745', ControleHorasVooController.obterCorTipo('SA')); // Serviço Aéreo
        System.assertEquals('#ffc107', ControleHorasVooController.obterCorTipo('EX')); // Experimental
        System.assertEquals('#dc3545', ControleHorasVooController.obterCorTipo('TT')); // Teste
        System.assertEquals('#ff9800', ControleHorasVooController.obterCorTipo('AB')); // Abastecimento
        System.assertEquals('#6c757d', ControleHorasVooController.obterCorTipo('XX')); // Outro
        System.assertEquals('#6c757d', ControleHorasVooController.obterCorTipo(null)); // Nulo
    }
    
    // Teste de camposHabilitados, camposEditaveis e outras propriedades
    @isTest 
    public static void testPropriedadesAdicionais(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        
        // Sem aeronave
        System.assertEquals(false, controller.camposHabilitados);
        System.assertEquals(false, controller.camposEditaveis);
        System.assertEquals(false, controller.camposManutencaoHabilitados);
        System.assertNotEquals(null, controller.mensagemCampoDesabilitado);
        
        // Com aeronave selecionada
        controller.aeronaveId = aeronave.Id;
        controller.selecionarAeronave();
        
        System.assertEquals(true, controller.camposHabilitados);
        System.assertEquals(true, controller.camposEditaveis);
        
        // Após salvar
        controller.registroSalvo = true;
        System.assertEquals(false, controller.camposEditaveis);
    }
    
    // Teste do fluxo de troca de abas
    @isTest
    public static void testTrocaAbasCompleto(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        PageReference p = Page.ControleHorasVoo;
        p.getParameters().put('aba', 'controles');
        Test.setCurrentPage(p);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.trocarAba();
        System.assertEquals('controles', controller.abaAtiva);
        
        // Trocar para manutenção
        p.getParameters().put('aba', 'manutencao');
        controller.aeronaveIdManutencao = aeronave.Id;
        controller.trocarAba();
        System.assertEquals('manutencao', controller.abaAtiva);
        
        // Trocar para calendário
        p.getParameters().put('aba', 'calendario');
        controller.trocarAba();
        System.assertEquals('calendario', controller.abaAtiva);
    }
    
    // Teste de sincronização de voos (com mais cenários)
    @isTest
    public static void testSincronizarVoosPlaneitCenarios(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        
        // Sem aeronave
        controller.sincronizarVoosPlaneit();
        
        // Com aeronave mas sem ano/mês
        controller.filtroAeronaveIdCalendario = aeronave.Id;
        controller.sincronizarVoosPlaneit();
        
        // Com aeronave, ano e mês
        controller.filtroAnoCalendario = String.valueOf(Date.today().year());
        controller.filtroMesCalendario = String.valueOf(Date.today().month());
        controller.sincronizarVoosPlaneit();
    }
    
    // Teste do fluxo de calendário sem aeronave
    @isTest
    public static void testCalendarioSemAeronave(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.abaAtiva = 'calendario';
        
        // Sem aeronave selecionada
        controller.filtroAeronaveIdCalendario = null;
        controller.aplicarFiltrosCalendario();
        
        System.assertEquals(0, controller.diasCalendario.size());
    }
    
    // Teste para DiaCalendario wrapper
    @isTest
    public static void testDiaCalendarioWrapper(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);
        
        Date base = baseDate();
        
        // Criar voo para hoje
        insert new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id, 
            Data_do_Voo__c = base, 
            Piloto__c = empregadoPiloto.Id, 
            Tipo__c = 'SA', 
            Horas_Voo__c = 1.0, 
            TOT__c = 1.0
        );
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.filtroAeronaveIdCalendario = aeronave.Id;
        controller.filtroAnoCalendario = String.valueOf(base.year());
        controller.filtroMesCalendario = String.valueOf(base.month());
        controller.aplicarFiltrosCalendario();
        
        // Verificar propriedades do DiaCalendario
        System.assertNotEquals(null, controller.diasCalendario);
        System.assertEquals(42, controller.diasCalendario.size());
        
        // Verificar resumo mensal
        System.assertNotEquals(null, controller.totalVoosMes);
        System.assertNotEquals(null, controller.totalHorasMesCalendario);
        System.assertNotEquals(null, controller.nomeAeronaveAtual);
        System.assertNotEquals(null, controller.nomeMesAtual);
    }
    
    // Teste de erro ao selecionar aeronave inválida
    @isTest
    public static void testSelecionarAeronaveInvalida(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        
        // Selecionar aeronave sem definir ID
        controller.aeronaveId = null;
        controller.selecionarAeronave();
        
        // Manutenção sem aeronave (usar null em vez de string vazia)
        controller.aeronaveIdManutencao = null;
        controller.selecionarAeronaveManutencao();
    }
    
    // Teste de calcularTotaisMes sem aeronave
    @isTest
    public static void testRecalcularValoresSemAeronave(){
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        setSession(empregadoPiloto.login__c);
        
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.aeronaveId = null;
        controller.selecionarAeronave(); // retorna early quando aeronaveId é null
        
        // Não deve dar erro
        System.assertEquals(0, controller.totalHorasVooMes);
    }

    // ===========================================================================
    // TESTES DE PROTEÇÃO MANUAL (Editado_Manualmente__c)
    // ===========================================================================

    /**
     * Editar um voo via Controller deve setar Editado_Manualmente__c = true
     */
    @isTest
    public static void testEdicaoSetaFlagEditadoManualmente() {
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);

        // 1. Criar voo original (sem flag)
        Controle_Horas_Voo__c voo = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Data_do_Voo__c = Date.today(),
            Piloto__c = empregadoPiloto.Id,
            Tipo__c = 'SA',
            Horas_Voo__c = 1,
            Editado_Manualmente__c = false
        );
        insert voo;

        // 2. Abrir modo edição via Controller
        PageReference pageRef = Page.ControleHorasVoo;
        pageRef.getParameters().put('controleId', String.valueOf(voo.Id));
        Test.setCurrentPage(pageRef);

        ControleHorasVooController controller = new ControleHorasVooController();
        controller.editarControle();

        System.assert(controller.modoEdicao, 'Deve estar em modo edição');

        // 3. Salvar a edição
        Test.startTest();
        controller.controleHoras.DEP__c = 'NOVA';
        controller.salvarControleHoras();
        Test.stopTest();

        // 4. Verificar flag
        Controle_Horas_Voo__c vooAtualizado = [
            SELECT Editado_Manualmente__c, DEP__c
            FROM Controle_Horas_Voo__c
            WHERE Id = :voo.Id
        ];
        System.assertEquals(true, vooAtualizado.Editado_Manualmente__c,
            'Edição manual deve setar Editado_Manualmente__c = true');
        System.assertEquals('NOVA', vooAtualizado.DEP__c,
            'Dados do usuário devem ter sido salvos');
    }

    /**
     * Editar um abastecimento existente via Controller deve setar Editado_Manualmente__c = true
     */
    @isTest
    public static void testEdicaoAbastecimentoSetaFlagEditadoManualmente() {
        empregado__c empregadoPiloto = TestDataStatic.empregadoPiloto;
        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        setSession(empregadoPiloto.login__c);

        // 1. Criar voo e abastecimento
        Controle_Horas_Voo__c voo = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Data_do_Voo__c = Date.today(),
            Piloto__c = empregadoPiloto.Id,
            Tipo__c = 'SA',
            Horas_Voo__c = 1
        );
        insert voo;

        Abastecimento__c ab = new Abastecimento__c(
            Voo__c = voo.Id,
            Data_Voo__c = Date.today(),
            Quantidade__c = 100,
            Custo_Unitario__c = 10,
            Editado_Manualmente__c = false
        );
        insert ab;

        // 2. Abrir modo edição via Controller
        PageReference pageRef = Page.ControleHorasVoo;
        pageRef.getParameters().put('controleId', String.valueOf(voo.Id));
        Test.setCurrentPage(pageRef);

        ControleHorasVooController controller = new ControleHorasVooController();
        controller.editarControle();

        // 3. Simular edição do abastecimento (via lista abastecimentosEdicao + backup de IDs)
        controller.abastecimentosEdicao = new List<Abastecimento__c>{
            new Abastecimento__c(
                Quantidade__c = 200,
                Custo_Unitario__c = 15
            )
        };
        controller.abastecimentoIdsBackup = new List<Id>{ ab.Id };

        Test.startTest();
        controller.salvarControleHoras();
        Test.stopTest();

        // 4. Verificar flag no abastecimento
        Abastecimento__c abAtualizado = [
            SELECT Editado_Manualmente__c, Quantidade__c
            FROM Abastecimento__c
            WHERE Id = :ab.Id
        ];
        System.assertEquals(true, abAtualizado.Editado_Manualmente__c,
            'Edição manual do abastecimento deve setar Editado_Manualmente__c = true');
        System.assertEquals(200, abAtualizado.Quantidade__c,
            'Quantidade corrigida pelo usuário deve ter sido salva');
    }

    // =============================================================================
    // TESTES: ABA DE CADASTRO DE AERONAVES (FROTA PRÓPRIA/LOCADA)
    // =============================================================================

    @isTest
    public static void testNovaAeronaveDefaultLocada(){
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.novaAeronave();
        System.assertEquals('Locada', controller.aeronaveForm.Tipo_Frota__c,
            'Nova aeronave deve vir com default Frota Locada, caso de uso principal desta aba');
        System.assertEquals(true, controller.modoEdicaoAeronave);
        System.assertEquals(null, controller.aeronaveFormOriginalId);
    }

    @isTest
    public static void testCadastrarAeronaveLocadaNuncaTemIdPlaneit(){
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.novaAeronave();
        controller.aeronaveForm.Name = 'PT-TESTE-LOCADA';
        controller.aeronaveForm.Modelo__c = 'C-206';
        controller.aeronaveForm.Empresa_Locadora__c = 'Locadora XPTO';
        controller.aeronaveForm.Id_Planeit__c = 999; // tentativa de forçar valor pela UI

        Test.startTest();
        controller.salvarAeronave();
        Test.stopTest();

        Aeronave__c criada = [
            SELECT Id, Tipo_Frota__c, Empresa_Locadora__c, Id_Planeit__c, Ativo__c
            FROM Aeronave__c
            WHERE Name = 'PT-TESTE-LOCADA'
            LIMIT 1
        ];
        System.assertEquals('Locada', criada.Tipo_Frota__c);
        System.assertEquals('Locadora XPTO', criada.Empresa_Locadora__c);
        System.assertEquals(null, criada.Id_Planeit__c,
            'Id_Planeit__c nunca deve ser gravado a partir do formulário — protege da sincronização automática do Planeit');
        System.assertEquals(true, criada.Ativo__c);
        System.assertEquals(false, controller.modoEdicaoAeronave, 'Formulário deve fechar após salvar');
    }

    @isTest
    public static void testSalvarAeronaveSemNomeAdicionaErro(){
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.novaAeronave();
        controller.aeronaveForm.Name = null;

        Test.startTest();
        controller.salvarAeronave();
        Test.stopTest();

        System.assertEquals(true, ApexPages.hasMessages(ApexPages.Severity.ERROR),
            'Deve exibir erro de validação quando Matrícula estiver em branco');
        System.assertEquals(0, [SELECT COUNT() FROM Aeronave__c WHERE Modelo__c = null AND Name = null]);
    }

    @isTest
    public static void testEditarAeronaveExistente(){
        Aeronave__c existente = new Aeronave__c(
            Name = 'PT-TESTE-EDICAO',
            Tipo_Frota__c = 'Propria',
            Ativo__c = true
        );
        insert existente;

        ControleHorasVooController controller = newControllerWithPage(
            new Map<String,String>{ 'aeronaveId' => String.valueOf(existente.Id) }
        );
        controller.editarAeronave();
        System.assertEquals(true, controller.modoEdicaoAeronave);
        System.assertEquals(existente.Id, controller.aeronaveFormOriginalId,
            'Padrão idBackup: Id original deve ficar guardado, não no sObject do form');
        System.assertEquals(null, controller.aeronaveForm.Id);

        controller.aeronaveForm.Modelo__c = 'C-206H';

        Test.startTest();
        controller.salvarAeronave();
        Test.stopTest();

        Aeronave__c atualizada = [SELECT Id, Modelo__c FROM Aeronave__c WHERE Id = :existente.Id];
        System.assertEquals('C-206H', atualizada.Modelo__c);
        System.assertEquals(1, [SELECT COUNT() FROM Aeronave__c WHERE Name = 'PT-TESTE-EDICAO'],
            'Edição deve fazer UPDATE, nunca criar um segundo registro');
    }

    @isTest
    public static void testAlternarAtivoAeronave(){
        Aeronave__c existente = new Aeronave__c(
            Name = 'PT-TESTE-TOGGLE',
            Tipo_Frota__c = 'Locada',
            Ativo__c = true
        );
        insert existente;

        ControleHorasVooController controller = newControllerWithPage(
            new Map<String,String>{ 'aeronaveId' => String.valueOf(existente.Id) }
        );

        Test.startTest();
        controller.alternarAtivoAeronave();
        Test.stopTest();

        Aeronave__c desativada = [SELECT Ativo__c FROM Aeronave__c WHERE Id = :existente.Id];
        System.assertEquals(false, desativada.Ativo__c, 'Deveria estar inativa após alternar');
    }

    @isTest
    public static void testFiltrosListaAeronaves(){
        insert new List<Aeronave__c>{
            new Aeronave__c(Name = 'PT-PROPRIA-ATIVA', Tipo_Frota__c = 'Propria', Ativo__c = true),
            new Aeronave__c(Name = 'PT-LOCADA-ATIVA', Tipo_Frota__c = 'Locada', Ativo__c = true),
            new Aeronave__c(Name = 'PT-LOCADA-INATIVA', Tipo_Frota__c = 'Locada', Ativo__c = false)
        };

        ControleHorasVooController controller = new ControleHorasVooController();
        controller.filtroTipoFrotaAeronaves = 'Locada';
        controller.filtroStatusAeronaves = 'ativas';

        Test.startTest();
        controller.aplicarFiltrosAeronaves();
        Test.stopTest();

        System.assertEquals(1, controller.listaAeronaves.size());
        System.assertEquals('PT-LOCADA-ATIVA', controller.listaAeronaves[0].Name);
    }

    @isTest
    public static void testCancelarEdicaoAeronave(){
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.novaAeronave();
        controller.aeronaveForm.Name = 'RASCUNHO';

        controller.cancelarEdicaoAeronave();

        System.assertEquals(false, controller.modoEdicaoAeronave);
        System.assertEquals(null, controller.aeronaveFormOriginalId);
        System.assertEquals(null, controller.aeronaveForm.Name);
    }

    @isTest
    public static void testTrocarAbaAeronavesCarregaLista(){
        insert new Aeronave__c(Name = 'PT-TROCA-ABA', Tipo_Frota__c = 'Propria', Ativo__c = true);

        ControleHorasVooController controller = newControllerWithPage(
            new Map<String,String>{ 'aba' => 'aeronaves' }
        );

        Test.startTest();
        controller.trocarAba();
        Test.stopTest();

        System.assertEquals('aeronaves', controller.abaAtiva);
        System.assertNotEquals(null, controller.listaAeronaves);
        System.assert(controller.listaAeronaves.size() > 0);
    }

    @isTest
    public static void testViewModelInspecaoETitulosAeronave() {
        ControleHorasVooController controller = new ControleHorasVooController();
        controller.novaAeronave();
        System.assert(String.isNotBlank(controller.tituloFormularioAeronave));

        Aeronave__c aeronave = TestDataStatic.aeronaveteste;
        controller.aeronaveFormOriginalId = aeronave.Id;
        controller.aeronaveForm.Name = aeronave.Name;
        System.assert(controller.tituloFormularioAeronave.contains(aeronave.Name));

        Inspecao_Aeronave__c inspecao = new Inspecao_Aeronave__c(
            Ativa__c = true,
            Horas_Proxima__c = 110,
            Data_Proxima__c = Date.today().addDays(20)
        );
        ControleHorasVooController.InspecaoViewModel viewModel =
            new ControleHorasVooController.InspecaoViewModel(inspecao, 100);

        System.assertEquals(inspecao, viewModel.registro);
        System.assert(String.isNotBlank(viewModel.status));
        System.assert(String.isNotBlank(viewModel.nivelStatus));
        System.assertEquals(10, viewModel.horasRestantes);
        System.assertEquals(20, viewModel.diasRestantes);
    }

    @isTest
    public static void testCalendarioExibeProximasInspecoes() {
        Id aeronaveId = TestDataStatic.aeronaveteste.Id;
        Aeronave__c aeronave = [
            SELECT Id, Horas_Totais_de_Voo__c
            FROM Aeronave__c
            WHERE Id = :aeronaveId
        ];
        insert new Inspecao_Aeronave__c(
            Aeronave__c = aeronave.Id,
            Chave_Unica__c = 'TESTE_CALENDARIO_100H',
            Id_Inspecao_Planeit__c = 'TESTE-100',
            Id_Aeronave_Planeit__c = 'TESTE-AERONAVE',
            Nome_Inspecao__c = '100hrs',
            Horas_Proxima__c = (aeronave.Horas_Totais_de_Voo__c ?? 0) + 10,
            Ativa__c = true
        );

        ControleHorasVooController controller =
            newControllerWithPage(new Map<String, String>());
        controller.filtroAeronaveIdCalendario = aeronave.Id;
        controller.filtroAnoCalendario = String.valueOf(Date.today().year());
        controller.filtroMesCalendario = String.valueOf(Date.today().month());

        Test.startTest();
        controller.aplicarFiltrosCalendario();
        Test.stopTest();

        System.assertEquals(
            1,
            controller.inspecoesProximasCalendario.size(),
            'A inspeção ativa deve ser exibida no resumo do calendário.'
        );
        System.assertEquals(
            true,
            controller.inspecoesProximasCalendario[0].registro.Ativa__c,
            'A consulta deve carregar os campos usados pela calculadora de status.'
        );
    }
}
