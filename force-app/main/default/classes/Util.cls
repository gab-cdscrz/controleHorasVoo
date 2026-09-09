global class Util {
  private static Boolean isSandboxValue;
  public static Boolean isSandboxx {
    get {
      if (isSandboxValue == null) {
        isSandboxValue = [SELECT Id, IsSandbox FROM Organization LIMIT 1]
        .IsSandbox;
      }
      return isSandboxValue;
    }
    private set;
  }

  public Util(PrevDespUpsertController controller) {
  }
  public Util(CronoProjUpsertController controller) {
  }
  public Util(ApexPages.StandardController controller) {
  }
  public Util(ApontamentoController controller) {
  }
  public Util(SatisfactionSurveyController controller) {
  }

  /*
   * Autor: Renato Matheus Simião
   * Esta classe contem metodos estaticos para serem usados afim de facilitar a manipulação dos dados visuais
   */

  /*public static String decimal2coin(Decimal d) {
        //return 'R$ ' + SUBSTITUTE(TEXT(roundToLong(d)), '.', ',');
        return d.format();
    }*/
  public static String getCallingClass() {
    return getCallingClass(null, null);
  }

  public static String getCallingClass(
    String actualClass,
    String actualMethod
  ) {
    List<String> stack = new List<String>();
    try {
      throwsException();
    } catch (Exception ex) {
      stack = ex.getStackTraceString().split('\n');
    }

    for (Integer i = 0; i < stack.size(); i++) {
      String linha = stack[i].trim();
      String classBeforeUtil;
      if (linha.startsWith('Class.')) {
        String className = extractClassName(stack[i]);
        System.debug('className: ' + className);
        if (className == 'Util') {
          continue;
        }
        classBeforeUtil = className;
      }
      if (
        classBeforeUtil != null &&
        actualClass != null &&
        classBeforeUtil == actualClass &&
        actualMethod != null
      ) {
        if (linha.contains('Class.' + actualClass + '.' + actualMethod)) {
          if (i + 1 < stack.size()) {
            return extractClassName(stack[i + 1]);
          }
        }
      } else {
        return classBeforeUtil;
      }
    }

    return null;
  }

  private static String extractClassName(String linha) {
    if (linha.startsWith('Class.')) {
      String classeMetodo = linha.removeStart('Class.').substringBefore(':');
      return classeMetodo.substringBefore('.');
    }
    return null;
  }

  public class CustomException extends Exception {
  }

  @TestVisible
  private static void throwsException() {
    throw new CustomException();
  }

  public static String float2Money(
    Decimal valor,
    String coin,
    Integer caseDecimal
  ) {
    String r = valor.setScale(caseDecimal).format();
    List<String> rs = r.split(',', -1);
    String zeroDireita = '';
    Integer length = 0;

    if (rs.size() == 2)
      length = rs.get(1).length();

    for (Integer i = length; i < caseDecimal; i++) {
      if (i == 0)
        zeroDireita = ',';
      zeroDireita = zeroDireita + '0';
    }

    return coin + r + zeroDireita;
  }

  public static String float2Money(Decimal valor) {
    return float2Money(valor, 'R$ ', 2);
  }
  // metodo estatico que funciona como um AJAX para retornar informações para a pagina
  @RemoteAction
  global static String getUnidadeMedida(String idTarefa) {
    String ret = '';

    if (idTarefa != '' && idTarefa != null) {
      Tarefa_projeto__c t = [
        SELECT Unidade_de_medida__c
        FROM Tarefa_projeto__c
        WHERE Id = :idTarefa
        LIMIT 1
      ];
      ret = t.Unidade_de_medida__c;
    }

    return ret;
  }

  public static String getDataFormatada(Date data) {
    if (data == null)
      return null;
    Datetime dataDateTime = Datetime.newInstance(
      data.year(),
      data.month(),
      data.day()
    );
    return dataDateTime.format('dd/MM/yyyy');
  }

  public static String getRGFormatado(String rg) {
    if (rg == null)
      return null;
    String rgRetornar = rg.replaceAll('[^0-9]', '');
    if (rgRetornar.length() == 9) {
      rgRetornar =
        rgRetornar.substring(0, 2) +
        '.' +
        rgRetornar.substring(2, 5) +
        '.' +
        rgRetornar.substring(5, 8) +
        '-' +
        rgRetornar.substring(8);
    }
    return rgRetornar;
  }

  public static String getTelefoneFormatado(String telefone) {
    if (telefone == null)
      return null;
    String phone = telefone.replaceAll('[^0-9]', '');

    if (phone.length() == 11) {
      phone =
        '(' +
        phone.substring(0, 2) +
        ') ' +
        phone.substring(2, 7) +
        '-' +
        phone.substring(7);
    } else if (phone.length() == 10) {
      phone =
        '(' +
        phone.substring(0, 2) +
        ') ' +
        phone.substring(2, 6) +
        '-' +
        phone.substring(6);
    }
    return phone;
  }

  @RemoteAction
  global static String getPrecoMedio(String idProduto) {
    String ret = '0';

    if (idProduto != '' && idProduto != null) {
      Produto_de_Compra__c pc = [
        SELECT Preco_medio__c
        FROM Produto_de_Compra__c
        WHERE Id = :idProduto
        LIMIT 1
      ];
      ret = pc.Preco_medio__c.format();
    }

    return ret;
  }

  /*
    Função para converter bytes em string visual
        parâmetro: bytes <Decimal> (valor a converter)
         */
  public static String bytesToSize(Decimal bytes) {
    List<String> sizes = new List<String>{ 'Bytes', 'KB', 'MB', 'GB', 'TB' };
    if (bytes == 0)
      return '0 Byte';
    Integer i = (Math.floor(Math.log(bytes) / Math.log(1024))).intValue();
    return Math.round(bytes / Math.pow(1024, i)) + ' ' + sizes.get(i);
  }

  public static String getWebdeskBaseUrl() {
    // Pega a URL da org atual
    String orgUrl = System.URL.getOrgDomainUrl().toExternalForm();
    // Ex: https://grupoengemap--devbase.sandbox.my.salesforce.com

    // Substitui salesforce.com por salesforce-sites.com
    return orgUrl.replace('.salesforce.com', '.salesforce-sites.com/webdesk');
    // Resultado: https://grupoengemap--devbase.sandbox.my.salesforce-sites.com/webdesk
  }

  /*
    Função para converter horario de campo Datetime para o horario do brasil
         */
  public static String getLocalDateTime(Datetime dt) {
    return dt.format('dd/MM/yyyy HH:mm', 'America/Sao_Paulo');
  }

  /*
    Como getLocalDateTime, mas só a data (sem hora). Para campos Datetime
    exibidos como dd/MM/yyyy: sem o fuso, o {0,date,...} do Visualforce usa GMT
    e pode adiantar a data em 1 dia nos registros criados à noite.
         */
  public static String getLocalDate(Datetime dt) {
    return dt.format('dd/MM/yyyy', 'America/Sao_Paulo');
  }

  /*
    Função para gerar uma nova senha
        parâmetro: len <Integer> (comprimento da senha)
         */
  public static String getNewKey(Integer len) {
    Blob blobKey = crypto.generateAesKey(128);
    String key = EncodingUtil.convertToHex(blobKey);
    return key.substring(0, len);
  }

  public static String getHost() {
    return 'https://' + ApexPages.currentPage().getHeaders().get('host');
  }

  public static String getLink() {
    return 'https://' +
      ApexPages.currentPage().getHeaders().get('host') +
      '/webdesk/';
  }

  public static String getLink(String page) {
    return getLink() + page;
  }

  public static void sendAdministratorMailError(
    String subject,
    String detail,
    Exception error
  ) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    String[] toAddresses = new List<String>{ 'suportegi@engemap.com.br' };
    mail.setToAddresses(toAddresses);
    mail.setSenderDisplayName('Engemap - Gestão da Informação');
    mail.setSubject(subject);
    mail.setBccSender(false);
    mail.setUseSignature(false);
    mail.setHtmlBody(
      '<h3>' +
        subject +
        '</h3> <br/>' +
        '<b>Organização: </b>' +
        UserInfo.getOrganizationName() +
        '<br/>' +
        '<b>Detalhes: </b>' +
        detail +
        '<br/>' +
        '<b>Erro: </b>' +
        error +
        '<br/>' +
        '<b>Passos do erro: </b><br/><br/>' +
        error.getStackTraceString() +
        '<br/><br/>' +
        'Atenciosamente,</br>' +
        Util.getAssinatureMail(
          'suportegi@engemap.com.br',
          'Depto. Gestão da Informação'
        )
    );

    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
  }

  /*
    Função que retorna uma assinatura de email
        parâmetros: email <String> (endereço de email da assinatura)
        departamento <String> (nome do departamento que esta enviando o email)
         */
  public static String getAssinatureMail(String email, String departamento) {
    String assinatura =
      '<table>' +
      '	<tr>' +
      '		<td>' +
      '			<a href="http://www.engemap.com.br">' +
      '				<img src="data:image/png;base64,' +
      '					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">' +
      '			</a>' +
      '		</td>' +
      '		<td>' +
      '			<b>Administrador</b> <br/>' +
      '			<label style="color:gray">' +
      departamento +
      '</label> <br/>' +
      '			<label style="color:gray">+55 18 3421-2525</label> <br/>' +
      '			<a href="mailto:' +
      email +
      '">' +
      email +
      '</a>' +
      '		</td>' +
      '		<td style="padding:10px;">' +
      '			<a href="http://www.engemap.com.br">www.engemap.com.br</a> <br/>' +
      '			<label style="color:gray">Rua Santos Dumont, 160</label> <br/>' +
      '			<label style="color:gray">19806-060 - Vila Boa Vista</label> <br/>' +
      '			<label style="color:gray">Assis - SP</label>' +
      '		</td>' +
      '	</tr>' +
      '</table>';

    return assinatura;
  }

  public static String getLogoEngemapVertical() {
    return 'data:image/png;base64,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';
  }

  public static String getLogoEngemapVerticalNegativo() {
    return 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQoAAACzCAMAAABGp6LyAAADd3pUWHRSYXcgcHJvZmlsZSB0eXBlIHhtcAAASInFVkuWm0AM3OsUOUIjdUtwHGxgl/eyzPFTpR7bgD3OTDYxDxv3p1QqfRr5/fOX/MBnqM3ErrbFGMUHN794i6rF1ZuHT77aorpul8tlU8X45JUjLazVxUpdolTD2tEnqWPMgY3NYq5rq45fAJphk6pttmqxa4w2x+jY6AuN+aCF//3qaxjnhBbApvpGHjb3ifvyZPKAwdiFO+p9h5Y21qUVUZLbIods0tWKLuBTeGEkOIZNg/EOmGpwxfWKOTXeqpsNNgh++GfBHzCxhskZd2g5XfrhpALWbW5aa/WHg5Ie9kk6OUbFBTA4tUV+dA0sAi/yjrQ/8cJTST5JRDqILmGBKFGXGOEclOL8kQUoIGAIh/qUek3QCSs4L1wAsRX2IC9ZdXn3EaHMz3zT2HoLlEDkFRm0+QJXRvApJJ+ib2dIbLEXAhRQAND14T0X4rthY2MC0FVY7cDDMzCyasReMAqTfPwr8QPv3fa+m6bktRNdl7qgEL5oQl5pA8DlBbhFrS28h+QMLp86cAJnnQaCjjVb00wDxlmxvhFeuqTMmW6fNiozpQGIOmijkc2vTzV20EpSLNYMmBlaiKIEs6X09MxFOn1iptXaf20RZO+t+NBhkPgLn1tFIaAX4Nuz9ixnLZ/LAXZxps2EzI7pgXuH7Rs1YS1hI2EJZR9GD7Byx83+4x1y+D60nLGzDGb3zPaFcBnsic9ovy0TckUdkMeLzJ7Z3pAx2P7hdWezi2am51wZBEv2a4YewnCl9EXInylbOzqBwcFkydZLh0Y6k2FAJ0MnYptRcG6ozHyykW2kGuKJYbZXTp0ZMG8s7kV8Y3AnUDsBgX1gA2oArtIa7AKW1oyS4k5WHGx9DOuqwS1wVhLAzCRPDCjy1E816HD9H4xuR+COFU7OjAzYxXQ6PQAQw3EM0QZQ2bUHdm+7NfXMn11d8eQ9rd6lguxz4ZwK33Fb3vl9ZhCB9G2d67nU5Yu1vodjDeAJsAMdr1k6wpC+b1lf61jMo+05Bu9DgK1D+FF+edb/nfyfV6K8L8WXlfhSfvnnnniSX571/4b8NY/ylF8+OTH2UnMrtaOR/r6yPUKkWw+SHKsnD8a3NXfbeH5bkntYT8v6q90D/vxW22cer9Zyf7eGNp04+zpfi+UPHkqlXiQxDpgAAAAJcEhZcwAAFxEAABcRAcom8z8AAAMAUExURUdwTP///////////wGz3P///////////////////////////////////////////////////////////wCz3ACz3ACz3ACz3ACx2wCz3ACw2wCz3ACz3ACz3ACz3ACz3P///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////wCz3ACz3P///wCz3P///wCz3ACz3P///////wCz3P///////////////////////wCz3ACz3ACz3ACz3ACz3ACz3P///wCz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3AGz3QCz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3ACz3JHf8LHo9DvF5Nbz+f///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////wCz3ACz3P///////////////////////////////////////////////////////////////wCz3P///////////////8YwAHMAAAEAdFJOUwACAwgsCTkfe7cFEQcLDhMb2xw46f/Pj5BoZVuWEewvDA8ZRzTvRRZ0HrUhoLkk45KQ92MiYvwNIz9n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';
  }

  // Retorna verdadeira se a instância estiver rodando em uma sandbox.
  public static boolean isSandbox() {
    return isSandboxx;
  }

  // Retorna uma lista contendo todos os campos de um SObject
  public static List<String> getFieldsList(String sobj) {
    List<String> fields = new List<String>{ 'Id' };
    Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe()
      .get(sobj)
      .getDescribe()
      .fields.getMap();
    for (Schema.SObjectField sfield : fieldsMap.values()) {
      Schema.DescribeFieldResult field = sfield.getDescribe();
      // Se for um campo customizado, então o adiciona na lista.
      if (field.isCustom())
        fields.add(field.getName());
    }
    return fields;
  }

  // Retorna um string contendo todos os campos de um SObject separados por virgula
  public static String getFields(String sobj) {
    String fields = 'Id';
    Map<String, Schema.SObjectField> fieldsMap = Schema.getGlobalDescribe()
      .get(sobj)
      .getDescribe()
      .fields.getMap();
    for (Schema.SObjectField sfield : fieldsMap.values()) {
      Schema.DescribeFieldResult field = sfield.getDescribe();
      // Se for um campo customizado, então o adiciona na lista.
      if (field.isCustom())
        fields += ', ' + field.getName();
    }
    return fields;
  }

  public static Boolean isIdFromObject(Id id, String objectApiName) {
    // Get prefix via describe
    Schema.SObjectType sObjectType = Schema.getGlobalDescribe()
      .get(objectApiName);
    if (sObjectType == null)
      return false;

    String expectedPrefix = sObjectType.getDescribe().getKeyPrefix();
    return id != null && String.valueOf(id).startsWith(expectedPrefix);
  }

  public static String getDayName(Date dateParam) {
    return Datetime.newInstance(
        dateParam.year(),
        dateParam.month(),
        dateParam.day()
      )
      .format('EEE');
  }

  public static Long getRecurringHolidayKey(Date dateParam) {
    return Datetime.newInstance(1970, dateParam.month(), dateParam.day())
      .getTime();
  }

  public static Long getSpecificHolidayKey(Date dateParam) {
    return Datetime.newInstance(
        dateParam.year(),
        dateParam.month(),
        dateParam.day()
      )
      .getTime();
  }

  public static Boolean verificarSobreposicaoDatas(
    Date inicio1,
    Date fim1,
    Date inicio2,
    Date fim2
  ) {
    // Verifica se há sobreposição entre dois períodos
    return (inicio1 <= inicio2 &&
      fim1 >= inicio2) || // início2 está dentro do período 1
      (inicio1 <= fim2 &&
      fim1 >= fim2) || // fim2 está dentro do período 1
      (inicio1 >= inicio2 &&
      fim1 <= fim2); // período 1 está totalmente dentro do período 2
  }

  public static String formatarNome(String nomeCompleto) {
    if (String.isBlank(nomeCompleto))
      return nomeCompleto;

    Set<String> minusculas = new Set<String>{
      'da',
      'de',
      'do',
      'das',
      'dos',
      'e'
    };
    List<String> partes = nomeCompleto.toLowerCase().split(' ');
    List<String> resultado = new List<String>();

    for (String palavra : partes) {
      if (minusculas.contains(palavra)) {
        resultado.add(palavra);
      } else if (palavra.length() > 0) {
        String formatada =
          palavra.substring(0, 1).toUpperCase() + palavra.substring(1);
        resultado.add(formatada);
      }
    }

    return String.join(resultado, ' ');
  }

  public static String getTelefoneFormatadoSimples(String numero) {
    if (String.isBlank(numero))
      return '';

    // Remove tudo que não for dígito
    String digits = numero.replaceAll('[^0-9]', '');

    // Remove o 0 inicial de discagem interurbana (ex: 011, 018)
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    Integer len = digits.length();

    // Esperado: 10 dígitos (DDD + fixo 8) ou 11 dígitos (DDD + celular 9)
    if (len == 10) {
      // Fixo: DDD (2) + número (8)
      String ddd = digits.substring(0, 2);
      String telNum = digits.substring(2);
      return ddd + ' ' + telNum;
    } else if (len == 11) {
      // Celular: DDD (2) + número (9)
      String ddd = digits.substring(0, 2);
      String telNum = digits.substring(2);
      return ddd + ' ' + telNum;
    } else {
      // Tamanho inesperado — retorna apenas os dígitos limpos
      return digits;
    }
  }
}