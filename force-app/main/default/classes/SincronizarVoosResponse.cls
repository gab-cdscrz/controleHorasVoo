/**
 * @description Response da sincronização de voos do Planeit
 * @author GabrielCruz
 * @date 2025-11-10
 */
public class SincronizarVoosResponse {
    public Boolean sucesso;
    public Integer totalImportados;
    public Integer totalAtualizados;
    public Integer totalDeletados;
    public String mensagem;
    public Integer totalAbastecimentosImportados;
    public Integer totalAbastecimentosAtualizados;
    public Integer totalAbastecimentosDeletados;
    public String tipoErro;
    public Boolean podeTentarNovamente;
}