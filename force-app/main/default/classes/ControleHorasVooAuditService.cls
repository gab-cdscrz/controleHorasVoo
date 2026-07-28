/**
 * Writes system-owned audit markers that are intentionally read-only to page users.
 * No user-provided field value is accepted by this class.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ControleHorasVooAuditService {
    public static void updateEditedFlight(Controle_Horas_Voo__c writableFlight) {
        if (writableFlight == null || writableFlight.Id == null) return;
        writableFlight.Editado_Manualmente__c = true;
        update writableFlight;
    }

    public static void updateEditedFuels(List<Abastecimento__c> writableFuels) {
        if (writableFuels == null || writableFuels.isEmpty()) return;
        for (Abastecimento__c fuel : writableFuels) {
            fuel.Editado_Manualmente__c = true;
        }
        update writableFuels;
    }
}
