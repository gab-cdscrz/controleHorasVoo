@IsTest
private class ControleHorasVooReportServiceTest {
    @IsTest
    static void shouldGeneratePilotReportWithCorrectDurationTotals() {
        Empregado__c pilot = TestDataStatic.empregadoPiloto;
        Empregado__c operatorValue = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aircraft = TestDataStatic.aeronaveTeste;
        Date reportDate = Date.today();

        insert new List<Controle_Horas_Voo__c>{
            createFlight(
                aircraft.Id,
                pilot.Id,
                operatorValue.Id,
                reportDate,
                'SA',
                Time.newInstance(8, 0, 0, 0),
                Time.newInstance(9, 15, 0, 0),
                1.3,
                99
            ),
            createFlight(
                aircraft.Id,
                pilot.Id,
                operatorValue.Id,
                reportDate,
                'TR',
                Time.newInstance(23, 30, 0, 0),
                Time.newInstance(0, 15, 0, 0),
                0.8,
                99
            ),
            createFlight(
                aircraft.Id,
                pilot.Id,
                operatorValue.Id,
                reportDate,
                'TT',
                null,
                null,
                2.5,
                2.30
            ),
            createFlight(
                aircraft.Id,
                pilot.Id,
                operatorValue.Id,
                reportDate,
                'AB',
                null,
                null,
                0,
                0
            )
        };

        Test.startTest();
        ControleHorasVooReportService.ReportResult result =
            ControleHorasVooReportService.generate(
                requestJson(
                    'PILOTO',
                    null,
                    null,
                    reportDate,
                    reportDate,
                    new List<String>{ 'TR', 'SA', 'TT' }
                )
            );
        Test.stopTest();

        Assert.areEqual(3, result.totalFlights);
        Assert.areEqual(Decimal.valueOf('4.6'), result.totalFlightHours);
        Assert.areEqual(
            270,
            result.totalTotMinutes,
            'TOT must prefer start/end times and understand HH.mm fallback.'
        );
        Assert.areEqual('4:30', result.totalTotDisplay);
        Assert.areEqual(1, result.summaries.size());
        Assert.areEqual(pilot.Name, result.summaries[0].responsibleName);
        Assert.areEqual('Translado', result.details[1].flightTypeLabel);
        Assert.areEqual('Tentativa', result.details[2].flightTypeLabel);
    }

    @IsTest
    static void shouldFilterOperatorAircraftAndType() {
        Empregado__c pilot = TestDataStatic.empregadoPiloto;
        Empregado__c operatorValue = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aircraft = TestDataStatic.aeronaveTeste;
        Date reportDate = Date.today();
        insert new List<Controle_Horas_Voo__c>{
            createFlight(
                aircraft.Id,
                pilot.Id,
                operatorValue.Id,
                reportDate,
                'EX',
                Time.newInstance(10, 0, 0, 0),
                Time.newInstance(11, 0, 0, 0),
                1,
                1
            ),
            createFlight(
                aircraft.Id,
                pilot.Id,
                operatorValue.Id,
                reportDate,
                'SA',
                Time.newInstance(12, 0, 0, 0),
                Time.newInstance(13, 0, 0, 0),
                1,
                1
            )
        };

        Test.startTest();
        ControleHorasVooReportService.ReportResult result =
            ControleHorasVooReportService.generate(
                requestJson(
                    'OPERADOR',
                    operatorValue.Id,
                    aircraft.Id,
                    reportDate,
                    reportDate,
                    new List<String>{ 'EX' }
                )
            );
        Test.stopTest();

        Assert.areEqual(1, result.totalFlights);
        Assert.areEqual('Operador', result.responsibleLabel);
        Assert.areEqual(operatorValue.Name, result.details[0].responsibleName);
        Assert.areEqual('EX', result.details[0].flightType);
    }

