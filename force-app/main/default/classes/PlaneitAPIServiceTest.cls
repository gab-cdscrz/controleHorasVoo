@IsTest
private class PlaneitAPIServiceTest {
    private class MultiEndpointMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Login
            if (req.getEndpoint().contains('/login')) {
                res.setStatusCode(200);
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"mensagem": "Sucesso",' +
                    '"metodo": "POST",' +
                    '"data": {' +
                        '"access_token": "TEST_TOKEN_123",' +
                        '"token_type": "Bearer"' +
                    '}' +
                '}');
            }
            // Voos com abastecimentos
            else if (req.getEndpoint().contains('/voos')) {
                res.setStatusCode(200);
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"mensagem": "Sucesso",' +
                    '"metodo": "GET",' +
                    '"data": [{' +
                        '"idVoo": 94611,' +
                        '"idAeronave": 1599,' +
                        '"matricula": "PPBAP",' +
                        '"dataVoo": "2025-10-21",' +
                        '"localDecolagem": "SBRP",' +
                        '"localPouso": "SBPA",' +
                        '"horarioPartida": "08:30:00",' +
                        '"horarioCorteMotores": "10:45:00",' +
                        '"totalCombustivelPartida": 150.50,' +
                        '"naturezaVoo": "SA",' +
                        '"campoCustomizado1": "Empregado OPERADOR DE EQUIP ESPECIAIS",' +
                        '"campoCustomizado2": "Sim",' +
                        '"campoCustomizado3": "Teste voo",' +
                        '"horasVooEtapa": "02:15:00",' +
                        '"horasVooEtapaDecimal": 2.25,' +
                        '"assinaturas": [{' +
                            '\"nome\": \"Empregado\",' +
                            '\"sobrenome\": \"Piloto\",' +
                            '\"tipoAssinatura\": \"Piloto em comando\"' +
                        '}],' +
                        '"tripulacao": [],' +
                        '"abastecimentos": [{' +
                            '"id": 24747,' +
                            '"idVoo": 94611,' +
                            '"dataVoo": "2025-10-21",' +
                            '"localAbastecimento": "SBRP",' +
                            '"quantidade": 257.00,' +
                            '"custoUnidade": 13.40,' +
                            '"custoTotal": 3443.80,' +
                            '"documentoReferencia": "NF 12345"' +
                        '}]' +
                    '}]' +
                '}');
            }
            
            return res;
        }
    }
    
    
    /**
     * Mock para simular SA com coletaDados = "NÃ£o" (deve virar TT)
     */
    private class VooTentativaMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('/login')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": {"access_token": "TEST", "token_type": "Bearer"}}');
            } else if (req.getEndpoint().contains('/voos')) {
                res.setStatusCode(200);
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"data": [{' +
                        '"idVoo": 94612,' +
                        '"idAeronave": 1599,' +
                        '"matricula": "PPBAP",' +
                        '"dataVoo": "2025-10-22",' +
                        '"localDecolagem": "SBPA",' +
                        '"localPouso": "SBRP",' +
                        '"horarioPartida": "14:00:00",' +
                        '"horarioCorteMotores": "16:15:00",' +
                        '"naturezaVoo": "SA",' +
                        '"campoCustomizado1": "Empregado OPERADOR DE EQUIP ESPECIAIS",' +
                        '"campoCustomizado2": "Não",' +
                        '"campoCustomizado3": "Tentativa",' +
                        '"horasVooEtapa": "02:15:00",' +
                        '"horasVooEtapaDecimal": 2.25,' +
                        '"assinaturas": [],' +
                        '"tripulacao": [],' +
                        '"abastecimentos": []' +
                    '}]' +
                '}');
            }
            return res;
        }
    }

    /** Retorna um voo privado e respostas vazias válidas para os demais endpoints. */
    private class VooPrivadoMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (req.getEndpoint().contains('/login')) {
                res.setBody('{"codigo":200,"data":{"access_token":"TEST","token_type":"Bearer"}}');
            } else if (req.getEndpoint().contains('/totais')) {
                res.setBody('{"codigo":200,"data":{"horasVooEtapaDecimalTotal":100}}');
            } else if (req.getEndpoint().contains('/voos')) {
                res.setBody('{' +
                    '"codigo":200,' +
                    '"data":[{' +
                        '"idVoo":197049,' +
                        '"idAeronave":1602,' +
                        '"matricula":"PTVGD",' +
                        '"dataVoo":"2025-10-22",' +
                        '"localDecolagem":"SNAX",' +
                        '"localPouso":"SSCP",' +
                        '"horarioPartida":"09:00:00",' +
                        '"horarioCorteMotores":"10:00:00",' +
                        '"naturezaVoo":"PV",' +
                        '"horasVooEtapa":"01:00:00",' +
                        '"horasVooEtapaDecimal":1,' +
                        '"assinaturas":[],' +
                        '"tripulacao":[],' +
                        '"abastecimentos":[]' +
                    '}]' +
                '}');
            } else if (req.getEndpoint().contains('/abastecimentos')) {
                res.setBody('{"codigo":200,"data":[]}');
            }
            return res;
        }
    }
    
    /**
     * Mock para simular erro na API
     */
    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('/login')) {
                res.setStatusCode(500);
                res.setBody('{"codigo": 500, "mensagem": "Erro interno"}');
            }
            return res;
        }
    }
    
    /**
     * Mock para voos sem dados (lista vazia)
     */
    private class EmptyVoosMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('/login')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": {"access_token": "TEST", "token_type": "Bearer"}}');
            } else if (req.getEndpoint().contains('/voos')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": []}');
            }
            return res;
        }
    }
    
    /**
     * Mock para inspeÃ§Ãµes e totais
     */
    private class InspecoesTotaisMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            String endpoint = req.getEndpoint();
            System.debug('InspecoesTotaisMock - Endpoint recebido: ' + endpoint);
            
            // Login - qualquer endpoint que contenha 'login' (case insensitive)
            if (endpoint.containsIgnoreCase('login')) {
                System.debug('InspecoesTotaisMock - Retornando resposta de LOGIN');
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"mensagem": "Sucesso",' +
                    '"metodo": "POST",' +
                    '"data": {' +
                        '"access_token": "TEST_TOKEN_MOCK_123",' +
                        '"token_type": "Bearer"' +
                    '}' +
                '}');
            } 
            // InspeÃ§Ãµes
            else if (endpoint.containsIgnoreCase('inspecoes')) {
                System.debug('InspecoesTotaisMock - Retornando resposta de INSPECOES');
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"mensagem": "Sucesso",' +
                    '"metodo": "GET",' +
                    '"data": [{' +
                        '"idInspecao": 1001,' +
                        '"nomeInspecao": "RevisÃ£o 100hrs",' +
                        '"idAeronave": 1599,' +
                        '"flagCVA": "N",' +
                        '"inicioHoras": "100",' +
                        '"repeticaoHoras": "100",' +
                        '"toleranciaHoras": "10",' +
                        '"situacaoInspecao": "ATIVO",' +
                        '"detalheUltimaExecucao": [{' +
                            '"idExecucaoInspecao": 5001,' +
                            '"idInspecao": 1001,' +
                            '"idAeronave": 1599,' +
                            '"dataExecucao": "2025-01-15",' +
                            '"horasExecucao": "1850.5",' +
                            '"dataProxima": "2025-06-15",' +
                            '"horasProxima": "1950.5",' +
                            '"responsavelExecucao": "Tecnico Teste",' +
                            '"observacoes": "Revisao completa",' +
                            '"rn": 1' +
                        '}]' +
                    '},{' +
                        '"idInspecao": 1002,' +
                        '"nomeInspecao": "TBO Motor",' +
                        '"idAeronave": 1599,' +
                        '"flagCVA": "N",' +
                        '"inicioHoras": "2000",' +
                        '"repeticaoHoras": "2000",' +
                        '"toleranciaHoras": "0",' +
                        '"situacaoInspecao": "ATIVO",' +
                        '"detalheUltimaExecucao": [{' +
                            '"idExecucaoInspecao": 5002,' +
                            '"idInspecao": 1002,' +
                            '"idAeronave": 1599,' +
                            '"dataExecucao": "2024-06-01",' +
                            '"horasExecucao": "0",' +
                            '"dataProxima": "2026-06-01",' +
                            '"horasProxima": "2000",' +
                            '"responsavelExecucao": "Oficina",' +
                            '"observacoes": "TBO Motor novo",' +
                            '"rn": 1' +
                        '}]' +
                    '},{' +
                        '"idInspecao": 1003,' +
                        '"nomeInspecao": "CVA",' +
                        '"idAeronave": 1599,' +
                        '"flagCVA": "S",' +
                        '"inicioHoras": null,' +
                        '"repeticaoHoras": null,' +
                        '"inicioTempo": "2025-01-01",' +
                        '"repeticaoTempo": 12,' +
                        '"situacaoInspecao": "ATIVO",' +
                        '"detalheUltimaExecucao": [{' +
                            '"idExecucaoInspecao": 5003,' +
                            '"idInspecao": 1003,' +
                            '"idAeronave": 1599,' +
                            '"dataExecucao": "2025-01-01",' +
                            '"horasExecucao": "1800",' +
                            '"dataProxima": "2026-01-01",' +
                            '"horasProxima": null,' +
                            '"responsavelExecucao": "ANAC",' +
                            '"observacoes": "CVA Valido",' +
                            '"rn": 1' +
                        '}]' +
                    '}]' +
                '}');
            } 
            // Totais
            else if (endpoint.containsIgnoreCase('totais')) {
                System.debug('InspecoesTotaisMock - Retornando resposta de TOTAIS');
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"mensagem": "Sucesso",' +
                    '"metodo": "GET",' +
                    '"data": {' +
                        '"tempoEmVooDecimalTotal": 1875.50,' +
                        '"horasVooEtapaDecimalTotal": 1850.25,' +
                        '"tempoAPUDecimalTotal": 0,' +
                        '"horasMotorTotal": 1875.50,' +
                        '"numeroPousosTotal": 2450' +
                    '}' +
                '}');
            }
            // Fallback - endpoint nÃ£o reconhecido
            else {
                System.debug('InspecoesTotaisMock - ENDPOINT NÃƒO RECONHECIDO: ' + endpoint);
                res.setStatusCode(404);
                res.setBody('{"codigo": 404, "mensagem": "Endpoint nÃ£o encontrado no mock"}');
            }
            
            return res;
        }
    }
    
    /**
     * Mock para inspeÃ§Ãµes sem dados
     */
    private class InspecoesEmptyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            String endpoint = req.getEndpoint();
            System.debug('InspecoesEmptyMock - Endpoint: ' + endpoint);
            
            if (endpoint.containsIgnoreCase('login')) {
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"mensagem": "Sucesso",' +
                    '"data": {' +
                        '"access_token": "TEST_TOKEN_EMPTY",' +
                        '"token_type": "Bearer"' +
                    '}' +
                '}');
            } 
            else if (endpoint.containsIgnoreCase('inspecoes')) {
                res.setBody('{"codigo": 200, "mensagem": "Sucesso", "data": []}');
            } 
            else if (endpoint.containsIgnoreCase('totais')) {
                res.setBody('{"codigo": 200, "mensagem": "Sucesso", "data": null}');
            }
            return res;
        }
    }
    
    /**
     * Mock para erro em inspeÃ§Ãµes/totais
     */
    private class InspecoesErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String endpoint = req.getEndpoint();
            System.debug('InspecoesErrorMock - Endpoint: ' + endpoint);
            
            if (endpoint.containsIgnoreCase('login')) {
                res.setStatusCode(200);
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"mensagem": "Sucesso",' +
                    '"data": {' +
                        '"access_token": "TEST_TOKEN_ERROR",' +
                        '"token_type": "Bearer"' +
                    '}' +
                '}');
            } 
            else if (endpoint.containsIgnoreCase('inspecoes') || endpoint.containsIgnoreCase('totais')) {
                res.setStatusCode(500);
                res.setBody('{"codigo": 500, "mensagem": "Erro interno do servidor"}');
            }
            return res;
        }
    }
    
    /**
     * Mock para sincronizaÃ§Ã£o completa de voos (login + totais + voos)
     */
    private class VoosCompletoMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            String endpoint = req.getEndpoint();
            
            if (endpoint.containsIgnoreCase('login')) {
                res.setBody('{"codigo": 200, "data": {"access_token": "TEST_TOKEN", "token_type": "Bearer"}}');
            }
            else if (endpoint.containsIgnoreCase('totais')) {
                res.setBody('{"codigo": 200, "data": {"horasVooEtapaDecimalTotal": 1850.25}}');
            }
            else if (endpoint.containsIgnoreCase('voos')) {
                res.setBody('{"codigo": 200, "data": []}');
            }
            return res;
        }
    }
    
    /**
     * Mock que retorna resposta invÃ¡lida (JSON malformado) para testar blocos catch
     */
    private class JsonInvalidoMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            String endpoint = req.getEndpoint();
            
            if (endpoint.containsIgnoreCase('login')) {
                res.setBody('{"codigo": 200, "data": {"access_token": "TEST", "token_type": "Bearer"}}');
            }
            else if (endpoint.containsIgnoreCase('inspecoes')) {
                // JSON malformado para provocar exception
                res.setBody('{invalid json content');
            }
            else if (endpoint.containsIgnoreCase('totais')) {
                // JSON malformado
                res.setBody('not valid json at all');
            }
            else if (endpoint.containsIgnoreCase('voos')) {
                res.setBody('{"malformed');
            }
            return res;
        }
    }
    
    /**
     * Mock que retorna cÃ³digo de erro no login
     */
    private class LoginFalhaMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(401);
            res.setBody('{"codigo": 401, "mensagem": "Credenciais invÃ¡lidas"}');
            return res;
        }
    }
    
    /**
     * Mock para testar cenÃ¡rio de exceÃ§Ã£o interna na busca de totais
     */
    private class TotaisExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            String endpoint = req.getEndpoint();
            
            if (endpoint.containsIgnoreCase('login')) {
                res.setBody('{"codigo": 200, "data": {"access_token": "TEST", "token_type": "Bearer"}}');
            }
            else if (endpoint.containsIgnoreCase('totais')) {
                // Retornar cÃ³digo de sucesso mas com dados invÃ¡lidos que causarÃ£o NullPointerException
                res.setBody('{"codigo": 200, "data": "string_invalida_ao_inves_de_objeto"}');
            }
            else if (endpoint.containsIgnoreCase('voos')) {
                res.setBody('{"codigo": 200, "data": []}');
            }
            return res;
        }
    }
    
    
    /**
     * Mock do endpoint dedicado /aeronave/abastecimentos: retorna um abastecimento
     * avulso (idVoo nulo, id 39760) e um vinculado a um voo (idVoo preenchido, id 28636),
     * que deve ser ignorado por esse fluxo pois já é tratado via /aeronave/voos.
     */
    private class AbastecimentosAvulsosMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();

            if (endpoint.containsIgnoreCase('login')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": {"access_token": "TEST", "token_type": "Bearer"}}');
            } else if (endpoint.containsIgnoreCase('/aeronave/voos')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": []}');
            } else if (endpoint.containsIgnoreCase('/aeronave/abastecimentos')) {
                res.setStatusCode(200);
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"data": [{' +
                        '"id": 39760,' +
                        '"idVoo": null,' +
                        '"idAeronave": 1599,' +
                        '"dataAbastecimento": "2025-10-15",' +
                        '"horaAbastecimento": "09:33:00",' +
                        '"status": 1,' +
                        '"localAbastecimento": "SNAX",' +
                        '"origemDestino": "Origem",' +
                        '"tipoAbastecimento": "AVGAS",' +
                        '"quantidade": "999.00",' +
                        '"unidade": "L",' +
                        '"custoUnidade": "1.00",' +
                        '"custoTotal": "999.00",' +
                        '"codigoMoeda": "BRL",' +
                        '"documentoReferencia": "Teste",' +
                        '"observacoes": "Teste"' +
                    '},{' +
                        '"id": 28636,' +
                        '"idVoo": 116364,' +
                        '"idAeronave": 1599,' +
                        '"dataAbastecimento": "2025-10-12",' +
                        '"horaAbastecimento": "11:27:00",' +
                        '"status": 1,' +
                        '"localAbastecimento": "SNAX",' +
                        '"origemDestino": "Destino",' +
                        '"tipoAbastecimento": "AVGAS",' +
                        '"quantidade": "118.40",' +
                        '"unidade": "L",' +
                        '"custoUnidade": "14.25",' +
                        '"custoTotal": "1687.20",' +
                        '"codigoMoeda": "BRL",' +
                        '"documentoReferencia": "RR Fuel Assis",' +
                        '"observacoes": null' +
                    '}]' +
                '}');
            }
            return res;
        }
    }

    /**
     * Mock do endpoint dedicado /aeronave/abastecimentos simulando que nenhum
     * avulso existe mais no Planeit (resposta 200 com lista vazia - diferente de
     * uma falha de callout, que não deve disparar exclusões).
     */
    private class AbastecimentosAvulsosVazioMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();

            if (endpoint.containsIgnoreCase('login')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": {"access_token": "TEST", "token_type": "Bearer"}}');
            } else if (endpoint.containsIgnoreCase('/aeronave/voos')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": []}');
            } else if (endpoint.containsIgnoreCase('/aeronave/abastecimentos')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": []}');
            }
            return res;
        }
    }

    /**
     * Mock com piloto (assinatura) e operador (campoCustomizado1) que não correspondem
     * a nenhum Empregado__c cadastrado nos testes - simula pessoas externas/terceirizadas.
     */
    private class PilotoOperadorExternoMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();

            if (endpoint.containsIgnoreCase('login')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": {"access_token": "TEST", "token_type": "Bearer"}}');
            } else if (endpoint.containsIgnoreCase('/aeronave/voos')) {
                res.setStatusCode(200);
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"data": [{' +
                        '"idVoo": 94611,' +
                        '"idAeronave": 1599,' +
                        '"matricula": "PPBAP",' +
                        '"dataVoo": "2025-10-21",' +
                        '"localDecolagem": "SBRP",' +
                        '"localPouso": "SBPA",' +
                        '"horarioPartida": "08:30:00",' +
                        '"horarioCorteMotores": "10:45:00",' +
                        '"naturezaVoo": "TR",' +
                        '"campoCustomizado1": "Fulano Terceirizado Externo",' +
                        '"campoCustomizado3": "Teste piloto externo",' +
                        '"campoCustomizado4": null,' +
                        '"horasVooEtapa": "02:15:00",' +
                        '"horasVooEtapaDecimal": 2.25,' +
                        '"assinaturas": [{' +
                            '"nome": "Carlos",' +
                            '"sobrenome": "Andrade Voador",' +
                            '"tipoAssinatura": "Piloto em comando"' +
                        '}],' +
                        '"tripulacao": [],' +
                        '"abastecimentos": []' +
                    '}]' +
                '}');
            } else if (endpoint.containsIgnoreCase('/aeronave/abastecimentos')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": []}');
            }
            return res;
        }
    }

    /**
     * Mock reproduzindo os valores reais da lista "Operador:" (campoCustomizado1) do PlaneIT:
     * - voo 90001: "Outro - Especificar em Extras" + nome real no campo "Extras" (campoCustomizado4)
     * - voo 90002: "N/A" (translado sem operador a bordo)
     * - voo 90003: "Outro - Especificar em Extras" mas com "Extras" vazio (sem operador identificável)
     */
    private class OperadorCamposCustomizadosMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();

            if (endpoint.containsIgnoreCase('login')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": {"access_token": "TEST", "token_type": "Bearer"}}');
            } else if (endpoint.containsIgnoreCase('/aeronave/voos')) {
                res.setStatusCode(200);
                res.setBody('{' +
                    '"codigo": 200,' +
                    '"data": [{' +
                        '"idVoo": 90001,' +
                        '"idAeronave": 1599,' +
                        '"dataVoo": "2025-10-21",' +
                        '"naturezaVoo": "SA",' +
                        '"campoCustomizado1": "Outro - Especificar em Extras",' +
                        '"campoCustomizado2": "Sim",' +
                        '"campoCustomizado3": "1518_IGC",' +
                        '"campoCustomizado4": "Gonzalo",' +
                        '"horasVooEtapa": "01:00:00",' +
                        '"horasVooEtapaDecimal": 1.0,' +
                        '"assinaturas": [], "tripulacao": [], "abastecimentos": []' +
                    '},{' +
                        '"idVoo": 90002,' +
                        '"idAeronave": 1599,' +
                        '"dataVoo": "2025-10-22",' +
                        '"naturezaVoo": "TR",' +
                        '"campoCustomizado1": "N/A",' +
                        '"campoCustomizado2": "Não",' +
                        '"campoCustomizado3": "1518_IGC",' +
                        '"campoCustomizado4": null,' +
                        '"horasVooEtapa": "01:00:00",' +
                        '"horasVooEtapaDecimal": 1.0,' +
                        '"assinaturas": [], "tripulacao": [], "abastecimentos": []' +
                    '},{' +
                        '"idVoo": 90003,' +
                        '"idAeronave": 1599,' +
                        '"dataVoo": "2025-10-23",' +
                        '"naturezaVoo": "SA",' +
                        '"campoCustomizado1": "Outro - Especificar em Extras",' +
                        '"campoCustomizado2": "Sim",' +
                        '"campoCustomizado3": "1518_IGC",' +
                        '"campoCustomizado4": null,' +
                        '"horasVooEtapa": "01:00:00",' +
                        '"horasVooEtapaDecimal": 1.0,' +
                        '"assinaturas": [], "tripulacao": [], "abastecimentos": []' +
                    '}]' +
                '}');
            } else if (endpoint.containsIgnoreCase('/aeronave/abastecimentos')) {
                res.setStatusCode(200);
                res.setBody('{"codigo": 200, "data": []}');
            }
            return res;
        }
    }

    // =========================================================================
    // TESTES
    // =========================================================================
    
    @IsTest
    static void testSincronizarVoosSucesso() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        
        // Garantir que os empregados existem antes do teste
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        Empregado__c operador = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        List<PlaneitAPIService.SincronizarVoosLoteRequest> requests = 
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request };
        
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(requests);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, resultados, 'Resultados nÃ£o devem ser nulos');
        System.assertEquals(1, resultados.size(), 'Deve retornar 1 resposta');
        System.assertEquals(true, resultados[0].sucesso, 'SincronizaÃ§Ã£o deve ter sucesso');
        System.assertEquals(1, resultados[0].totalImportados, 'Deve importar 1 voo');
        
        // Verificar se o voo foi criado no banco
        List<Controle_Horas_Voo__c> voos = [SELECT Id, Id_Voo_Planeit__c, DEP__c, ARR__c, Tipo__c 
                                             FROM Controle_Horas_Voo__c];
        System.assertEquals(1, voos.size(), 'Deve criar 1 registro de voo');
        System.assertEquals(94611, voos[0].Id_Voo_Planeit__c, 'ID Planeit deve ser 94611');
        System.assertEquals('SBRP', voos[0].DEP__c, 'Decolagem deve ser SBRP');
        System.assertEquals('SBPA', voos[0].ARR__c, 'Pouso deve ser SBPA');
        System.assertEquals('SA', voos[0].Tipo__c, 'Tipo deve ser SA');
    }
    
    @IsTest
    static void testSincronizarVoosComAbastecimentos() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        Empregado__c operador = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Deve ter sucesso');
        
        List<Abastecimento__c> abastecimentos = [SELECT Quantidade__c, Custo_Unitario__c, Custo_Total__c, Documento_Referencia__c 
                                                  FROM Abastecimento__c];
        System.assertEquals(1, abastecimentos.size(), 'Deve criar 1 abastecimento');
        System.assertEquals(257.00, abastecimentos[0].Quantidade__c, 'Litros deve ser 257');
        System.assertEquals(13.40, abastecimentos[0].Custo_Unitario__c, 'Valor unitário deve ser 13.40');
        System.assertEquals(3443.80, abastecimentos[0].Custo_Total__c, 'Total deve ser 3443.80');
        System.assertEquals('NF 12345', abastecimentos[0].Documento_Referencia__c, 'Documento deve ser NF 12345');
    }
    
    @IsTest
    static void testRegraTipoControleHoras_SA_Com_Sim() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        Empregado__c operador = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        Controle_Horas_Voo__c voo = [SELECT Tipo__c FROM Controle_Horas_Voo__c LIMIT 1];
        System.assertEquals('SA', voo.Tipo__c, 'Tipo controle deve ser SA (coleta = Sim)');
    }
    
    @IsTest
    static void testRegraTipoControleHoras_SA_Com_Nao() {
        // Arrange - Usar mock especÃ­fico que retorna "NÃ£o" na coleta de dados
        Test.setMock(HttpCalloutMock.class, new VooTentativaMock());
        
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        Empregado__c operador = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        Controle_Horas_Voo__c voo = [SELECT Tipo__c FROM Controle_Horas_Voo__c LIMIT 1];
        System.assertEquals('TT', voo.Tipo__c, 'Tipo controle deve ser TT (Tentativa quando coleta = NÃ£o)');
    }
    
    @IsTest
    static void testAtualizarVooExistente() {
        // Arrange - Criar voo existente
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        Controle_Horas_Voo__c vooExistente = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 94611,
            DEP__c = 'OLD',
            ARR__c = 'OLD'
        );
        insert vooExistente;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, resultados[0].totalImportados, 'NÃ£o deve importar novos');
        System.assertEquals(1, resultados[0].totalAtualizados, 'Deve atualizar 1 voo');
        
        Controle_Horas_Voo__c vooAtualizado = [SELECT DEP__c, ARR__c FROM Controle_Horas_Voo__c WHERE Id = :vooExistente.Id];
        System.assertEquals('SBRP', vooAtualizado.DEP__c, 'DEP deve ser atualizado');
        System.assertEquals('SBPA', vooAtualizado.ARR__c, 'ARR deve ser atualizado');
    }
    
    @IsTest
    static void testErroNaAPI() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, resultados, 'Deve retornar resultado mesmo com erro');
        System.assertEquals(false, resultados[0].sucesso, 'Sucesso deve ser false');
        System.assertNotEquals(null, resultados[0].mensagem, 'Deve ter mensagem de erro');
    }
    
    @IsTest
    static void testRequestVazio() {
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>()
        );
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, resultados, 'Deve retornar lista mesmo vazia');
        System.assertEquals(1, resultados.size(), 'Deve retornar erro de validaÃ§Ã£o');
        System.assertEquals(false, resultados[0].sucesso, 'Deve indicar falha');
        System.assert(resultados[0].mensagem.contains('Nenhuma requisição'), 'Mensagem deve indicar request vazio');
    }
    
    @IsTest
    static void testRequestNull() {
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(null);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, resultados, 'Deve retornar lista mesmo com null');
        System.assertEquals(1, resultados.size(), 'Deve retornar erro de validaÃ§Ã£o');
        System.assertEquals(false, resultados[0].sucesso, 'Deve indicar falha');
    }
    
    @IsTest
    static void testSemAeronaves() {
        // Arrange
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>();
        request.idsAeronavesRecords = new List<String>();
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, resultados[0].sucesso, 'Deve falhar sem aeronaves');
        System.assert(resultados[0].mensagem.contains('Nenhuma aeronave'), 'Mensagem deve indicar falta de aeronaves');
    }
    
    @IsTest
    static void testIdsInconsistentes() {
        // Arrange
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599, 1600 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id }; // SÃ³ 1 ID ao invÃ©s de 2
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, resultados[0].sucesso, 'Deve falhar com IDs inconsistentes');
        System.assert(resultados[0].mensagem.contains('inconsistente'), 'Mensagem deve indicar inconsistÃªncia');
    }
    
    @IsTest
    static void testVoosSemDados() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new EmptyVoosMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Deve ter sucesso mesmo sem voos');
        System.assertEquals(0, resultados[0].totalImportados, 'NÃ£o deve importar nada');
        System.assertEquals(0, resultados[0].totalAtualizados, 'NÃ£o deve atualizar nada');
    }
    
    @IsTest
    static void testCacheToken() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act - Primeira chamada
        Test.startTest();
        List<SincronizarVoosResponse> resultado1 = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert - Deve funcionar (token em cache Ã© usado internamente)
        System.assertEquals(true, resultado1[0].sucesso, 'Primeira chamada deve ter sucesso');
    }
    
    @IsTest
    static void testLimparCacheToken() {
        // Act
        Test.startTest();
        PlaneitAPIService.limparCacheToken();
        Test.stopTest();
        
        // Assert - MÃ©todo deve executar sem erros
        System.assert(true, 'Limpar cache deve executar sem exceÃ§Ãµes');
    }
    
    @IsTest
    static void testMatchingEmpregados() {
        // Arrange - Mock com nome de piloto diferente
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        
        // Garantir que os empregados existem
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        Empregado__c operador = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert - Verificar se fez lookup de empregado
        Controle_Horas_Voo__c voo = [SELECT Piloto__c, Operador__c FROM Controle_Horas_Voo__c LIMIT 1];
        System.assertNotEquals(null, voo.Piloto__c, 'Piloto deve ser encontrado');
        System.assertNotEquals(null, voo.Operador__c, 'Operador deve ser encontrado');
    }
    
    @IsTest
    static void testConversaoTempos() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        Empregado__c operador = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        
        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);
        
        // Act
        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();
        
        // Assert
        Controle_Horas_Voo__c voo = [SELECT Acionamento__c, Corte__c, TOT__c, Horas_Voo__c 
                                      FROM Controle_Horas_Voo__c LIMIT 1];
        System.assertNotEquals(null, voo.Acionamento__c, 'Acionamento deve ser convertido');
        System.assertNotEquals(null, voo.Corte__c, 'Corte deve ser convertido');
        System.assertEquals(2.15, voo.TOT__c, 'TOT deve ser 2.15 (02:15:00)');
        System.assertEquals(2.25, voo.Horas_Voo__c, 'Horas_Voo deve ser 2.25');
    }
    
    // =========================================================================
    // TESTES PARA buscarInspecoes
    // =========================================================================
    
    @IsTest
    static void testBuscarInspecoesSucesso() {
        // Arrange
        PlaneitAPIService.limparCacheToken(); // Limpar cache antes do teste
        Test.setMock(HttpCalloutMock.class, new InspecoesTotaisMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        aeronave.Id_Planeit__c = 1599;
        update aeronave;
        
        // Act
        Test.startTest();
        List<PlaneitAPIService.InspecaoData> inspecoes = PlaneitAPIService.buscarInspecoes(aeronave.Id_Planeit__c);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, inspecoes, 'InspeÃ§Ãµes nÃ£o devem ser nulas');
        System.assertEquals(3, inspecoes.size(), 'Deve retornar 3 inspeÃ§Ãµes');
        System.assertEquals('RevisÃ£o 100hrs', inspecoes[0].nomeInspecao, 'Nome da primeira inspeÃ§Ã£o');
        System.assertEquals('TBO Motor', inspecoes[1].nomeInspecao, 'Nome da segunda inspeÃ§Ã£o');
        System.assertEquals('CVA', inspecoes[2].nomeInspecao, 'Nome da terceira inspeÃ§Ã£o');
    }
    
    @IsTest
    static void testBuscarInspecoesVazio() {
        // Arrange
        PlaneitAPIService.limparCacheToken();
        Test.setMock(HttpCalloutMock.class, new InspecoesEmptyMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        aeronave.Id_Planeit__c = 1599;
        update aeronave;
        
        // Act
        Test.startTest();
        List<PlaneitAPIService.InspecaoData> inspecoes = PlaneitAPIService.buscarInspecoes(aeronave.Id_Planeit__c);
        Test.stopTest();
        
        // Assert - Deve retornar null ou lista vazia quando sem inspeÃ§Ãµes
        System.assert(inspecoes == null || inspecoes.isEmpty(), 'Deve retornar null ou lista vazia');
    }
    
    @IsTest
    static void testBuscarInspecoesErro() {
        // Arrange
        PlaneitAPIService.limparCacheToken();
        Test.setMock(HttpCalloutMock.class, new InspecoesErrorMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        aeronave.Id_Planeit__c = 1599;
        update aeronave;
        
        // Act
        Test.startTest();
        List<PlaneitAPIService.InspecaoData> inspecoes = PlaneitAPIService.buscarInspecoes(aeronave.Id_Planeit__c);
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, inspecoes, 'Deve retornar null em caso de erro');
    }
    
    // =========================================================================
    // TESTES PARA buscarTotais
    // =========================================================================
    
    @IsTest
    static void testBuscarTotaisSucesso() {
        // Arrange
        PlaneitAPIService.limparCacheToken();
        Test.setMock(HttpCalloutMock.class, new InspecoesTotaisMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        aeronave.Id_Planeit__c = 1599;
        update aeronave;
        
        // Act
        Test.startTest();
        PlaneitAPIService.TotaisData totais = PlaneitAPIService.buscarTotais(aeronave.Id_Planeit__c);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, totais, 'Totais nÃ£o devem ser nulos');
        System.assertEquals(1875.50, totais.tempoEmVooDecimalTotal, 'Tempo em voo total');
        System.assertEquals(1850.25, totais.horasVooEtapaDecimalTotal, 'Horas voo etapa total');
        System.assertEquals(2450, totais.numeroPousosTotal, 'NÃºmero de pousos');
    }
    
    @IsTest
    static void testBuscarTotaisVazio() {
        // Arrange
        PlaneitAPIService.limparCacheToken();
        Test.setMock(HttpCalloutMock.class, new InspecoesEmptyMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        aeronave.Id_Planeit__c = 1599;
        update aeronave;
        
        // Act
        Test.startTest();
        PlaneitAPIService.TotaisData totais = PlaneitAPIService.buscarTotais(aeronave.Id_Planeit__c);
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, totais, 'Deve retornar null quando sem dados');
    }
    
    @IsTest
    static void testBuscarTotaisErro() {
        // Arrange
        PlaneitAPIService.limparCacheToken();
        Test.setMock(HttpCalloutMock.class, new InspecoesErrorMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        aeronave.Id_Planeit__c = 1599;
        update aeronave;
        
        // Act
        Test.startTest();
        PlaneitAPIService.TotaisData totais = PlaneitAPIService.buscarTotais(aeronave.Id_Planeit__c);
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, totais, 'Deve retornar null em caso de erro');
    }
    
    @IsTest
    static void testSincronizarVoosComVariosAbastecimentos() {
        // Mock com vÃ¡rios abastecimentos para cobrir mais cÃ³digo
        PlaneitAPIService.limparCacheToken();
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        aeronave.Id_Planeit__c = 1599;
        update aeronave;
        
        PlaneitAPIService.SincronizarVoosLoteRequest loteReq = new PlaneitAPIService.SincronizarVoosLoteRequest();
        loteReq.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        loteReq.idsAeronavesRecords = new List<String>{ aeronave.Id };
        loteReq.dataInicio = Date.today().addDays(-365);
        loteReq.dataFim = Date.today();
        
        // Act
        Test.startTest();
        List<SincronizarVoosResponse> respostas = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ loteReq }
        );
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, respostas, 'Deve retornar respostas');
        System.assertEquals(true, respostas[0].sucesso, 'Deve sincronizar com sucesso');
    }

    @IsTest
    static void testSincronizarVooPrivado() {
        Test.setMock(HttpCalloutMock.class, new VooPrivadoMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1602 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        Assert.isTrue(resultados[0].sucesso, 'A categoria PV deve ser aceita pela sincronização.');
        Controle_Horas_Voo__c vooPrivado = [
            SELECT Tipo__c, Data_do_Voo__c, DEP__c, ARR__c
            FROM Controle_Horas_Voo__c
            WHERE Id_Voo_Planeit__c = 197049
        ];
        Assert.areEqual('PV', vooPrivado.Tipo__c);
        Assert.areEqual(Date.newInstance(2025, 10, 22), vooPrivado.Data_do_Voo__c);
        Assert.areEqual('SNAX', vooPrivado.DEP__c);
        Assert.areEqual('SSCP', vooPrivado.ARR__c);
    }

    // =========================================================================
    // TESTES DE PROTEÇÃO CONTRA SOBRESCRITA (EDIÇÃO MANUAL OU FATURAMENTO)
    // =========================================================================

    /**
     * Voo com Editado_Manualmente__c = true não deve ser sobrescrito pela sync
     */
    @IsTest
    static void testVooEditadoManualmenteNaoEAtualizado() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());

        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        // Voo existente com flag ativado e dados diferentes dos que virarão da API
        Controle_Horas_Voo__c vooProtegido = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 94611,
            DEP__c = 'CORR',
            ARR__c = 'MANU',
            Editado_Manualmente__c = true
        );
        insert vooProtegido;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert: registro protegido não deve ter sido sobrescrito
        Controle_Horas_Voo__c vooAposSync = [SELECT DEP__c, ARR__c, Editado_Manualmente__c FROM Controle_Horas_Voo__c WHERE Id = :vooProtegido.Id];
        System.assertEquals('CORR', vooAposSync.DEP__c, 'DEP não deve ser sobrescrito pela sync');
        System.assertEquals('MANU', vooAposSync.ARR__c, 'ARR não deve ser sobrescrito pela sync');
        System.assertEquals(true, vooAposSync.Editado_Manualmente__c, 'Flag deve permanecer ativo');
    }

    /**
     * Voo com Editado_Manualmente__c = true que sumiu do Planeit não deve ser deletado
     */
    @IsTest
    static void testVooEditadoManualmenteNaoEDeletado() {
        // Arrange: Mock que não retorna o voo 94611 (simula deleção no Planeit)
        Test.setMock(HttpCalloutMock.class, new EmptyVoosMock());

        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        Controle_Horas_Voo__c vooProtegido = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 94611,
            Data_do_Voo__c = Date.newInstance(2025, 10, 21),
            DEP__c = 'CORR',
            Editado_Manualmente__c = true
        );
        insert vooProtegido;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert: registro protegido não deve ter sido deletado
        List<Controle_Horas_Voo__c> voosRestantes = [
            SELECT Id FROM Controle_Horas_Voo__c WHERE Id = :vooProtegido.Id
        ];
        System.assertEquals(1, voosRestantes.size(), 'Voo editado manualmente não deve ser deletado pelo sync');
    }

    /**
     * Abastecimento com Editado_Manualmente__c = true não deve ser sobrescrito
     * quando o voo pai não está protegido
     */
    @IsTest
    static void testAbastecimentoEditadoManualmenteNaoEAtualizado() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());

        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        // Voo existente SEM proteção (pode ser atualizado)
        Controle_Horas_Voo__c voo = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 94611,
            DEP__c = 'OLD',
            Editado_Manualmente__c = false
        );
        insert voo;

        // Abastecimento existente COM proteção
        Abastecimento__c abProtegido = new Abastecimento__c(
            Voo__c = voo.Id,
            Id_Abastecimento_Planeit__c = 24747,
            Quantidade__c = 999,
            Custo_Unitario__c = 99,
            Editado_Manualmente__c = true
        );
        insert abProtegido;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert: abastecimento protegido não deve ter sido sobrescrito
        Abastecimento__c abAposSync = [SELECT Quantidade__c, Editado_Manualmente__c FROM Abastecimento__c WHERE Id = :abProtegido.Id];
        System.assertEquals(999, abAposSync.Quantidade__c, 'Quantidade do abastecimento não deve ser sobrescrita');
        System.assertEquals(true, abAposSync.Editado_Manualmente__c, 'Flag do abastecimento deve permanecer ativo');
    }

    @IsTest
    static void testVooFaturadoNaoEAtualizado() {
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        Controle_Horas_Voo__c vooProtegido = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 94611,
            DEP__c = 'USER',
            ARR__c = 'DATA',
            Faturado__c = true
        );
        insert vooProtegido;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        Controle_Horas_Voo__c vooAposSync = [
            SELECT DEP__c, ARR__c, Faturado__c
            FROM Controle_Horas_Voo__c
            WHERE Id = :vooProtegido.Id
        ];
        Assert.areEqual('USER', vooAposSync.DEP__c);
        Assert.areEqual('DATA', vooAposSync.ARR__c);
        Assert.isTrue(vooAposSync.Faturado__c);
    }

    @IsTest
    static void testVooFaturadoNaoEDeletado() {
        Test.setMock(HttpCalloutMock.class, new EmptyVoosMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        Controle_Horas_Voo__c vooProtegido = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 94611,
            Data_do_Voo__c = Date.newInstance(2025, 10, 21),
            Faturado__c = true
        );
        insert vooProtegido;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Controle_Horas_Voo__c WHERE Id = :vooProtegido.Id],
            'Um voo faturado não pode ser excluído pela sincronização.'
        );
    }

    @IsTest
    static void testAbastecimentoFaturadoNaoEAtualizado() {
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        Controle_Horas_Voo__c voo = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 94611
        );
        insert voo;
        Abastecimento__c abastecimentoProtegido = new Abastecimento__c(
            Voo__c = voo.Id,
            Id_Abastecimento_Planeit__c = 24747,
            Quantidade__c = 999,
            Faturado__c = true
        );
        insert abastecimentoProtegido;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        Abastecimento__c abastecimentoAposSync = [
            SELECT Quantidade__c, Faturado__c
            FROM Abastecimento__c
            WHERE Id = :abastecimentoProtegido.Id
        ];
        Assert.areEqual(Decimal.valueOf('999'), abastecimentoAposSync.Quantidade__c);
        Assert.isTrue(abastecimentoAposSync.Faturado__c);
    }

    @IsTest
    static void testVooComAbastecimentoFaturadoNaoEDeletado() {
        Test.setMock(HttpCalloutMock.class, new EmptyVoosMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        Controle_Horas_Voo__c voo = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 94611,
            Data_do_Voo__c = Date.newInstance(2025, 10, 21)
        );
        insert voo;
        insert new Abastecimento__c(
            Voo__c = voo.Id,
            Id_Abastecimento_Planeit__c = 24747,
            Faturado__c = true
        );

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Controle_Horas_Voo__c WHERE Id = :voo.Id],
            'O pai deve ser preservado para impedir exclusão em cascata do abastecimento faturado.'
        );
    }

    @IsTest
    static void testAbastecimentoDeVooFaturadoNaoEDeletado() {
        Test.setMock(HttpCalloutMock.class, new VooPrivadoMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;
        Controle_Horas_Voo__c vooFaturado = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 197049,
            Data_do_Voo__c = Date.newInstance(2025, 10, 22),
            Tipo__c = 'PV',
            Faturado__c = true
        );
        insert vooFaturado;
        Abastecimento__c abastecimento = new Abastecimento__c(
            Voo__c = vooFaturado.Id,
            Id_Abastecimento_Planeit__c = 99999
        );
        insert abastecimento;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1602 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        Assert.areEqual(
            1,
            [SELECT COUNT() FROM Abastecimento__c WHERE Id = :abastecimento.Id],
            'Os abastecimentos de um voo faturado também devem ser preservados.'
        );
    }

    // =========================================================================
    // TESTES PARA ABASTECIMENTOS AVULSOS (SEM VOO) - /aeronave/abastecimentos
    // =========================================================================

    /**
     * Um abastecimento avulso (idVoo nulo) deve virar um placeholder Controle_Horas_Voo__c
     * (Tipo__c='AB') + seu Abastecimento__c filho. O abastecimento vinculado a um voo que
     * vem na mesma resposta (idVoo preenchido) não deve ser processado por este fluxo.
     */
    @IsTest
    static void testSincronizarCriaAbastecimentoAvulso() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new AbastecimentosAvulsosMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Deve sincronizar com sucesso');

        List<Controle_Horas_Voo__c> placeholders = [
            SELECT Id, Id_Voo_Planeit__c FROM Controle_Horas_Voo__c WHERE Tipo__c = 'AB'
        ];
        System.assertEquals(1, placeholders.size(), 'Deve criar 1 placeholder AB para o abastecimento avulso');
        System.assertEquals(null, placeholders[0].Id_Voo_Planeit__c, 'Placeholder não tem voo Planeit associado');

        List<Abastecimento__c> abastecimentos = [
            SELECT Voo__c, Quantidade__c, Custo_Unitario__c, Custo_Total__c, Local__c
            FROM Abastecimento__c
            WHERE Id_Abastecimento_Planeit__c = 39760
        ];
        System.assertEquals(1, abastecimentos.size(), 'Deve criar o abastecimento avulso');
        System.assertEquals(placeholders[0].Id, abastecimentos[0].Voo__c, 'Abastecimento deve apontar para o placeholder');
        System.assertEquals(999.00, abastecimentos[0].Quantidade__c, 'Quantidade deve ser convertida da string da API');
        System.assertEquals(1.00, abastecimentos[0].Custo_Unitario__c, 'Custo unitário deve ser convertido da string da API');
        System.assertEquals(999.00, abastecimentos[0].Custo_Total__c, 'Custo total deve ser convertido da string da API');
        System.assertEquals('SNAX', abastecimentos[0].Local__c, 'Local deve ser SNAX');

        List<Abastecimento__c> abastecimentoVinculado = [
            SELECT Id FROM Abastecimento__c WHERE Id_Abastecimento_Planeit__c = 28636
        ];
        System.assertEquals(0, abastecimentoVinculado.size(),
            'Abastecimento com idVoo preenchido não deve ser criado por este fluxo (tratado via /voos)');
    }

    /**
     * Sincronizar um avulso que já existe no SF (criado em um ciclo anterior) não deve
     * duplicar o placeholder nem o abastecimento - apenas atualiza os dados.
     * Segue o mesmo padrão de testAtualizarVooExistente: o estado "já sincronizado
     * anteriormente" é simulado inserindo o registro antes da chamada, pois uma segunda
     * chamada real ao método na mesma transação violaria a regra "callout após DML
     * pendente" (a arquitetura do método já assume que cada ciclo de sync é uma transação
     * própria, como acontece em produção via PlaneitAircraftSyncQueueable).
     */
    @IsTest
    static void testSincronizarAtualizaAbastecimentoAvulsoExistente() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new AbastecimentosAvulsosMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        Controle_Horas_Voo__c placeholderExistente = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Tipo__c = 'AB',
            TOT__c = 0,
            Horas_Voo__c = 0,
            Data_do_Voo__c = Date.newInstance(2025, 10, 15)
        );
        insert placeholderExistente;

        Abastecimento__c abExistente = new Abastecimento__c(
            Voo__c = placeholderExistente.Id,
            Id_Abastecimento_Planeit__c = 39760,
            Data_Voo__c = Date.newInstance(2025, 10, 15),
            Quantidade__c = 1,
            Custo_Unitario__c = 1,
            Custo_Total__c = 1,
            Local__c = 'ANTIGO'
        );
        insert abExistente;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Deve sincronizar com sucesso');
        System.assertEquals(1, resultados[0].totalAbastecimentosAtualizados, 'Deve apenas atualizar o abastecimento avulso existente');

        List<Controle_Horas_Voo__c> placeholders = [SELECT Id FROM Controle_Horas_Voo__c WHERE Tipo__c = 'AB'];
        System.assertEquals(1, placeholders.size(), 'Não deve duplicar o placeholder AB');
        System.assertEquals(placeholderExistente.Id, placeholders[0].Id, 'Deve reutilizar o placeholder existente');

        List<Abastecimento__c> abastecimentos = [
            SELECT Id, Quantidade__c, Local__c FROM Abastecimento__c WHERE Id_Abastecimento_Planeit__c = 39760
        ];
        System.assertEquals(1, abastecimentos.size(), 'Não deve duplicar o abastecimento avulso');
        System.assertEquals(abExistente.Id, abastecimentos[0].Id, 'Deve reutilizar o abastecimento existente');
        System.assertEquals(999.00, abastecimentos[0].Quantidade__c, 'Quantidade deve ser atualizada com o valor da API');
        System.assertEquals('SNAX', abastecimentos[0].Local__c, 'Local deve ser atualizado com o valor da API');
    }

    /**
     * Sem proteção manual, o par (abastecimento + placeholder) que sumiu do Planeit
     * deve ser excluído.
     */
    @IsTest
    static void testSincronizarExcluiAbastecimentoAvulsoOrfaoSemProtecao() {
        // Arrange: avulso já sincronizado anteriormente, sem proteção manual
        Test.setMock(HttpCalloutMock.class, new AbastecimentosAvulsosVazioMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        Controle_Horas_Voo__c placeholderOrfao = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Tipo__c = 'AB',
            TOT__c = 0,
            Horas_Voo__c = 0,
            Data_do_Voo__c = Date.newInstance(2025, 10, 15)
        );
        insert placeholderOrfao;

        Abastecimento__c abOrfao = new Abastecimento__c(
            Voo__c = placeholderOrfao.Id,
            Id_Abastecimento_Planeit__c = 39760,
            Data_Voo__c = Date.newInstance(2025, 10, 15),
            Quantidade__c = 999,
            Custo_Unitario__c = 1,
            Custo_Total__c = 999
        );
        insert abOrfao;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act: sync roda com resposta 200 vazia do endpoint de abastecimentos (avulso sumiu do Planeit)
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Deve sincronizar com sucesso mesmo sem o avulso');

        List<Abastecimento__c> abastecimentosRestantes = [
            SELECT Id FROM Abastecimento__c WHERE Id_Abastecimento_Planeit__c = 39760
        ];
        System.assertEquals(0, abastecimentosRestantes.size(), 'Abastecimento avulso órfão deve ser excluído');

        List<Controle_Horas_Voo__c> placeholdersRestantes = [
            SELECT Id FROM Controle_Horas_Voo__c WHERE Id = :placeholderOrfao.Id
        ];
        System.assertEquals(0, placeholdersRestantes.size(), 'Placeholder órfão deve ser excluído junto com o abastecimento');
    }

    /**
     * Com Editado_Manualmente__c = true, o par (abastecimento + placeholder) deve ser
     * preservado mesmo que o avulso tenha sumido do Planeit.
     */
    @IsTest
    static void testSincronizarPreservaAbastecimentoAvulsoProtegido() {
        // Arrange: avulso já sincronizado anteriormente, protegido por edição manual
        Test.setMock(HttpCalloutMock.class, new AbastecimentosAvulsosVazioMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        Controle_Horas_Voo__c placeholderProtegido = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Tipo__c = 'AB',
            TOT__c = 0,
            Horas_Voo__c = 0,
            Data_do_Voo__c = Date.newInstance(2025, 10, 15)
        );
        insert placeholderProtegido;

        Abastecimento__c abProtegido = new Abastecimento__c(
            Voo__c = placeholderProtegido.Id,
            Id_Abastecimento_Planeit__c = 39760,
            Data_Voo__c = Date.newInstance(2025, 10, 15),
            Quantidade__c = 999,
            Custo_Unitario__c = 1,
            Custo_Total__c = 999,
            Editado_Manualmente__c = true
        );
        insert abProtegido;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Deve sincronizar com sucesso mesmo sem o avulso');

        List<Abastecimento__c> abastecimentosRestantes = [
            SELECT Id FROM Abastecimento__c WHERE Id_Abastecimento_Planeit__c = 39760
        ];
        System.assertEquals(1, abastecimentosRestantes.size(), 'Abastecimento avulso protegido não deve ser excluído');

        List<Controle_Horas_Voo__c> placeholdersRestantes = [
            SELECT Id FROM Controle_Horas_Voo__c WHERE Id = :placeholderProtegido.Id
        ];
        System.assertEquals(1, placeholdersRestantes.size(), 'Placeholder do abastecimento protegido não deve ser excluído');
    }

    /**
     * Uma falha (não-200) ao consultar /aeronave/abastecimentos não deve derrubar a
     * sincronização de voos e, principalmente, não deve ser interpretada como "o avulso
     * sumiu do Planeit" - avulsos já sincronizados devem ser preservados nesse ciclo
     * (fail-safe: sem uma leitura confiável do Planeit, nada é excluído).
     */
    @IsTest
    static void testFalhaAoBuscarAvulsosNaoExcluiExistentes() {
        // Arrange: avulso já sincronizado anteriormente; mock não trata /aeronave/abastecimentos
        // (resposta sem status 200), simulando uma falha transitória de callout
        Test.setMock(HttpCalloutMock.class, new EmptyVoosMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        Controle_Horas_Voo__c placeholderExistente = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Tipo__c = 'AB',
            TOT__c = 0,
            Horas_Voo__c = 0,
            Data_do_Voo__c = Date.newInstance(2025, 10, 15)
        );
        insert placeholderExistente;

        Abastecimento__c abExistente = new Abastecimento__c(
            Voo__c = placeholderExistente.Id,
            Id_Abastecimento_Planeit__c = 39760,
            Data_Voo__c = Date.newInstance(2025, 10, 15),
            Quantidade__c = 999,
            Custo_Unitario__c = 1,
            Custo_Total__c = 999
        );
        insert abExistente;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Sync de voos deve ter sucesso mesmo com falha ao buscar avulsos');

        List<Abastecimento__c> abastecimentosRestantes = [
            SELECT Id FROM Abastecimento__c WHERE Id_Abastecimento_Planeit__c = 39760
        ];
        System.assertEquals(1, abastecimentosRestantes.size(),
            'Avulso não deve ser excluído quando a busca de avulsos falhar (fail-safe)');

        List<Controle_Horas_Voo__c> placeholdersRestantes = [
            SELECT Id FROM Controle_Horas_Voo__c WHERE Id = :placeholderExistente.Id
        ];
        System.assertEquals(1, placeholdersRestantes.size(),
            'Placeholder não deve ser excluído quando a busca de avulsos falhar (fail-safe)');
    }

    // =========================================================================
    // TESTES PARA PILOTO/OPERADOR EXTERNO (sem Empregado__c correspondente)
    // =========================================================================

    /**
     * Quando o nome do piloto/operador não corresponde a nenhum Empregado__c, o voo
     * deve ser sincronizado com Piloto__c/Operador__c nulos, mas com o nome cru
     * preservado em Piloto_Externo__c/Operador_Externo__c.
     */
    @IsTest
    static void testSincronizarCapturaPilotoOperadorExterno() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new PilotoOperadorExternoMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Deve sincronizar com sucesso');

        Controle_Horas_Voo__c voo = [
            SELECT Piloto__c, Piloto_Externo__c, Operador__c, Operador_Externo__c
            FROM Controle_Horas_Voo__c
            WHERE Id_Voo_Planeit__c = 94611
        ];
        System.assertEquals(null, voo.Piloto__c, 'Piloto não deve corresponder a nenhum empregado');
        System.assertEquals('Carlos Andrade Voador', voo.Piloto_Externo__c, 'Nome do piloto externo deve ser preservado');
        System.assertEquals(null, voo.Operador__c, 'Operador não deve corresponder a nenhum empregado');
        System.assertEquals('Fulano Terceirizado Externo', voo.Operador_Externo__c, 'Nome do operador externo deve ser preservado');
    }

    /**
     * Se a pessoa antes externa passar a existir como Empregado__c (nome batendo), um
     * novo ciclo de sincronização deve vincular o Empregado__c e limpar a tag de externo.
     * Simula o estado "já sincronizado como externo" via inserção direta (mesmo padrão de
     * testAtualizarVooExistente), pois duas chamadas reais na mesma transação violariam a
     * regra de callout após DML pendente.
     */
    @IsTest
    static void testSincronizarLimpaTagExternoQuandoEmpregadoPassaAExistir() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new PilotoOperadorExternoMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        Controle_Horas_Voo__c vooExistente = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Id_Voo_Planeit__c = 94611,
            Piloto_Externo__c = 'Carlos Andrade Voador',
            Operador_Externo__c = 'Fulano Terceirizado Externo'
        );
        insert vooExistente;

        // Empregados agora cadastrados com os mesmos nomes que antes eram externos
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        piloto.Name = 'Carlos Andrade Voador';
        update piloto;

        Empregado__c operador = TestDataStatic.empregadoOpEquipEsp;
        operador.Name = 'Fulano Terceirizado Externo';
        update operador;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Deve sincronizar com sucesso');

        Controle_Horas_Voo__c vooAtualizado = [
            SELECT Piloto__c, Piloto_Externo__c, Operador__c, Operador_Externo__c
            FROM Controle_Horas_Voo__c
            WHERE Id = :vooExistente.Id
        ];
        System.assertEquals(piloto.Id, vooAtualizado.Piloto__c, 'Piloto deve ser vinculado ao empregado agora cadastrado');
        System.assertEquals(null, vooAtualizado.Piloto_Externo__c, 'Tag de piloto externo deve ser limpa após o match');
        System.assertEquals(operador.Id, vooAtualizado.Operador__c, 'Operador deve ser vinculado ao empregado agora cadastrado');
        System.assertEquals(null, vooAtualizado.Operador_Externo__c, 'Tag de operador externo deve ser limpa após o match');
    }

    /**
     * A lista "Operador:" do PlaneIT tem valores sentinela que não são nomes de pessoas:
     * "N/A" (voo sem operador) e "Outro - Especificar em Extras" (nome real vai no campo
     * livre "Extras" = campoCustomizado4). Nenhum dos dois pode virar nome de operador.
     */
    @IsTest
    static void testResolveOperadorAPartirDosCamposCustomizados() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new OperadorCamposCustomizadosMock());
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        List<SincronizarVoosResponse> resultados = PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert
        System.assertEquals(true, resultados[0].sucesso, 'Deve sincronizar com sucesso');

        Map<Decimal, Controle_Horas_Voo__c> voosPorIdPlaneit = new Map<Decimal, Controle_Horas_Voo__c>();
        for (Controle_Horas_Voo__c voo : [
            SELECT Id_Voo_Planeit__c, Operador__c, Operador_Externo__c
            FROM Controle_Horas_Voo__c
            WHERE Id_Voo_Planeit__c IN (90001, 90002, 90003)
        ]) {
            voosPorIdPlaneit.put(voo.Id_Voo_Planeit__c, voo);
        }
        System.assertEquals(3, voosPorIdPlaneit.size(), 'Os 3 voos devem ser sincronizados');

        // "Outro - Especificar em Extras" -> nome real vem do campo "Extras"
        Controle_Horas_Voo__c vooComExtras = voosPorIdPlaneit.get(90001);
        System.assertEquals(null, vooComExtras.Operador__c, 'Gonzalo não é empregado cadastrado');
        System.assertEquals('Gonzalo', vooComExtras.Operador_Externo__c,
            'O nome do operador deve vir do campo "Extras", não do texto da lista de seleção');

        // "N/A" -> voo sem operador, não é nome de pessoa
        Controle_Horas_Voo__c vooSemOperador = voosPorIdPlaneit.get(90002);
        System.assertEquals(null, vooSemOperador.Operador__c, 'Voo N/A não deve ter operador');
        System.assertEquals(null, vooSemOperador.Operador_Externo__c,
            '"N/A" não pode ser gravado como nome de operador externo');

        // "Outro - Especificar em Extras" sem preencher "Extras" -> nada a exibir
        Controle_Horas_Voo__c vooExtrasVazio = voosPorIdPlaneit.get(90003);
        System.assertEquals(null, vooExtrasVazio.Operador__c, 'Sem "Extras" preenchido não há operador');
        System.assertEquals(null, vooExtrasVazio.Operador_Externo__c,
            '"Outro - Especificar em Extras" não pode ser gravado como nome de operador externo');
    }

    /**
     * Quando o valor da lista "Operador:" é o nome de um empregado cadastrado, o vínculo
     * normal (lookup) deve continuar funcionando - o campo "Extras" não interfere.
     */
    @IsTest
    static void testOperadorInternoContinuaSendoVinculado() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new MultiEndpointMock());
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        Empregado__c operador = TestDataStatic.empregadoOpEquipEsp;
        Aeronave__c aeronave = TestDataStatic.aeronaveTeste;

        PlaneitAPIService.SincronizarVoosLoteRequest request = new PlaneitAPIService.SincronizarVoosLoteRequest();
        request.idsAeronavesPlaneit = new List<Decimal>{ 1599 };
        request.idsAeronavesRecords = new List<String>{ aeronave.Id };
        request.dataInicio = Date.newInstance(2025, 10, 1);
        request.dataFim = Date.newInstance(2025, 10, 31);

        // Act
        Test.startTest();
        PlaneitAPIService.sincronizarVoosDoPlaneit(
            new List<PlaneitAPIService.SincronizarVoosLoteRequest>{ request }
        );
        Test.stopTest();

        // Assert
        Controle_Horas_Voo__c voo = [
            SELECT Operador__c, Operador_Externo__c
            FROM Controle_Horas_Voo__c
            WHERE Id_Voo_Planeit__c = 94611
        ];
        System.assertEquals(operador.Id, voo.Operador__c, 'Operador interno deve continuar sendo vinculado');
        System.assertEquals(null, voo.Operador_Externo__c, 'Operador interno não deve receber tag de externo');
    }
}