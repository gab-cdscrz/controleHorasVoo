@IsTest
private class PlaneitScheduledSyncTest {
    private class PlaneitMock implements HttpCalloutMock {
        private final String mode;

        PlaneitMock(String mode) {
            this.mode = mode;
        }

        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');

            if (request.getEndpoint().contains('/login')) {
                response.setStatusCode(200);
                response.setBody(
                    '{"codigo":200,"data":{"access_token":"TEST_TOKEN","token_type":"Bearer"}}'
                );
            } else if (request.getEndpoint().contains('/totais')) {
                response.setStatusCode(200);
                response.setBody(
                    '{"codigo":200,"data":{"horasVooEtapaDecimalTotal":321.5}}'
                );
            } else if (mode == 'HTTP_ERROR') {
                response.setStatusCode(503);
                response.setBody('{"codigo":503,"mensagem":"Indisponível"}');
            } else if (mode == 'INVALID_JSON') {
                response.setStatusCode(200);
                response.setBody('not-json');
            } else if (mode == 'DML_ERROR') {
                response.setStatusCode(200);
                response.setBody(buildFlightResponse(
                    '123456789012345678901234567890123456789012345678901234567890' +
                    '123456789012345678901234567890123456789012345678901234567890'
                ));
            } else {
                response.setStatusCode(200);
                response.setBody('{"codigo":200,"data":[]}');
            }
            return response;
        }

