/**
 * Cobre a descoberta de notas anexadas na Planeit: os dois endpoints novos do
 * PlaneitAPIService e a fila de verificação do PlaneitAnexoSyncQueueable.
 */
@IsTest
private class PlaneitAnexoSyncQueueableTest {
    private static final String MATRICULA = 'PT-ABC';
    private static final String CAMINHO = 'anexos/PTABC/Abastecimento/555/NOTA.jpg';

    /**
     * Responde login, /anexos/listar e /anexos/url. O construtor decide se a
     * listagem devolve um anexo ou uma lista vazia.
     */
    private class AnexoMock implements HttpCalloutMock {
        private final Boolean comAnexo;

        private AnexoMock(Boolean comAnexo) {
            this.comAnexo = comAnexo;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            String endpoint = req.getEndpoint();

            if (endpoint.contains('/login')) {
                res.setBody('{"codigo":200,"mensagem":"Sucesso","metodo":"POST",' +
                            '"data":{"access_token":"TOKEN_TESTE","token_type":"Bearer"}}');
            } else if (endpoint.contains('/anexos/listar')) {
                String itens = comAnexo
                    ? '[{"id":7261,"diretorioArquivo":"' + CAMINHO + '",' +
                      '"nomeArquivo":"NOTA.jpg","extensaoArquivo":"jpg"}]'
                    : '[]';
                res.setBody('{"codigo":200,"mensagem":"Sucesso","metodo":"GET","data":' + itens + '}');
            } else if (endpoint.contains('/anexos/url')) {
                res.setBody('{"codigo":200,"mensagem":"Sucesso","metodo":"GET",' +
                            '"data":{"url":"https://bucket.s3.amazonaws.com/' + CAMINHO +
                            '?X-Amz-Signature=abc123"}}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"message":""}');
            }
            return res;
        }
    }