    @IsTest
    static void shouldRejectInvalidFilters() {
        Date reportDate = Date.today();

        assertReportError(
            requestJson(
                'PILOTO',
                null,
                null,
                reportDate,
                reportDate.addDays(-1),
                new List<String>{ 'SA' }
            ),
            'A data inicial não pode ser posterior à data final.'
        );
        assertReportError(
            requestJson(
                'PILOTO',
                null,
                null,
                reportDate,
                reportDate,
                new List<String>{ 'AB' }
            ),
            'O tipo de voo informado não é permitido.'
        );
        assertReportError(
            requestJson(
                'OUTRO',
                null,
                null,
                reportDate,
                reportDate,
                new List<String>{ 'SA' }
            ),
            'Selecione relatório por piloto ou por operador.'
        );
    }

    @IsTest
    static void shouldAuthorizeOnlyAerolevantamentoScopedToken() {
        Empregado__c pilot = TestDataStatic.empregadoPiloto;
        Grupo__c groupValue = TestDataStatic.grupoAerolevantamento;
        insert new Grupo_Funcionarios__c(
            Grupo__c = groupValue.Id,
            Empregado__c = pilot.Id
        );

        String token =
            ControleHorasVooReportController.issueAccessTokenForLogin(
                pilot.Login__c
            );
        String validRequest = requestJson(
            'PILOTO',
            null,
            null,
            Date.today(),
            Date.today(),
            new List<String>{ 'SA' }
        );

        Test.startTest();
        Boolean validToken =
            ControleHorasVooReportController.validateAccessToken(token);
        Boolean tamperedToken =
            ControleHorasVooReportController.validateAccessToken(token + 'x');
        Boolean blankLoginAccess =
            ControleHorasVooReportController.hasReportAccess(null);
        ControleHorasVooReportController.Response successResponse =
            ControleHorasVooController.gerarRelatorioHoras(
                token,
                validRequest
            );
        ControleHorasVooReportController.Response deniedResponse =
            ControleHorasVooReportController.generate(
                token + 'x',
                validRequest
            );
        ControleHorasVooReportController.Response invalidRequestResponse =
            ControleHorasVooReportController.generate(token, '{invalid');
        Test.stopTest();

        Assert.isTrue(validToken, 'A valid scoped token should be accepted.');
        Assert.isFalse(tamperedToken, 'A modified signature must be rejected.');
        Assert.isFalse(blankLoginAccess, 'Blank portal identity must be denied.');
        Assert.isTrue(successResponse.success);
        Assert.isFalse(deniedResponse.success);
        Assert.isFalse(invalidRequestResponse.success);
        Assert.isNotNull(invalidRequestResponse.message);
    }

    private static Controle_Horas_Voo__c createFlight(
        Id aircraftId,
        Id pilotId,
        Id operatorId,
        Date flightDate,
        String flightType,
        Time startTime,
        Time endTime,
        Decimal flightHours,
        Decimal totalTime
    ) {
        return new Controle_Horas_Voo__c(
            Aeronave__c = aircraftId,
            Piloto__c = pilotId,
            Operador__c = operatorId,
            Data_do_Voo__c = flightDate,
            Tipo__c = flightType,
            Acionamento__c = startTime,
            Corte__c = endTime,
            Horas_Voo__c = flightHours,
            TOT__c = totalTime,
            DEP__c = 'SBAU',
            ARR__c = 'SBSP',
            Descricao__c = 'Voo de teste'
        );
    }

    private static String requestJson(
        String reportMode,
        Id responsibleId,
        Id aircraftId,
        Date startDate,
        Date endDate,
        List<String> flightTypes
    ) {
        return JSON.serialize(new Map<String, Object>{
            'reportMode' => reportMode,
            'responsibleId' => responsibleId,
            'aircraftId' => aircraftId,
            'startDate' => String.valueOf(startDate),
            'endDate' => String.valueOf(endDate),
            'flightTypes' => flightTypes
        });
    }

    private static void assertReportError(
        String requestValue,
        String expectedMessage
    ) {
        try {
            ControleHorasVooReportService.generate(requestValue);
            Assert.fail('Expected report validation to fail.');
        } catch (ControleHorasVooReportService.ReportException exceptionValue) {
            Assert.areEqual(expectedMessage, exceptionValue.getMessage());
        }
    }
}