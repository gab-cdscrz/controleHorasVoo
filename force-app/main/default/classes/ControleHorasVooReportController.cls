/**
 * Visualforce remoting endpoint for flight-hour reports.
 */
public without sharing class ControleHorasVooReportController {
    private static final String TOKEN_SCOPE = 'controle-horas-voo-report';
    private static final Integer TOKEN_TTL_MINUTES = 480;

    @RemoteAction
    public static Response generate(String accessToken, String requestJson) {
        Response responseValue = new Response();
        try {
            if (!validateAccessToken(accessToken)) {
                throw new ReportAccessException(
                    'Sua sessão não permite exportar este relatório. Atualize a página e tente novamente.'
                );
            }
            responseValue.data = ControleHorasVooReportService.generate(
                requestJson
            );
            responseValue.success = true;
        } catch (ControleHorasVooReportService.ReportException exceptionValue) {
            responseValue.message = exceptionValue.getMessage();
        } catch (ReportAccessException exceptionValue) {
            responseValue.message = exceptionValue.getMessage();
        } catch (Exception exceptionValue) {
            System.debug(
                LoggingLevel.ERROR,
                'Erro ao gerar relatório de horas: ' +
                exceptionValue.getMessage() + '\n' +
                exceptionValue.getStackTraceString()
            );
            responseValue.message =
                'Não foi possível gerar o relatório. Tente novamente.';
        }
        return responseValue;
    }

    public static String issueAccessToken() {
        String loginId = Session.getLoginId();
        if (!hasReportAccess(loginId)) {
            return '';
        }
        return issueAccessTokenForLogin(loginId);
    }

    @TestVisible
    private static String issueAccessTokenForLogin(String loginId) {
        TokenPayload payload = new TokenPayload();
        payload.loginId = loginId;
        payload.scope = TOKEN_SCOPE;
        payload.expiresAt = Datetime.now()
            .addMinutes(TOKEN_TTL_MINUTES)
            .getTime();
        String encodedPayload = base64UrlEncode(JSON.serialize(payload));
        return encodedPayload + '.' + sign(encodedPayload);
    }

    /**
     * @description Valida um token de sessão da página de Controle de Horas.
     * Exposto porque JavaScript Remoting não enxerga a sessão do portal
     * (ApexPages.currentPage() é nulo nesse contexto), então todo @RemoteAction
     * da página precisa autenticar pelo token emitido no carregamento.
     */
    public static Boolean isSessionTokenValid(String accessToken) {
        return validateAccessToken(accessToken);
    }

    @TestVisible
    private static Boolean validateAccessToken(String accessToken) {
        if (String.isBlank(accessToken)) {
            return false;
        }
        List<String> parts = accessToken.split('\\.');
        if (parts.size() != 2) {
            return false;
        }
        String expectedSignature = sign(parts[0]);
        if (!secureEquals(expectedSignature, parts[1])) {
            return false;
        }

        try {
            TokenPayload payload = (TokenPayload) JSON.deserialize(
                base64UrlDecode(parts[0]),
                TokenPayload.class
            );
            return payload != null &&
                payload.scope == TOKEN_SCOPE &&
                payload.expiresAt >= Datetime.now().getTime() &&
                hasReportAccess(payload.loginId);
        } catch (Exception exceptionValue) {
            return false;
        }
    }

    @TestVisible
    private static Boolean hasReportAccess(String loginId) {
        if (String.isBlank(loginId)) {
            return false;
        }
        List<Grupo_Funcionarios__c> memberships = [
            SELECT Id
            FROM Grupo_Funcionarios__c
            WHERE Grupo__r.Name = 'Aerolevantamento'
              AND (
                  Empregado__r.Login__c = :loginId
                  OR Contato__r.Login__c = :loginId
              )
              AND (
                  Empregado__r.Login__r.isActive__c = true
                  OR Contato__r.Login__r.isActive__c = true
              )
            WITH SYSTEM_MODE
            LIMIT 1
        ];
        return !memberships.isEmpty();
    }

    private static String sign(String encodedPayload) {
        Portal_engemap_config__mdt configuration =
            Portal_engemap_config__mdt.getInstance('portal_secret_key');
        if (
            configuration == null ||
            String.isBlank(configuration.Secret_Key__c)
        ) {
            throw new ReportAccessException(
                'A exportação de relatórios não está configurada.'
            );
        }
        Blob signature = Crypto.generateMac(
            'HmacSHA256',
            Blob.valueOf(TOKEN_SCOPE + '.' + encodedPayload),
            Blob.valueOf(configuration.Secret_Key__c)
        );
        return base64UrlEncode(signature);
    }

    private static Boolean secureEquals(String first, String second) {
        if (first == null || second == null) {
            return false;
        }
        Blob firstDigest = Crypto.generateDigest(
            'SHA-256',
            Blob.valueOf(first)
        );
        Blob secondDigest = Crypto.generateDigest(
            'SHA-256',
            Blob.valueOf(second)
        );
        return EncodingUtil.base64Encode(firstDigest) ==
            EncodingUtil.base64Encode(secondDigest);
    }

    private static String base64UrlEncode(String value) {
        return base64UrlEncode(Blob.valueOf(value));
    }

    private static String base64UrlEncode(Blob value) {
        return EncodingUtil.base64Encode(value)
            .replace('+', '-')
            .replace('/', '_')
            .replace('=', '');
    }

    private static String base64UrlDecode(String value) {
        String normalized = value.replace('-', '+').replace('_', '/');
        while (Math.mod(normalized.length(), 4) != 0) {
            normalized += '=';
        }
        return EncodingUtil.base64Decode(normalized).toString();
    }

    private class TokenPayload {
        public String loginId;
        public String scope;
        public Long expiresAt;
    }

    public class Response {
        public Boolean success { get; set; }
        public String message { get; set; }
        public ControleHorasVooReportService.ReportResult data {
            get;
            set;
        }

        public Response() {
            success = false;
            message = '';
        }
    }

    private class ReportAccessException extends Exception {}
}