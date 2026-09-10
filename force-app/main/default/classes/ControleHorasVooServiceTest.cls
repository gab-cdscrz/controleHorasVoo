@IsTest
private class ControleHorasVooServiceTest {
    @TestSetup
    static void createSecurityFixture() {
        insert new Aeronave__c(Name = 'PT-SEC', Ativo__c = true);
    }

    @IsTest
    static void savesFlightWithServerCalculatedHours() {
        Aeronave__c aircraft = TestDataStatic.aeronaveteste;
        Empregado__c pilot = TestDataStatic.empregadoPiloto;

        ControleHorasVooService.SaveRequest request =
            new ControleHorasVooService.SaveRequest();
        request.controle = new Controle_Horas_Voo__c(
            Aeronave__c = aircraft.Id,
            Piloto__c = pilot.Id,
            Data_do_Voo__c = Date.today(),
            Tipo__c = 'SA',
            Acionamento__c = Time.newInstance(23, 30, 0, 0),
            Corte__c = Time.newInstance(1, 0, 0, 0)
        );

        Test.startTest();
        ControleHorasVooService.SaveResult result =
            ControleHorasVooService.save(request);
        Test.stopTest();

        Controle_Horas_Voo__c saved = [
            SELECT TOT__c, Horas_Voo__c
            FROM Controle_Horas_Voo__c
            WHERE Id = :result.controleId
        ];
        Aeronave__c updatedAircraft = [
            SELECT Horas_Totais_de_Voo__c
            FROM Aeronave__c
            WHERE Id = :aircraft.Id
        ];
        System.assertEquals(1.50, saved.TOT__c);
        System.assertEquals(1.5, saved.Horas_Voo__c);
        System.assertEquals(1.5, updatedAircraft.Horas_Totais_de_Voo__c);
    }

    @IsTest
    static void editingAcrossAircraftRecalculatesBothTotals() {
        Aeronave__c sourceAircraft = TestDataStatic.aeronaveteste;
        Empregado__c pilot = TestDataStatic.empregadoPiloto;
        Aeronave__c targetAircraft = new Aeronave__c(
            Name = 'PT-NVA',
            Ativo__c = true
        );
        insert targetAircraft;

        Controle_Horas_Voo__c existingFlight = new Controle_Horas_Voo__c(
            Aeronave__c = sourceAircraft.Id,
            Piloto__c = pilot.Id,
            Data_do_Voo__c = Date.today(),
            Tipo__c = 'SA',
            Horas_Voo__c = 2,
            TOT__c = 2
        );
        insert existingFlight;

        ControleHorasVooService.SaveRequest request =
            new ControleHorasVooService.SaveRequest();
        request.controleOriginalId = existingFlight.Id;
        request.controle = new Controle_Horas_Voo__c(
            Aeronave__c = targetAircraft.Id,
            Piloto__c = pilot.Id,
            Data_do_Voo__c = Date.today(),
            Tipo__c = 'SA',
            Horas_Voo__c = 3,
            TOT__c = 3
        );

        Test.startTest();
        ControleHorasVooService.save(request);
        Test.stopTest();

        Map<Id, Aeronave__c> aircraftById = new Map<Id, Aeronave__c>([
            SELECT Horas_Totais_de_Voo__c
            FROM Aeronave__c
            WHERE Id IN :new Set<Id>{ sourceAircraft.Id, targetAircraft.Id }
        ]);
        System.assertEquals(0, aircraftById.get(sourceAircraft.Id).Horas_Totais_de_Voo__c);
        System.assertEquals(3, aircraftById.get(targetAircraft.Id).Horas_Totais_de_Voo__c);
    }

