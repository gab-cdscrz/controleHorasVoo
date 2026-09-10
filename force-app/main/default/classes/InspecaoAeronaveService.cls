/**
 * @description Serviço para sincronização de inspeções de aeronaves com API Planeit
 * Segue boas práticas Salesforce: bulkification, separação de callouts e DML
 * 
 * @author Gabriel Cardoso
 * @date 2026-01-19
 * @version 2.0
 * 
 * Fluxo:
 * 1. Callout HTTP para API Planeit (busca inspeções)
 * 2. Parse/Deserialize do JSON de resposta
 * 3. Organização dos dados em Maps/Lists
 * 4. Query no Salesforce para registros existentes
 * 5. Match entre dados da API e Salesforce por Id_Inspecao_Planeit__c
 * 6. Upsert em massa dos registros
 */
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public without sharing class InspecaoAeronaveService {
    
    // =========================================================================
    // CONSTANTES
    // =========================================================================
    
    private static final String NAMED_CREDENTIAL_LOGIN = 'callout:Planeit_API_Login';
    private static final String NAMED_CREDENTIAL = 'callout:Planeit_API';
    private static final String LOGIN_ENDPOINT = '/login';
    private static final String INSPECOES_ENDPOINT = '/aeronave/inspecoes';
    private static final String EXECUCOES_ENDPOINT = '/aeronave/inspecao/execucoes';
    private static final String TOTAIS_ENDPOINT = '/aeronave/totais';
    private static final Integer TIMEOUT_MS = 120000;
    
    // Cache do token
    private static String cachedToken = null;
    private static DateTime cachedTokenExpiracao = null;
    
    // =========================================================================
    // WRAPPER CLASSES PARA JSON
    // =========================================================================
    
    /**
     * Response da API de Login
     */
    private class LoginResponse {
        public Integer codigo;
        public String mensagem;
        public LoginData data;
    }
    
    private class LoginData {
        public String access_token;
        public String token_type;
    }
    
    /**
     * Response da API de Inspeções
     */
    public class InspecoesResponse {
        public Integer codigo;
        public String mensagem;
        public String metodo;
        public List<InspecaoJSON> data;
    }
    
    /**
     * Dados de uma inspeção conforme retornado pela API
     */
    public class InspecaoJSON {
        public Integer idInspecao;
        public Integer idAeronave;
        public String nomeInspecao;
        public String flagCVA;
        public String inicioHoras;
        public String repeticaoHoras;
        public String toleranciaHoras;
        public String inicioTempo;
        public Integer repeticaoTempo;
        public String toleranciaTempo;
        public String situacaoInspecao; // 'A' = ativa, 'I' = inativa
        public String created_at;
        public String updated_at;
        public List<DetalheExecucaoJSON> detalheUltimaExecucao;
    }
    
    /**
     * Detalhes da última execução de uma inspeção
     */
    public class DetalheExecucaoJSON {
        public String nomeInspecao;
        public Integer idExecucaoInspecao;
        public Integer idInspecao;
        public Integer idAeronave;
        public String situacaoInspecao;
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

    public class ExecucoesResponse {
        public Integer codigo;
        public String mensagem;
        public String metodo;
        public List<DetalheExecucaoJSON> data;
    }
    
    /**
     * Response da API de Totais
     */
    private class TotaisResponse {
        public Integer codigo;
        public String mensagem;
        public TotaisJSON data;
    }
    
    public class TotaisJSON {
        public Decimal tempoEmVooDecimalTotal;
        public Decimal horasVooEtapaDecimalTotal;
        public Decimal tempoAPUDecimalTotal;
        public Decimal horasMotorTotal;
        public Integer numeroPousosTotal;
    }
    
    /**
     * Resultado da sincronização
     */
    public class ResultadoSincronizacao {
        public Boolean sucesso { get; set; }
        public String mensagem { get; set; }
        public Integer totalInseridos { get; set; }
        public Integer totalAtualizados { get; set; }
        public Integer totalInativos { get; set; }
        public Integer totalFalhas { get; set; }
        public Boolean sucessoParcial { get; set; }
        public String aeronaveNome { get; set; }
        
        public ResultadoSincronizacao() {
            this.sucesso = false;
            this.totalInseridos = 0;
            this.totalAtualizados = 0;
            this.totalInativos = 0;
            this.totalFalhas = 0;
            this.sucessoParcial = false;
        }
    }
    
    // =========================================================================
    // AUTENTICAÇÃO
    // =========================================================================
    
    /**
     * @description Obtém token de acesso com cache de 38 minutos
     * @return Token Bearer válido ou null se erro
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
            req.setTimeout(TIMEOUT_MS);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                LoginResponse loginRes = (LoginResponse) JSON.deserialize(
                    res.getBody(), 
                    LoginResponse.class
                );
                
                if (loginRes.codigo == 200 && loginRes.data != null) {
                    cachedToken = loginRes.data.access_token;
                    cachedTokenExpiracao = DateTime.now().addMinutes(38);
                    return cachedToken;
                }
            }
            
            System.debug(LoggingLevel.ERROR, 'Falha ao obter token: ' + res.getStatusCode());
            return null;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exceção ao obter token: ' + e.getMessage());
            return null;
        }
    }
    
    // =========================================================================
    // MÉTODOS PRINCIPAIS DE SINCRONIZAÇÃO
    // =========================================================================
    
    /**
     * @description Sincroniza inspeções de uma aeronave específica
     * @param aeronaveId ID do registro Aeronave__c no Salesforce
     * @return ResultadoSincronizacao com detalhes da operação
     */
    public static ResultadoSincronizacao sincronizarInspecoesAeronave(Id aeronaveId) {
        ResultadoSincronizacao resultado = new ResultadoSincronizacao();
        
        // Buscar aeronave
        List<Aeronave__c> aeronaves = [
            SELECT Id, Name, Id_Planeit__c, Horas_Totais_de_Voo__c
            FROM Aeronave__c
            WHERE Id = :aeronaveId
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        
        if (aeronaves.isEmpty()) {
            resultado.mensagem = 'Aeronave não encontrada';
            return resultado;
        }
        
        Aeronave__c aeronave = aeronaves[0];
        resultado.aeronaveNome = aeronave.Name;
        
        if (aeronave.Id_Planeit__c == null) {
            resultado.mensagem = 'Aeronave não possui ID Planeit configurado';
            return resultado;
        }
        
        return sincronizarInspecoesLote(new List<Aeronave__c>{ aeronave });
    }
    
    /**
     * @description Sincroniza inspeções de múltiplas aeronaves em lote
     * Arquitetura: Callouts primeiro → DML depois (evita "uncommitted work pending")
     * 
     * @param aeronaves Lista de aeronaves para sincronizar
     * @return ResultadoSincronizacao consolidado
     */
    public static ResultadoSincronizacao sincronizarInspecoesLote(List<Aeronave__c> aeronaves) {
        ResultadoSincronizacao resultado = new ResultadoSincronizacao();
        
        if (aeronaves == null || aeronaves.isEmpty()) {
            resultado.mensagem = 'Nenhuma aeronave fornecida';
            return resultado;
        }
        
        // Obter token
        String token = obterToken();
        if (String.isBlank(token)) {
            resultado.mensagem = 'Falha na autenticação com API Planeit';
            return resultado;
        }
        
        // =====================================================================
        // FASE 1: CALLOUTS - Buscar dados de TODAS as aeronaves
        // =====================================================================
        
        // Map: Id Aeronave SF → Lista de inspeções da API
        Map<Id, List<InspecaoJSON>> inspecoesPorAeronave = new Map<Id, List<InspecaoJSON>>();
        
        // Map: Id Aeronave SF → Horas Totais da API
        Map<Id, Decimal> horasTotaisPorAeronave = new Map<Id, Decimal>();
        
        // Map: Id Aeronave SF → Id Planeit
        Map<Id, Decimal> idPlaneitPorAeronave = new Map<Id, Decimal>();

        Map<Id, Map<Integer, DetalheExecucaoJSON>> execucoesPorAeronave =
            new Map<Id, Map<Integer, DetalheExecucaoJSON>>();
        
        for (Aeronave__c aero : aeronaves) {
            if (aero.Id_Planeit__c == null) {
                continue;
            }
            
            idPlaneitPorAeronave.put(aero.Id, aero.Id_Planeit__c);
            
            try {
                // Buscar inspeções
                List<InspecaoJSON> inspecoes = buscarInspecoesAPI(token, aero.Id_Planeit__c);
                if (inspecoes != null) {
                    inspecoesPorAeronave.put(aero.Id, inspecoes);
                } else {
                    resultado.totalFalhas++;
                    continue;
                }

                List<DetalheExecucaoJSON> execucoes =
                    buscarExecucoesAPI(token, aero.Id_Planeit__c);
                if (execucoes != null) {
                    execucoesPorAeronave.put(
                        aero.Id,
                        mapearUltimasExecucoes(execucoes)
                    );
                } else {
                    resultado.totalFalhas++;
                }
                
                // Buscar totais (horas totais de voo)
                TotaisJSON totais = buscarTotaisAPI(token, aero.Id_Planeit__c);
                if (totais != null && totais.horasVooEtapaDecimalTotal != null) {
                    horasTotaisPorAeronave.put(aero.Id, totais.horasVooEtapaDecimalTotal);
                } else {
                    resultado.totalFalhas++;
                    horasTotaisPorAeronave.put(aero.Id, aero.Horas_Totais_de_Voo__c);
                }
                
            } catch (Exception e) {
                resultado.totalFalhas++;
                System.debug(LoggingLevel.ERROR, 'Erro ao buscar dados aeronave ' + aero.Name + ': ' + e.getMessage());
            }
        }
        
        if (inspecoesPorAeronave.isEmpty()) {
            resultado.mensagem = 'Nenhuma inspeção encontrada na API';
            return resultado;
        }
        
        // =====================================================================
        // FASE 2: COLETAR TODAS AS CHAVES ÚNICAS PARA QUERY
        // Chave Única = IdAeronavePlaneit_NomeInspecao (ex: "1599_100hrs")
        // =====================================================================
        
        Set<String> todasChavesUnicas = new Set<String>();
        
        for (Id aeroId : inspecoesPorAeronave.keySet()) {
            List<InspecaoJSON> inspecoes = inspecoesPorAeronave.get(aeroId);
            Decimal idPlaneit = idPlaneitPorAeronave.get(aeroId);
            
            for (InspecaoJSON insp : inspecoes) {
                if (insp.nomeInspecao != null && idPlaneit != null) {
                    String chaveUnica = String.valueOf(idPlaneit.intValue()) + '_' + insp.nomeInspecao;
                    todasChavesUnicas.add(chaveUnica);
                }
            }
        }
        
        // =====================================================================
        // FASE 3: QUERY - Buscar registros existentes por Chave Única
        // =====================================================================
        
        // Map: Chave Única → Registro Existente (apenas ativos)
        Map<String, Inspecao_Aeronave__c> registrosAtivosPorChave = new Map<String, Inspecao_Aeronave__c>();
        
        if (!todasChavesUnicas.isEmpty()) {
            for (Inspecao_Aeronave__c insp : [
                SELECT Id, Chave_Unica__c, Id_Inspecao_Planeit__c, Aeronave__c, 
                       Nome_Inspecao__c, Id_Aeronave_Planeit__c, Inicio_Horas__c, 
                       Data_Proxima__c, Horas_Proxima__c, Data_Execucao__c, 
                       Horas_Execucao__c, Responsavel_Execucao__c, Ativa__c,
                       Status_Inspecao__c, Ultima_Sincronizacao__c
                FROM Inspecao_Aeronave__c
                WHERE Chave_Unica__c IN :todasChavesUnicas
                AND Ativa__c = true
                WITH SYSTEM_MODE
            ]) {
                registrosAtivosPorChave.put(insp.Chave_Unica__c, insp);
            }
        }
        
        // =====================================================================
        // FASE 4: PROCESSAR E CRIAR/ATUALIZAR REGISTROS
        // Lógica:
        // - Inspeção INATIVA (I): Apenas atualiza registro existente para arquivar
        // - Inspeção ATIVA (A): Atualiza se existe, cria se não existe
        // =====================================================================
        
        List<Inspecao_Aeronave__c> registrosParaUpsert = new List<Inspecao_Aeronave__c>();
        List<Aeronave__c> aeronavesParaAtualizar = new List<Aeronave__c>();
        
        // Set para rastrear chaves únicas recebidas (para detectar removidas)
        Set<String> chavesRecebidas = new Set<String>();
        
        for (Id aeronaveId : inspecoesPorAeronave.keySet()) {
            List<InspecaoJSON> inspecoes = inspecoesPorAeronave.get(aeronaveId);
            Decimal horasTotais = horasTotaisPorAeronave.get(aeronaveId);
            Decimal idPlaneit = idPlaneitPorAeronave.get(aeronaveId);
            Boolean execucoesDisponiveis =
                execucoesPorAeronave.containsKey(aeronaveId);
            Map<Integer, DetalheExecucaoJSON> execucoesInspecao =
                execucoesDisponiveis
                    ? execucoesPorAeronave.get(aeronaveId)
                    : new Map<Integer, DetalheExecucaoJSON>();
            
            // Verificar se TBO existe na lista de inspeções ativas
            Boolean tboEncontrada = false;
            for (InspecaoJSON insp : inspecoes) {
                if (insp.nomeInspecao != null && 
                    insp.nomeInspecao.equalsIgnoreCase('TBO') &&
                    insp.situacaoInspecao == 'A') {
                    tboEncontrada = true;
                    break;
                }
            }
            
            for (InspecaoJSON inspJSON : inspecoes) {
                // Gerar Chave Única
                String chaveUnica = String.valueOf(idPlaneit.intValue()) + '_' + inspJSON.nomeInspecao;
                Boolean isInativa = (inspJSON.situacaoInspecao == 'I');
                
                // =============================================================
                // CASO 1: INSPEÇÃO INATIVA
                // Apenas arquiva registro existente, NÃO cria novo
                // =============================================================
                if (isInativa) {
                    // Adiciona à lista de chaves processadas para não processar novamente na FASE 5
                    chavesRecebidas.add(chaveUnica);
                    
                    if (registrosAtivosPorChave.containsKey(chaveUnica)) {
                        Inspecao_Aeronave__c registro = registrosAtivosPorChave.get(chaveUnica);
                        registro.Ativa__c = false;
                        registro.Status_Inspecao__c = 'ARQUIVADA';
                        registro.Ultima_Sincronizacao__c = DateTime.now();
                        registrosParaUpsert.add(registro);
                        resultado.totalInativos++;
                        
                        System.debug('📦 Arquivando inspeção: ' + chaveUnica);
                    }
                    // Se não existe registro ativo, não faz nada (não cria novo para inativa)
                    continue;
                }
                
                // =============================================================
                // CASO 2: INSPEÇÃO ATIVA
                // Atualiza se existe, cria se não existe
                // =============================================================
                chavesRecebidas.add(chaveUnica);
                
                Inspecao_Aeronave__c registro;
                Boolean isUpdate = false;
                
                if (registrosAtivosPorChave.containsKey(chaveUnica)) {
                    registro = registrosAtivosPorChave.get(chaveUnica);
                    isUpdate = true;
                } else {
                    registro = new Inspecao_Aeronave__c();
                    registro.Aeronave__c = aeronaveId;
                }
                
                // Preencher campos da inspeção
                registro.Chave_Unica__c = chaveUnica;
                registro.Id_Inspecao_Planeit__c = String.valueOf(inspJSON.idInspecao);
                registro.Id_Aeronave_Planeit__c = String.valueOf(inspJSON.idAeronave);
                registro.Nome_Inspecao__c = inspJSON.nomeInspecao;
                registro.Ativa__c = true;
                registro.Ultima_Sincronizacao__c = DateTime.now();
                
                // Preencher inicioHoras
                if (String.isNotBlank(inspJSON.inicioHoras)) {
                    try {
                        registro.Inicio_Horas__c = Decimal.valueOf(inspJSON.inicioHoras);
                    } catch (Exception e) {
                        System.debug(LoggingLevel.WARN, 'Erro ao converter inicioHoras: ' + inspJSON.inicioHoras);
                    }
                }
                
                DetalheExecucaoJSON ultimaExec = inspJSON.idInspecao == null
                    ? null
                    : execucoesInspecao.get(inspJSON.idInspecao);

                Boolean dadosExecucaoProcessados = false;
                if (execucoesDisponiveis || !isUpdate) {
                    limparDadosExecucao(registro);
                    aplicarExecucao(registro, ultimaExec);
                    aplicarConfiguracaoInicial(registro, inspJSON);
                    dadosExecucaoProcessados = true;
                }

                // Processar detalheUltimaExecucao (pegar primeiro item)
                if (!dadosExecucaoProcessados && inspJSON.detalheUltimaExecucao != null && !inspJSON.detalheUltimaExecucao.isEmpty()) {
                    DetalheExecucaoJSON exec = inspJSON.detalheUltimaExecucao[0];
                    
                    // Data de Execução
                    if (String.isNotBlank(exec.dataExecucao)) {
                        try {
                            registro.Data_Execucao__c = Date.valueOf(exec.dataExecucao.substring(0, 10));
                        } catch (Exception e) {
                            System.debug(LoggingLevel.WARN, 'Erro ao converter dataExecucao: ' + exec.dataExecucao);
                        }
                    }
                    
                    // Horas de Execução
                    if (String.isNotBlank(exec.horasExecucao)) {
                        try {
                            registro.Horas_Execucao__c = Decimal.valueOf(exec.horasExecucao);
                        } catch (Exception e) {
                            System.debug(LoggingLevel.WARN, 'Erro ao converter horasExecucao: ' + exec.horasExecucao);
                        }
                    }
                    
                    // Data Próxima (importante para CVA)
                    if (String.isNotBlank(exec.dataProxima)) {
                        try {
                            registro.Data_Proxima__c = Date.valueOf(exec.dataProxima.substring(0, 10));
                        } catch (Exception e) {
                            System.debug(LoggingLevel.WARN, 'Erro ao converter dataProxima: ' + exec.dataProxima);
                        }
                    }
                    
                    // Horas Próxima - da última execução
                    if (String.isNotBlank(exec.horasProxima)) {
                        try {
                            registro.Horas_Proxima__c = Decimal.valueOf(exec.horasProxima);
                        } catch (Exception e) {
                            System.debug(LoggingLevel.WARN, 'Erro ao converter horasProxima: ' + exec.horasProxima);
                        }
                    }
                    
                    // Responsável pela Execução
                    registro.Responsavel_Execucao__c = exec.responsavelExecucao;
                }
                
                // FALLBACK: Se não temos Horas_Proxima__c da execução, usar inicioHoras
                // Isso é importante para inspeções como TBO que não têm execução prévia
                if (registro.Horas_Proxima__c == null && String.isNotBlank(inspJSON.inicioHoras)) {
                    try {
                        registro.Horas_Proxima__c = Decimal.valueOf(inspJSON.inicioHoras);
                    } catch (Exception e) {
                        System.debug(LoggingLevel.WARN, 'Erro ao usar inicioHoras como Horas_Proxima: ' + inspJSON.inicioHoras);
                    }
                }
                if (registro.Data_Proxima__c == null && String.isNotBlank(inspJSON.inicioTempo)) {
                    registro.Data_Proxima__c = converterDataPlaneit(inspJSON.inicioTempo);
                }
                
                // NOTA: Horas_Restantes__c NÃO é salvo no banco de dados
                // É calculado dinamicamente no frontend usando:
                // Horas_Restantes = Horas_Proxima - Horas_Totais_de_Voo (da aeronave)
                
                // Calcular Status da Inspeção (usa cálculo interno, não salva Horas_Restantes)
                registro.Status_Inspecao__c = calcularStatusInspecao(registro, horasTotais);
                
                registrosParaUpsert.add(registro);
                
                if (isUpdate) {
                    resultado.totalAtualizados++;
                } else {
                    resultado.totalInseridos++;
                }
            }
            
            // Se TBO não foi encontrada (ativa), criar registro indicando "VENCIDA"
            if (!tboEncontrada) {
                String tboChaveUnica = String.valueOf(idPlaneit.intValue()) + '_TBO';
                
                // Verificar se já existe registro TBO ativo para não duplicar
                if (!registrosAtivosPorChave.containsKey(tboChaveUnica)) {
                    Inspecao_Aeronave__c tboVencida = new Inspecao_Aeronave__c();
                    tboVencida.Aeronave__c = aeronaveId;
                    tboVencida.Chave_Unica__c = tboChaveUnica;
                    tboVencida.Id_Inspecao_Planeit__c = 'TBO_V_' + String.valueOf(idPlaneit.intValue());
                    tboVencida.Id_Aeronave_Planeit__c = String.valueOf(idPlaneit.intValue());
                    tboVencida.Nome_Inspecao__c = 'TBO';
                    tboVencida.Status_Inspecao__c = 'VENCIDA';
                    tboVencida.Ativa__c = true; // Marcada como ativa para aparecer na tela
                    tboVencida.Ultima_Sincronizacao__c = DateTime.now();
                    
                    registrosParaUpsert.add(tboVencida);
                    resultado.totalInseridos++;
                    chavesRecebidas.add(tboChaveUnica);
                    
                    System.debug('⚠️ TBO VENCIDA para aeronave: ' + aeronaveId);
                }
            }
            
            // Atualizar horas totais da aeronave
            if (horasTotais != null) {
                Aeronave__c aeroUpdate = new Aeronave__c();
                aeroUpdate.Id = aeronaveId;
                aeroUpdate.Horas_Totais_de_Voo__c = horasTotais;
                aeronavesParaAtualizar.add(aeroUpdate);
            }
        }
        
        // =====================================================================
        // FASE 5: ARQUIVAR INSPEÇÕES QUE NÃO EXISTEM MAIS NA API
        // Usa Chave_Unica__c para identificação
        // =====================================================================
        
        Set<Id> idsAeronaves = inspecoesPorAeronave.keySet();
        
        List<Inspecao_Aeronave__c> inspecoesParaArquivar = [
            SELECT Id, Chave_Unica__c, Ativa__c
            FROM Inspecao_Aeronave__c
            WHERE Aeronave__c IN :idsAeronaves
            AND Ativa__c = true
            AND Chave_Unica__c NOT IN :chavesRecebidas
            WITH SYSTEM_MODE
        ];
        
        for (Inspecao_Aeronave__c insp : inspecoesParaArquivar) {
            insp.Ativa__c = false;
            insp.Status_Inspecao__c = 'REMOVIDA';
            insp.Ultima_Sincronizacao__c = DateTime.now();
            registrosParaUpsert.add(insp);
            resultado.totalInativos++;
            
            System.debug('🗑️ Removendo inspeção não encontrada na API: ' + insp.Chave_Unica__c);
        }
        
        // =====================================================================
        // FASE 6: DML - Salvar todos os registros
        // Usa Chave_Unica__c como External ID para upsert
        // =====================================================================
        
        try {
            resultado.totalInseridos = 0;
            resultado.totalAtualizados = 0;
            Integer gravacoesComSucesso = 0;

            // Upsert inspeções usando Chave_Unica__c (External ID)
            if (!registrosParaUpsert.isEmpty()) {
                Database.UpsertResult[] upsertResults = Database.upsert(
                    registrosParaUpsert, 
                    Inspecao_Aeronave__c.Chave_Unica__c, 
                    false,
                    AccessLevel.SYSTEM_MODE
                );
                
                for (Integer i = 0; i < upsertResults.size(); i++) {
                    if (upsertResults[i].isSuccess()) {
                        gravacoesComSucesso++;
                        if (upsertResults[i].isCreated()) {
                            resultado.totalInseridos++;
                        } else {
                            resultado.totalAtualizados++;
                        }
                    } else {
                        resultado.totalFalhas++;
                        for (Database.Error err : upsertResults[i].getErrors()) {
                            System.debug(LoggingLevel.ERROR, 'Erro upsert inspeção: ' + err.getMessage());
                        }
                    }
                }
            }
            
            // Atualizar aeronaves
            if (!aeronavesParaAtualizar.isEmpty()) {
                for (Database.SaveResult saveResult : Database.update(
                    aeronavesParaAtualizar,
                    false,
                    AccessLevel.SYSTEM_MODE
                )) {
                    if (saveResult.isSuccess()) {
                        gravacoesComSucesso++;
                    } else {
                        resultado.totalFalhas++;
                    }
                }
            }
            
            resultado.sucesso = resultado.totalFalhas == 0 || gravacoesComSucesso > 0;
            resultado.sucessoParcial = resultado.totalFalhas > 0 && gravacoesComSucesso > 0;
            resultado.mensagem = resultado.sucessoParcial
                ? 'Sincronização concluída parcialmente. '
                : 'Sincronização concluída! ';
            resultado.mensagem +=
                'Inseridos: ' + resultado.totalInseridos + ', ' +
                'Atualizados: ' + resultado.totalAtualizados + ', ' +
                'Inativos: ' + resultado.totalInativos + ', ' +
                'Falhas: ' + resultado.totalFalhas;
                
        } catch (DmlException e) {
            resultado.sucesso = false;
            resultado.mensagem = 'Erro ao salvar registros: ' + e.getMessage();
            System.debug(LoggingLevel.ERROR, 'DML Exception: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return resultado;
    }
    
    // =========================================================================
    // MÉTODOS AUXILIARES - CALLOUTS
    // =========================================================================
    
    /**
     * @description Busca inspeções de uma aeronave via API
     * @param token Token Bearer
     * @param idAeronavePlaneit ID da aeronave no Planeit
     * @return Lista de InspecaoJSON ou null
     */
    private static List<InspecaoJSON> buscarInspecoesAPI(String token, Decimal idAeronavePlaneit) {
        try {
            String endpoint = NAMED_CREDENTIAL + INSPECOES_ENDPOINT + 
                '?idAeronave=' + String.valueOf(idAeronavePlaneit.intValue());
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(TIMEOUT_MS);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                InspecoesResponse inspecoesRes = (InspecoesResponse) JSON.deserialize(
                    res.getBody(), 
                    InspecoesResponse.class
                );
                
                if (inspecoesRes.codigo == 200 && inspecoesRes.data != null) {
                    System.debug('✅ Inspeções encontradas: ' + inspecoesRes.data.size() + 
                        ' para aeronave ' + idAeronavePlaneit);
                    return inspecoesRes.data;
                }
            }
            
            System.debug(LoggingLevel.ERROR, 'Erro buscar inspeções: HTTP ' + res.getStatusCode());
            return null;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exceção buscar inspeções: ' + e.getMessage());
            return null;
        }
    }

    private static List<DetalheExecucaoJSON> buscarExecucoesAPI(
        String token,
        Decimal idAeronavePlaneit
    ) {
        try {
            String endpoint = NAMED_CREDENTIAL + EXECUCOES_ENDPOINT +
                '?idAeronave=' + String.valueOf(idAeronavePlaneit.intValue());

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Accept', 'application/json');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(TIMEOUT_MS);

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) {
                System.debug(
                    LoggingLevel.ERROR,
                    'Erro buscar execucoes: HTTP ' + res.getStatusCode()
                );
                return null;
            }

            ExecucoesResponse execucoesRes = (ExecucoesResponse) JSON.deserialize(
                res.getBody(),
                ExecucoesResponse.class
            );
            return execucoesRes.codigo == 200 && execucoesRes.data != null
                ? execucoesRes.data
                : null;
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Excecao buscar execucoes: ' + e.getMessage()
            );
            return null;
        }
    }

    private static Map<Integer, DetalheExecucaoJSON> mapearUltimasExecucoes(
        List<DetalheExecucaoJSON> execucoes
    ) {
        Map<Integer, DetalheExecucaoJSON> resultado =
            new Map<Integer, DetalheExecucaoJSON>();
        if (execucoes == null) {
            return resultado;
        }

        for (DetalheExecucaoJSON execucao : execucoes) {
            if (execucao.idInspecao == null) {
                continue;
            }

            DetalheExecucaoJSON atual = resultado.get(execucao.idInspecao);
            if (atual == null) {
                resultado.put(execucao.idInspecao, execucao);
                continue;
            }

            Date dataNova = converterDataPlaneit(execucao.dataExecucao);
            Date dataAtual = converterDataPlaneit(atual.dataExecucao);
            if (dataNova != null && (dataAtual == null || dataNova > dataAtual)) {
                resultado.put(execucao.idInspecao, execucao);
            }
        }
        return resultado;
    }

    private static void limparDadosExecucao(Inspecao_Aeronave__c registro) {
        registro.Data_Execucao__c = null;
        registro.Horas_Execucao__c = null;
        registro.Data_Proxima__c = null;
        registro.Horas_Proxima__c = null;
        registro.Responsavel_Execucao__c = null;
    }

    private static void aplicarExecucao(
        Inspecao_Aeronave__c registro,
        DetalheExecucaoJSON execucao
    ) {
        if (execucao == null) {
            return;
        }

        registro.Data_Execucao__c = converterDataPlaneit(execucao.dataExecucao);
        registro.Horas_Execucao__c = converterDecimalPlaneit(
            execucao.horasExecucao
        );
        registro.Data_Proxima__c = converterDataPlaneit(execucao.dataProxima);
        registro.Horas_Proxima__c = converterDecimalPlaneit(
            execucao.horasProxima
        );
        registro.Responsavel_Execucao__c = execucao.responsavelExecucao;
    }

    private static void aplicarConfiguracaoInicial(
        Inspecao_Aeronave__c registro,
        InspecaoJSON inspecao
    ) {
        if (registro.Data_Proxima__c == null) {
            registro.Data_Proxima__c = converterDataPlaneit(inspecao.inicioTempo);
        }
        if (registro.Horas_Proxima__c == null) {
            registro.Horas_Proxima__c = converterDecimalPlaneit(
                inspecao.inicioHoras
            );
        }
    }
    
    /**
     * @description Busca totais de uma aeronave via API
     * @param token Token Bearer
     * @param idAeronavePlaneit ID da aeronave no Planeit
     * @return TotaisJSON ou null
     */
    private static TotaisJSON buscarTotaisAPI(String token, Decimal idAeronavePlaneit) {
        try {
            String endpoint = NAMED_CREDENTIAL + TOTAIS_ENDPOINT + 
                '?idAeronave=' + String.valueOf(idAeronavePlaneit.intValue());
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + token);
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(TIMEOUT_MS);
            
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
            
            return null;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exceção buscar totais: ' + e.getMessage());
            return null;
        }
    }
    
    // =========================================================================
    // MÉTODOS AUXILIARES - CÁLCULOS
    // =========================================================================
    
    /**
     * @description Calcula o status da inspeção baseado nas horas/datas
     * @param registro Registro de inspeção
     * @param horasTotais Horas totais da aeronave
     * @return Status calculado
     */
    private static Date converterDataPlaneit(String dataTexto) {
        if (String.isBlank(dataTexto)) {
            return null;
        }

        try {
            String dataNormalizada = dataTexto.length() >= 10
                ? dataTexto.substring(0, 10)
                : dataTexto;
            return Date.valueOf(dataNormalizada);
        } catch (Exception e) {
            System.debug(
                LoggingLevel.WARN,
                'Erro ao converter data Planeit: ' + dataTexto
            );
            return null;
        }
    }

    private static Decimal converterDecimalPlaneit(String valor) {
        if (String.isBlank(valor)) {
            return null;
        }

        try {
            return Decimal.valueOf(valor);
        } catch (Exception e) {
            System.debug(
                LoggingLevel.WARN,
                'Erro ao converter decimal Planeit: ' + valor
            );
            return null;
        }
    }

    private static String calcularStatusInspecao(Inspecao_Aeronave__c registro, Decimal horasTotais) {
        return InspecaoStatusService.calculate(registro, horasTotais).status;
    }
    
    /**
     * @description Limpa cache do token (útil para testes)
     */
    @TestVisible
    private static void limparCacheToken() {
        cachedToken = null;
        cachedTokenExpiracao = null;
    }
}