/**
 * Read-only queries shared by the flight-control page and its services.
 */
public without sharing class ControleHorasVooSelector {
    /**
     * Returns flight-hour totals grouped by aircraft and flight type.
     *
     * @param aircraftIds Aircraft records represented in the dashboard.
     * @param startDate Inclusive period start.
     * @param endDate Exclusive period end.
     * @param flightTypes Flight types included in the distribution.
     * @return Aggregate rows containing aircraft, type, count and total hours.
     */
    public static List<AggregateResult> selectFlightDistribution(
        Set<Id> aircraftIds,
        Date startDate,
        Date endDate,
        Set<String> flightTypes
    ) {
        if (
            aircraftIds == null || aircraftIds.isEmpty() ||
            startDate == null || endDate == null || startDate >= endDate ||
            flightTypes == null || flightTypes.isEmpty()
        ) {
            return new List<AggregateResult>();
        }

        return [
            SELECT Aeronave__c, Tipo__c,
                   COUNT(Id) flightCount,
                   SUM(Horas_Voo__c) totalHours
            FROM Controle_Horas_Voo__c
            WHERE Aeronave__c IN :aircraftIds
              AND Data_do_Voo__c >= :startDate
              AND Data_do_Voo__c < :endDate
              AND Tipo__c IN :flightTypes
            WITH SYSTEM_MODE
            GROUP BY Aeronave__c, Tipo__c
        ];
    }

    public static Controle_Horas_Voo__c selectById(Id controleId) {
        return [
            SELECT Id, Name, Data_do_Voo__c,
                   Piloto__c, Piloto__r.Name, Piloto_Externo__c,
                   Operador__c, Operador__r.Name, Operador_Externo__c,
                   Aeronave__c, Aeronave__r.Name,
                   Horas_Voo__c, Descricao__c, Tipo__c,
                   ARR__c, DEP__c, Acionamento__c, Corte__c, TOT__c,
                   Notas__c, Obs__c, Faturado__c, Total_Horas_Voo__c,
                   Id_Voo_Planeit__c,
                   Usuario_Alteracao__c, Usuario_Alteracao__r.Name,
                   Contato_Alteracao__c, Contato_Alteracao__r.Name
            FROM Controle_Horas_Voo__c
            WHERE Id = :controleId
            WITH SYSTEM_MODE
            LIMIT 1
        ];
    }

    public static List<Controle_Horas_Voo__c> selectDetailsByAircraftAndDate(
        Id aeronaveId,
        Date dataVoo
    ) {
        return [
            SELECT Id, Aeronave__c, Aeronave__r.Name, Data_do_Voo__c,
                   Piloto__c, Piloto__r.Name, Piloto_Externo__c,
                   Operador__c, Operador__r.Name, Operador_Externo__c,
                   Tipo__c, Descricao__c, DEP__c, ARR__c,
                   Acionamento__c, Corte__c, TOT__c, Horas_Voo__c,
                   Notas__c, Obs__c, Faturado__c,
                   CreatedDate, Usuario_Alteracao__c, Usuario_Alteracao__r.Name,
                   Contato_Alteracao__c, Contato_Alteracao__r.Name,
                   (SELECT Id, Local__c, Origem_Destino__c, Tipo_Combustivel__c,
                           Quantidade__c, Unidade__c, Custo_Unitario__c, Custo_Total__c,
                           Documento_Referencia__c, Observacoes__c, Faturado__c
                    FROM Abastecimentos__r
                    ORDER BY Id_Abastecimento_Planeit__c ASC NULLS LAST)
            FROM Controle_Horas_Voo__c
            WHERE Aeronave__c = :aeronaveId
              AND Data_do_Voo__c = :dataVoo
            WITH SYSTEM_MODE
            ORDER BY CreatedDate
        ];
    }

    public static Decimal selectMonthlyHours(Id aeronaveId, Date referenceDate) {
        Date startDate = Date.newInstance(referenceDate.year(), referenceDate.month(), 1);
        Date endDate = startDate.addMonths(1);
        AggregateResult result = [
            SELECT SUM(Horas_Voo__c) total
            FROM Controle_Horas_Voo__c
            WHERE Aeronave__c = :aeronaveId
              AND Data_do_Voo__c >= :startDate
              AND Data_do_Voo__c < :endDate
              AND Tipo__c != 'AB'
            WITH SYSTEM_MODE
        ];
        Decimal total = (Decimal) result.get('total');
        return total == null ? 0 : total;
    }
}