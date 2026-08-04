/**
 * Performs the elevated, read-only queries required by the extranet report.
 *
 * The portal authenticates users outside Salesforce. Record access is therefore
 * intentionally isolated here and is only reached after the report endpoint
 * validates its scoped token and the Aerolevantamento group membership.
 */
public without sharing class ControleHorasVooReportSelector {
    public static List<Controle_Horas_Voo__c> selectFlights(
        ControleHorasVooReportService.ValidatedRequest requestValue,
        Integer rowLimit
    ) {
        Map<String, Object> binds = new Map<String, Object>{
            'startDate' => requestValue.startDate,
            'endDate' => requestValue.endDate,
            'flightTypes' => requestValue.flightTypes,
            'rowLimit' => rowLimit
        };
        List<String> filters = new List<String>{
            'Data_do_Voo__c >= :startDate',
            'Data_do_Voo__c <= :endDate',
            'Tipo__c IN :flightTypes'
        };

        if (requestValue.aircraftId != null) {
            filters.add('Aeronave__c = :aircraftId');
            binds.put('aircraftId', requestValue.aircraftId);
        }
        if (requestValue.responsibleId != null) {
            String responsibleField = requestValue.isPilotReport
                ? 'Piloto__c'
                : 'Operador__c';
            filters.add(responsibleField + ' = :responsibleId');
            binds.put('responsibleId', requestValue.responsibleId);
        }

        String responsibleOrder = requestValue.isPilotReport
            ? 'Piloto__r.Name'
            : 'Operador__r.Name';
        String queryValue =
            'SELECT Id, Aeronave__c, Aeronave__r.Name, Data_do_Voo__c, ' +
            'Piloto__c, Piloto__r.Name, Operador__c, Operador__r.Name, ' +
            'Tipo__c, Acionamento__c, Corte__c, Horas_Voo__c, TOT__c, ' +
            'DEP__c, ARR__c, Descricao__c ' +
            'FROM Controle_Horas_Voo__c ' +
            'WHERE ' + String.join(filters, ' AND ') + ' ' +
            'ORDER BY ' + responsibleOrder + ' NULLS LAST, ' +
            'Aeronave__r.Name NULLS LAST, Data_do_Voo__c, ' +
            'Acionamento__c NULLS LAST, Id ' +
            'LIMIT :rowLimit';

        return (List<Controle_Horas_Voo__c>) Database.queryWithBinds(
            queryValue,
            binds,
            AccessLevel.SYSTEM_MODE
        );
    }
}