    @IsTest
    static void rollsBackFlightWhenFuelPersistenceFails() {
        Aeronave__c aircraft = TestDataStatic.aeronaveteste;
        Empregado__c pilot = TestDataStatic.empregadoPiloto;
        Integer flightsBefore = [SELECT COUNT() FROM Controle_Horas_Voo__c];

        ControleHorasVooService.SaveRequest request =
            new ControleHorasVooService.SaveRequest();
        request.controle = new Controle_Horas_Voo__c(
            Aeronave__c = aircraft.Id,
            Piloto__c = pilot.Id,
            Data_do_Voo__c = Date.today(),
            Tipo__c = 'SA',
            Horas_Voo__c = 1,
            TOT__c = 1
        );
        request.abastecimentos = new List<Abastecimento__c>{
            new Abastecimento__c(Quantidade__c = 10, Custo_Unitario__c = 5)
        };
        request.abastecimentoIds = new List<Id>{ aircraft.Id };

        Test.startTest();
        try {
            ControleHorasVooService.save(request);
            System.assert(false, 'A gravação deveria falhar para validar o rollback.');
        } catch (ControleHorasVooService.ControleHorasVooException expected) {
            System.assert(expected.getMessage().contains('Não foi possível'));
        }
        Test.stopTest();

        System.assertEquals(
            flightsBefore,
            [SELECT COUNT() FROM Controle_Horas_Voo__c],
            'O voo inserido antes da falha do abastecimento deve ser revertido.'
        );
    }