    /** Responde erro em tudo que não seja o login. */
    private class FalhaMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().contains('/login')) {
                res.setStatusCode(200);
                res.setBody('{"codigo":200,"data":{"access_token":"TOKEN_TESTE"}}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"message":"erro interno"}');
            }
            return res;
        }
    }

    private static Abastecimento__c criarAbastecimento(Integer idPlaneit) {
        Aeronave__c aeronave = new Aeronave__c(Name = MATRICULA, Ativo__c = true);
        insert aeronave;

        Controle_Horas_Voo__c voo = new Controle_Horas_Voo__c(
            Aeronave__c = aeronave.Id,
            Data_do_Voo__c = Date.today()
        );
        insert voo;

        Abastecimento__c ab = new Abastecimento__c(
            Voo__c = voo.Id,
            Id_Abastecimento_Planeit__c = idPlaneit,
            Quantidade__c = 100
        );
        insert ab;
        return ab;
    }

    /**
     * Token de sessão da página, do mesmo tipo emitido no carregamento.
     * O @RemoteAction autentica por ele porque JavaScript Remoting não
     * enxerga a sessão do portal.
     */
    private static String tokenValido() {
        Empregado__c piloto = TestDataStatic.empregadoPiloto;
        Grupo__c grupo = TestDataStatic.grupoAerolevantamento;
        insert new Grupo_Funcionarios__c(
            Grupo__c = grupo.Id,
            Empregado__c = piloto.Id
        );
        return ControleHorasVooReportController.issueAccessTokenForLogin(piloto.Login__c);
    }

    private static Abastecimento__c recarregar(Id abId) {
        return [
            SELECT Id, Caminho_Anexo__c, Anexo_Verificado_Em__c
            FROM Abastecimento__c
            WHERE Id = :abId
        ];
    }

    @IsTest
    static void deveGravarCaminhoQuandoExisteAnexo() {
        Abastecimento__c ab = criarAbastecimento(555);
        Test.setMock(HttpCalloutMock.class, new AnexoMock(true));
        PlaneitAnexoSyncQueueable.suppressContinuationInTests = true;

        Test.startTest();
        System.enqueueJob(new PlaneitAnexoSyncQueueable());
        Test.stopTest();

        Abastecimento__c atualizado = recarregar(ab.Id);
        System.assertEquals(CAMINHO, atualizado.Caminho_Anexo__c,
            'O caminho do anexo deve ser gravado a partir da resposta da Planeit');
        System.assertNotEquals(null, atualizado.Anexo_Verificado_Em__c,
            'A verificação deve ser marcada mesmo quando encontra anexo');
    }

    @IsTest
    static void deveMarcarVerificacaoQuandoNaoHaAnexo() {
        Abastecimento__c ab = criarAbastecimento(556);
        Test.setMock(HttpCalloutMock.class, new AnexoMock(false));
        PlaneitAnexoSyncQueueable.suppressContinuationInTests = true;

        Test.startTest();
        System.enqueueJob(new PlaneitAnexoSyncQueueable());
        Test.stopTest();

        Abastecimento__c atualizado = recarregar(ab.Id);
        System.assertEquals(null, atualizado.Caminho_Anexo__c,
            'Sem anexo na Planeit, o caminho deve permanecer vazio');
        System.assertNotEquals(null, atualizado.Anexo_Verificado_Em__c,
            'Sem esta marca a fila reconsultaria o mesmo registro indefinidamente');
    }

    @IsTest
    static void naoDeveReprocessarRegistroJaVerificado() {
        Abastecimento__c ab = criarAbastecimento(557);
        Datetime verificadoAgora = Datetime.now();
        ab.Anexo_Verificado_Em__c = verificadoAgora;
        Database.update(ab, true, AccessLevel.SYSTEM_MODE);

        Test.setMock(HttpCalloutMock.class, new AnexoMock(true));
        PlaneitAnexoSyncQueueable.suppressContinuationInTests = true;

        Test.startTest();
        System.enqueueJob(new PlaneitAnexoSyncQueueable());
        Test.stopTest();

        Abastecimento__c atualizado = recarregar(ab.Id);
        System.assertEquals(null, atualizado.Caminho_Anexo__c,
            'Registro verificado há menos de 7 dias não deve ser reconsultado');
    }

    @IsTest
    static void deveBuscarCaminhoDoAnexo() {
        Test.setMock(HttpCalloutMock.class, new AnexoMock(true));

        Test.startTest();
        String caminho = PlaneitAPIService.buscarCaminhoAnexo(555, MATRICULA);
        Test.stopTest();

        System.assertEquals(CAMINHO, caminho, 'Deve retornar o diretório do primeiro anexo');
    }

    @IsTest
    static void deveRetornarNuloQuandoListagemVazia() {
        Test.setMock(HttpCalloutMock.class, new AnexoMock(false));

        Test.startTest();
        String caminho = PlaneitAPIService.buscarCaminhoAnexo(555, MATRICULA);
        Test.stopTest();

        System.assertEquals(null, caminho, 'Sem anexos, o retorno deve ser nulo');
    }

    @IsTest
    static void deveGerarUrlAssinada() {
        Test.setMock(HttpCalloutMock.class, new AnexoMock(true));

        Test.startTest();
        String url = PlaneitAPIService.gerarUrlAnexo(555, MATRICULA, CAMINHO);
        Test.stopTest();

        System.assertNotEquals(null, url, 'Deve retornar a URL de download');
        System.assert(url.contains('X-Amz-Signature'),
            'A URL deve vir assinada pelo storage da Planeit');
    }

    @IsTest
    static void deveIgnorarEntradasInvalidas() {
        Test.setMock(HttpCalloutMock.class, new AnexoMock(true));

        Test.startTest();
        System.assertEquals(null, PlaneitAPIService.buscarCaminhoAnexo(null, MATRICULA),
            'Sem id do Planeit não há o que consultar');
        System.assertEquals(null, PlaneitAPIService.buscarCaminhoAnexo(555, null),
            'Sem matrícula não há o que consultar');
        System.assertEquals(null, PlaneitAPIService.gerarUrlAnexo(555, MATRICULA, null),
            'Sem caminho não há URL a gerar');
        Test.stopTest();
    }

    @IsTest
    static void deveTolerarFalhaDaApi() {
        Abastecimento__c ab = criarAbastecimento(558);
        Test.setMock(HttpCalloutMock.class, new FalhaMock());
        PlaneitAnexoSyncQueueable.suppressContinuationInTests = true;

        Test.startTest();
        System.enqueueJob(new PlaneitAnexoSyncQueueable());
        System.assertEquals(null, PlaneitAPIService.gerarUrlAnexo(555, MATRICULA, CAMINHO),
            'Erro HTTP ao gerar URL deve retornar nulo em vez de lançar exceção');
        Test.stopTest();

        Abastecimento__c atualizado = recarregar(ab.Id);
        System.assertEquals(null, atualizado.Caminho_Anexo__c,
            'Falha da API não deve gravar caminho');
        System.assertNotEquals(null, atualizado.Anexo_Verificado_Em__c,
            'A verificação é marcada mesmo em falha, para a fila não travar no mesmo registro');
    }

    @IsTest
    static void deveDevolverUrlPeloRemoteAction() {
        Abastecimento__c ab = criarAbastecimento(559);
        ab.Caminho_Anexo__c = CAMINHO;
        Database.update(ab, true, AccessLevel.SYSTEM_MODE);

        Test.setMock(HttpCalloutMock.class, new AnexoMock(true));
        String token = tokenValido();

        Test.startTest();
        String url = ControleHorasVooController.obterUrlAnexo(token, ab.Id);
        Test.stopTest();

        System.assertNotEquals(null, url, 'Com token válido e anexo, deve devolver a URL de download');
        System.assert(url.contains('X-Amz-Signature'), 'A URL deve vir assinada');
    }

    @IsTest
    static void remoteActionDeveNegarTokenInvalido() {
        Abastecimento__c ab = criarAbastecimento(560);
        ab.Caminho_Anexo__c = CAMINHO;
        Database.update(ab, true, AccessLevel.SYSTEM_MODE);

        Test.setMock(HttpCalloutMock.class, new AnexoMock(true));

        Test.startTest();
        String url = ControleHorasVooController.obterUrlAnexo('token-invalido', ab.Id);
        Test.stopTest();

        System.assertEquals(null, url, 'Token inválido não deve devolver URL de anexo');
    }

    @IsTest
    static void remoteActionDeveIgnorarAbastecimentoSemAnexo() {
        Abastecimento__c ab = criarAbastecimento(561);

        Test.setMock(HttpCalloutMock.class, new AnexoMock(true));
        String token = tokenValido();

        Test.startTest();
        String url = ControleHorasVooController.obterUrlAnexo(token, ab.Id);
        Test.stopTest();

        System.assertEquals(null, url, 'Sem caminho gravado não há anexo a baixar');
    }

    @IsTest
    static void deveNormalizarMatricula() {
        System.assertEquals('PTABC', PlaneitAPIService.normalizarMatricula('PT-ABC'),
            'A Planeit usa a matrícula sem hífen');
        System.assertEquals('PTABC', PlaneitAPIService.normalizarMatricula('pt-abc'),
            'A normalização deve ser insensível a caixa');
        System.assertEquals(null, PlaneitAPIService.normalizarMatricula(null),
            'Matrícula nula deve continuar nula');
    }
}
