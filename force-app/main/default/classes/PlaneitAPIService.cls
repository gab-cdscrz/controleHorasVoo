/**
 * @description Serviço para integração com API Planeit
 * @author GabrielCruz
 * @date 2025-11-07
 * @version 1.1
 * 
 * Responsabilidades:
 * - Autenticação e gerenciamento de token (válido por 40 minutos)
 * - Consulta de voos de aeronaves
 * - Consulta de dados de abastecimento
 * - Transformação de dados para a página e processos assíncronos
 * - Sincronização transacional de controle técnico
 * 
 * NOTA: Usa 'without sharing' para garantir acesso a todos os registros
 * durante a sincronização, independente das permissões do usuário.
 */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexSuggestUsingNamedCred')
public without sharing class PlaneitAPIService {
    private class PlaneitSyncException extends Exception {}
    
    // =========================================================================
    // CONSTANTES E CONFIGURAÇÕES
    // =========================================================================
    
    // Named Credential para login (com Basic Authentication)
    private static final String NAMED_CREDENTIAL_LOGIN = 'callout:Planeit_API_Login';
    // Named Credential para demais endpoints (sem autenticação automática - usa Bearer token)
    private static final String NAMED_CREDENTIAL = 'callout:Planeit_API';
    private static final String LOGIN_ENDPOINT = '/login';
    private static final String VOOS_ENDPOINT = '/aeronave/voos';
    private static final String ABASTECIMENTOS_ENDPOINT = '/aeronave/abastecimentos';
    private static final String INSPECOES_ENDPOINT = '/aeronave/inspecoes';
    private static final String TOTAIS_ENDPOINT = '/aeronave/totais';
    private static final String ANEXOS_LISTAR_ENDPOINT = '/anexos/listar';
    private static final String ANEXOS_URL_ENDPOINT = '/anexos/url';
    // Parâmetros fixos dos endpoints de anexo para o contexto de abastecimento.
    private static final String ANEXO_MODULE = 'Aeronave';
    private static final String ANEXO_TIPO_REGISTRO = 'Abastecimento';
    private static final Integer TIMEOUT_SEGUNDOS = 120;
    private static final Integer MAX_CALLOUTS = 90; // Margem de segurança (limite: 100)

    // Valores da lista "Operador:" (campoCustomizado1) que indicam ausência de operador
    // (usados em translados e voos sem operador a bordo), e não nomes de pessoas.
    private static final Set<String> OPERADOR_SEM_VALOR = new Set<String>{
        'N/A', 'NA', 'N.A.', '-', '--'
    };
    
    // Cache do token em memória (válido apenas durante a transação)
    private static String cachedToken = null;
    private static DateTime cachedTokenExpiracao = null;
    
    // =========================================================================
    // WRAPPER CLASSES INTERNAS (usadas apenas internamente)
    // =========================================================================
    
    /**
     * Response da API de Login
     */
    private class LoginResponse {
        public Integer codigo;
        public String mensagem;
        public String metodo;
        public LoginData data;
    }
    
    private class LoginData {
        public String access_token;
        public String token_type;
    }
    
    /**
     * Response da API de Voos
     */
    private class VoosResponse {
        public Integer codigo;
        public String mensagem;
        public String metodo;
        public List<VooData> data;
    }
    
    /**
     * Dados de voo retornados da API
     */
    private class VooData {
        public Integer idVoo;
        public Integer idAeronave;
        public String matricula;
        public String dataVoo;
        public String localDecolagem;
        public String localPouso;
        public String horarioPartida;
        public String horarioCorteMotores;
        public Decimal totalCombustivelPartida;
        public String naturezaVoo;
        public String campoCustomizado1; // "Operador:" (lista de seleção)
        public String campoCustomizado2; // "Coleta de Dados?" (Sim/Não)
        public String campoCustomizado3; // "Projeto" (vai para Descrição)
        public String campoCustomizado4; // "Extras" (nome do operador quando fora da lista)
        public String horasVooEtapa; // TOT no formato HH:MM:SS
        public Decimal horasVooEtapaDecimal; // Horas de voo em decimal
        public List<AssinaturaData> assinaturas; // Piloto e operador
        public List<TripulacaoData> tripulacao;  // Dados da tripulação
        public List<AbastecimentoData> abastecimentos; // Abastecimentos do voo
    }
    
    /**
     * Dados de assinatura (piloto/operador)
     */
    private class AssinaturaData {
        public String nome;
        public String sobrenome;
        public String tipoAssinatura;
    }
    
    /**
     * Dados de tripulação
     */
    private class TripulacaoData {
        public String nome;
        public String sobrenome;
        public String funcaoBordo;
    }
    
    /**
     * Dados de abastecimento (vem junto na resposta de voos)
     */
    private class AbastecimentoData {
        public Integer id;
        public Integer idVoo;
        public String dataVoo;
        public String localAbastecimento;
        public String origemDestino;
        public String tipoAbastecimento;
        public Decimal quantidade;
        public String unidade;
        public Decimal custoUnidade;
        public Decimal custoTotal;
        public String codigoMoeda;
        public String documentoReferencia; // Vai para campo Notas
        // A Planeit oferece dois campos para o numero da nota e o uso varia por
        // fornecedor: uns preenchem documentoReferencia (texto livre), outros
        // delivery_receipt_code (numero) com o fornecedor em observacoes.
        public String delivery_receipt_code;
        public String observacoes;
    }
    
    /**
     * Response da API dedicada de Abastecimentos (inclui avulsos sem voo associado)
     */
    private class AbastecimentosResponse {
        public Integer codigo;
        public String mensagem;
        public String metodo;
        public List<AbastecimentoAvulsoData> data;
    }

    /**
     * Dados de abastecimento retornados pelo endpoint dedicado /aeronave/abastecimentos.
     * Diferente de AbastecimentoData (aninhado na resposta de voos), os valores
     * numéricos vêm como String (ex: "999.00"), por isso a classe é separada.
     */
    private class AbastecimentoAvulsoData {
        public Integer id;
        public Integer idVoo;
        public Integer idAeronave;
        public String dataAbastecimento;
        public String horaAbastecimento;
        public Integer status;
        public String localAbastecimento;
        public String origemDestino;
        public String tipoAbastecimento;
        public String quantidade;
        public String unidade;
        public String custoUnidade;
        public String custoTotal;
        public String codigoMoeda;
        public String documentoReferencia;
        public String delivery_receipt_code;
        public String observacoes;
    }

    /**
     * Response da API de Inspeções
     */
    private class InspecoesResponse {
        public Integer codigo;
        public String mensagem;
        public String metodo;
        public List<InspecaoData> data;
    }
    
    /**
     * Dados de uma inspeção
     */
    public class InspecaoData {
        public Integer idInspecao;
        public String nomeInspecao;
        public Integer idAeronave;
        public String flagCVA;
        public String inicioHoras;
        public String repeticaoHoras;
        public String toleranciaHoras;
        public String inicioTempo;
        public Integer repeticaoTempo;
        public String toleranciaTempo;
        public String situacaoInspecao;
        public String created_at;
        public String updated_at;
        public List<DetalheExecucaoData> detalheUltimaExecucao;
    }
    
    /**
     * Detalhes da última execução de uma inspeção
     */
    public class DetalheExecucaoData {
        public Integer idExecucaoInspecao;
        public Integer idInspecao;
        public Integer idAeronave;
        public String dataExecucao;
        public String horasExecucao;
        public String dataProxima;
        public String horasProxima;
        public String responsavelExecucao;
        public String observacoes;
        public String created_at;
        public String updated_at;
        public Integer rn;
    }
    
    /**
     * Response da API de Totais
     */
    private class TotaisResponse {
        public Integer codigo;
        public String mensagem;
        public String metodo;
        public TotaisData data;
    }
    
    /**
     * Dados de totais da aeronave
     */
    public class TotaisData {
        public Decimal tempoEmVooDecimalTotal;
        public Decimal horasVooEtapaDecimalTotal;
        public Decimal tempoAPUDecimalTotal;
        public Decimal horasMotorTotal;
        public Integer numeroPousosTotal;
    }
    
    // =========================================================================
    // AUTENTICAÇÃO
    // =========================================================================
    
    /**
     * @description Obtém token de acesso (com cache de 40 minutos)
     * Usa Named Credential específico para login com Basic Authentication
     * @return Token Bearer válido
     */
    private static String obterToken() {
        // Verificar cache
        if (cachedToken != null && cachedTokenExpiracao != null && 
            DateTime.now() < cachedTokenExpiracao) {
            return cachedToken;
        }
        
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(NAMED_CREDENTIAL_LOGIN + LOGIN_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(TIMEOUT_SEGUNDOS * 1000);
            
            // NAMED_CREDENTIAL_LOGIN tem "Gerar cabeçalho de autorização" marcado
            // e injeta automaticamente as credenciais Basic Authentication
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                LoginResponse loginRes = (LoginResponse) JSON.deserialize(
                    res.getBody(), 
                    LoginResponse.class
                );
                
                if (loginRes.codigo == 200 && loginRes.data != null) {
                    cachedToken = loginRes.data.access_token;
                    // Cache válido por 38 minutos (2 minutos de margem de segurança)
                    cachedTokenExpiracao = DateTime.now().addMinutes(38);
                    
                    return cachedToken;
                }
            }
            
            System.debug(LoggingLevel.ERROR, 'Falha ao obter token: ' + res.getStatusCode() + ' - ' + res.getBody());
            return null;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exceção ao obter token: ' + e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    // =========================================================================
    // CONTRATO DE SINCRONIZAÇÃO
    // =========================================================================
    
    /**
     * Agrupa os parâmetros usados pela página e pelo processamento assíncrono.
     */
    public class SincronizarVoosLoteRequest {
        public List<Decimal> idsAeronavesPlaneit;
        
        public List<String> idsAeronavesRecords;
        
        public Date dataInicio;
        
        public Date dataFim;
    }
    
    /**
     * Sincroniza voos de uma ou mais aeronaves em uma única transação.
     * Arquitetura: Todos os callouts primeiro → Depois todos os DMLs
     * Evita erro "You have uncommitted work pending"
     * @param loteRequests Lista contendo uma request com múltiplas aeronaves
     * @return Lista de respostas (uma por aeronave)
     */
    public static List<SincronizarVoosResponse> sincronizarVoosDoPlaneit(List<SincronizarVoosLoteRequest> loteRequests) {
        if (loteRequests == null || loteRequests.isEmpty()) {
            return criarRespostaErro('Nenhuma requisição fornecida', 'VALIDACAO', false);
        }
        
        // O contrato atual recebe uma única requisição agregada.
        SincronizarVoosLoteRequest loteReq = loteRequests[0];
        List<Decimal> idsAeronavesPlaneit = loteReq.idsAeronavesPlaneit;
        List<String> idsAeronavesRecords = loteReq.idsAeronavesRecords;
        Date dataInicio = loteReq.dataInicio;
        Date dataFim = loteReq.dataFim;
        
        // Validação
        if (idsAeronavesPlaneit == null || idsAeronavesPlaneit.isEmpty()) {
            return criarRespostaErro('Nenhuma aeronave fornecida', 'VALIDACAO', false);
        }
        
        if (idsAeronavesRecords == null || idsAeronavesRecords.size() != idsAeronavesPlaneit.size()) {
            return criarRespostaErro('Quantidade de IDs inconsistente', 'VALIDACAO', false);
        }

        if (dataInicio == null || dataFim == null || dataInicio > dataFim) {
            return criarRespostaErro('Período de sincronização inválido', 'VALIDACAO', false);
        }
        
        // Obter token uma única vez
        String token = obterToken();
        
        if (String.isBlank(token)) {
            return criarRespostaErro('Falha na autenticação com o Planeit', 'AUTENTICACAO', true);
        }
        
        // VALIDAÇÃO: Verificar limite de callouts (3 por aeronave: totais + voos + abastecimentos avulsos, mais 1 de autenticação)
        Integer calloutsNecessarios = 1 + (idsAeronavesPlaneit.size() * 3);
        if (calloutsNecessarios > MAX_CALLOUTS) {
            return criarRespostaErro(
                'Limite de consultas excedido para ' + idsAeronavesPlaneit.size() + ' aeronaves',
                'LIMITE',
                true
            );
        }
        
        // FASE 1: BUSCAR HORAS TOTAIS DAS AERONAVES (APENAS CALLOUT, SEM DML)
        Map<String, Decimal> horasTotaisPorAeronave = new Map<String, Decimal>();
        
        for (Integer i = 0; i < idsAeronavesPlaneit.size(); i++) {
            Decimal idAeronave = idsAeronavesPlaneit[i];
            String aeronaveRecordId = idsAeronavesRecords[i];
            
            try {
                TotaisData totais = buscarTotais(idAeronave);
                
                if (totais != null && totais.horasVooEtapaDecimalTotal != null) {
                    horasTotaisPorAeronave.put(aeronaveRecordId, totais.horasVooEtapaDecimalTotal);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Erro ao buscar totais aeronave ' + idAeronave + ': ' + e.getMessage());
            }
        }
        
        // FASE 2: BUSCAR TODOS OS VOOS (APENAS CALLOUTS)
        Map<Integer, List<VooData>> voosPorAeronave = new Map<Integer, List<VooData>>();
        
        try {
            for (Integer i = 0; i < idsAeronavesPlaneit.size(); i++) {
                Integer idAeronave = idsAeronavesPlaneit[i].intValue();
                List<VooData> voos = buscarVoosAPI(token, idAeronave, dataInicio, dataFim);
                voosPorAeronave.put(idAeronave, voos);
            }
        } catch (PlaneitSyncException e) {
            return criarRespostaErro(e.getMessage(), 'API', true);
        }

        // FASE 2.5: BUSCAR E FILTRAR ABASTECIMENTOS AVULSOS (SEM VOO) DE TODAS AS AERONAVES
        // Falha aqui não aborta a sincronização de voos (já concluída na FASE 2) - apenas
        // ignora avulsos da aeronave afetada nesse ciclo (será retentado no próximo sync).
        // todosIdsAbastecimentosAvulsosAPI guarda TODOS os ids retornados (qualquer data), usado
        // para provar que um avulso ainda existe no Planeit mesmo que sua data tenha mudado para
        // fora da janela do sync - evita exclusão indevida na FASE 4.3.
        // aeronavesComFalhaAvulsos marca aeronaves cuja busca falhou: SEM essa informação não
        // sabemos se um avulso já sincronizado ainda existe no Planeit, então a FASE 4.3 NUNCA
        // exclui avulsos dessas aeronaves nesse ciclo (evita apagar dados por uma falha transitória).
        Map<String, List<AbastecimentoAvulsoData>> avulsosPorAeronave = new Map<String, List<AbastecimentoAvulsoData>>();
        Set<Integer> todosIdsAbastecimentosAvulsosAPI = new Set<Integer>();
        Set<String> aeronavesComFalhaAvulsos = new Set<String>();

        for (Integer i = 0; i < idsAeronavesPlaneit.size(); i++) {
            Integer idAeronave = idsAeronavesPlaneit[i].intValue();
            String aeronaveRecordId = idsAeronavesRecords[i];
            List<AbastecimentoAvulsoData> avulsosAeronave = new List<AbastecimentoAvulsoData>();

            try {
                for (AbastecimentoAvulsoData avData : buscarAbastecimentosAPI(token, idAeronave)) {
                    if (avData.idVoo != null) {
                        continue; // já tratado via abastecimentos aninhados em /voos
                    }
                    todosIdsAbastecimentosAvulsosAPI.add(avData.id);

                    if (String.isBlank(avData.dataAbastecimento)) {
                        continue;
                    }
                    Date dataAvulso;
                    try {
                        dataAvulso = Date.valueOf(avData.dataAbastecimento);
                    } catch (Exception e) {
                        System.debug(LoggingLevel.WARN, 'Data inválida em abastecimento avulso ' + avData.id + ': ' + avData.dataAbastecimento);
                        continue;
                    }
                    if (dataAvulso < dataInicio || dataAvulso > dataFim) {
                        continue; // fora da janela deste sync; será pego em um range maior
                    }
                    avulsosAeronave.add(avData);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Erro ao buscar abastecimentos avulsos da aeronave ' + idAeronave + ': ' + e.getMessage());
                aeronavesComFalhaAvulsos.add(aeronaveRecordId);
            }

            avulsosPorAeronave.put(aeronaveRecordId, avulsosAeronave);
        }

        // FASE 3: COLETAR TODOS OS NOMES DE PILOTOS, OPERADORES E IDS DE ABASTECIMENTOS
        Set<String> todosNomesPilotos = new Set<String>();
        Set<String> todosNomesOperadores = new Set<String>();
        Set<Integer> todosIdsAbastecimentosAPI = new Set<Integer>();
        
        for (List<VooData> voosAeronave : voosPorAeronave.values()) {
            for (VooData vooData : voosAeronave) {
                // Extrair piloto
                String piloto = extrairNomePiloto(vooData);
                if (String.isNotBlank(piloto)) {
                    todosNomesPilotos.add(piloto.trim());
                }
                // Extrair operador (lista "Operador:" ou campo livre "Extras")
                String nomeOperador = resolverNomeOperador(vooData);
                if (String.isNotBlank(nomeOperador)) {
                    todosNomesOperadores.add(nomeOperador);
                }
                // Coletar IDs de todos os abastecimentos
                if (vooData.abastecimentos != null) {
                    for (AbastecimentoData ab : vooData.abastecimentos) {
                        if (ab.id != null) {
                            todosIdsAbastecimentosAPI.add(ab.id);
                        }
                    }
                }
            }
        }

        // Incluir avulsos (dentro da janela do sync) na mesma query de dedup de abastecimentos
        for (List<AbastecimentoAvulsoData> avulsosAeronave : avulsosPorAeronave.values()) {
            for (AbastecimentoAvulsoData avData : avulsosAeronave) {
                todosIdsAbastecimentosAPI.add(avData.id);
            }
        }

        // UMA query para todos os pilotos e operadores
        Map<String, Id> empregadosPorNome = buscarEmpregadosEmMassa(todosNomesPilotos, todosNomesOperadores);
        
        // FASE 4: BUSCAR TODOS OS VOOS EXISTENTES (UMA QUERY PARA TODAS AS AERONAVES)
        Set<Integer> todosIdsVoosAPI = new Set<Integer>();
        for (List<VooData> voosAeronave : voosPorAeronave.values()) {
            for (VooData vooData : voosAeronave) {
                if (vooData.idVoo != null) {
                    todosIdsVoosAPI.add(vooData.idVoo);
                }
            }
        }
        
        Map<Integer, Controle_Horas_Voo__c> todosVoosExistentes = new Map<Integer, Controle_Horas_Voo__c>();
        if (!todosIdsVoosAPI.isEmpty()) {
            for (Controle_Horas_Voo__c vooExist : [
                SELECT Id, Id_Voo_Planeit__c, Editado_Manualmente__c, Faturado__c
                FROM Controle_Horas_Voo__c 
                WHERE Id_Voo_Planeit__c IN :todosIdsVoosAPI
            ]) {
                todosVoosExistentes.put(Integer.valueOf(vooExist.Id_Voo_Planeit__c), vooExist);
            }
        }
        
        // FASE 4.0: BUSCAR TODOS OS ABASTECIMENTOS EXISTENTES
        // Os campos do voo pai são necessários para avulsos: permitem
        // localizar o placeholder AB já criado e verificar se ele está protegido.
        Map<Integer, Abastecimento__c> todosAbastecimentosExistentes = new Map<Integer, Abastecimento__c>();
        if (!todosIdsAbastecimentosAPI.isEmpty()) {
            for (Abastecimento__c abExist : [
                SELECT Id, Id_Abastecimento_Planeit__c, Editado_Manualmente__c, Faturado__c,
                    Voo__c, Voo__r.Editado_Manualmente__c, Voo__r.Faturado__c
                FROM Abastecimento__c
                WHERE Id_Abastecimento_Planeit__c IN :todosIdsAbastecimentosAPI
            ]) {
                todosAbastecimentosExistentes.put(Integer.valueOf(abExist.Id_Abastecimento_Planeit__c), abExist);
            }
        }
        
        // FASE 4.1: IDENTIFICAR VOOS PARA DELETAR (existem no SF mas não vieram da API)
        // Regra: Voos com Id_Voo_Planeit__c preenchido que não existem mais no Planeit
        // Voos manuais (Id_Voo_Planeit__c = null) são preservados
        List<Controle_Horas_Voo__c> voosParaDeletar = new List<Controle_Horas_Voo__c>();
        
        // Buscar voos do SF que têm Id_Voo_Planeit__c preenchido, no período e aeronaves sincronizadas
        Set<String> idsAeronavesSet = new Set<String>(idsAeronavesRecords);
        List<Controle_Horas_Voo__c> voosSFComIdPlaneit = [
            SELECT Id, Id_Voo_Planeit__c, Aeronave__c, Data_do_Voo__c,
                Editado_Manualmente__c, Faturado__c,
                (SELECT Id FROM Abastecimentos__r
                    WHERE Editado_Manualmente__c = true OR Faturado__c = true
                    LIMIT 1)
            FROM Controle_Horas_Voo__c
            WHERE Aeronave__c IN :idsAeronavesSet
            AND Data_do_Voo__c >= :dataInicio
            AND Data_do_Voo__c <= :dataFim
            AND Id_Voo_Planeit__c != null
        ];
        
        // Verificar quais não vieram da API
        for (Controle_Horas_Voo__c vooSF : voosSFComIdPlaneit) {
            Integer idVooPlaneit = Integer.valueOf(vooSF.Id_Voo_Planeit__c);
            if (!todosIdsVoosAPI.contains(idVooPlaneit)) {
                // Este voo foi deletado no Planeit
                if (vooSF.Editado_Manualmente__c || vooSF.Faturado__c ||
                    !vooSF.Abastecimentos__r.isEmpty()) {
                    // Preserva também o pai para impedir exclusão em cascata de abastecimento protegido.
                    System.debug('🔒 Voo preservado (edição manual ou faturamento): Id_Voo_Planeit__c=' + idVooPlaneit);
                } else {
                    voosParaDeletar.add(vooSF);
                    System.debug('🗑️ Voo para deletar: Id_Voo_Planeit__c=' + idVooPlaneit + 
                                ' (não existe mais no Planeit)');
                }
            }
        }
        
        // FASE 4.2: IDENTIFICAR ABASTECIMENTOS PARA DELETAR
        // Buscar abastecimentos no SF vinculados aos voos do período com Id_Abastecimento_Planeit__c preenchido
        Set<Id> idsVoosExistentes = new Set<Id>();
        for (Controle_Horas_Voo__c vooExist : todosVoosExistentes.values()) {
            idsVoosExistentes.add(vooExist.Id);
        }
        List<Abastecimento__c> abastecimentosParaDeletar = new List<Abastecimento__c>();
        if (!idsVoosExistentes.isEmpty()) {
            for (Abastecimento__c abSF : [
                SELECT Id, Id_Abastecimento_Planeit__c, Editado_Manualmente__c, Faturado__c,
                    Voo__r.Editado_Manualmente__c, Voo__r.Faturado__c
                FROM Abastecimento__c 
                WHERE Voo__c IN :idsVoosExistentes 
                AND Id_Abastecimento_Planeit__c != null
            ]) {
                Integer idAbPlaneit = Integer.valueOf(abSF.Id_Abastecimento_Planeit__c);
                if (!todosIdsAbastecimentosAPI.contains(idAbPlaneit)) {
                    if (abSF.Editado_Manualmente__c || abSF.Faturado__c ||
                        abSF.Voo__r.Editado_Manualmente__c || abSF.Voo__r.Faturado__c) {
                        System.debug('🔒 Abastecimento preservado (edição manual ou faturamento): Id=' + abSF.Id);
                    } else {
                        abastecimentosParaDeletar.add(abSF);
                    }
                }
            }
        }

        // FASE 4.3: IDENTIFICAR ABASTECIMENTOS AVULSOS (SEM VOO) PARA DELETAR
        // Regra: abastecimento avulso já sincronizado (Id_Abastecimento_Planeit__c preenchido)
        // cujo placeholder AB (Tipo__c='AB', Id_Voo_Planeit__c=null) não existe mais no Planeit.
        // O par (abastecimento + placeholder) só é excluído se nenhum dos dois estiver protegido.
        // Aeronaves com falha na busca de avulsos (FASE 2.5) ficam de fora: sem uma leitura
        // confiável do Planeit, não há como provar que o registro realmente sumiu.
        Set<String> idsAeronavesParaExclusaoAvulsos = new Set<String>(idsAeronavesSet);
        idsAeronavesParaExclusaoAvulsos.removeAll(aeronavesComFalhaAvulsos);

        Set<Id> idsPlaceholdersParaDeletar = new Set<Id>();
        if (!idsAeronavesParaExclusaoAvulsos.isEmpty()) {
            for (Abastecimento__c abAvulsoSF : [
                SELECT Id, Id_Abastecimento_Planeit__c, Editado_Manualmente__c, Faturado__c,
                    Voo__c, Voo__r.Editado_Manualmente__c, Voo__r.Faturado__c
                FROM Abastecimento__c
                WHERE Voo__r.Aeronave__c IN :idsAeronavesParaExclusaoAvulsos
                AND Voo__r.Tipo__c = 'AB'
                AND Voo__r.Id_Voo_Planeit__c = null
                AND Voo__r.Data_do_Voo__c >= :dataInicio
                AND Voo__r.Data_do_Voo__c <= :dataFim
                AND Id_Abastecimento_Planeit__c != null
            ]) {
                Integer idAvulsoPlaneit = Integer.valueOf(abAvulsoSF.Id_Abastecimento_Planeit__c);
                if (todosIdsAbastecimentosAvulsosAPI.contains(idAvulsoPlaneit)) {
                    continue; // ainda existe no Planeit (mesmo que fora da janela por data)
                }
                if (abAvulsoSF.Editado_Manualmente__c || abAvulsoSF.Faturado__c ||
                    abAvulsoSF.Voo__r.Editado_Manualmente__c || abAvulsoSF.Voo__r.Faturado__c) {
                    System.debug('🔒 Abastecimento avulso preservado (edição manual ou faturamento): Id=' + abAvulsoSF.Id);
                    continue;
                }
                abastecimentosParaDeletar.add(abAvulsoSF);
                idsPlaceholdersParaDeletar.add(abAvulsoSF.Voo__c);
            }
        }
        for (Id placeholderId : idsPlaceholdersParaDeletar) {
            voosParaDeletar.add(new Controle_Horas_Voo__c(Id = placeholderId));
        }

        // FASE 5: PROCESSAR TODOS OS VOOS DE TODAS AS AERONAVES
        List<Controle_Horas_Voo__c> todosVoosParaCriar = new List<Controle_Horas_Voo__c>();
        List<Controle_Horas_Voo__c> todosVoosParaAtualizar = new List<Controle_Horas_Voo__c>();
        List<Abastecimento__c> todosAbastecimentosParaCriar = new List<Abastecimento__c>();
        List<Abastecimento__c> todosAbastecimentosParaAtualizar = new List<Abastecimento__c>();
        // Mapa para resolver abastecimentos de voos novos após o insert (VooData → lista de AbastecimentoData)
        Map<Integer, List<AbastecimentoData>> abastNovosPorIndexVooNovo = new Map<Integer, List<AbastecimentoData>>();
        // Mapa para resolver abastecimento avulso do placeholder AB recém-criado após o insert
        Map<Integer, AbastecimentoAvulsoData> abastNovosAvulsosPorIndexVooNovo = new Map<Integer, AbastecimentoAvulsoData>();

        for (Integer i = 0; i < idsAeronavesPlaneit.size(); i++) {
            Integer idAeronave = idsAeronavesPlaneit[i].intValue();
            String aeronaveRecordId = idsAeronavesRecords[i];
            List<VooData> voos = voosPorAeronave.get(idAeronave);
            if (voos == null) {
                voos = new List<VooData>();
            }

            for (VooData vooData : voos) {
                Controle_Horas_Voo__c vooRecord;
                Boolean isUpdate = false;
                
                // Verificar se já existe
                if (todosVoosExistentes.containsKey(vooData.idVoo)) {
                    vooRecord = todosVoosExistentes.get(vooData.idVoo);
                    isUpdate = true;
                } else {
                    vooRecord = new Controle_Horas_Voo__c();
                    vooRecord.Aeronave__c = aeronaveRecordId;
                    vooRecord.Id_Voo_Planeit__c = vooData.idVoo;
                }
                
                // Converter data
                Date dataVoo = null;
                if (String.isNotBlank(vooData.dataVoo)) {
                    try {
                        dataVoo = Date.valueOf(vooData.dataVoo);
                    } catch (Exception e) {
                        System.debug(LoggingLevel.WARN, 'Erro ao converter data: ' + vooData.dataVoo);
                    }
                }
                
                // REGRA DE NEGÓCIO: Determinar tipo de controle de horas
                String tipoControleHoras = vooData.naturezaVoo;
                if (vooData.naturezaVoo == 'SA') {
                    if (vooData.campoCustomizado2 == 'Não') {
                        tipoControleHoras = 'TT';
                    } else if (vooData.campoCustomizado2 == 'Sim') {
                        tipoControleHoras = 'SA';
                    }
                }
                
                // Extrair nome do piloto
                String nomePiloto = extrairNomePiloto(vooData);
                
                // Atualizar todos os campos
                vooRecord.Data_do_Voo__c = dataVoo;
                vooRecord.DEP__c = vooData.localDecolagem;
                vooRecord.ARR__c = vooData.localPouso;
                vooRecord.Acionamento__c = converterStringParaTime(vooData.horarioPartida);
                vooRecord.Corte__c = converterStringParaTime(vooData.horarioCorteMotores);
                vooRecord.Tipo__c = tipoControleHoras;
                vooRecord.Descricao__c = vooData.campoCustomizado3;
                
                // Campos de tempo de voo
                vooRecord.Horas_Voo__c = vooData.horasVooEtapaDecimal; //Mudar para horasVooEtapaDecimal
                vooRecord.TOT__c = converterTempoParaDecimalHHMM(vooData.horasVooEtapa); //mudar para horasVooEtapa
                
                // Lookup de Piloto e Operador (usa Map - ZERO queries!)
                // Quando não há Empregado__c correspondente, guarda o nome cru em
                // Piloto_Externo__c/Operador_Externo__c (pessoa externa/terceirizada) para
                // exibição na UI. Limpa o campo externo quando um match é encontrado, para
                // autocorrigir caso a pessoa seja cadastrada como empregado depois.
                if (String.isNotBlank(nomePiloto)) {
                    Id pilotoId = empregadosPorNome.get(nomePiloto.trim());
                    vooRecord.Piloto__c = pilotoId;
                    vooRecord.Piloto_Externo__c = pilotoId == null ? nomePiloto.trim() : null;
                } else {
                    vooRecord.Piloto__c = null;
                    vooRecord.Piloto_Externo__c = null;
                }

                String nomeOperadorVoo = resolverNomeOperador(vooData);
                if (String.isNotBlank(nomeOperadorVoo)) {
                    Id operadorId = empregadosPorNome.get(nomeOperadorVoo);
                    vooRecord.Operador__c = operadorId;
                    vooRecord.Operador_Externo__c = operadorId == null ? nomeOperadorVoo : null;
                } else {
                    vooRecord.Operador__c = null;
                    vooRecord.Operador_Externo__c = null;
                }
                
                // Adicionar na lista correta
                if (isUpdate) {
                    // Dados confirmados pelo usuário ou já faturados não podem ser sobrescritos.
                    if (vooRecord.Editado_Manualmente__c || vooRecord.Faturado__c) {
                        System.debug('🔒 Voo ignorado (edição manual ou faturamento): Id_Voo_Planeit__c=' + vooData.idVoo);
                        continue;
                    }
                    todosVoosParaAtualizar.add(vooRecord);
                    // Processar abastecimentos do voo existente (Id já disponível)
                    if (vooData.abastecimentos != null) {
                        for (AbastecimentoData abData : vooData.abastecimentos) {
                            Abastecimento__c abRecord = construirAbastecimento(abData, vooRecord.Id, todosAbastecimentosExistentes);
                            if (todosAbastecimentosExistentes.containsKey(abData.id)) {
                                Abastecimento__c abastecimentoExistente = todosAbastecimentosExistentes.get(abData.id);
                                if (abastecimentoExistente.Editado_Manualmente__c || abastecimentoExistente.Faturado__c) {
                                    System.debug('🔒 Abastecimento ignorado (edição manual ou faturamento): Id_Abastecimento_Planeit__c=' + abData.id);
                                } else {
                                    todosAbastecimentosParaAtualizar.add(abRecord);
                                }
                            } else {
                                todosAbastecimentosParaCriar.add(abRecord);
                            }
                        }
                    }
                } else {
                    Integer indexVooNovo = todosVoosParaCriar.size();
                    todosVoosParaCriar.add(vooRecord);
                    // Guardar abastecimentos para processar após o insert do voo
                    if (vooData.abastecimentos != null && !vooData.abastecimentos.isEmpty()) {
                        abastNovosPorIndexVooNovo.put(indexVooNovo, vooData.abastecimentos);
                    }
                }
            }

            // Processar abastecimentos avulsos (sem voo) desta aeronave: cada um vira um
            // placeholder Controle_Horas_Voo__c (Tipo__c='AB') + seu Abastecimento__c filho,
            // já que Abastecimento__c.Voo__c é obrigatório.
            List<AbastecimentoAvulsoData> avulsosAeronave = avulsosPorAeronave.get(aeronaveRecordId);
            if (avulsosAeronave != null) {
                for (AbastecimentoAvulsoData avData : avulsosAeronave) {
                    if (todosAbastecimentosExistentes.containsKey(avData.id)) {
                        Abastecimento__c existente = todosAbastecimentosExistentes.get(avData.id);
                        if (existente.Editado_Manualmente__c || existente.Faturado__c ||
                            existente.Voo__r.Editado_Manualmente__c || existente.Voo__r.Faturado__c) {
                            System.debug('🔒 Abastecimento avulso ignorado (edição manual ou faturamento): Id_Abastecimento_Planeit__c=' + avData.id);
                            continue;
                        }
                        Abastecimento__c abAtualizado = construirAbastecimentoAvulso(avData, existente.Voo__c, todosAbastecimentosExistentes);
                        todosAbastecimentosParaAtualizar.add(abAtualizado);
                    } else {
                        Controle_Horas_Voo__c placeholder = new Controle_Horas_Voo__c();
                        placeholder.Aeronave__c = aeronaveRecordId;
                        placeholder.Tipo__c = 'AB';
                        placeholder.TOT__c = 0;
                        placeholder.Horas_Voo__c = 0;
                        if (String.isNotBlank(avData.dataAbastecimento)) {
                            try {
                                placeholder.Data_do_Voo__c = Date.valueOf(avData.dataAbastecimento);
                            } catch (Exception e) {
                                System.debug(LoggingLevel.WARN, 'Data inválida em abastecimento avulso ' + avData.id + ': ' + avData.dataAbastecimento);
                            }
                        }

                        Integer indexPlaceholderNovo = todosVoosParaCriar.size();
                        todosVoosParaCriar.add(placeholder);
                        abastNovosAvulsosPorIndexVooNovo.put(indexPlaceholderNovo, avData);
                    }
                }
            }
        }

        // FASE 6: DML ÚNICO PARA VOOS, ABASTECIMENTOS E HORAS TOTAIS
        Integer totalCriados = 0;
        Integer totalAtualizados = 0;
        Integer totalDeletados = 0;
        Integer horasTotaisAtualizadas = 0;
        Integer totalAbastCriados = 0;
        Integer totalAbastAtualizados = 0;
        Integer totalAbastDeletados = 0;
        
        Savepoint savepointSincronizacao = Database.setSavepoint();
        try {
            // 1. Atualizar horas totais das aeronaves
            if (!horasTotaisPorAeronave.isEmpty()) {
                List<Aeronave__c> aeronavesParaAtualizar = new List<Aeronave__c>();
                for (String aeronaveId : horasTotaisPorAeronave.keySet()) {
                    Aeronave__c aero = new Aeronave__c();
                    aero.Id = aeronaveId;
                    aero.Horas_Totais_de_Voo__c = horasTotaisPorAeronave.get(aeronaveId);
                    aeronavesParaAtualizar.add(aero);
                }
                update aeronavesParaAtualizar;
                horasTotaisAtualizadas = aeronavesParaAtualizar.size();
            }
            
            // 2. Inserir TODOS os novos voos de UMA VEZ
            if (!todosVoosParaCriar.isEmpty()) {
                insert todosVoosParaCriar;
                totalCriados = todosVoosParaCriar.size();
            }
            
            // 3. Resolver abastecimentos dos voos recém-criados (agora têm Id)
            for (Integer idx : abastNovosPorIndexVooNovo.keySet()) {
                Id vooNovoId = todosVoosParaCriar[idx].Id;
                for (AbastecimentoData abData : abastNovosPorIndexVooNovo.get(idx)) {
                    Abastecimento__c abRecord = construirAbastecimento(abData, vooNovoId, todosAbastecimentosExistentes);
                    // Para voos novos, todos os abastecimentos são inserções
                    todosAbastecimentosParaCriar.add(abRecord);
                }
            }

            // 3.1 Resolver abastecimentos avulsos dos placeholders AB recém-criados (agora têm Id)
            for (Integer idx : abastNovosAvulsosPorIndexVooNovo.keySet()) {
                Id placeholderNovoId = todosVoosParaCriar[idx].Id;
                AbastecimentoAvulsoData avData = abastNovosAvulsosPorIndexVooNovo.get(idx);
                Abastecimento__c abRecord = construirAbastecimentoAvulso(avData, placeholderNovoId, todosAbastecimentosExistentes);
                todosAbastecimentosParaCriar.add(abRecord);
            }

            // 4. Inserir TODOS os novos abastecimentos de UMA VEZ
            if (!todosAbastecimentosParaCriar.isEmpty()) {
                insert todosAbastecimentosParaCriar;
                totalAbastCriados = todosAbastecimentosParaCriar.size();
            }
            
            // 5. Atualizar TODOS os abastecimentos existentes de UMA VEZ
            if (!todosAbastecimentosParaAtualizar.isEmpty()) {
                update todosAbastecimentosParaAtualizar;
                totalAbastAtualizados = todosAbastecimentosParaAtualizar.size();
            }
            
            // 6. Deletar abastecimentos que foram removidos do Planeit
            if (!abastecimentosParaDeletar.isEmpty()) {
                delete abastecimentosParaDeletar;
                totalAbastDeletados = abastecimentosParaDeletar.size();
            }
            
            // 7. Atualizar TODOS os voos existentes de UMA VEZ
            if (!todosVoosParaAtualizar.isEmpty()) {
                update todosVoosParaAtualizar;
                totalAtualizados = todosVoosParaAtualizar.size();
            }
            
            // 8. Deletar voos que foram removidos do Planeit
            if (!voosParaDeletar.isEmpty()) {
                delete voosParaDeletar;
                totalDeletados = voosParaDeletar.size();
                System.debug('🗑️ Deletados ' + totalDeletados + ' voos que não existem mais no Planeit');
            }
            
        } catch (Exception e) {
            Database.rollback(savepointSincronizacao);
            System.debug(LoggingLevel.ERROR, 'Erro DML ao salvar: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
            return criarRespostaErro('Não foi possível salvar a sincronização', 'DML', true);
        }
        
        // Consolidar resultados em uma única resposta.
        SincronizarVoosResponse respostaConsolidada = new SincronizarVoosResponse();
        respostaConsolidada.sucesso = true;
        respostaConsolidada.totalImportados = totalCriados;
        respostaConsolidada.totalAtualizados = totalAtualizados;
        respostaConsolidada.totalDeletados = totalDeletados;
        respostaConsolidada.totalAbastecimentosImportados = totalAbastCriados;
        respostaConsolidada.totalAbastecimentosAtualizados = totalAbastAtualizados;
        respostaConsolidada.totalAbastecimentosDeletados = totalAbastDeletados;
        respostaConsolidada.podeTentarNovamente = false;
        respostaConsolidada.mensagem = 'Processadas ' + idsAeronavesPlaneit.size() + ' aeronaves. ' +
                                       'Voos - Criados: ' + totalCriados + ', Atualizados: ' + totalAtualizados + 
                                       ', Deletados: ' + totalDeletados + '. ' +
                                       'Abastecimentos - Criados: ' + totalAbastCriados + 
                                       ', Atualizados: ' + totalAbastAtualizados +
                                       ', Deletados: ' + totalAbastDeletados + '. ' +
                                       'Horas Totais atualizadas: ' + horasTotaisAtualizadas;
        
        // Retornar lista com apenas uma resposta consolidada
        return new List<SincronizarVoosResponse>{ respostaConsolidada };
    }
    
    // =========================================================================
    // MÉTODOS AUXILIARES
    // =========================================================================
    
    /**
     * @description Constrói ou atualiza um registro Abastecimento__c a partir dos dados da API
     * @param abData Dados de abastecimento vindos da API
     * @param vooId Id do Controle_Horas_Voo__c pai
     * @param existentes Mapa de abastecimentos já existentes no SF
     * @return Abastecimento__c preenchido (com ou sem Id, dependendo se é insert ou update)
     */
    private static Abastecimento__c construirAbastecimento(
        AbastecimentoData abData, 
        Id vooId, 
        Map<Integer, Abastecimento__c> existentes
    ) {
        Abastecimento__c ab;
        if (existentes.containsKey(abData.id)) {
            ab = existentes.get(abData.id);
        } else {
            ab = new Abastecimento__c();
            ab.Id_Abastecimento_Planeit__c = abData.id;
            ab.Voo__c = vooId;
        }
        
        ab.Local__c               = abData.localAbastecimento;
        ab.Origem_Destino__c      = abData.origemDestino;
        ab.Tipo_Combustivel__c    = abData.tipoAbastecimento;
        ab.Quantidade__c          = abData.quantidade;
        ab.Unidade__c             = abData.unidade;
        ab.Custo_Unitario__c      = abData.custoUnidade;
        ab.Custo_Total__c         = abData.custoTotal;
        ab.Documento_Referencia__c = abData.documentoReferencia;
        ab.Numero_Recibo__c       = abData.delivery_receipt_code;
        ab.Observacoes__c         = abData.observacoes;
        
        if (String.isNotBlank(abData.dataVoo)) {
            try {
                ab.Data_Voo__c = Date.valueOf(abData.dataVoo);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Erro ao converter data abastecimento: ' + abData.dataVoo);
            }
        }

        return ab;
    }

    /**
     * @description Constrói ou atualiza um Abastecimento__c avulso (sem voo) a partir do
     * endpoint dedicado /aeronave/abastecimentos. O pai é sempre um Controle_Horas_Voo__c
     * placeholder (Tipo__c = 'AB'), já que Abastecimento__c.Voo__c é obrigatório.
     * @param avData Dados de abastecimento avulso vindos da API
     * @param vooId Id do Controle_Horas_Voo__c placeholder pai
     * @param existentes Mapa de abastecimentos já existentes no SF
     * @return Abastecimento__c preenchido (com ou sem Id, dependendo se é insert ou update)
     */
    private static Abastecimento__c construirAbastecimentoAvulso(
        AbastecimentoAvulsoData avData,
        Id vooId,
        Map<Integer, Abastecimento__c> existentes
    ) {
        Abastecimento__c ab;
        if (existentes.containsKey(avData.id)) {
            ab = existentes.get(avData.id);
        } else {
            ab = new Abastecimento__c();
            ab.Id_Abastecimento_Planeit__c = avData.id;
            ab.Voo__c = vooId;
        }

        ab.Local__c                = avData.localAbastecimento;
        ab.Origem_Destino__c       = avData.origemDestino;
        ab.Tipo_Combustivel__c     = avData.tipoAbastecimento;
        ab.Quantidade__c           = converterStringParaDecimal(avData.quantidade);
        ab.Unidade__c              = avData.unidade;
        ab.Custo_Unitario__c       = converterStringParaDecimal(avData.custoUnidade);
        ab.Custo_Total__c          = converterStringParaDecimal(avData.custoTotal);
        ab.Documento_Referencia__c = avData.documentoReferencia;
        ab.Numero_Recibo__c        = avData.delivery_receipt_code;
        ab.Observacoes__c          = avData.observacoes;

        if (String.isNotBlank(avData.dataAbastecimento)) {
            try {
                ab.Data_Voo__c = Date.valueOf(avData.dataAbastecimento);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Erro ao converter data abastecimento avulso: ' + avData.dataAbastecimento);
            }
        }

        return ab;
    }

    /**
     * @description Converte String numérica vinda da API (ex: "999.00") para Decimal
     * @param value String numérica
     * @return Decimal ou null se vazio/inválido
     */
    private static Decimal converterStringParaDecimal(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            return Decimal.valueOf(value);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Erro ao converter valor decimal "' + value + '": ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Busca voos de uma aeronave via API
     * @param token Token Bearer válido
     * @param idAeronave ID da aeronave no Planeit
     * @param dataInicio Data inicial do filtro
     * @param dataFim Data final do filtro
     * @return Lista de VooData da API
     */
    private static List<VooData> buscarVoosAPI(String token, Integer idAeronave, Date dataInicio, Date dataFim) {
        try {
            // Montar URL com parâmetros (API espera dataVooInicio e dataVooFim)
            String endpoint = NAMED_CREDENTIAL + VOOS_ENDPOINT + '?idAeronave=' + idAeronave;
            
            if (dataInicio != null) {
                endpoint += '&dataVooInicio=' + String.valueOf(dataInicio);
            }
            
            if (dataFim != null) {
                endpoint += '&dataVooFim=' + String.valueOf(dataFim);
            }
            
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(endpoint);
            httpReq.setMethod('GET');
            httpReq.setHeader('Authorization', 'Bearer ' + token); // NOPMD - endpoint uses a Named Credential.
            httpReq.setHeader('Accept', 'application/json');
            httpReq.setTimeout(TIMEOUT_SEGUNDOS * 1000);
            
            Http http = new Http();
            HttpResponse res = http.send(httpReq);
            
            if (res.getStatusCode() != 200) {
                throw new PlaneitSyncException(
                    'Falha ao consultar voos da aeronave ' + idAeronave +
                    ' (HTTP ' + res.getStatusCode() + ')'
                );
            }

            VoosResponse voosRes = (VoosResponse) JSON.deserialize(
                res.getBody(),
                VoosResponse.class
            );

            if (voosRes == null || voosRes.codigo != 200) {
                throw new PlaneitSyncException(
                    'Resposta inválida ao consultar voos da aeronave ' + idAeronave
                );
            }

            return voosRes.data == null ? new List<VooData>() : voosRes.data;
        } catch (PlaneitSyncException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exceção ao buscar voos aeronave ' + idAeronave + ': ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new PlaneitSyncException(
                'Resposta inválida ao consultar voos da aeronave ' + idAeronave
            );
        }
    }

    /**
     * @description Busca todos os abastecimentos de uma aeronave via API dedicada.
     * Diferente de buscarVoosAPI, retorna tanto abastecimentos vinculados a voos
     * quanto avulsos (idVoo nulo) - o chamador é responsável por filtrar.
     * @param token Token Bearer válido
     * @param idAeronave ID da aeronave no Planeit
     * @return Lista de AbastecimentoAvulsoData da API
     */
    private static List<AbastecimentoAvulsoData> buscarAbastecimentosAPI(String token, Integer idAeronave) {
        try {
            String endpoint = NAMED_CREDENTIAL + ABASTECIMENTOS_ENDPOINT + '?idAeronave=' + idAeronave;

            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(endpoint);
            httpReq.setMethod('GET');
            httpReq.setHeader('Authorization', 'Bearer ' + token); // NOPMD - endpoint uses a Named Credential.
            httpReq.setHeader('Accept', 'application/json');
            httpReq.setTimeout(TIMEOUT_SEGUNDOS * 1000);

            Http http = new Http();
            HttpResponse res = http.send(httpReq);

            if (res.getStatusCode() != 200) {
                throw new PlaneitSyncException(
                    'Falha ao consultar abastecimentos da aeronave ' + idAeronave +
                    ' (HTTP ' + res.getStatusCode() + ')'
                );
            }

            AbastecimentosResponse abastecimentosRes = (AbastecimentosResponse) JSON.deserialize(
                res.getBody(),
                AbastecimentosResponse.class
            );

            if (abastecimentosRes == null || abastecimentosRes.codigo != 200) {
                throw new PlaneitSyncException(
                    'Resposta inválida ao consultar abastecimentos da aeronave ' + idAeronave
                );
            }

            return abastecimentosRes.data == null ? new List<AbastecimentoAvulsoData>() : abastecimentosRes.data;
        } catch (PlaneitSyncException e) {
            throw e;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exceção ao buscar abastecimentos aeronave ' + idAeronave + ': ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new PlaneitSyncException(
                'Resposta inválida ao consultar abastecimentos da aeronave ' + idAeronave
            );
        }
    }

    private static List<SincronizarVoosResponse> criarRespostaErro(
        String mensagem,
        String tipoErro,
        Boolean podeTentarNovamente
    ) {
        SincronizarVoosResponse resposta = new SincronizarVoosResponse();
        resposta.sucesso = false;
        resposta.mensagem = mensagem;
        resposta.tipoErro = tipoErro;
        resposta.podeTentarNovamente = podeTentarNovamente;
        resposta.totalImportados = 0;
        resposta.totalAtualizados = 0;
        resposta.totalDeletados = 0;
        resposta.totalAbastecimentosImportados = 0;
        resposta.totalAbastecimentosAtualizados = 0;
        resposta.totalAbastecimentosDeletados = 0;
        return new List<SincronizarVoosResponse>{ resposta };
    }
    
    /**
     * @description Extrai nome do piloto de assinaturas ou tripulacao
     * @param vooData Dados do voo
     * @return Nome completo do piloto ou null
     */
    private static String extrairNomePiloto(VooData vooData) {
        // Tentar em assinaturas primeiro (tipoAssinatura = "Piloto em comando")
        if (vooData.assinaturas != null && !vooData.assinaturas.isEmpty()) {
            for (AssinaturaData assinatura : vooData.assinaturas) {
                if (assinatura.tipoAssinatura != null && 
                    assinatura.tipoAssinatura.containsIgnoreCase('Piloto')) {
                    return (assinatura.nome + ' ' + assinatura.sobrenome).trim();
                }
            }
        }
        
        // Tentar em tripulacao (funcaoBordo = "P1")
        if (vooData.tripulacao != null && !vooData.tripulacao.isEmpty()) {
            for (TripulacaoData tripulante : vooData.tripulacao) {
                if (tripulante.funcaoBordo != null && tripulante.funcaoBordo == 'P1') {
                    return (tripulante.nome + ' ' + tripulante.sobrenome).trim();
                }
            }
        }

        return null;
    }

    /**
     * @description Resolve o nome do operador a partir dos campos customizados do PlaneIT.
     *
     * No PlaneIT, "Operador:" (campoCustomizado1) é uma lista de seleção cujo valor pode ser:
     * - o nome de um operador da lista (ex.: "Lucas Rolim");
     * - "N/A", quando o voo não tem operador a bordo (translados, por exemplo);
     * - "Outro - Especificar em Extras", quando o operador não está na lista - nesse caso o
     *   nome real é digitado no campo livre "Extras" (campoCustomizado4).
     *
     * Sem esse tratamento, os valores sentinela seriam gravados como se fossem nomes de
     * pessoas (ex.: um operador chamado "N/A").
     *
     * @param vooData Dados do voo vindos da API
     * @return Nome do operador, ou null quando o voo não tem operador identificado
     */
    private static String resolverNomeOperador(VooData vooData) {
        String operadorSelecionado = String.isBlank(vooData.campoCustomizado1)
            ? null
            : vooData.campoCustomizado1.trim();

        if (String.isBlank(operadorSelecionado) ||
            OPERADOR_SEM_VALOR.contains(operadorSelecionado.toUpperCase())) {
            return null;
        }

        // "Outro - Especificar em Extras": o nome real está no campo livre "Extras"
        if (operadorSelecionado.startsWithIgnoreCase('OUTRO')) {
            return String.isBlank(vooData.campoCustomizado4)
                ? null
                : vooData.campoCustomizado4.trim();
        }

        return operadorSelecionado;
    }

    /**
     * @description Busca IDs de empregados em massa (pilotos e operadores)
     * Estratégia: normalização + matching de tokens (palavras-chave do nome)
     * @param nomesPilotos Set de nomes de pilotos
     * @param nomesOperadores Set de nomes de operadores
     * @return Map com nome completo → ID do empregado
     */
    private static Map<String, Id> buscarEmpregadosEmMassa(Set<String> nomesPilotos, Set<String> nomesOperadores) {
        Map<String, Id> empregadosPorNome = new Map<String, Id>();
        
        // Combinar todos os nomes únicos
        Set<String> todosNomes = new Set<String>();
        todosNomes.addAll(nomesPilotos);
        todosNomes.addAll(nomesOperadores);
        
        if (todosNomes.isEmpty()) {
            return empregadosPorNome;
        }
        
        try {
            // Buscar TODOS os empregados ativos de uma vez (pilotos + operadores)
            List<Empregado__c> todosEmpregados = [
                SELECT Id, Name 
                FROM Empregado__c 
                WHERE Funcao__r.Name IN ('PILOTO', 'OPERADOR DE EQUIP ESPECIAIS', 
                                         'OPERADOR DE EQUIP ESPECIAIS II', 
                                         'OPERADOR DE EQUIP ESPECIAIS III')
                LIMIT 1000
            ];
            
            // Para cada nome da API, encontrar melhor match
            for (String nomeAPI : todosNomes) {
                Id melhorMatch = encontrarMelhorMatch(nomeAPI, todosEmpregados);
                if (melhorMatch != null) {
                    empregadosPorNome.put(nomeAPI, melhorMatch);
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Erro ao buscar empregados: ' + e.getMessage());
        }
        
        return empregadosPorNome;
    }
    
    /**
     * @description Encontra o empregado mais similar ao nome fornecido
     * Usa matching de tokens (palavras significativas do nome)
     * @param nomeAPI Nome vindo da API Planeit
     * @param empregados Lista de empregados do Salesforce
     * @return ID do empregado ou null se não encontrado
     */
    private static Id encontrarMelhorMatch(String nomeAPI, List<Empregado__c> empregados) {
        // Extrair tokens significativos do nome da API (ignorar palavras pequenas)
        Set<String> tokensAPI = extrairTokensSignificativos(nomeAPI);
        
        if (tokensAPI.isEmpty()) {
            return null;
        }
        
        Id melhorMatch = null;
        Integer maiorNumeroMatches = 0;
        
        for (Empregado__c emp : empregados) {
            Set<String> tokensSF = extrairTokensSignificativos(emp.Name);
            
            // Contar quantos tokens batem
            Integer matches = 0;
            for (String tokenAPI : tokensAPI) {
                for (String tokenSF : tokensSF) {
                    if (tokenAPI.equals(tokenSF)) {
                        matches++;
                        break; // Cada token da API conta apenas uma vez
                    }
                }
            }
            
            // Match válido se pelo menos 2 tokens batem (ex: "FERNANDO ANTELO" = 2 tokens)
            // E se é o melhor match até agora
            Integer minTokensNecessarios = Math.min(tokensAPI.size(), 2);
            if (matches >= minTokensNecessarios && matches > maiorNumeroMatches) {
                maiorNumeroMatches = matches;
                melhorMatch = emp.Id;
            }
        }
        
        return melhorMatch;
    }
    
    /**
     * @description Extrai tokens significativos de um nome (normalizado)
     * Remove conectores (de, da, dos, das) e palavras muito curtas
     * @param nome Nome completo
     * @return Set de tokens em lowercase
     */
    private static Set<String> extrairTokensSignificativos(String nome) {
        Set<String> tokens = new Set<String>();
        
        if (String.isBlank(nome)) {
            return tokens;
        }
        
        // Normalizar e dividir em palavras
        String nomeNormalizado = nome.trim().toLowerCase();
        List<String> palavras = nomeNormalizado.split('\\s+');
        
        // Conectores comuns em nomes brasileiros
        Set<String> conectores = new Set<String>{'de', 'da', 'do', 'dos', 'das'};
        
        for (String palavra : palavras) {
            // Adicionar apenas palavras significativas (>= 3 chars e não conectores)
            if (palavra.length() >= 3 && !conectores.contains(palavra)) {
                tokens.add(palavra);
            }
        }
        
        return tokens;
    }
    
    /**
     * @description Converte String no formato "HH:mm:ss" para Time
     * @param timeString String no formato "14:30:00"
     * @return Time object ou null se inválido
     */
    @TestVisible
    private static Time converterStringParaTime(String timeString) {
        if (String.isBlank(timeString)) {
            return null;
        }
        
        try {
            // Formato esperado: "14:30:00" ou "14:30"
            List<String> parts = timeString.split(':');
            if (parts.size() >= 2) {
                Integer hour = Integer.valueOf(parts[0]);
                Integer minute = Integer.valueOf(parts[1]);
                Integer second = parts.size() > 2 ? Integer.valueOf(parts[2]) : 0;
                
                return Time.newInstance(hour, minute, second, 0);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Erro ao converter time "' + timeString + '": ' + e.getMessage());
        }
        
        return null;
    }
    
    /**
     * @description Converte String "HH:mm:ss" para Decimal no formato HH.MM
     * Exemplo: "03:55:00" -> 3.55 (onde .55 representa 55 minutos, não fração decimal)
     * @param timeString String no formato "03:55:00"
     * @return Decimal no formato HH.MM ou null se inválido
     */
    private static Decimal converterTempoParaDecimalHHMM(String timeString) {
        if (String.isBlank(timeString)) {
            return null;
        }
        
        try {
            // Formato esperado: "03:55:00" ou "03:55"
            List<String> parts = timeString.split(':');
            if (parts.size() >= 2) {
                Integer horas = Integer.valueOf(parts[0]);
                Integer minutos = Integer.valueOf(parts[1]);
                
                // Converter para formato HH.MM (ex: 3 horas 55 minutos = 3.55)
                String horasStr = String.valueOf(horas);
                String minutosStr = minutos < 10 ? '0' + String.valueOf(minutos) : String.valueOf(minutos);
                String resultado = horasStr + '.' + minutosStr;
                
                return Decimal.valueOf(resultado);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Erro ao converter tempo para decimal "' + timeString + '": ' + e.getMessage());
        }
        
        return null;
    }
    
    /**
     * @description Limpa cache do token (útil para testes)
     */
    @TestVisible
    private static void limparCacheToken() {
        cachedToken = null;
        cachedTokenExpiracao = null;
    }
    
    // =========================================================================
    // MÉTODOS PARA INSPEÇÕES E CONTROLE TÉCNICO
    // =========================================================================
    
    /**
     * @description Busca inspeções da aeronave na API Planeit
     * @param idAeronavePlaneit ID da aeronave no Planeit
     * @return Lista de inspeções ou null se erro
     */
    public static List<InspecaoData> buscarInspecoes(Decimal idAeronavePlaneit) {
        String token = obterToken();
        if (String.isBlank(token)) {
            System.debug(LoggingLevel.ERROR, 'Token não disponível para buscar inspeções');
            return null;
        }
        
        try {
            String endpoint = NAMED_CREDENTIAL + INSPECOES_ENDPOINT + '?idAeronave=' + 
                String.valueOf(idAeronavePlaneit.intValue());
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token); // NOPMD - endpoint uses a Named Credential.
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(TIMEOUT_SEGUNDOS * 1000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                InspecoesResponse inspecoesRes = (InspecoesResponse) JSON.deserialize(
                    res.getBody(), 
                    InspecoesResponse.class
                );
                
                if (inspecoesRes.codigo == 200 && inspecoesRes.data != null) {
                    return inspecoesRes.data;
                }
            }
            
            System.debug(LoggingLevel.ERROR, 'Erro ao buscar inspeções: ' + res.getStatusCode() + ' - ' + res.getBody());
            return null;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exceção ao buscar inspeções: ' + e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }
    
    /**
     * @description Busca totais da aeronave na API Planeit
     * @param idAeronavePlaneit ID da aeronave no Planeit
     * @return Dados de totais ou null se erro
     */
    public static TotaisData buscarTotais(Decimal idAeronavePlaneit) {
        String token = obterToken();
        if (String.isBlank(token)) {
            System.debug(LoggingLevel.ERROR, 'Token não disponível para buscar totais');
            return null;
        }
        
        try {
            String endpoint = NAMED_CREDENTIAL + TOTAIS_ENDPOINT + '?idAeronave=' + 
                String.valueOf(idAeronavePlaneit.intValue());
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token); // NOPMD - endpoint uses a Named Credential.
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(TIMEOUT_SEGUNDOS * 1000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                TotaisResponse totaisRes = (TotaisResponse) JSON.deserialize(
                    res.getBody(), 
                    TotaisResponse.class
                );
                
                if (totaisRes.codigo == 200 && totaisRes.data != null) {
                    return totaisRes.data;
                }
            }
            
            System.debug(LoggingLevel.ERROR, 'Erro ao buscar totais: ' + res.getStatusCode() + ' - ' + res.getBody());
            return null;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exceção ao buscar totais: ' + e.getMessage() + '\n' + e.getStackTraceString());
            return null;
        }
    }

    // =========================================================================
    // ANEXOS (notas de abastecimento)
    //
    // O arquivo permanece no storage da Planeit. Guardamos apenas o caminho
    // (Abastecimento__c.Caminho_Anexo__c); a URL de download é assinada e
    // expira em 1 hora, por isso é gerada sob demanda, nunca persistida.
    // =========================================================================

    /**
     * Dados de um anexo retornados por /anexos/listar.
     */
    public class AnexoData {
        public Integer id;
        public String diretorioArquivo;
        public String nomeArquivo;
        public String extensaoArquivo;
    }

    private class AnexosResponse {
        public Integer codigo;
        public String mensagem;
        public List<AnexoData> data;
    }

    private class AnexoUrlData {
        public String url;
    }

    private class AnexoUrlResponse {
        public Integer codigo;
        public String mensagem;
        public AnexoUrlData data;
    }

    /**
     * @description Converte a matrícula do Salesforce para o formato da API de anexos.
     * A Planeit usa a matrícula sem hífen (PT-VGD -> PTVGD).
     */
    public static String normalizarMatricula(String matricula) {
        return String.isBlank(matricula) ? null : matricula.replace('-', '').trim().toUpperCase();
    }

    private static String montarQueryStringAnexo(Integer idAbastecimento, String matricula) {
        return '?module=' + ANEXO_MODULE +
               '&tipoRegistro=' + ANEXO_TIPO_REGISTRO +
               '&idRegistro=' + idAbastecimento +
               '&matricula=' + EncodingUtil.urlEncode(matricula, 'UTF-8');
    }

    /**
     * @description Retorna o caminho do anexo de um abastecimento, ou null se não houver.
     * Custa um callout por abastecimento: a API não oferece consulta em lote.
     * @param idAbastecimento Id do abastecimento no Planeit
     * @param matricula Matrícula da aeronave (com ou sem hífen)
     * @return diretorioArquivo do primeiro anexo, ou null
     */
    public static String buscarCaminhoAnexo(Integer idAbastecimento, String matricula) {
        String matriculaApi = normalizarMatricula(matricula);
        if (idAbastecimento == null || String.isBlank(matriculaApi)) {
            return null;
        }

        try {
            String token = obterToken();
            if (String.isBlank(token)) {
                return null;
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(
                NAMED_CREDENTIAL + ANEXOS_LISTAR_ENDPOINT +
                montarQueryStringAnexo(idAbastecimento, matriculaApi)
            );
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token); // NOPMD - endpoint uses a Named Credential.
            req.setHeader('Accept', 'application/json');
            req.setTimeout(TIMEOUT_SEGUNDOS * 1000);

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                System.debug(LoggingLevel.WARN,
                    'Falha ao listar anexos do abastecimento ' + idAbastecimento +
                    ': HTTP ' + res.getStatusCode());
                return null;
            }

            AnexosResponse anexosRes = (AnexosResponse) JSON.deserialize(res.getBody(), AnexosResponse.class);
            if (anexosRes.data == null || anexosRes.data.isEmpty()) {
                return null;
            }

            // A operação anexa no máximo um arquivo por abastecimento; se houver
            // mais de um, o primeiro é o relevante (ordem da própria Planeit).
            return anexosRes.data[0].diretorioArquivo;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Exceção ao listar anexos do abastecimento ' + idAbastecimento + ': ' + e.getMessage());
            return null;
        }
    }

    /**
     * @description Gera a URL assinada de download do anexo. Válida por 1 hora,
     * portanto deve ser usada imediatamente e nunca armazenada.
     * @param idAbastecimento Id do abastecimento no Planeit
     * @param matricula Matrícula da aeronave (com ou sem hífen)
     * @param caminhoArquivo Valor de Abastecimento__c.Caminho_Anexo__c
     * @return URL de download, ou null em caso de falha
     */
    public static String gerarUrlAnexo(Integer idAbastecimento, String matricula, String caminhoArquivo) {
        String matriculaApi = normalizarMatricula(matricula);
        if (idAbastecimento == null || String.isBlank(matriculaApi) || String.isBlank(caminhoArquivo)) {
            return null;
        }

        try {
            String token = obterToken();
            if (String.isBlank(token)) {
                return null;
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(
                NAMED_CREDENTIAL + ANEXOS_URL_ENDPOINT +
                montarQueryStringAnexo(idAbastecimento, matriculaApi) +
                '&diretorioArquivo=' + EncodingUtil.urlEncode(caminhoArquivo, 'UTF-8')
            );
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token); // NOPMD - endpoint uses a Named Credential.
            req.setHeader('Accept', 'application/json');
            req.setTimeout(TIMEOUT_SEGUNDOS * 1000);

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                System.debug(LoggingLevel.WARN,
                    'Falha ao gerar URL do anexo ' + caminhoArquivo + ': HTTP ' + res.getStatusCode());
                return null;
            }

            AnexoUrlResponse urlRes = (AnexoUrlResponse) JSON.deserialize(res.getBody(), AnexoUrlResponse.class);
            return (urlRes.data == null) ? null : urlRes.data.url;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Exceção ao gerar URL do anexo ' + caminhoArquivo + ': ' + e.getMessage());
            return null;
        }
    }
}
