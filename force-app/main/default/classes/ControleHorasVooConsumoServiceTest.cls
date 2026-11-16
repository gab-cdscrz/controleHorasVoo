@IsTest
private class ControleHorasVooConsumoServiceTest {
    private static final Date VOO_2025 = Date.newInstance(2025, 5, 10);
    private static final Date VOO_2026 = Date.newInstance(2026, 3, 4);

    private static Controle_Horas_Voo__c criarVoo(
        Id aeronaveId,
        Date dataVoo,
        String tipo,
        Decimal horas
    ) {
        return new Controle_Horas_Voo__c(
            Aeronave__c = aeronaveId,
            Data_do_Voo__c = dataVoo,
            Tipo__c = tipo,
            Horas_Voo__c = horas
        );
    }

    private static Abastecimento__c criarAbastecimento(
        Id vooId,
        Decimal litros,
        Decimal custo
    ) {
        return new Abastecimento__c(
            Voo__c = vooId,
            Quantidade__c = litros,
            Custo_Total__c = custo,
            Unidade__c = 'L'
        );
    }

    private static ControleHorasVooConsumoService.Linha buscarLinha(
        ControleHorasVooConsumoService.ConsumoResult resultado,
        String aeronave,
        Integer ano,
        Integer mes,
        String tipo
    ) {
        for (ControleHorasVooConsumoService.Linha linha : resultado.linhas) {
            if (
                linha.aeronave == aeronave && linha.ano == ano &&
                linha.mes == mes && linha.tipo == tipo
            ) {
                return linha;
            }
        }
        return null;
    }

    @IsTest
    static void deveAgruparHorasELitrosPorAeronaveMesETipo() {
        Aeronave__c primeira = new Aeronave__c(Name = 'PT-AAA', Ativo__c = true);
        Aeronave__c segunda = new Aeronave__c(Name = 'PT-BBB', Ativo__c = false);
        insert new List<Aeronave__c>{ primeira, segunda };

        List<Controle_Horas_Voo__c> voos = new List<Controle_Horas_Voo__c>{
            criarVoo(primeira.Id, VOO_2025, 'SA', 2.5),
            criarVoo(primeira.Id, VOO_2025, 'SA', 1.5),
            criarVoo(primeira.Id, VOO_2025, 'TR', 1),
            criarVoo(primeira.Id, VOO_2026, 'SA', 3),
            criarVoo(segunda.Id, VOO_2025, 'AB', 0)
        };
        insert voos;

        insert new List<Abastecimento__c>{
            criarAbastecimento(voos[0].Id, 200, 2000),
            criarAbastecimento(voos[1].Id, 100, 1100),
            criarAbastecimento(voos[2].Id, 80, 800),
            criarAbastecimento(voos[3].Id, 150, 1800),
            criarAbastecimento(voos[4].Id, 50, 600)
        };

        Test.startTest();
        ControleHorasVooConsumoService.ConsumoResult resultado =
            ControleHorasVooConsumoService.carregar();
        Test.stopTest();

        ControleHorasVooConsumoService.Linha servicoAereo =
            buscarLinha(resultado, 'PT-AAA', 2025, 5, 'SA');
        Assert.isNotNull(servicoAereo, 'Voos do mesmo mês e tipo formam uma linha.');
        Assert.areEqual(4, servicoAereo.horas);
        Assert.areEqual(300, servicoAereo.litros);
        Assert.areEqual(300, servicoAereo.litrosComCusto);
        Assert.areEqual(3100, servicoAereo.custo);

        ControleHorasVooConsumoService.Linha translado =
            buscarLinha(resultado, 'PT-AAA', 2025, 5, 'TR');
        Assert.areEqual(1, translado.horas);
        Assert.areEqual(80, translado.litros);

        ControleHorasVooConsumoService.Linha outroAno =
            buscarLinha(resultado, 'PT-AAA', 2026, 3, 'SA');
        Assert.areEqual(3, outroAno.horas);
        Assert.areEqual(150, outroAno.litros);

        ControleHorasVooConsumoService.Linha somenteAbastecimento =
            buscarLinha(resultado, 'PT-BBB', 2025, 5, 'AB');
        Assert.areEqual(0, somenteAbastecimento.horas);
        Assert.areEqual(50, somenteAbastecimento.litros);

        Assert.areEqual(
            ControleHorasVooConsumoService.FATOR_CO2_KG_POR_LITRO,
            resultado.fatorCo2
        );
        Assert.isNotNull(resultado.geradoEm);

        Set<String> nomes = new Set<String>();
        for (ControleHorasVooConsumoService.AeronaveInfo aeronave : resultado.aeronaves) {
            nomes.add(aeronave.nome);
            if (aeronave.nome == 'PT-BBB') {
                Assert.isFalse(aeronave.ativa);
            }
        }
        Assert.isTrue(nomes.contains('PT-AAA') && nomes.contains('PT-BBB'));
    }

