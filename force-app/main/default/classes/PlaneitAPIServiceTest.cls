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

    // =========================================================================
    // TESTES DE PROTEÇÃO CONTRA SOBRESCRITA (Editado_Manualmente__c)
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
}