    @IsTest
    static void deletesFlightAndRecalculatesAircraft() {
        Aeronave__c aircraft = TestDataStatic.aeronaveteste;
        Empregado__c pilot = TestDataStatic.empregadoPiloto;
        Controle_Horas_Voo__c flight = new Controle_Horas_Voo__c(
            Aeronave__c = aircraft.Id,
            Piloto__c = pilot.Id,
            Data_do_Voo__c = Date.today(),
            Tipo__c = 'SA',
            Horas_Voo__c = 2,
            TOT__c = 2
        );
        insert flight;

        Test.startTest();
        ControleHorasVooService.deleteFlight(flight.Id);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Controle_Horas_Voo__c WHERE Id = :flight.Id]);
        aircraft = [
            SELECT Horas_Totais_de_Voo__c
            FROM Aeronave__c
            WHERE Id = :aircraft.Id
        ];
        System.assertEquals(0, aircraft.Horas_Totais_de_Voo__c);
    }

    @IsTest
    static void rejectsInvalidDomainValuesBeforeDml() {
        ControleHorasVooService.SaveRequest request =
            new ControleHorasVooService.SaveRequest();
        request.controle = new Controle_Horas_Voo__c(
            Data_do_Voo__c = Date.today(),
            Tipo__c = 'SA',
            Horas_Voo__c = -1
        );
        request.abastecimentoAtual = new Abastecimento__c(
            Quantidade__c = -10,
            Custo_Unitario__c = -1
        );

        try {
            ControleHorasVooService.save(request);
            System.assert(false, 'Valores inválidos deveriam ser rejeitados.');
        } catch (ControleHorasVooService.ControleHorasVooException expected) {
            System.assert(expected.getMessage().contains('aeronave'));
            System.assert(expected.getMessage().contains('piloto'));
            System.assert(expected.getMessage().contains('negativas'));
        }
    }

    @IsTest
    static void externalAuthContextUsesSystemDataAccess() {
        Aeronave__c aircraft = [
            SELECT Id
            FROM Aeronave__c
            WHERE Name = 'PT-SEC'
            LIMIT 1
        ];
        Empregado__c pilot = TestDataStatic.empregadoPiloto;
        Profile restrictedProfile = [
            SELECT Id
            FROM Profile
            WHERE PermissionsModifyAllData = false
              AND UserType = 'Standard'
            LIMIT 1
        ];
        String uniqueValue = String.valueOf(DateTime.now().getTime());
        User restrictedUser = new User(
            Alias = 'chvsec',
            Email = 'chv.security.' + uniqueValue + '@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Controle Horas Security',
            LanguageLocaleKey = 'pt_BR',
            LocaleSidKey = 'pt_BR',
            ProfileId = restrictedProfile.Id,
            TimeZoneSidKey = 'America/Sao_Paulo',
            Username = 'chv.security.' + uniqueValue + '@example.com'
        );
        insert restrictedUser;

        System.runAs(restrictedUser) {
            ControleHorasVooController controller = new ControleHorasVooController();
            System.assert(
                controller.aeronaveOptions.size() > 1,
                'As aeronaves devem permanecer visíveis no contexto técnico da extranet.'
            );

            ControleHorasVooService.SaveRequest request =
                new ControleHorasVooService.SaveRequest();
            request.controle = new Controle_Horas_Voo__c(
                Aeronave__c = aircraft.Id,
                Piloto__c = pilot.Id,
                Data_do_Voo__c = Date.today(),
                Tipo__c = 'SA',
                Horas_Voo__c = 1
            );
            ControleHorasVooService.SaveResult result =
                ControleHorasVooService.save(request);
            System.assertNotEquals(
                null,
                result.controleId,
                'A extranet usa autenticação própria e acesso sistêmico controlado pela página.'
            );
            System.assertEquals(
                1,
                [
                    SELECT COUNT()
                    FROM Controle_Horas_Voo__c
                    WHERE Id = :result.controleId
                    WITH SYSTEM_MODE
                ],
                'O controle salvo deve estar disponível para a consulta sistêmica.'
            );

            controller.filtroAeronaveIdCalendario = aircraft.Id;
            controller.filtroAnoCalendario = String.valueOf(Date.today().year());
            controller.filtroMesCalendario = String.valueOf(Date.today().month());
            controller.aplicarFiltrosCalendario();
            System.assert(
                controller.totalVoosMes > 0,
                'Os controles também devem permanecer visíveis no contexto da extranet. Mensagens: ' +
                JSON.serialize(ApexPages.getMessages())
            );
        }
    }

    /**
     * Um voo com piloto externo (Piloto__c nulo, mas Piloto_Externo__c preenchido) deve
     * ser salvo normalmente - a validação de "piloto obrigatório" não deve bloquear esse
     * caso, já que o dropdown de piloto só lista Empregado__c e pilotos externos não
     * aparecem lá.
     */
    @IsTest
    static void savesFlightWithExternalPilotWithoutValidationError() {
        Aeronave__c aircraft = TestDataStatic.aeronaveteste;

        ControleHorasVooService.SaveRequest request =
            new ControleHorasVooService.SaveRequest();
        request.controle = new Controle_Horas_Voo__c(
            Aeronave__c = aircraft.Id,
            Piloto_Externo__c = 'Carlos Andrade Voador',
            Data_do_Voo__c = Date.today(),
            Tipo__c = 'SA'
        );

        Test.startTest();
        ControleHorasVooService.SaveResult result =
            ControleHorasVooService.save(request);
        Test.stopTest();

        Controle_Horas_Voo__c saved = [
            SELECT Piloto__c, Piloto_Externo__c
            FROM Controle_Horas_Voo__c
            WHERE Id = :result.controleId
        ];
        System.assertEquals(null, saved.Piloto__c);
        System.assertEquals('Carlos Andrade Voador', saved.Piloto_Externo__c);
    }

    /**
     * Editar outro campo de um voo com piloto externo (ex.: corrigir a rota) não deve
     * apagar a tag de piloto externo já preenchida pela sincronização.
     */
    @IsTest
    static void editingFlightPreservesExternalPilotName() {
        Aeronave__c aircraft = TestDataStatic.aeronaveteste;

        Controle_Horas_Voo__c existingFlight = new Controle_Horas_Voo__c(
            Aeronave__c = aircraft.Id,
            Piloto_Externo__c = 'Carlos Andrade Voador',
            Data_do_Voo__c = Date.today(),
            Tipo__c = 'SA',
            DEP__c = 'OLD',
            ARR__c = 'OLD'
        );
        insert existingFlight;

        ControleHorasVooService.SaveRequest request =
            new ControleHorasVooService.SaveRequest();
        request.controleOriginalId = existingFlight.Id;
        request.controle = new Controle_Horas_Voo__c(
            Aeronave__c = aircraft.Id,
            Piloto_Externo__c = 'Carlos Andrade Voador',
            Data_do_Voo__c = Date.today(),
            Tipo__c = 'SA',
            DEP__c = 'SBRP',
            ARR__c = 'SBPA'
        );

        Test.startTest();
        ControleHorasVooService.save(request);
        Test.stopTest();

        Controle_Horas_Voo__c updated = [
            SELECT DEP__c, ARR__c, Piloto_Externo__c
            FROM Controle_Horas_Voo__c
            WHERE Id = :existingFlight.Id
        ];
        System.assertEquals('SBRP', updated.DEP__c, 'DEP deve ser atualizado normalmente');
        System.assertEquals('SBPA', updated.ARR__c, 'ARR deve ser atualizado normalmente');
        System.assertEquals('Carlos Andrade Voador', updated.Piloto_Externo__c, 'Tag de piloto externo não deve ser apagada ao editar outros campos');
    }
}