    @IsTest
    static void naoDeveContarAbastecimentoSemCustoNoPrecoMedio() {
        Aeronave__c aeronave = new Aeronave__c(Name = 'PT-CCC', Ativo__c = true);
        insert aeronave;
        Controle_Horas_Voo__c voo = criarVoo(aeronave.Id, VOO_2025, 'TR', 1);
        insert voo;
        insert new List<Abastecimento__c>{
            criarAbastecimento(voo.Id, 100, 1000),
            criarAbastecimento(voo.Id, 100, null)
        };

        ControleHorasVooConsumoService.Linha linha = buscarLinha(
            ControleHorasVooConsumoService.carregar(),
            'PT-CCC', 2025, 5, 'TR'
        );

        Assert.areEqual(200, linha.litros, 'O consumo soma todos os abastecimentos.');
        Assert.areEqual(100, linha.litrosComCusto);
        Assert.areEqual(1000, linha.custo);
    }

    @IsTest
    static void deveManterVooSemTipoComoLinhaPropria() {
        Aeronave__c aeronave = new Aeronave__c(Name = 'PT-DDD', Ativo__c = true);
        insert aeronave;
        Controle_Horas_Voo__c voo = criarVoo(aeronave.Id, VOO_2026, null, 0);
        insert voo;
        insert criarAbastecimento(voo.Id, 166, 2538.14);

        ControleHorasVooConsumoService.Linha linha = buscarLinha(
            ControleHorasVooConsumoService.carregar(),
            'PT-DDD', 2026, 3, null
        );

        Assert.isNotNull(linha);
        Assert.areEqual(166, linha.litros);
    }

    @IsTest
    static void deveRecusarTokenInvalido() {
        ControleHorasVooConsumoService.Response resposta =
            ControleHorasVooController.obterConsumoCombustivel('token-invalido');

        Assert.isFalse(resposta.success);
        Assert.isNull(resposta.data);
        Assert.isTrue(String.isNotBlank(resposta.message));
    }

    @IsTest
    static void deveEntregarConsumoParaTokenDeSessaoValido() {
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        insert new Grupo_Funcionarios__c(
            Grupo__c = TestDataStatic.grupoAerolevantamento.Id,
            Empregado__c = piloto.Id
        );
        String token = ControleHorasVooReportController.issueAccessTokenForLogin(
            piloto.Login__c
        );

        Aeronave__c aeronave = new Aeronave__c(Name = 'PT-EEE', Ativo__c = true);
        insert aeronave;
        Controle_Horas_Voo__c voo = criarVoo(aeronave.Id, VOO_2025, 'SA', 2);
        insert voo;
        insert criarAbastecimento(voo.Id, 120, 1500);

        ControleHorasVooConsumoService.Response resposta =
            ControleHorasVooController.obterConsumoCombustivel(token);

        Assert.isTrue(resposta.success, resposta.message);
        Assert.isNotNull(buscarLinha(resposta.data, 'PT-EEE', 2025, 5, 'SA'));
    }
}
