/**
 * Agenda a sincronização diária e apenas inicia a cadeia assíncrona.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class PlaneitDailySyncScheduler implements Schedulable {
    public static final String JOB_NAME = 'Sincronizacao Diaria Planeit Apex';
    public static final String DAILY_CRON = '0 0 11 * * ?';
    private static final Integer LOOKBACK_DAYS = 7;

    public void execute(SchedulableContext context) {
        if (hasActiveQueue()) {
            return;
        }

        List<Id> aircraftIds = PlaneitAircraftSelector.selectEligibleIds();
        if (aircraftIds.isEmpty()) {
            return;
        }

        Date endDate = Date.today();
        System.enqueueJob(
            new PlaneitAircraftSyncQueueable(
                aircraftIds,
                0,
                endDate.addDays(-LOOKBACK_DAYS),
                endDate,
                'Agendado',
                1
            )
        );
    }

    public static Id scheduleDaily() {
        List<CronTrigger> existingJobs = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name = :JOB_NAME
            AND State IN ('WAITING', 'ACQUIRED', 'EXECUTING', 'PAUSED', 'BLOCKED')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (!existingJobs.isEmpty()) {
            return existingJobs[0].Id;
        }
        return System.schedule(JOB_NAME, DAILY_CRON, new PlaneitDailySyncScheduler());
    }

    @TestVisible
    private static Boolean hasActiveQueue() {
        return [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'PlaneitAircraftSyncQueueable'
            AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ] > 0;
    }
}
