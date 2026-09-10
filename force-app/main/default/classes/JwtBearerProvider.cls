public without sharing class JwtBearerProvider {
    // Armazene em Custom Metadata (ex: CometD_Integration__mdt)
    private static final String CLIENT_ID = CometD_Integration__mdt.getInstance('Default').ClientId__c; // Consumer Key do Connected App
    private static final String USERNAME = CometD_Integration__mdt.getInstance('Default').Username__c; // Ex: integrationuser@yourorg.com
    private static final String CERTIFICATE_NAME = 'Cometd_Integration'; // Nome do certificado no org
    
    public static String getAccessToken() {
        String audience = URL.getOrgDomainUrl().toExternalForm();
        // Claims para JWT Bearer
        Map<String, Object> claims = new Map<String, Object>{
            'iss' => CLIENT_ID,    // Issuer: Consumer Key
            'sub' => USERNAME,     // Subject: Username do usuário de integração
            'aud' => audience,     // audience: orgUrl
            'exp' => String.valueOf((DateTime.now().getTime() / 1000) + 300) // Expiração em 5 min (Unix timestamp)
        };
        
        // Gera JWT (header + payload + assinatura RSA)
        String header = EncodingUtil.base64Encode(Blob.valueOf('{"alg":"RS256"}')).replace('+', '-').replace('/', '_').replace('=', ''); // Header mantém 'RS256' (é padrão JWT)
        String payload = EncodingUtil.base64Encode(Blob.valueOf(JSON.serialize(claims))).replace('+', '-').replace('/', '_').replace('=', '');
        String data = header + '.' + payload;
        
        // Assina com certificado — MUDANÇA AQUI: Use 'RSA-SHA256' em vez de 'RS256'
        Blob signature = Crypto.signWithCertificate('RSA-SHA256', Blob.valueOf(data), CERTIFICATE_NAME);
        String encodedSignature = EncodingUtil.base64Encode(signature).replace('+', '-').replace('/', '_').replace('=', '');
        
        String jwt = data + '.' + encodedSignature;
        
        // Troca JWT por access token via callout
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(audience + '/services/oauth2/token');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setBody('grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + jwt);
        
        HttpResponse res = http.send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            return (String) response.get('access_token');
        } else {
            System.debug('Erro ao obter token: ' + res.getStatusCode() + ' - ' + res.getBody());
            return null;
        }
    }
}