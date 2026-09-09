public without sharing class JwtAuthProvider {
    private static final String SECRET_KEY = Portal_engemap_config__mdt.getInstance('portal_secret_key').Secret_Key__c;

    // Tempo de expiração do token em horas
    public static final Integer TOKEN_EXPIRY_HOURS = 8;
    public static final Integer TOKEN_EXPIRY_HOURS_EXTERNAL = 4;
    public static final Integer TOKEN_EXPIRY_HOURS_IMPERSONATION = 1;
    private static Boolean externalLogin = false;

    private static final Integer MAX_TENTATIVAS_LOGIN = 5;
    private static final Integer BLOQUEIO_MINUTOS = 15;
    private static final String GRUPO_ADMINISTRADORES_SISTEMA = 'Administradores Sistema';

    public class LoginResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String redirectUrl;
        @AuraEnabled public String token;
    }

    public class ValidationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String loginId;
        @AuraEnabled public String impersonatedBy;
    }

    public class ForgotPasswordResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
    }

    public class ImpersonationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String token;
    }

    /**
* Método de login que gera um JWT ao invés de salvar tokens no banco
*/
    @AuraEnabled
    public static LoginResult login(String username, String password) {
        LoginResult result = new LoginResult();
        result.success = false;

        List<Login__c> logins = [
            SELECT Id, Name, Senha__c, Senha_Salt__c, Trocar_senha__c, isActive__c, Tentativas_Falhas__c, Bloqueado_Ate__c
            FROM Login__c
            WHERE isActive__c = true AND Name = :username
            LIMIT 1
        ];

        if (logins.isEmpty()) {
            result.message = 'Usuário ou Senha inválidos.';
            return result;
        }

        Login__c login = logins[0];

        if (estaBloqueado(login)) {
            result.message = 'Conta temporariamente bloqueada por excesso de tentativas. Tente novamente mais tarde.';
            return result;
        }

        if (!verificarSenha(login, password)) {
            result.message = 'Usuário ou Senha inválidos.';
            return result;
        }

        // Se precisa trocar senha
        if (login.Trocar_senha__c) {
            result.redirectUrl = '/ChangePassword?id=' + login.Id;
            result.success = true;
            return result;
        }

        // Tudo certo → gera JWT token
        Map<String, Object> claims = new Map<String, Object>{
            'sub' => login.Id,
                'username' => login.Name,
                'exp' => getExpirationTime()
                };

                    String token = generateJwt(claims);

        result.token = token;
        result.success = true;
        result.redirectUrl = '/portalengemap/Home';
        return result;
    }

    public static LoginResult login(String username, String password, Boolean external){
        externalLogin = external;
        return login(username, password);
    }

    @AuraEnabled
    public static LoginResult changePassword(String username, String password, String newPassword){
        LoginResult result = new LoginResult();
        result.success = false;

        List<Login__c> logins = [
            SELECT Id, Name, Senha__c, Senha_Salt__c, Trocar_senha__c, isActive__c, Tentativas_Falhas__c, Bloqueado_Ate__c
            FROM Login__c
            WHERE isActive__c = true AND Name = :username
            LIMIT 1
        ];

        if (logins.isEmpty()) {
            result.message = 'Usuário ou Senha inválidos.';
            return result;
        }

        Login__c login = logins[0];
        if (estaBloqueado(login)) {
            result.message = 'Conta temporariamente bloqueada por excesso de tentativas. Tente novamente mais tarde.';
            return result;
        }

        if (!verificarSenha(login, password)) {
            result.message = 'Usuário ou Senha inválidos.';
            return result;
        }

        definirSenha(login, newPassword);
        login.Trocar_senha__c = false;
        update login;

        return login(username, newPassword);
    }

    /**
* Método para validar o token JWT
*/
    @AuraEnabled
    public static ValidationResult validateToken(String token) {
        ValidationResult result = new ValidationResult();
        result.success = false;
        if (String.isBlank(token)) {
            result.message = 'Token não fornecido';
            return result;
        }

        Map<String, Object> claims = verifyJwt(token);
        if (claims == null) {
            result.message = 'Sessão inválida ou expirada';
            return result;
        }

        // Verificar se o login ainda existe e está ativo
        String loginId = (String)claims.get('sub');
        List<Login__c> logins = [
            SELECT Id, isActive__c
            FROM Login__c
            WHERE Id = :loginId AND isActive__c = true
            LIMIT 1
        ];

        if (logins.isEmpty()) {
            result.message = 'Usuário não encontrado ou inativo';
            return result;
        }

        result.success = true;
        result.loginId = loginId;
        result.impersonatedBy = (String) claims.get('impersonatedBy');
        return result;
    }

    @AuraEnabled
    public static ForgotPasswordResult forgotPassword(String username, Boolean notUser) {
        ForgotPasswordResult result = new ForgotPasswordResult();
        result.success = false;
        List<Empregado__c> empregados;

        if (!notUser) {
            empregados = [
                SELECT Id, email__c, Login__c, isActive__c
                FROM Empregado__c
                WHERE Login__r.Name = :username AND isActive__c = true
                LIMIT 1
            ];
        } else {
            empregados = [
                SELECT Id, email__c, Login__c, isActive__c
                FROM Empregado__c
                WHERE email__c = :username AND isActive__c = true
                LIMIT 1
            ];
        }

        if (empregados.isEmpty()) {
            result.message = 'Usuário ou e-mail não encontrado.';
            return result;
        }

        Empregado__c empregado = empregados[0];

        // Se não tiver login associado
        if (empregado.Login__c == null) {
            result.message = 'Usuário ou e-mail não encontrado.';
            return result;
        }

        Login__c login = [
            SELECT Id, Name, Senha__c, Senha_Salt__c, Trocar_senha__c, isActive__c
            FROM Login__c WHERE Id =: empregado.Login__c
            LIMIT 1
        ];

        // Se login inativo
        if(!login.isActive__c){
            result.message = 'Usuário ou e-mail não encontrado.';
            return result;
        }

        // Gera nova senha
        String novaSenha = gerarSenhaTemporaria();
        definirSenha(login, novaSenha);
        login.Trocar_senha__c = true;
        update login;

        // Envia e-mail
        enviarEmailSenha(empregado.email__c, novaSenha, login.Name);

        result.success = true;
        result.message = 'A senha foi enviada para o e-mail cadastrado';
        return result;
    }

    /**
* Permite que um administrador (membro do grupo "Administradores Sistema") gere um
* token de sessão para outro usuário, para fins de suporte. Toda chamada fica
* registrada em Personificacao_Log__c.
* @param loginAdminId Id do Login__c do administrador, já autenticado (validado pelo chamador)
* @param loginAlvoId Id do Login__c do usuário a ser personificado
*/
    @AuraEnabled
    public static ImpersonationResult impersonar(Id loginAdminId, Id loginAlvoId) {
        ImpersonationResult result = new ImpersonationResult();
        result.success = false;

        if (!podePersonificar(loginAdminId)) {
            result.message = 'Sem permissão para personificar usuários.';
            return result;
        }

        List<Login__c> alvos = [
            SELECT Id, Name FROM Login__c WHERE Id = :loginAlvoId AND isActive__c = true LIMIT 1
        ];
        if (alvos.isEmpty()) {
            result.message = 'Usuário alvo não encontrado ou inativo.';
            return result;
        }
        Login__c alvo = alvos[0];

        insert new Personificacao_Log__c(
            Login_Admin__c = loginAdminId,
            Login_Alvo__c = alvo.Id
        );

        Map<String, Object> claims = new Map<String, Object>{
            'sub' => alvo.Id,
            'username' => alvo.Name,
            'impersonatedBy' => loginAdminId,
            'exp' => System.currentTimeMillis() / 1000 + (TOKEN_EXPIRY_HOURS_IMPERSONATION * 60 * 60)
        };

        result.token = generateJwt(claims);
        result.success = true;
        return result;
    }

    /**
* Verifica se o login informado pertence a um Empregado__c membro do grupo
* "Administradores Sistema" (mesmo critério já usado em AccessControl.isAdminSistema).
*/
    public static Boolean podePersonificar(Id loginId) {
        List<Empregado__c> empregados = [
            SELECT Id FROM Empregado__c WHERE Login__c = :loginId AND isActive__c = true LIMIT 1
        ];
        if (empregados.isEmpty()) {
            return false;
        }
        List<Grupo_Funcionarios__c> grupos = [
            SELECT Id
            FROM Grupo_Funcionarios__c
            WHERE Empregado__c = :empregados[0].Id AND Grupo__r.Name = :GRUPO_ADMINISTRADORES_SISTEMA
            LIMIT 1
        ];
        return !grupos.isEmpty();
    }

    public static String createToken(Id loginId, String username) {
        Map<String, Object> claims = new Map<String, Object>{
            'sub'      => loginId,
            'username' => username,
            'exp'      => getExpirationTime()
        };
        return generateJwt(claims);
    }

    // Verificação de senha, hashing e bloqueio por tentativas

    /**
* Confere a senha informada contra o login. Suporta tanto logins já migrados para
* hash (Senha_Salt__c preenchido) quanto logins legados ainda em texto puro — nesse
* caso, se a senha bater, o registro é migrado para hash automaticamente (lazy upgrade).
* Também controla o contador de tentativas falhas e o bloqueio temporário.
*/
    public static Boolean verificarSenha(Login__c login, String senhaInformada) {
        if (estaBloqueado(login) || String.isBlank(senhaInformada)) {
            return false;
        }

        Boolean valida;
        if (String.isNotBlank(login.Senha_Salt__c)) {
            valida = hashSenha(senhaInformada, login.Senha_Salt__c) == login.Senha__c;
        } else {
            // Senha legada em texto puro: compara direto e, se bater, migra para hash
            valida = senhaInformada == login.Senha__c;
            if (valida) {
                Login__c migrado = new Login__c(Id = login.Id);
                definirSenha(migrado, senhaInformada);
                update migrado;
            }
        }

        registrarTentativa(login, valida);
        return valida;
    }

    /**
* Define a senha (em texto puro) do login informado, já como hash + salt novo.
* Não faz DML — quem chamar é responsável por dar update no registro.
*/
    public static void definirSenha(Login__c login, String novaSenhaEmTextoPuro) {
        String salt = gerarSalt();
        login.Senha_Salt__c = salt;
        login.Senha__c = hashSenha(novaSenhaEmTextoPuro, salt);
    }

    private static Boolean estaBloqueado(Login__c login) {
        return login.Bloqueado_Ate__c != null && login.Bloqueado_Ate__c > DateTime.now();
    }

    private static void registrarTentativa(Login__c login, Boolean sucesso) {
        if (sucesso) {
            if (login.Tentativas_Falhas__c == null || login.Tentativas_Falhas__c == 0) {
                return;
            }
            update new Login__c(Id = login.Id, Tentativas_Falhas__c = 0, Bloqueado_Ate__c = null);
            return;
        }

        Integer tentativas = (login.Tentativas_Falhas__c == null ? 0 : Integer.valueOf(login.Tentativas_Falhas__c)) + 1;
        Login__c toUpdate = new Login__c(Id = login.Id, Tentativas_Falhas__c = tentativas);
        if (tentativas >= MAX_TENTATIVAS_LOGIN) {
            toUpdate.Bloqueado_Ate__c = DateTime.now().addMinutes(BLOQUEIO_MINUTOS);
        }
        update toUpdate;
    }

    private static String hashSenha(String senha, String salt) {
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(senha + salt));
        return EncodingUtil.base64Encode(digest);
    }

    private static String gerarSalt() {
        return EncodingUtil.base64Encode(Crypto.generateAesKey(128));
    }

    // Métodos auxiliares para JWT

    private static String generateJwt(Map<String, Object> claims) {
        // Header
        Map<String, Object> header = new Map<String, Object>{
            'alg' => 'HS256',
                'typ' => 'JWT'
                };

                    // Codifica o header para base64url
                    String encodedHeader = base64UrlEncode(JSON.serialize(header));

        // Codifica o payload (claims) para base64url
        String encodedPayload = base64UrlEncode(JSON.serialize(claims));

        // Concatena header e payload
        String data = encodedHeader + '.' + encodedPayload;

        // Gera assinatura
        Blob signature = Crypto.generateMac('hmacSHA256', Blob.valueOf(data), Blob.valueOf(SECRET_KEY));
        String encodedSignature = base64UrlEncode(signature);

        // Retorna o token completo
        return data + '.' + encodedSignature;
    }

    /**
* Verifica e decodifica um token JWT
* Retorna null se o token for inválido ou expirado
*/
    private static Map<String, Object> verifyJwt(String token) {
        // Separa o token em partes
        List<String> parts = token.split('\\.');
        if (parts.size() != 3) {
            return null;
        }

        String encodedHeader = parts[0];
        String encodedPayload = parts[1];
        String providedSignature = parts[2];

        // Recalcula a assinatura para validar
        String data = encodedHeader + '.' + encodedPayload;
        Blob calculatedSignature = Crypto.generateMac('hmacSHA256', Blob.valueOf(data), Blob.valueOf(SECRET_KEY));
        String encodedCalculatedSignature = base64UrlEncode(calculatedSignature);

        // Verifica se a assinatura é válida
        if (providedSignature != encodedCalculatedSignature) {
            return null;
        }

        // Decodifica o payload
        String decodedPayload = base64UrlDecode(encodedPayload);
        Map<String, Object> claims = (Map<String, Object>)JSON.deserializeUntyped(decodedPayload);

        // Verifica a expiração
        if (claims.containsKey('exp')) {
            Long expTime = (Long)claims.get('exp');
            if (expTime < System.currentTimeMillis() / 1000) {
                return null; // Token expirado
            }
        }

        return claims;
    }

    /**
* Retorna um timestamp Unix de expiração do token
*/
    private static Long getExpirationTime() {
        Integer expiration = TOKEN_EXPIRY_HOURS;
        // para login externo via api
        if(externalLogin){
            expiration = TOKEN_EXPIRY_HOURS_EXTERNAL;
        }
        return System.currentTimeMillis() / 1000 + (expiration * 60 * 60);
    }

    /**
* Codifica para base64url (base64 seguro para URLs)
*/
    private static String base64UrlEncode(Blob input) {
        String standard = EncodingUtil.base64Encode(input);
        return standard.replace('+', '-').replace('/', '_').replace('=', '');
    }

    /**
* Codifica para base64url (base64 seguro para URLs)
*/
    private static String base64UrlEncode(String input) {
        Blob inputBlob = Blob.valueOf(input);
        return base64UrlEncode(inputBlob);
    }

    /**
* Decodifica de base64url
*/
    private static String base64UrlDecode(String input) {
        String padded = input;
        Integer padding = Math.mod(4 - Math.mod(input.length(), 4), 4);
        for (Integer i = 0; i < padding; i++) {
            padded += '=';
        }
        padded = padded.replace('-', '+').replace('_', '/');
        return EncodingUtil.base64Decode(padded).toString();
    }

    // Métodos auxiliares reaproveitados do código original

    private static String gerarSenhaTemporaria() {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        String senha = '';
        for (Integer i = 0; i < 10; i++) {
            Integer randomNumber = (Integer)(Math.random() * chars.length());
            senha += chars.substring(randomNumber, randomNumber+1);
        }
        return senha;
    }

    private static final String REMETENTE_SENHA_TEMPORARIA = 'suportegi@engemap.com.br';

    /**
* Busca o Id do Organization-Wide Email Address usado como remetente dos e-mails de senha.
* Sem isso, Messaging.sendEmail usa o e-mail do usuário/contexto de execução como remetente,
* que em sandboxes cai no endereço genérico "*.sfcustomeremail.com" e é comumente barrado
* por filtros de spam corporativos (o domínio do remetente não bate com o do destinatário).
*/
    private static Id getRemetenteSenhaTemporariaId() {
        List<OrgWideEmailAddress> enderecos = [
            SELECT Id FROM OrgWideEmailAddress WHERE Address = :REMETENTE_SENHA_TEMPORARIA LIMIT 1
        ];
        return enderecos.isEmpty() ? null : enderecos[0].Id;
    }

    private static void enviarEmailSenha(String emailDestino, String senhaTemporaria, String userName) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { emailDestino });
        Id remetenteId = getRemetenteSenhaTemporariaId();
        if (remetenteId != null) {
            email.setOrgWideEmailAddressId(remetenteId);
        }
        email.setSubject('Sua nova senha temporária');
        email.setPlainTextBody('Seu login é: ' + userName + ', e a sua senha temporária é: ' + senhaTemporaria +
                               '. Por favor, troque no próximo login.');
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
}