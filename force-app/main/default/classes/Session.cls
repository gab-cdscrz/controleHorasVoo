public class Session {

     public String redirect {get;set;} // endereco para o redirecionamento apos a seção

    // Construtor usado para chamadas de dentro do CRM salesforce, foi necessario este contrutor apenas para vincular a pagina SessionPage que cria uma seção
    // para o usuario logado pela minha pagina cliente
    public Session(){

        // O certo aqui é validar para ver se o authToken recebido esta atrelado ao usuario logado do salesforce, para lhe dar uma seção
        String authToken = ApexPages.currentPage().getParameters().get('authToken');
        if (authToken != '' && authToken != null) Session.add('authToken', authToken);
        redirect = ApexPages.currentPage().getParameters().get('redirect');
    }
    
    // Chamado pela pagina de redirecionamento
    public PageReference getRedirect(){

        if (redirect != null && redirect != '') {
            return new PageReference(redirect);
        } else {
            return new PageReference('/home/home.jsp');
        }
    }
                 
    public static String getValue(String key) {
        
        Cookie c = ApexPages.currentPage().getCookies().get(key);
        
        if (c != null) return c.getValue();
        else return null;
    }
    
    public static void add(String key, String value){
        ApexPages.currentPage().setCookies(mergeCookies(key, new Cookie(key, value, null, 43200, true)));
    }

    public static String getLoginId() {
        String token = Session.getValue('authToken');
        if (String.isBlank(token)) return null;
        JwtAuthProvider.ValidationResult v = JwtAuthProvider.validateToken(token);
        return v.success ? v.loginId : null;
    }

    // Retorna o Id do Login__c do administrador, se a sessão atual for uma personificação
    public static String getImpersonatedBy() {
        String token = Session.getValue('authToken');
        if (String.isBlank(token)) return null;
        JwtAuthProvider.ValidationResult v = JwtAuthProvider.validateToken(token);
        return v.success ? v.impersonatedBy : null;
    }


    public static void remove(String key) {
        ApexPages.currentPage().setCookies(mergeCookies(key, new Cookie(key, null, null, 0, false)));
    }

    // setCookies substitui todo o array de cookies da resposta, então é preciso juntar com
    // os que já foram setados nesta mesma requisição (ex.: add/remove chamados mais de uma
    // vez, como acontece ao restaurar a sessão do admin após uma personificação), senão a
    // chamada anterior é perdida.
    private static List<Cookie> mergeCookies(String key, Cookie substituto) {
        Map<String, Cookie> existentes = ApexPages.currentPage().getCookies();
        List<Cookie> cookies = new List<Cookie>();
        for (String k : existentes.keySet()) {
            if (k != key) {
                cookies.add(existentes.get(k));
            }
        }
        cookies.add(substituto);
        return cookies;
    }
    
    public static Boolean validate(String key) {
        String token = Session.getValue(key);
        if (String.isBlank(token)) return false;
        JwtAuthProvider.ValidationResult v = JwtAuthProvider.validateToken(token);
        return v.success;
    }
}