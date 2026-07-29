/**
 * Centraliza o acesso em contexto de sistema às aeronaves elegíveis para o Planeit.
 * Aeronaves sem Id_Planeit__c, incluindo as locadas preenchidas manualmente, não entram na fila.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PlaneitAircraftSelector {

    public static List<Id> selectEligibleIds() {
        List<Id> aircraftIds = new List<Id>();
        for (Aeronave__c aircraft : [
            SELECT Id
            FROM Aeronave__c
            WHERE Ativo__c = true
            AND Id_Planeit__c != null
            ORDER BY Name
        ]) {
            aircraftIds.add(aircraft.Id);
        }
        return aircraftIds;
    }

    public static Aeronave__c selectEligibleById(Id aircraftId) {
        if (aircraftId == null) {
            return null;
        }

        List<Aeronave__c> aircraft = [
            SELECT Id, Name, Id_Planeit__c
            FROM Aeronave__c
            WHERE Id = :aircraftId
            AND Ativo__c = true
            AND Id_Planeit__c != null
            LIMIT 1
        ];
        return aircraft.isEmpty() ? null : aircraft[0];
    }
}
