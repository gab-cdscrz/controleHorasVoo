/**
 * @description Classe de teste para InspecaoAeronaveService
 * @author Gabriel Cardoso
 * @date 2026-01-19
 */
@isTest
private class InspecaoAeronaveServiceTest {
    
    /**
     * @description Cria dados de teste
     */
    @TestSetup
    static void setupTestData() {
        // Criar aeronave de teste com Id_Planeit__c
        Aeronave__c aeronave = new Aeronave__c(
            Name = 'PT-TST',
            Modelo__c = 'EMB-810C',
            Fabricante__c = 'EMBRAER',
            Ano_de_Fabricacao__c = 1982,
            Ativo__c = true,
            Horas_Totais_de_Voo__c = 2450.0,
            Id_Planeit__c = 1599
        );
        insert aeronave;
    }
    
    /**
     * @description Mock para simular resposta da API de inspeções
     */
    private class InspecoesMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String endpoint = req.getEndpoint();
            System.debug('### Mock endpoint: ' + endpoint);
            
            // Mock de login
            if (endpoint.contains('login')) {
                res.setBody('{"codigo":200,"mensagem":"OK","data":{"access_token":"mock_token","token_type":"Bearer"}}');
                res.setStatusCode(200);
            }
            // Mock de inspeções
            else if (endpoint.contains('inspecoes')) {
                String jsonResponse = '{' +
                    '"codigo": 200,' +
                    '"mensagem": "Inspeções encontradas",' +
                    '"metodo": "GET",' +
                    '"data": [' +
                        '{' +
                            '"idInspecao": 3057,' +
                            '"idAeronave": 1599,' +
                            '"nomeInspecao": "100hrs",' +
                            '"inicioHoras": "2500",' +
                            '"situacaoInspecao": "A",' +
                            '"detalheUltimaExecucao": [{' +
                                '"idExecucaoInspecao": 1,' +
                                '"dataExecucao": "2025-12-30",' +
                                '"horasExecucao": "2400",' +
                                '"dataProxima": "2026-03-07",' +
                                '"horasProxima": "2500",' +
                                '"responsavelExecucao": "FLIGHT CORNÉNIO"' +
                            '}]' +
                        '},' +
                        '{' +
                            '"idInspecao": 3058,' +
                            '"idAeronave": 1599,' +
                            '"nomeInspecao": "CVA",' +
                            '"situacaoInspecao": "A",' +
                            '"detalheUltimaExecucao": [{' +
                                '"dataExecucao": "2025-05-22",' +
                                '"dataProxima": "2026-05-22",' +
                                '"responsavelExecucao": "ANAC"' +
                            '}]' +
                        '},' +
                        '{' +
                            '"idInspecao": 3059,' +
                            '"idAeronave": 1599,' +
                            '"nomeInspecao": "200hrs",' +
                            '"inicioHoras": "2600",' +
                            '"situacaoInspecao": "A",' +
                            '"detalheUltimaExecucao": [{' +
                                '"horasProxima": "2600",' +
                                '"responsavelExecucao": "FLIGHT CORNÉNIO"' +
                            '}]' +
                        '}' +
                    ']' +
                '}';
                res.setBody(jsonResponse);
                res.setStatusCode(200);
            }
            // Mock de totais
            else if (endpoint.contains('totais')) {
                res.setBody('{"codigo":200,"mensagem":"OK","data":{"horasVooEtapaDecimalTotal":2500.5}}');
                res.setStatusCode(200);
            }
            else {
                System.debug('### Mock endpoint não reconhecido: ' + endpoint);
                res.setStatusCode(404);
            }
            
