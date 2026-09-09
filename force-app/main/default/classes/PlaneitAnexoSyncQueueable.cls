/**
 * Descobre quais abastecimentos têm nota anexada na Planeit e grava o caminho
 * do arquivo em Abastecimento__c.Caminho_Anexo__c.
 *
 * O arquivo não é copiado: fica no storage da Planeit e é baixado pelo próprio
 * navegador do usuário, através de uma URL assinada gerada no momento do clique.
 *
 * Roda em transação própria porque /anexos/listar custa um callout por
 * abastecimento (a API não oferece consulta em lote). Processa um bloco por
 * execução e encadeia a próxima enquanto houver candidatos.
 */
public with sharing class PlaneitAnexoSyncQueueable implements Queueable, Database.AllowsCallouts {
    // Abaixo do teto de 100 callouts por transação, com margem para o login.
    @TestVisible
    private static final Integer MAX_POR_TRANSACAO = 80;
    private static final Integer MARGEM_CALLOUTS = 90;

    // Abastecimentos mais antigos que isso não recebem mais anexo na prática.
    private static final Integer JANELA_DIAS = 90;
    // Quem já foi verificado e não tinha anexo é reconsultado após este intervalo,
    // para capturar notas anexadas depois do lançamento.
    private static final Integer REVERIFICAR_APOS_DIAS = 7;

    @TestVisible
    private static Boolean suppressContinuationInTests = false;

    private final Integer profundidade;

    public PlaneitAnexoSyncQueueable() {
        this(0);
    }

    public PlaneitAnexoSyncQueueable(Integer profundidade) {
        this.profundidade = profundidade == null || profundidade < 0 ? 0 : profundidade;
    }

    public void execute(QueueableContext context) {
        List<Abastecimento__c> candidatos = selecionarCandidatos();
        if (candidatos.isEmpty()) {
            return;
        }

        Datetime agora = Datetime.now();
        List<Abastecimento__c> paraAtualizar = new List<Abastecimento__c>();
        Boolean interrompidoPorLimite = false;

        for (Abastecimento__c ab : candidatos) {
            if (Limits.getCallouts() >= MARGEM_CALLOUTS) {
                interrompidoPorLimite = true;
                break;
            }

            String matricula = (ab.Voo__r == null || ab.Voo__r.Aeronave__r == null)
                ? null
                : ab.Voo__r.Aeronave__r.Name;
            if (String.isBlank(matricula)) {
                continue;
            }

            Integer idPlaneit = Integer.valueOf(ab.Id_Abastecimento_Planeit__c);
            String caminho = PlaneitAPIService.buscarCaminhoAnexo(idPlaneit, matricula);

            // Marca a verificação mesmo sem anexo: é o que faz a fila avançar.
            ab.Anexo_Verificado_Em__c = agora;
            if (String.isNotBlank(caminho)) {
                ab.Caminho_Anexo__c = caminho;
            }
            paraAtualizar.add(ab);
        }

        // Todos os callouts acontecem antes de qualquer DML: o Apex proíbe
        // callout depois de DML na mesma transação.
        //
        // SYSTEM_MODE porque os dois campos são deliberadamente não-editáveis no
        // permission set: quem escreve neles é a sincronização, não o usuário.
        if (!paraAtualizar.isEmpty()) {
            Database.update(paraAtualizar, true, AccessLevel.SYSTEM_MODE);
        }

        encadearSeNecessario(paraAtualizar.size(), interrompidoPorLimite);
    }

    private List<Abastecimento__c> selecionarCandidatos() {
        Datetime limiteReverificacao = Datetime.now().addDays(-REVERIFICAR_APOS_DIAS);
        Datetime inicioJanela = Datetime.now().addDays(-JANELA_DIAS);

        return [
            SELECT Id, Id_Abastecimento_Planeit__c, Caminho_Anexo__c, Anexo_Verificado_Em__c,
                   Voo__r.Aeronave__r.Name
            FROM Abastecimento__c
            WHERE Id_Abastecimento_Planeit__c != NULL
              AND Caminho_Anexo__c = NULL
              AND CreatedDate >= :inicioJanela
              AND (Anexo_Verificado_Em__c = NULL OR Anexo_Verificado_Em__c < :limiteReverificacao)
            WITH SYSTEM_MODE
            ORDER BY Anexo_Verificado_Em__c ASC NULLS FIRST, CreatedDate DESC
            LIMIT :MAX_POR_TRANSACAO
        ];
    }

    private void encadearSeNecessario(Integer processados, Boolean interrompidoPorLimite) {
        if (Test.isRunningTest() && suppressContinuationInTests) {
            return;
        }
        // Só continua se o bloco encheu (ou parou no limite de callouts):
        // um bloco parcial significa que a fila acabou.
        Boolean podeHaverMais = interrompidoPorLimite || processados >= MAX_POR_TRANSACAO;
        if (!podeHaverMais || Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            return;
        }
        System.enqueueJob(new PlaneitAnexoSyncQueueable(profundidade + 1));
    }
}
