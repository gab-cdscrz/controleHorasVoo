/**
 * @description Response da sincronização de voos do Planeit
 * @author GabrielCruz
 * @date 2025-11-10
 */
public class SincronizarVoosResponse {
    @InvocableVariable public Boolean sucesso;
    @InvocableVariable public Integer totalImportados;
    @InvocableVariable public Integer totalAtualizados;
    @InvocableVariable public Integer totalDeletados;
    @InvocableVariable public String mensagem;
}