/**
 * Validates report filters and builds typed data for the XLSX generator.
 */
public with sharing class ControleHorasVooReportService {
    private static final Integer MAX_RANGE_DAYS = 366;
    private static final Integer MAX_ROWS = 2000;
    private static final List<String> TYPE_ORDER =
        new List<String>{ 'TR', 'SA', 'EX', 'TT' };
    private static final Set<String> ALLOWED_TYPES =
        new Set<String>(TYPE_ORDER);
    private static final Map<String, String> TYPE_LABELS =
        new Map<String, String>{
            'TR' => 'Translado',
            'SA' => 'Serviço Aéreo',
            'EX' => 'Experimental',
            'TT' => 'Tentativa'
        };

    public class ReportException extends Exception {}

    public static ReportResult generate(String requestJson) {
        ValidatedRequest requestValue = validateRequest(requestJson);
        List<Controle_Horas_Voo__c> flights =
            ControleHorasVooReportSelector.selectFlights(
                requestValue,
                MAX_ROWS + 1
            );
        if (flights.size() > MAX_ROWS) {
            throw new ReportException(
                'O relatório ultrapassa 2.000 voos. Reduza o período ou aplique mais filtros.'
            );
        }
        return buildResult(requestValue, flights);
    }

    @TestVisible
    private static ValidatedRequest validateRequest(String requestJson) {
        if (String.isBlank(requestJson)) {
            throw new ReportException('Informe os filtros do relatório.');
        }

        ReportRequest requestValue;
        try {
            requestValue = (ReportRequest) JSON.deserialize(
                requestJson,
                ReportRequest.class
            );
        } catch (Exception exceptionValue) {
            throw new ReportException('Os filtros do relatório são inválidos.');
        }

        String reportMode = String.valueOf(requestValue.reportMode)
            .trim()
            .toUpperCase();
        if (reportMode != 'PILOTO' && reportMode != 'OPERADOR') {
            throw new ReportException(
                'Selecione relatório por piloto ou por operador.'
            );
        }

        Date startDate = parseDate(requestValue.startDate, 'data inicial');
        Date endDate = parseDate(requestValue.endDate, 'data final');
        if (startDate > endDate) {
            throw new ReportException(
                'A data inicial não pode ser posterior à data final.'
            );
        }
        if (startDate.daysBetween(endDate) > MAX_RANGE_DAYS) {
            throw new ReportException(
                'O período máximo permitido é de 12 meses.'
            );
        }

        Set<String> normalizedTypes = new Set<String>();
        if (requestValue.flightTypes != null) {
            for (String flightType : requestValue.flightTypes) {
                String normalizedType = String.valueOf(flightType)
                    .trim()
                    .toUpperCase();
                if (!ALLOWED_TYPES.contains(normalizedType)) {
                    throw new ReportException(
                        'O tipo de voo informado não é permitido.'
                    );
                }
                normalizedTypes.add(normalizedType);
            }
        }
        if (normalizedTypes.isEmpty()) {
            throw new ReportException(
                'Selecione ao menos um tipo de voo.'
            );
        }

        return new ValidatedRequest(
            reportMode,
            parseOptionalId(requestValue.responsibleId, 'responsável'),
            parseOptionalId(requestValue.aircraftId, 'aeronave'),
            startDate,
            endDate,
            normalizedTypes
        );
    }

    @TestVisible
    private static ReportResult buildResult(
        ValidatedRequest requestValue,
        List<Controle_Horas_Voo__c> flights
    ) {
        ReportResult result = new ReportResult(requestValue);
        Map<String, SummaryRow> summaryByKey = new Map<String, SummaryRow>();

        for (Controle_Horas_Voo__c flight : flights) {
            DetailRow detail = new DetailRow(flight, requestValue);
            result.details.add(detail);
            result.totalFlights++;
            result.totalFlightHours += detail.flightHours;
            result.totalTotMinutes += detail.totMinutes;

            String summaryKey = detail.responsibleId == null
                ? 'SEM_RESPONSAVEL'
                : detail.responsibleId;
            SummaryRow summary = summaryByKey.get(summaryKey);
            if (summary == null) {
                summary = new SummaryRow(
                    detail.responsibleId,
                    detail.responsibleName
                );
                summaryByKey.put(summaryKey, summary);
                result.summaries.add(summary);
            }
            summary.add(detail);
        }

        result.totalFlightHours = result.totalFlightHours.setScale(1);
        result.totalTotDisplay = formatDuration(result.totalTotMinutes);
        for (SummaryRow summary : result.summaries) {
            summary.finish();
        }
        return result;
    }

    private static Date parseDate(String rawValue, String fieldLabel) {
        try {
            if (
                String.isBlank(rawValue) ||
                !Pattern.matches('\\d{4}-\\d{2}-\\d{2}', rawValue)
            ) {
                throw new TypeException();
            }
            return Date.valueOf(rawValue);
        } catch (Exception exceptionValue) {
            throw new ReportException('Informe uma ' + fieldLabel + ' válida.');
        }
    }

    private static Id parseOptionalId(String rawValue, String fieldLabel) {
        if (String.isBlank(rawValue)) {
            return null;
        }
        try {
            return Id.valueOf(rawValue.trim());
        } catch (Exception exceptionValue) {
            throw new ReportException(
                'O filtro de ' + fieldLabel + ' é inválido.'
            );
        }
    }

    private static Integer calculateTotMinutes(
        Controle_Horas_Voo__c flight
    ) {
        if (flight.Acionamento__c != null && flight.Corte__c != null) {
            Integer startMinutes =
                flight.Acionamento__c.hour() * 60 +
                flight.Acionamento__c.minute();
            Integer endMinutes =
                flight.Corte__c.hour() * 60 +
                flight.Corte__c.minute();
            Integer duration = endMinutes - startMinutes;
            return duration < 0 ? duration + 1440 : duration;
        }

        if (flight.TOT__c != null && flight.TOT__c >= 0) {
            Integer hours = Integer.valueOf(flight.TOT__c.setScale(0, RoundingMode.FLOOR));
            Integer minutes = Integer.valueOf(
                ((flight.TOT__c - hours) * 100).setScale(0, RoundingMode.HALF_UP)
            );
            if (minutes >= 0 && minutes < 60) {
                return hours * 60 + minutes;
            }
        }

        Decimal fallbackHours = flight.Horas_Voo__c ?? 0;
        return Integer.valueOf(
            (fallbackHours * 60).setScale(0, RoundingMode.HALF_UP)
        );
    }

    private static String formatDuration(Integer minutesValue) {
        Integer safeMinutes = Math.max(minutesValue ?? 0, 0);
        return String.valueOf(safeMinutes / 60) + ':' +
            String.valueOf(Math.mod(safeMinutes, 60)).leftPad(2, '0');
    }

    private static String formatTime(Time timeValue) {
        if (timeValue == null) {
            return '';
        }
        return String.valueOf(timeValue.hour()).leftPad(2, '0') + ':' +
            String.valueOf(timeValue.minute()).leftPad(2, '0');
    }

    private static String safeName(SObject relationshipValue) {
        if (relationshipValue == null) {
            return 'Não informado';
        }
        String nameValue = (String) relationshipValue.get('Name');
        return String.isBlank(nameValue) ? 'Não informado' : nameValue;
    }

    public class ReportRequest {
        public String reportMode;
        public String responsibleId;
        public String aircraftId;
        public String startDate;
        public String endDate;
        public List<String> flightTypes;
    }

    public class ValidatedRequest {
        public String reportMode { get; private set; }
        public Id responsibleId { get; private set; }
        public Id aircraftId { get; private set; }
        public Date startDate { get; private set; }
        public Date endDate { get; private set; }
        public Set<String> flightTypes { get; private set; }
        public Boolean isPilotReport {
            get { return reportMode == 'PILOTO'; }
        }

        public ValidatedRequest(
            String reportModeValue,
            Id responsibleIdValue,
            Id aircraftIdValue,
            Date startDateValue,
            Date endDateValue,
            Set<String> flightTypesValue
        ) {
            reportMode = reportModeValue;
            responsibleId = responsibleIdValue;
            aircraftId = aircraftIdValue;
            startDate = startDateValue;
            endDate = endDateValue;
            flightTypes = flightTypesValue;
        }
    }

    public class ReportResult {
        public String reportMode { get; private set; }
        public String reportTitle { get; private set; }
        public String responsibleLabel { get; private set; }
        public String startDate { get; private set; }
        public String endDate { get; private set; }
        public String generatedAt { get; private set; }
        public String fileName { get; private set; }
        public List<String> flightTypes { get; private set; }
        public List<SummaryRow> summaries { get; private set; }
        public List<DetailRow> details { get; private set; }
        public Integer totalFlights { get; private set; }
        public Decimal totalFlightHours { get; private set; }
        public Integer totalTotMinutes { get; private set; }
        public String totalTotDisplay { get; set; }

        public ReportResult(ValidatedRequest requestValue) {
            reportMode = requestValue.reportMode;
            responsibleLabel = requestValue.isPilotReport
                ? 'Piloto'
                : 'Operador';
            reportTitle = 'Relatório de Horas por ' + responsibleLabel;
            startDate = String.valueOf(requestValue.startDate);
            endDate = String.valueOf(requestValue.endDate);
            generatedAt = Datetime.now().format('dd/MM/yyyy HH:mm');
            fileName =
                'Relatorio_Horas_' + requestValue.reportMode.toLowerCase() +
                '_' + startDate + '_a_' + endDate + '.xlsx';
            flightTypes = new List<String>();
            for (String flightType : TYPE_ORDER) {
                if (requestValue.flightTypes.contains(flightType)) {
                    flightTypes.add(flightType);
                }
            }
            summaries = new List<SummaryRow>();
            details = new List<DetailRow>();
            totalFlights = 0;
            totalFlightHours = 0;
            totalTotMinutes = 0;
            totalTotDisplay = '0:00';
        }
    }

    public class SummaryRow {
        public String responsibleId { get; private set; }
        public String responsibleName { get; private set; }
        public Integer flightCount { get; private set; }
        public Decimal flightHours { get; private set; }
        public Integer totMinutes { get; private set; }
        public String totDisplay { get; private set; }
        public List<String> aircraft { get; private set; }
        private Set<String> aircraftNames;

        public SummaryRow(String idValue, String nameValue) {
            responsibleId = idValue;
            responsibleName = nameValue;
            flightCount = 0;
            flightHours = 0;
            totMinutes = 0;
            totDisplay = '0:00';
            aircraft = new List<String>();
            aircraftNames = new Set<String>();
        }

        public void add(DetailRow detail) {
            flightCount++;
            flightHours += detail.flightHours;
            totMinutes += detail.totMinutes;
            aircraftNames.add(detail.aircraftName);
        }

        public void finish() {
            flightHours = flightHours.setScale(1);
            totDisplay = formatDuration(totMinutes);
            aircraft.addAll(aircraftNames);
            aircraft.sort();
        }
    }

    public class DetailRow {
        public String id { get; private set; }
        public String aircraftName { get; private set; }
        public String flightDate { get; private set; }
        public String responsibleId { get; private set; }
        public String responsibleName { get; private set; }
        public String pilotName { get; private set; }
        public String operatorName { get; private set; }
        public String flightType { get; private set; }
        public String flightTypeLabel { get; private set; }
        public String startTime { get; private set; }
        public String endTime { get; private set; }
        public Decimal flightHours { get; private set; }
        public Integer totMinutes { get; private set; }
        public String totDisplay { get; private set; }
        public String departure { get; private set; }
        public String arrival { get; private set; }
        public String description { get; private set; }

        public DetailRow(
            Controle_Horas_Voo__c flight,
            ValidatedRequest requestValue
        ) {
            id = flight.Id;
            aircraftName = safeName(flight.Aeronave__r);
            flightDate = String.valueOf(flight.Data_do_Voo__c);
            pilotName = safeName(flight.Piloto__r);
            operatorName = safeName(flight.Operador__r);
            responsibleId = String.valueOf(
                requestValue.isPilotReport
                    ? flight.Piloto__c
                    : flight.Operador__c
            );
            if (responsibleId == 'null') {
                responsibleId = null;
            }
            responsibleName = requestValue.isPilotReport
                ? pilotName
                : operatorName;
            flightType = flight.Tipo__c;
            flightTypeLabel = TYPE_LABELS.get(flight.Tipo__c)
                ?? flight.Tipo__c;
            startTime = formatTime(flight.Acionamento__c);
            endTime = formatTime(flight.Corte__c);
            flightHours = (flight.Horas_Voo__c ?? 0).setScale(1);
            totMinutes = calculateTotMinutes(flight);
            totDisplay = formatDuration(totMinutes);
            departure = flight.DEP__c ?? '';
            arrival = flight.ARR__c ?? '';
            description = flight.Descricao__c ?? '';
        }
    }
}
