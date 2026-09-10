/**
 * Single source of truth for inspection status and remaining time.
 */
public with sharing class InspecaoStatusService {
    private static final Decimal DEFAULT_HOURS_WARNING = 50;
    private static final Decimal DEFAULT_HOURS_DUE_SOON = 10;
    private static final Integer DEFAULT_DAYS_WARNING = 90;
    private static final Integer DEFAULT_DAYS_DUE_SOON = 30;

    public class Thresholds {
        public Decimal hoursWarning;
        public Decimal hoursDueSoon;
        public Integer daysWarning;
        public Integer daysDueSoon;
    }

    public class StatusResult {
        public String status;
        public String level;
        public Decimal remainingHours;
        public Integer remainingDays;
    }

    public static StatusResult calculate(
        Inspecao_Aeronave__c inspection,
        Decimal aircraftHours
    ) {
        StatusResult result = new StatusResult();
        if (inspection == null || inspection.Ativa__c == false) {
            result.status = 'INATIVA';
            result.level = 'inativa';
            return result;
        }

        Thresholds thresholds = getThresholds();
        StatusResult hoursResult = calculateHours(inspection, aircraftHours, thresholds);
        StatusResult daysResult = calculateDays(inspection, thresholds);
        result = mostUrgent(hoursResult, daysResult);

        if (result == null) {
            result = fromStoredStatus(inspection.Status_Inspecao__c);
        }
        return result;
    }

    private static StatusResult fromStoredStatus(String storedStatus) {
        StatusResult result = new StatusResult();
        String normalized = String.isBlank(storedStatus)
            ? 'SEM DADOS'
            : storedStatus.trim().toUpperCase();
        result.status = normalized;

        if (normalized == 'VENCIDA') {
            result.level = 'vencida';
        } else if (normalized.startsWith('PR')) {
            result.level = 'proxima';
        } else if (normalized == 'EM DIA') {
            result.level = 'em-dia';
        } else if (
            normalized == 'INATIVA'
            || normalized == 'ARQUIVADA'
            || normalized == 'REMOVIDA'
        ) {
            result.level = 'inativa';
        } else {
            result.level = 'sem-dados';
        }
        return result;
    }

    @TestVisible
    private static Thresholds getThresholds() {
        Thresholds thresholds = new Thresholds();
        thresholds.hoursWarning = DEFAULT_HOURS_WARNING;
        thresholds.hoursDueSoon = DEFAULT_HOURS_DUE_SOON;
        thresholds.daysWarning = DEFAULT_DAYS_WARNING;
        thresholds.daysDueSoon = DEFAULT_DAYS_DUE_SOON;

        Controle_Horas_Voo_Config__mdt configuration =
            Controle_Horas_Voo_Config__mdt.getInstance('Padrao');
        if (configuration == null) {
            return thresholds;
        }

        thresholds.hoursWarning = configuration.Horas_Alerta__c
            ?? thresholds.hoursWarning;
        thresholds.hoursDueSoon = configuration.Horas_Proxima__c
            ?? thresholds.hoursDueSoon;
        thresholds.daysWarning = configuration.Dias_Alerta__c == null
            ? thresholds.daysWarning
            : configuration.Dias_Alerta__c.intValue();
        thresholds.daysDueSoon = configuration.Dias_Proxima__c == null
            ? thresholds.daysDueSoon
            : configuration.Dias_Proxima__c.intValue();
        return thresholds;
    }

    private static StatusResult calculateHours(
        Inspecao_Aeronave__c inspection,
        Decimal aircraftHours,
        Thresholds thresholds
    ) {
        if (inspection.Horas_Proxima__c == null || aircraftHours == null) {
            return null;
        }

        StatusResult result = new StatusResult();
        result.remainingHours = inspection.Horas_Proxima__c - aircraftHours;
        if (result.remainingHours < 0) {
            result.status = 'VENCIDA';
            result.level = 'vencida';
        } else if (result.remainingHours <= thresholds.hoursDueSoon) {
            result.status = 'PRÓXIMA';
            result.level = 'proxima';
        } else if (result.remainingHours <= thresholds.hoursWarning) {
            result.status = 'EM DIA';
            result.level = 'alerta';
        } else {
            result.status = 'EM DIA';
            result.level = 'em-dia';
        }
        return result;
    }

    private static StatusResult calculateDays(
        Inspecao_Aeronave__c inspection,
        Thresholds thresholds
    ) {
        if (inspection.Data_Proxima__c == null) {
            return null;
        }

        StatusResult result = new StatusResult();
        result.remainingDays = Date.today().daysBetween(inspection.Data_Proxima__c);
        if (result.remainingDays < 0) {
            result.status = 'VENCIDA';
            result.level = 'vencida';
        } else if (result.remainingDays <= thresholds.daysDueSoon) {
            result.status = 'PRÓXIMA';
            result.level = 'proxima';
        } else if (result.remainingDays <= thresholds.daysWarning) {
            result.status = 'EM DIA';
            result.level = 'alerta';
        } else {
            result.status = 'EM DIA';
            result.level = 'em-dia';
        }
        return result;
    }

    private static StatusResult mostUrgent(StatusResult first, StatusResult second) {
        if (first == null) {
            return second;
        }
        if (second == null) {
            return first;
        }

        StatusResult selected = severity(first.level) >= severity(second.level)
            ? first
            : second;
        selected.remainingHours = first.remainingHours;
        selected.remainingDays = second.remainingDays;
        return selected;
    }

    private static Integer severity(String level) {
        if (level == 'vencida') {
            return 4;
        }
        if (level == 'proxima') {
            return 3;
        }
        if (level == 'alerta') {
            return 2;
        }
        if (level == 'em-dia') {
            return 1;
        }
        return 0;
    }
}