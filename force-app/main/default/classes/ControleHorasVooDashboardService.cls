/**
 * Builds the monthly fleet dashboard displayed before an aircraft is selected.
 */
public with sharing class ControleHorasVooDashboardService {
    private static final List<String> FLIGHT_TYPE_ORDER =
        new List<String>{ 'TR', 'SA', 'EX', 'TT' };
    private static final Set<String> FLIGHT_TYPES =
        new Set<String>(FLIGHT_TYPE_ORDER);
    private static final Map<String, String> FLIGHT_TYPE_LABELS =
        new Map<String, String>{
            'TR' => 'Translado',
            'SA' => 'Serviço Aéreo',
            'EX' => 'Experimental',
            'TT' => 'Tentativa',
            'AB' => 'Abastecimento'
        };
    private static final Map<String, String> FLIGHT_TYPE_COLORS =
        new Map<String, String>{
            'TR' => '#007bff',
            'SA' => '#28a745',
            'EX' => '#ffc107',
            'TT' => '#dc3545',
            'AB' => '#ff9800'
        };

    /**
     * Returns the canonical definitions used by chart segments and the legend.
     *
     * @return Ordered flight-type definitions.
     */
    public static List<FlightTypeDefinition> getFlightTypes() {
        List<FlightTypeDefinition> flightTypes =
            new List<FlightTypeDefinition>();
        for (String flightType : FLIGHT_TYPE_ORDER) {
            flightTypes.add(new FlightTypeDefinition(
                flightType,
                FLIGHT_TYPE_LABELS.get(flightType),
                FLIGHT_TYPE_COLORS.get(flightType)
            ));
        }
        return flightTypes;
    }

    /**
     * Resolves a flight type to its user-facing label.
     *
     * @param flightType Stored flight type code.
     * @return Canonical label, the original code, or "Outro" when blank.
     */
    public static String getFlightTypeLabel(String flightType) {
        if (String.isBlank(flightType)) {
            return 'Outro';
        }
        return FLIGHT_TYPE_LABELS.get(flightType) ?? flightType;
    }

    /**
     * Resolves a flight type to its canonical chart color.
     *
     * @param flightType Stored flight type code.
     * @return Hex color used consistently by the calendar and dashboard.
     */
    public static String getFlightTypeColor(String flightType) {
        if (String.isBlank(flightType)) {
            return '#6c757d';
        }
        return FLIGHT_TYPE_COLORS.get(flightType) ?? '#6c757d';
    }

    /**
     * Aggregates flight hours for all supplied aircraft in one query.
     *
     * @param aircraftReferences Ordered aircraft displayed in the dashboard.
     * @param startDate Inclusive period start.
     * @param endDate Exclusive period end.
     * @return Dashboard totals and one summary per aircraft.
     */
    public static DashboardResult build(
        List<AircraftReference> aircraftReferences,
        Date startDate,
        Date endDate
    ) {
        DashboardResult dashboard = new DashboardResult();
        if (
            aircraftReferences == null || aircraftReferences.isEmpty() ||
            startDate == null || endDate == null || startDate >= endDate
        ) {
            return dashboard;
        }

        List<FlightTypeDefinition> flightTypes = getFlightTypes();
        Map<Id, AircraftSummary> summaryByAircraft =
            new Map<Id, AircraftSummary>();

        for (AircraftReference aircraftReference : aircraftReferences) {
            if (
                aircraftReference == null ||
                aircraftReference.aircraftId == null
            ) {
                continue;
            }

            AircraftSummary summary = new AircraftSummary(
                aircraftReference,
                flightTypes
            );
            dashboard.aircraft.add(summary);
            summaryByAircraft.put(aircraftReference.aircraftId, summary);
        }

        if (summaryByAircraft.isEmpty()) {
            return dashboard;
        }

        for (AggregateResult aggregate :
            ControleHorasVooSelector.selectFlightDistribution(
                summaryByAircraft.keySet(),
                startDate,
                endDate,
                FLIGHT_TYPES
            )
        ) {
            AircraftSummary summary =
                summaryByAircraft.get((Id) aggregate.get('Aeronave__c'));
            if (summary == null) {
                continue;
            }

            Decimal hoursValue = (Decimal) aggregate.get('totalHours');
            Integer countValue = (Integer) aggregate.get('flightCount');
            summary.addMetric(
                (String) aggregate.get('Tipo__c'),
                hoursValue,
                countValue
            );
            dashboard.totalHours += hoursValue ?? 0;
            dashboard.totalFlights += countValue ?? 0;
        }

        return dashboard;
    }

    public class AircraftReference {
        public Id aircraftId { get; private set; }
        public String aircraftName { get; private set; }

        public AircraftReference(Id aircraftIdValue, String aircraftNameValue) {
            aircraftId = aircraftIdValue;
            aircraftName = aircraftNameValue;
        }
    }

    public class FlightTypeDefinition {
        public String codigo { get; private set; }
        public String nome { get; private set; }
        public String cor { get; private set; }

        public FlightTypeDefinition(
            String codeValue,
            String labelValue,
            String colorValue
        ) {
            codigo = codeValue;
            nome = labelValue;
            cor = colorValue;
        }
    }

    public class FlightTypeMetric {
        private Decimal hoursValue;
        private Integer countValue;

        public String codigo { get; private set; }
        public String nome { get; private set; }
        public String cor { get; private set; }
        public Decimal horas { get { return hoursValue; } }
        public Integer quantidade { get { return countValue; } }
        public String horasData {
            get { return String.valueOf(hoursValue.setScale(2)); }
        }

        public FlightTypeMetric(FlightTypeDefinition flightType) {
            codigo = flightType.codigo;
            nome = flightType.nome;
            cor = flightType.cor;
            hoursValue = 0;
            countValue = 0;
        }

        public void add(Decimal hoursToAdd, Integer countToAdd) {
            hoursValue += hoursToAdd ?? 0;
            countValue += countToAdd ?? 0;
        }
    }

    public class AircraftSummary {
        private Map<String, FlightTypeMetric> metricByCode;
        private Decimal totalHoursValue;
        private Integer totalFlightsValue;

        public Id aeronaveId { get; private set; }
        public String nome { get; private set; }
        public List<FlightTypeMetric> metricas { get; private set; }
        public Decimal totalHoras { get { return totalHoursValue; } }
        public Integer totalVoos { get { return totalFlightsValue; } }
        public Boolean temVoos {
            get { return totalFlightsValue > 0 && totalHoursValue > 0; }
        }

        public AircraftSummary(
            AircraftReference aircraftReference,
            List<FlightTypeDefinition> flightTypes
        ) {
            aeronaveId = aircraftReference.aircraftId;
            nome = aircraftReference.aircraftName;
            metricas = new List<FlightTypeMetric>();
            metricByCode = new Map<String, FlightTypeMetric>();
            totalHoursValue = 0;
            totalFlightsValue = 0;

            for (FlightTypeDefinition flightType : flightTypes) {
                FlightTypeMetric metric = new FlightTypeMetric(flightType);
                metricas.add(metric);
                metricByCode.put(flightType.codigo, metric);
            }
        }

        public void addMetric(
            String flightType,
            Decimal hoursToAdd,
            Integer countToAdd
        ) {
            FlightTypeMetric metric = metricByCode.get(flightType);
            if (metric == null) {
                return;
            }

            Decimal normalizedHours = hoursToAdd ?? 0;
            Integer normalizedCount = countToAdd ?? 0;
            metric.add(normalizedHours, normalizedCount);
            totalHoursValue += normalizedHours;
            totalFlightsValue += normalizedCount;
        }
    }

    public class DashboardResult {
        public List<AircraftSummary> aircraft { get; private set; }
        public Decimal totalHours { get; private set; }
        public Integer totalFlights { get; private set; }

        public DashboardResult() {
            aircraft = new List<AircraftSummary>();
            totalHours = 0;
            totalFlights = 0;
        }
    }
}