            return res;
        }
    }
    
    /**
     * @description Mock para simular TBO vencida (não retorna TBO)
     */
    private class TBOVencidaMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String endpoint = req.getEndpoint();
            
            if (endpoint.contains('login')) {
                res.setBody('{"codigo":200,"mensagem":"OK","data":{"access_token":"mock_token","token_type":"Bearer"}}');
                res.setStatusCode(200);
            }
            else if (endpoint.contains('inspecoes')) {
                // Retorna inspeções SEM TBO (TBO vencida)
                String jsonResponse = '{' +
                    '"codigo": 200,' +
                    '"mensagem": "OK",' +
                    '"data": [' +
                        '{' +
                            '"idInspecao": 3060,' +
                            '"idAeronave": 1599,' +
                            '"nomeInspecao": "50hrs",' +
                            '"inicioHoras": "2550",' +
                            '"situacaoInspecao": "A",' +
                            '"detalheUltimaExecucao": []' +
                        '}' +
                    ']' +
                '}';
                res.setBody(jsonResponse);
                res.setStatusCode(200);
            }
            else if (endpoint.contains('totais')) {
                res.setBody('{"codigo":200,"mensagem":"OK","data":{"horasVooEtapaDecimalTotal":2500}}');
                res.setStatusCode(200);
            }
            else {
                res.setStatusCode(404);
            }
            
            return res;
        }
    }
    
    /**
     * @description Mock para simular inspeção inativa (situacaoInspecao = 'I')
     */
    private class InspecaoInativaMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String endpoint = req.getEndpoint();
            
            if (endpoint.contains('login')) {
                res.setBody('{"codigo":200,"mensagem":"OK","data":{"access_token":"mock_token","token_type":"Bearer"}}');
                res.setStatusCode(200);
            }
            else if (endpoint.contains('inspecoes')) {
                // Retorna inspeção INATIVA (situacaoInspecao = 'I')
                String jsonResponse = '{' +
                    '"codigo": 200,' +
                    '"mensagem": "OK",' +
                    '"data": [' +
                        '{' +
                            '"idInspecao": 9999,' +
                            '"idAeronave": 1599,' +
                            '"nomeInspecao": "ANTIGA",' +
                            '"situacaoInspecao": "I",' +
                            '"detalheUltimaExecucao": []' +
                        '},' +
                        '{' +
                            '"idInspecao": 3061,' +
                            '"idAeronave": 1599,' +
                            '"nomeInspecao": "TBO",' +
                            '"inicioHoras": "3000",' +
                            '"situacaoInspecao": "A",' +
                            '"detalheUltimaExecucao": [{' +
                                '"horasProxima": "3000"' +
                            '}]' +
                        '}' +
                    ']' +
                '}';
                res.setBody(jsonResponse);
                res.setStatusCode(200);
            }
            else if (endpoint.contains('totais')) {
                res.setBody('{"codigo":200,"mensagem":"OK","data":{"horasVooEtapaDecimalTotal":2500}}');
                res.setStatusCode(200);
            }
            else {
                res.setStatusCode(404);
            }
            
            return res;
        }
    }
    
    /**
     * @description Testa sincronização bem-sucedida de inspeções
     */
    @isTest
    static void testSincronizarInspecoesAeronave() {
        Aeronave__c aeronave = [SELECT Id, Id_Planeit__c FROM Aeronave__c LIMIT 1];
        System.debug('Aeronave ID: ' + aeronave.Id + ', Id_Planeit: ' + aeronave.Id_Planeit__c);
        
        Test.setMock(HttpCalloutMock.class, new InspecoesMock());
        
        Test.startTest();
        InspecaoAeronaveService.ResultadoSincronizacao resultado = 
            InspecaoAeronaveService.sincronizarInspecoesAeronave(aeronave.Id);
        Test.stopTest();
        
        System.debug('### Resultado sucesso: ' + resultado.sucesso);
        System.debug('### Resultado mensagem: ' + resultado.mensagem);
        System.debug('### Total inseridos: ' + resultado.totalInseridos);
        System.debug('### Total atualizados: ' + resultado.totalAtualizados);
        
        System.assertEquals(true, resultado.sucesso, 'Sincronização deveria ter sucesso. Mensagem: ' + resultado.mensagem);
        System.assert(resultado.totalInseridos > 0, 'Deveria ter inserido inspeções');
        
        // Verificar registros criados
        List<Inspecao_Aeronave__c> inspecoes = [
            SELECT Id, Nome_Inspecao__c, Ativa__c, Status_Inspecao__c
            FROM Inspecao_Aeronave__c
            WHERE Aeronave__c = :aeronave.Id
        ];
        
        System.debug('### Inspeções criadas: ' + inspecoes.size());
        System.assert(!inspecoes.isEmpty(), 'Deveria ter criado inspeções');
    }
    
    /**
     * @description Testa atualização de inspeções existentes
     */
    @isTest
    static void testAtualizarInspecoesExistentes() {
        Aeronave__c aeronave = [SELECT Id FROM Aeronave__c LIMIT 1];
        
        // Criar inspeção existente com Chave_Unica__c
        Inspecao_Aeronave__c inspecaoExistente = new Inspecao_Aeronave__c();
        inspecaoExistente.Aeronave__c = aeronave.Id;
        inspecaoExistente.Chave_Unica__c = '1599_100hrs';
        inspecaoExistente.Id_Inspecao_Planeit__c = '3057';
        inspecaoExistente.Id_Aeronave_Planeit__c = '1599';
        inspecaoExistente.Nome_Inspecao__c = '100hrs';
        inspecaoExistente.Ativa__c = true;
        insert inspecaoExistente;
        
        Test.setMock(HttpCalloutMock.class, new InspecoesMock());
        
        Test.startTest();
        InspecaoAeronaveService.ResultadoSincronizacao resultado = 
            InspecaoAeronaveService.sincronizarInspecoesAeronave(aeronave.Id);
        Test.stopTest();
        
        System.assertEquals(true, resultado.sucesso, 'Sincronização deveria ter sucesso');
        System.assert(resultado.totalAtualizados > 0, 'Deveria ter atualizado inspeção existente');
    }
    
    /**
     * @description Testa arquivamento de inspeção inativa
     */
    @isTest
    static void testInspecaoInativaArquivada() {
        Aeronave__c aeronave = [SELECT Id FROM Aeronave__c LIMIT 1];
        
        // Criar inspeção existente que será arquivada
        Inspecao_Aeronave__c inspecaoExistente = new Inspecao_Aeronave__c();
        inspecaoExistente.Aeronave__c = aeronave.Id;
        inspecaoExistente.Chave_Unica__c = '1599_ANTIGA';
        inspecaoExistente.Id_Inspecao_Planeit__c = '9999';
        inspecaoExistente.Id_Aeronave_Planeit__c = '1599';
        inspecaoExistente.Nome_Inspecao__c = 'ANTIGA';
        inspecaoExistente.Ativa__c = true;
        insert inspecaoExistente;
        
        Test.setMock(HttpCalloutMock.class, new InspecaoInativaMock());
        
        Test.startTest();
        InspecaoAeronaveService.ResultadoSincronizacao resultado = 
            InspecaoAeronaveService.sincronizarInspecoesAeronave(aeronave.Id);
        Test.stopTest();
        
        System.assertEquals(true, resultado.sucesso, 'Sincronização deveria ter sucesso');
        
        // Verificar se inspeção foi arquivada
        Inspecao_Aeronave__c inspecaoArquivada = [
            SELECT Id, Ativa__c, Status_Inspecao__c
            FROM Inspecao_Aeronave__c
            WHERE Chave_Unica__c = '1599_ANTIGA'
        ];
        
        System.assertEquals(false, inspecaoArquivada.Ativa__c, 'Inspeção deveria estar inativa');
    }
    
    /**
     * @description Testa TBO vencida (não retorna na API)
     */
    @isTest
    static void testTBOVencida() {
        Aeronave__c aeronave = [SELECT Id FROM Aeronave__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new TBOVencidaMock());
        
        Test.startTest();
        InspecaoAeronaveService.ResultadoSincronizacao resultado = 
            InspecaoAeronaveService.sincronizarInspecoesAeronave(aeronave.Id);
        Test.stopTest();
        
        System.assertEquals(true, resultado.sucesso, 'Sincronização deveria ter sucesso');
        
        // Verificar se TBO foi criada como VENCIDA
        List<Inspecao_Aeronave__c> tboVencidas = [
            SELECT Id, Nome_Inspecao__c, Status_Inspecao__c
            FROM Inspecao_Aeronave__c
            WHERE Aeronave__c = :aeronave.Id
            AND Nome_Inspecao__c = 'TBO'
            AND Status_Inspecao__c = 'VENCIDA'
        ];
        
        System.assertEquals(1, tboVencidas.size(), 'Deveria ter criado TBO como VENCIDA');
    }
    
    /**
     * @description Testa aeronave não encontrada
     */
    @isTest
    static void testAeronaveNaoEncontrada() {
        Id fakeId = '001000000000000AAA';
        
        Test.startTest();
        InspecaoAeronaveService.ResultadoSincronizacao resultado = 
            InspecaoAeronaveService.sincronizarInspecoesAeronave(fakeId);
        Test.stopTest();
        
        System.assertEquals(false, resultado.sucesso, 'Deveria falhar');
        System.assert(resultado.mensagem.contains('não encontrada'), 'Mensagem deveria indicar aeronave não encontrada');
    }
    
    /**
     * @description Testa aeronave sem ID Planeit
     */
    @isTest
    static void testAeronaveSemIdPlaneit() {
        // Criar aeronave sem Id_Planeit__c
        Aeronave__c aeroSemPlaneit = new Aeronave__c();
        aeroSemPlaneit.Name = 'PT-NONE';
        aeroSemPlaneit.Ativo__c = true;
        insert aeroSemPlaneit;
        
        Test.startTest();
        InspecaoAeronaveService.ResultadoSincronizacao resultado = 
            InspecaoAeronaveService.sincronizarInspecoesAeronave(aeroSemPlaneit.Id);
        Test.stopTest();
        
        System.assertEquals(false, resultado.sucesso, 'Deveria falhar');
        System.assert(resultado.mensagem.contains('ID Planeit'), 'Mensagem deveria indicar falta de ID Planeit');
    }
    
    /**
     * @description Testa sincronização em lote
     */
    @isTest
    static void testSincronizarLote() {
        List<Aeronave__c> aeronaves = [
            SELECT Id, Name, Id_Planeit__c, Horas_Totais_de_Voo__c
            FROM Aeronave__c
        ];
        
        Test.setMock(HttpCalloutMock.class, new InspecoesMock());
        
        Test.startTest();
        InspecaoAeronaveService.ResultadoSincronizacao resultado = 
            InspecaoAeronaveService.sincronizarInspecoesLote(aeronaves);
        Test.stopTest();
        
        System.assertEquals(true, resultado.sucesso, 'Sincronização em lote deveria ter sucesso');
    }
    
    /**
     * @description Testa lista vazia
     */
    @isTest
    static void testListaVazia() {
        Test.startTest();
        InspecaoAeronaveService.ResultadoSincronizacao resultado = 
            InspecaoAeronaveService.sincronizarInspecoesLote(new List<Aeronave__c>());
        Test.stopTest();
        
        System.assertEquals(false, resultado.sucesso, 'Deveria falhar com lista vazia');
    }
    
    /**
     * @description Testa deserialização do JSON das inspeções
     */
    @isTest
    static void testDeserializeInspecaoJSON() {
        String jsonResponse = '{' +
            '"codigo": 200,' +
            '"mensagem": "Inspeções encontradas",' +
            '"metodo": "GET",' +
            '"data": [' +
                '{' +
                    '"idInspecao": 3057,' +
                    '"idAeronave": 1599,' +
                    '"nomeInspecao": "100hrs",' +
                    '"inicioHoras": "2500",' +
                    '"situacaoInspecao": "A",' +
                    '"detalheUltimaExecucao": [{' +
                        '"idExecucaoInspecao": 1,' +
                        '"dataExecucao": "2025-12-30",' +
                        '"horasExecucao": "2400",' +
                        '"dataProxima": "2026-03-07",' +
                        '"horasProxima": "2500",' +
                        '"responsavelExecucao": "FLIGHT CORNÉNIO"' +
                    '}]' +
                '}' +
            ']' +
        '}';
        
        Test.startTest();
        InspecaoAeronaveService.InspecoesResponse response = 
            (InspecaoAeronaveService.InspecoesResponse) JSON.deserialize(
                jsonResponse, 
                InspecaoAeronaveService.InspecoesResponse.class
            );
        Test.stopTest();
        
        System.assertEquals(200, response.codigo, 'Código deveria ser 200');
        System.assertEquals(1, response.data.size(), 'Deveria ter 1 inspeção');
        System.assertEquals('100hrs', response.data[0].nomeInspecao, 'Nome deveria ser 100hrs');
    }
    
    /**
     * @description Testa se o mock HTTP está funcionando
     */
    @isTest
    static void testMockHTTP() {
        Test.setMock(HttpCalloutMock.class, new InspecoesMock());
        
        Test.startTest();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Planeit_API_Login/login');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        Test.stopTest();
        
        System.assertEquals(200, res.getStatusCode(), 'Status code deveria ser 200');
        System.assert(res.getBody().contains('access_token'), 'Response deveria conter access_token');
    }
}