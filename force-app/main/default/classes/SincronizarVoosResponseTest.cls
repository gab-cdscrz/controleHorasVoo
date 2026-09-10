/**
 * @description Testes para SincronizarVoosResponse
 * @author GabrielCruz
 * @date 2025-11-24
 */
@IsTest
private class SincronizarVoosResponseTest {
    
    @IsTest
    static void testResponse() {
        Test.startTest();
        SincronizarVoosResponse response = new SincronizarVoosResponse();
        response.sucesso = true;
        response.totalImportados = 10;
        response.totalAtualizados = 5;
        response.mensagem = 'Teste';
        Test.stopTest();
        
        System.assertNotEquals(null, response);
        System.assertEquals(true, response.sucesso);
        System.assertEquals(10, response.totalImportados);
        System.assertEquals(5, response.totalAtualizados);
        System.assertEquals('Teste', response.mensagem);
    }
}