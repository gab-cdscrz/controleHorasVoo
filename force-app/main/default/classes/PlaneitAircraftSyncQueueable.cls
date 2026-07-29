/**
 * Sincroniza uma aeronave por transação e encadeia a próxima.
 * Isso isola falhas, callouts e limites de governança por aeronave.
 */
public with sharing class PlaneitAircraftSyncQueueable implements Queueable, Database.AllowsCallouts {
    private static final Integer MAX_ATTEMPTS = 2;
    @TestVisible
    private static Boolean suppressContinuationInTests = false;

    private final List<Id> aircraftIds;
    private final Integer currentIndex;
    private final Date startDate;
    private final Date endDate;
    private final String source;
    private final Integer attempt;

    public PlaneitAircraftSyncQueueable(
        List<Id> aircraftIds,
        Integer currentIndex,
        Date startDate,
        Date endDate,
        String source,
        Integer attempt
    ) {
        this.aircraftIds = new List<Id>();
        if (aircraftIds != null) {
            this.aircraftIds.addAll(aircraftIds);
        }
        this.currentIndex = currentIndex == null ? 0 : currentIndex;
        this.startDate = startDate;
        this.endDate = endDate;
        this.source = String.isBlank(source) ? 'Agendado' : source;
        this.attempt = attempt == null || attempt < 1 ? 1 : attempt;
    }

    public void execute(QueueableContext context) {
        if (currentIndex >= aircraftIds.size()) {
            return;
        }

        Id aircraftId = aircraftIds[currentIndex];
        Datetime startedAt = Datetime.now();
        SincronizarVoosResponse result;

        try {
            Aeronave__c aircraft = PlaneitAircraftSelector.selectEligibleById(aircraftId);
            if (aircraft == null) {
                result = failure(
                    'Aeronave inativa ou sem identificador Planeit; sincronização ignorada.',
                    'NAO_ELEGIVEL',
                    false
                );
            } else {
                PlaneitAPIService.SincronizarVoosLoteRequest request =
                    new PlaneitAPIService.SincronizarVoosLoteRequest();
                request.idsAeronavesPlaneit = new List<Decimal>{ aircraft.Id_Planeit__c };
                request.idsAeronavesRecords = new List<String>{ String.valueOf(aircraft.Id) };
                request.dataInicio = startDate;
                request.dataFim = endDate;

                List<SincronizarVoosResponse> responses =
                    PlaneitAPIService.sincronizarVoosDoPlaneit(
                        new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
                    );
                result = responses == null || responses.isEmpty()
                    ? failure('A sincronização não retornou resultado.', 'INTERNO', true)
                    : responses[0];
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Falha inesperada na sincronização Planeit: ' + e.getStackTraceString());
            result = failure('Falha inesperada durante a sincronização.', 'INTERNO', true);
        }

        PlaneitSyncLogService.Entry logEntry = new PlaneitSyncLogService.Entry();
        logEntry.aircraftId = aircraftId;
        logEntry.asyncJobId = context.getJobId();
        logEntry.source = source;
        logEntry.attempt = attempt;
        logEntry.startDate = startDate;
        logEntry.endDate = endDate;
        logEntry.startedAt = startedAt;
        logEntry.result = result;
        PlaneitSyncLogService.record(logEntry);
        enqueueContinuation(result);
    }

    @TestVisible
    private void enqueueContinuation(SincronizarVoosResponse result) {
        if (Test.isRunningTest() && suppressContinuationInTests) {
            return;
        }

        if (result != null && !result.sucesso && result.podeTentarNovamente && attempt < MAX_ATTEMPTS) {
            System.enqueueJob(
                new PlaneitAircraftSyncQueueable(
                    aircraftIds,
                    currentIndex,
                    startDate,
                    endDate,
                    source,
                    attempt + 1
                )
            );
            return;
        }

        Integer nextIndex = currentIndex + 1;
        if (nextIndex < aircraftIds.size()) {
            System.enqueueJob(
                new PlaneitAircraftSyncQueueable(
                    aircraftIds,
                    nextIndex,
                    startDate,
                    endDate,
                    source,
                    1
                )
            );
        }
    }

    private static SincronizarVoosResponse failure(
        String message,
        String errorType,
        Boolean retryable
    ) {
        SincronizarVoosResponse result = new SincronizarVoosResponse();
        result.sucesso = false;
        result.mensagem = message;
        result.tipoErro = errorType;
        result.podeTentarNovamente = retryable;
        return result;
    }
}
