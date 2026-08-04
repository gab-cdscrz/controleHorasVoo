/**
 * Persiste o resultado de cada tentativa de sincronização em uma única operação.
 */
public without sharing class PlaneitSyncLogService {
    private static final Integer MAX_MESSAGE_LENGTH = 32768;

    public class Entry {
        public Id aircraftId;
        public Id asyncJobId;
        public String source;
        public Integer attempt;
        public Date startDate;
        public Date endDate;
        public Datetime startedAt;
        public SincronizarVoosResponse result;
    }

    public static void record(Entry entry) {
        Datetime finishedAt = Datetime.now();
        SincronizarVoosResponse result = normalizeResult(entry.result);

        Planeit_Sync_Log__c log = new Planeit_Sync_Log__c(
            Aeronave__c = entry.aircraftId,
            Job_Id__c = entry.asyncJobId == null ? null : String.valueOf(entry.asyncJobId),
            Status__c = result.sucesso ? 'Sucesso' : 'Falha',
            Origem__c = entry.source,
            Tentativa__c = entry.attempt,
            Data_Inicio__c = entry.startedAt,
            Data_Fim__c = finishedAt,
            Data_Inicial_Consulta__c = entry.startDate,
            Data_Final_Consulta__c = entry.endDate,
            Duracao_Ms__c = finishedAt.getTime() - entry.startedAt.getTime(),
            Voos_Criados__c = valueOrZero(result.totalImportados),
            Voos_Atualizados__c = valueOrZero(result.totalAtualizados),
            Voos_Excluidos__c = valueOrZero(result.totalDeletados),
            Abastecimentos_Criados__c = valueOrZero(result.totalAbastecimentosImportados),
            Abastecimentos_Atualizados__c = valueOrZero(result.totalAbastecimentosAtualizados),
            Abastecimentos_Excluidos__c = valueOrZero(result.totalAbastecimentosDeletados),
            Tipo_Erro__c = result.tipoErro,
            Mensagem__c = truncate(result.mensagem)
        );
        Database.insert(log, AccessLevel.SYSTEM_MODE);
    }

    private static SincronizarVoosResponse normalizeResult(SincronizarVoosResponse result) {
        if (result != null) {
            return result;
        }

        SincronizarVoosResponse failure = new SincronizarVoosResponse();
        failure.sucesso = false;
        failure.tipoErro = 'INTERNO';
        failure.mensagem = 'A sincronização não retornou resultado.';
        return failure;
    }

    private static Integer valueOrZero(Integer value) {
        return value == null ? 0 : value;
    }

    private static String truncate(String value) {
        if (String.isBlank(value) || value.length() <= MAX_MESSAGE_LENGTH) {
            return value;
        }
        return value.substring(0, MAX_MESSAGE_LENGTH);
    }
}