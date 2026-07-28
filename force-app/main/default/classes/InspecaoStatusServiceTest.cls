@IsTest
private class InspecaoStatusServiceTest {
    @IsTest
    static void evaluatesHourThresholds() {
        Inspecao_Aeronave__c inspection = new Inspecao_Aeronave__c(
            Ativa__c = true,
            Horas_Proxima__c = 100
        );

        InspecaoStatusService.StatusResult dueSoon =
            InspecaoStatusService.calculate(inspection, 90);
        System.assertEquals('PRÓXIMA', dueSoon.status);
        System.assertEquals('proxima', dueSoon.level);
        System.assertEquals(10, dueSoon.remainingHours);

        InspecaoStatusService.StatusResult warning =
            InspecaoStatusService.calculate(inspection, 60);
        System.assertEquals('EM DIA', warning.status);
        System.assertEquals('alerta', warning.level);
        System.assertEquals(40, warning.remainingHours);

        InspecaoStatusService.StatusResult overdue =
            InspecaoStatusService.calculate(inspection, 101);
        System.assertEquals('VENCIDA', overdue.status);
        System.assertEquals(-1, overdue.remainingHours);
    }

    @IsTest
    static void evaluatesDateThresholdsWithoutTimezoneConversion() {
        Inspecao_Aeronave__c inspection = new Inspecao_Aeronave__c(
            Ativa__c = true,
            Data_Proxima__c = Date.today().addDays(30)
        );
        InspecaoStatusService.StatusResult dueSoon =
            InspecaoStatusService.calculate(inspection, null);
        System.assertEquals('PRÓXIMA', dueSoon.status);
        System.assertEquals(30, dueSoon.remainingDays);

        inspection.Data_Proxima__c = Date.today().addDays(90);
        InspecaoStatusService.StatusResult warning =
            InspecaoStatusService.calculate(inspection, null);
        System.assertEquals('alerta', warning.level);
        System.assertEquals(90, warning.remainingDays);

        inspection.Data_Proxima__c = Date.today().addDays(-1);
        InspecaoStatusService.StatusResult overdue =
            InspecaoStatusService.calculate(inspection, null);
        System.assertEquals('VENCIDA', overdue.status);
        System.assertEquals(-1, overdue.remainingDays);
    }

    @IsTest
    static void choosesMostUrgentDimensionAndHandlesInactiveRecords() {
        Inspecao_Aeronave__c inspection = new Inspecao_Aeronave__c(
            Ativa__c = true,
            Horas_Proxima__c = 200,
            Data_Proxima__c = Date.today().addDays(-2)
        );
        InspecaoStatusService.StatusResult result =
            InspecaoStatusService.calculate(inspection, 100);
        System.assertEquals('VENCIDA', result.status);
        System.assertEquals(100, result.remainingHours);
        System.assertEquals(-2, result.remainingDays);

        inspection.Ativa__c = false;
        result = InspecaoStatusService.calculate(inspection, 100);
        System.assertEquals('INATIVA', result.status);
        System.assertEquals('inativa', result.level);
    }

    @IsTest
    static void preservesStoredOverdueStatusWithoutCalculatedDimensions() {
        Inspecao_Aeronave__c inspection = new Inspecao_Aeronave__c(
            Ativa__c = true,
            Nome_Inspecao__c = 'TBO',
            Status_Inspecao__c = 'VENCIDA'
        );

        InspecaoStatusService.StatusResult result =
            InspecaoStatusService.calculate(inspection, 100);

        System.assertEquals('VENCIDA', result.status);
        System.assertEquals('vencida', result.level);
        System.assertEquals(null, result.remainingHours);
        System.assertEquals(null, result.remainingDays);
    }
}