        private String buildFlightResponse(String departure) {
            return '{"codigo":200,"data":[{' +
                '"idVoo":987654,' +
                '"idAeronave":1599,' +
                '"dataVoo":"' + String.valueOf(Date.today()) + '",' +
                '"localDecolagem":"' + departure + '",' +
                '"localPouso":"SBSP",' +
                '"horarioPartida":"10:00:00",' +
                '"horarioCorteMotores":"11:00:00",' +
                '"naturezaVoo":"TR",' +
                '"horasVooEtapa":"01:00:00",' +
                '"horasVooEtapaDecimal":1,' +
                '"assinaturas":[],"tripulacao":[],"abastecimentos":[]' +
            '}]}';
        }
    }

    @IsTest
    static void selectorExcludesAircraftWithoutPlaneitId() {
        Aeronave__c eligible = createAircraft('PT-API', 1599, 'Propria');
        createAircraft('PT-LOC', null, 'Locada');

        Test.startTest();
        List<Id> selectedIds = PlaneitAircraftSelector.selectEligibleIds();
        Test.stopTest();

        Assert.areEqual(1, selectedIds.size(), 'Somente aeronaves integradas devem ser selecionadas.');
        Assert.areEqual(eligible.Id, selectedIds[0], 'A aeronave com Id Planeit deve entrar na fila.');
        Assert.isNull(PlaneitAircraftSelector.selectEligibleById(null));
    }

    @IsTest
    static void queueableSynchronizesAndRecordsAudit() {
        Aeronave__c aircraft = createAircraft('PT-API', 1599, 'Propria');
        Aeronave__c nextAircraft = createAircraft('PT-NEXT', 1600, 'Propria');
        Test.setMock(HttpCalloutMock.class, new PlaneitMock('SUCCESS'));
        PlaneitAircraftSyncQueueable.suppressContinuationInTests = true;

        Test.startTest();
        System.enqueueJob(new PlaneitAircraftSyncQueueable(
            new List<Id>{ aircraft.Id, nextAircraft.Id },
            0,
            Date.today().addDays(-7),
            Date.today(),
            'Agendado',
            1
        ));
        Test.stopTest();

        Planeit_Sync_Log__c log = [
            SELECT Status__c, Job_Id__c, Aeronave__c, Tentativa__c,
                   Voos_Criados__c, Data_Inicial_Consulta__c, Data_Final_Consulta__c
            FROM Planeit_Sync_Log__c
            WHERE Aeronave__c = :aircraft.Id
            LIMIT 1
        ];
        Aeronave__c updatedAircraft = [
            SELECT Horas_Totais_de_Voo__c
            FROM Aeronave__c
            WHERE Id = :aircraft.Id
        ];

        Assert.areEqual('Sucesso', log.Status__c, 'A tentativa válida deve ser registrada como sucesso.');
        Assert.isNotNull(log.Job_Id__c, 'O log deve guardar o identificador do job assíncrono.');
        Assert.areEqual(aircraft.Id, log.Aeronave__c, 'O log deve identificar a aeronave.');
        Assert.areEqual(1, log.Tentativa__c, 'A primeira execução deve ser a tentativa 1.');
        Assert.areEqual(Date.today().addDays(-7), log.Data_Inicial_Consulta__c);
        Assert.areEqual(Date.today(), log.Data_Final_Consulta__c);
        Assert.areEqual(321.5, updatedAircraft.Horas_Totais_de_Voo__c);
    }

    @IsTest
    static void apiFailureDoesNotDeleteExistingFlight() {
        Aeronave__c aircraft = createAircraft('PT-API', 1599, 'Propria');
        Controle_Horas_Voo__c existingFlight = new Controle_Horas_Voo__c(
            Aeronave__c = aircraft.Id,
            Id_Voo_Planeit__c = 456789,
            Data_do_Voo__c = Date.today()
        );
        insert existingFlight;
        Test.setMock(HttpCalloutMock.class, new PlaneitMock('HTTP_ERROR'));
        PlaneitAircraftSyncQueueable.suppressContinuationInTests = true;

        Test.startTest();
        System.enqueueJob(new PlaneitAircraftSyncQueueable(
            new List<Id>{ aircraft.Id },
            0,
            Date.today().addDays(-7),
            Date.today(),
            'Agendado',
            1
        ));
        Test.stopTest();

        Planeit_Sync_Log__c log = [
            SELECT Status__c, Tipo_Erro__c, Tentativa__c
            FROM Planeit_Sync_Log__c
            LIMIT 1
        ];
        Assert.areEqual('Falha', log.Status__c, 'Erro HTTP deve ser auditado como falha.');
        Assert.areEqual('API', log.Tipo_Erro__c, 'A categoria deve permitir diagnóstico objetivo.');
        Assert.areEqual(1, log.Tentativa__c);
        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Controle_Horas_Voo__c WHERE Id = :existingFlight.Id],
            'Falha de consulta não pode ser interpretada como exclusão no Planeit.'
        );
    }

    @IsTest
    static void invalidResponseDoesNotDeleteExistingFlight() {
        Aeronave__c aircraft = createAircraft('PT-API', 1599, 'Propria');
        Controle_Horas_Voo__c existingFlight = new Controle_Horas_Voo__c(
            Aeronave__c = aircraft.Id,
            Id_Voo_Planeit__c = 456790,
            Data_do_Voo__c = Date.today()
        );
        insert existingFlight;
        Test.setMock(HttpCalloutMock.class, new PlaneitMock('INVALID_JSON'));

        PlaneitAPIService.SincronizarVoosLoteRequest request =
            buildRequest(aircraft, Date.today().addDays(-7), Date.today());

        Test.startTest();
        SincronizarVoosResponse result = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        )[0];
        Test.stopTest();

        Assert.isFalse(result.sucesso, 'JSON inválido deve falhar de forma explícita.');
        Assert.areEqual('API', result.tipoErro);
        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Controle_Horas_Voo__c WHERE Id = :existingFlight.Id],
            'Resposta inválida não pode remover dados existentes.'
        );
    }

    @IsTest
    static void dmlFailureRollsBackAircraftHours() {
        Aeronave__c aircraft = createAircraft('PT-API', 1599, 'Propria');
        aircraft.Horas_Totais_de_Voo__c = 10;
        update aircraft;
        Test.setMock(HttpCalloutMock.class, new PlaneitMock('DML_ERROR'));

        Test.startTest();
        SincronizarVoosResponse result = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{
                buildRequest(aircraft, Date.today().addDays(-7), Date.today())
            }
        )[0];
        Test.stopTest();

        Aeronave__c unchangedAircraft = [
            SELECT Horas_Totais_de_Voo__c
            FROM Aeronave__c
            WHERE Id = :aircraft.Id
        ];
        Assert.isFalse(result.sucesso, 'Falha em qualquer DML deve falhar a sincronização.');
        Assert.areEqual('DML', result.tipoErro);
        Assert.areEqual(10, unchangedAircraft.Horas_Totais_de_Voo__c, 'O rollback deve restaurar as horas.');
        Assert.areEqual(0, [SELECT COUNT() FROM Controle_Horas_Voo__c]);
    }

    @IsTest
    static void schedulerStartsEligibleAircraftQueue() {
        Aeronave__c aircraft = createAircraft('PT-API', 1599, 'Propria');
        createAircraft('PT-LOC', null, 'Locada');
        Test.setMock(HttpCalloutMock.class, new PlaneitMock('SUCCESS'));
        PlaneitAircraftSyncQueueable.suppressContinuationInTests = true;

        Test.startTest();
        new PlaneitDailySyncScheduler().execute(null);
        Test.stopTest();

        List<Planeit_Sync_Log__c> logs = [
            SELECT Aeronave__c, Status__c
            FROM Planeit_Sync_Log__c
        ];
        Assert.areEqual(1, logs.size(), 'O agendador deve iniciar somente a frota integrada.');
        Assert.areEqual(aircraft.Id, logs[0].Aeronave__c);
        Assert.areEqual('Sucesso', logs[0].Status__c);
    }

    @IsTest
    static void queueableLogsAircraftThatBecameIneligible() {
        Aeronave__c aircraft = createAircraft('PT-API', 1599, 'Propria');
        aircraft.Id_Planeit__c = null;
        update aircraft;

        Test.startTest();
        System.enqueueJob(new PlaneitAircraftSyncQueueable(
            new List<Id>{ aircraft.Id },
            0,
            Date.today().addDays(-7),
            Date.today(),
            'Agendado',
            1
        ));
        Test.stopTest();

        Planeit_Sync_Log__c log = [
            SELECT Status__c, Tipo_Erro__c, Mensagem__c
            FROM Planeit_Sync_Log__c
            WHERE Aeronave__c = :aircraft.Id
            LIMIT 1
        ];
        Assert.areEqual('Falha', log.Status__c);
        Assert.areEqual('NAO_ELEGIVEL', log.Tipo_Erro__c);
        Assert.isTrue(log.Mensagem__c.contains('ignorada'));
    }

    @IsTest
    static void queueableWithEmptyWorkListFinishesWithoutSideEffects() {
        Test.startTest();
        System.enqueueJob(new PlaneitAircraftSyncQueueable(
            null,
            null,
            Date.today(),
            Date.today(),
            null,
            null
        ));
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Planeit_Sync_Log__c]);
    }

    @IsTest
    static void continuationSelectsRetryOrNextAircraft() {
        PlaneitAircraftSyncQueueable.suppressContinuationInTests = false;
        Aeronave__c firstAircraft = createAircraft('PT-ONE', 1599, 'Propria');
        Aeronave__c secondAircraft = createAircraft('PT-TWO', 1600, 'Propria');
        PlaneitAircraftSyncQueueable queueable = new PlaneitAircraftSyncQueueable(
            new List<Id>{ firstAircraft.Id, secondAircraft.Id },
            0,
            Date.today().addDays(-7),
            Date.today(),
            'Agendado',
            1
        );

        SincronizarVoosResponse retryableFailure = new SincronizarVoosResponse();
        retryableFailure.sucesso = false;
        retryableFailure.podeTentarNovamente = true;
        queueable.enqueueContinuation(retryableFailure);

        SincronizarVoosResponse success = new SincronizarVoosResponse();
        success.sucesso = true;
        success.podeTentarNovamente = false;
        queueable.enqueueContinuation(success);

        Assert.areEqual(2, Limits.getQueueableJobs(), 'Retry e próxima aeronave devem gerar um job cada.');
        PlaneitAircraftSyncQueueable.suppressContinuationInTests = true;
    }

    @IsTest
    static void scheduleDailyIsIdempotent() {
        Test.startTest();
        Id firstJobId = PlaneitDailySyncScheduler.scheduleDaily();
        Id secondJobId = PlaneitDailySyncScheduler.scheduleDaily();
        CronTrigger scheduledJob = [
            SELECT Id, CronExpression, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :firstJobId
        ];
        Test.stopTest();

        Assert.areEqual(firstJobId, secondJobId, 'Chamadas repetidas não devem duplicar o agendamento.');
        Assert.areEqual(PlaneitDailySyncScheduler.DAILY_CRON, scheduledJob.CronExpression);
        Assert.areEqual(PlaneitDailySyncScheduler.JOB_NAME, scheduledJob.CronJobDetail.Name);
    }

    private static Aeronave__c createAircraft(String name, Decimal planeitId, String fleetType) {
        Aeronave__c aircraft = new Aeronave__c(
            Name = name,
            Ativo__c = true,
            Id_Planeit__c = planeitId,
            Tipo_Frota__c = fleetType,
            Horas_Totais_de_Voo__c = 1
        );
        insert aircraft;
        return aircraft;
    }

    private static PlaneitAPIService.SincronizarVoosLoteRequest buildRequest(
        Aeronave__c aircraft,
        Date startDate,
        Date endDate
    ) {
        PlaneitAPIService.SincronizarVoosLoteRequest request =
            new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ aircraft.Id_Planeit__c };
        request.idsAeronavesRecords = new List<String>{ String.valueOf(aircraft.Id) };
        request.dataInicio = startDate;
        request.dataFim = endDate;
        return request;
    }
}