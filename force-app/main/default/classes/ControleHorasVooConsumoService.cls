/**
 * Consolida consumo de combustível, horas de voo e custo por aeronave, mês e
 * tipo de voo para a aba "Consumo e Emissões" do Controle de Horas.
 *
 * O portal autentica fora do Salesforce, então a leitura é elevada
 * (without sharing + SYSTEM_MODE) e só é alcançada depois que o endpoint valida
 * o token de sessão e a participação no grupo Aerolevantamento.
 *
 * O consumo vem de Abastecimento__c.Quantidade__c (litros) atribuído ao mês e
 * ao tipo do voo ao qual o abastecimento pertence. O campo legado
 * Controle_Horas_Voo__c.Litros_AVGAS__c não é usado: ele só reflete a
 * sincronização inicial e fica defasado.
 */
public without sharing class ControleHorasVooConsumoService {
    /** Fator de emissão adotado na planilha de índice ambiental (kg CO2 por litro). */
    public static final Decimal FATOR_CO2_KG_POR_LITRO = 2.31;

    public static Response responder(String accessToken) {
        Response resposta = new Response();
        try {
            if (!ControleHorasVooReportController.isSessionTokenValid(accessToken)) {
                resposta.message =
                    'Sua sessão não permite consultar o consumo. Atualize a página e tente novamente.';
                return resposta;
            }
            resposta.data = carregar();
            resposta.success = true;
        } catch (Exception erro) {
            System.debug(
                LoggingLevel.ERROR,
                'Erro ao carregar consumo de combustível: ' +
                erro.getMessage() + '\n' + erro.getStackTraceString()
            );
            resposta.message =
                'Não foi possível carregar o consumo de combustível. Tente novamente.';
        }
        return resposta;
    }

    public static ConsumoResult carregar() {
        Map<String, Linha> linhasPorChave = new Map<String, Linha>();

        for (AggregateResult agregado : [
            SELECT Aeronave__r.Name aeronave,
                   CALENDAR_YEAR(Data_do_Voo__c) ano,
                   CALENDAR_MONTH(Data_do_Voo__c) mes,
                   Tipo__c tipo,
                   SUM(Horas_Voo__c) horas
            FROM Controle_Horas_Voo__c
            WHERE Aeronave__c != null AND Data_do_Voo__c != null
            WITH SYSTEM_MODE
            GROUP BY Aeronave__r.Name,
                     CALENDAR_YEAR(Data_do_Voo__c),
                     CALENDAR_MONTH(Data_do_Voo__c),
                     Tipo__c
        ]) {
            obterLinha(linhasPorChave, agregado).horas = decimalOuZero(agregado, 'horas');
        }

        for (AggregateResult agregado : [
            SELECT Voo__r.Aeronave__r.Name aeronave,
                   CALENDAR_YEAR(Voo__r.Data_do_Voo__c) ano,
                   CALENDAR_MONTH(Voo__r.Data_do_Voo__c) mes,
                   Voo__r.Tipo__c tipo,
                   SUM(Quantidade__c) litros
            FROM Abastecimento__c
            WHERE Voo__r.Aeronave__c != null AND Voo__r.Data_do_Voo__c != null
            WITH SYSTEM_MODE
            GROUP BY Voo__r.Aeronave__r.Name,
                     CALENDAR_YEAR(Voo__r.Data_do_Voo__c),
                     CALENDAR_MONTH(Voo__r.Data_do_Voo__c),
                     Voo__r.Tipo__c
        ]) {
            obterLinha(linhasPorChave, agregado).litros = decimalOuZero(agregado, 'litros');
        }

        // O preço médio só considera abastecimentos que têm custo informado;
        // contar os demais como R$ 0 puxaria a média para baixo.
        for (AggregateResult agregado : [
            SELECT Voo__r.Aeronave__r.Name aeronave,
                   CALENDAR_YEAR(Voo__r.Data_do_Voo__c) ano,
                   CALENDAR_MONTH(Voo__r.Data_do_Voo__c) mes,
                   Voo__r.Tipo__c tipo,
                   SUM(Quantidade__c) litrosComCusto,
                   SUM(Custo_Total__c) custo
            FROM Abastecimento__c
            WHERE Voo__r.Aeronave__c != null
              AND Voo__r.Data_do_Voo__c != null
              AND Quantidade__c > 0
              AND Custo_Total__c > 0
            WITH SYSTEM_MODE
            GROUP BY Voo__r.Aeronave__r.Name,
                     CALENDAR_YEAR(Voo__r.Data_do_Voo__c),
                     CALENDAR_MONTH(Voo__r.Data_do_Voo__c),
                     Voo__r.Tipo__c
        ]) {
            Linha linha = obterLinha(linhasPorChave, agregado);
            linha.litrosComCusto = decimalOuZero(agregado, 'litrosComCusto');
            linha.custo = decimalOuZero(agregado, 'custo');
        }

        List<Linha> linhas = linhasPorChave.values();
        linhas.sort();

        ConsumoResult resultado = new ConsumoResult();
        resultado.linhas = linhas;
        resultado.fatorCo2 = FATOR_CO2_KG_POR_LITRO;
        resultado.geradoEm = Datetime.now();
        resultado.aeronaves = new List<AeronaveInfo>();
        for (Aeronave__c aeronave : [
            SELECT Name, Ativo__c, Modelo__c
            FROM Aeronave__c
            WITH SYSTEM_MODE
            ORDER BY Name
        ]) {
            resultado.aeronaves.add(new AeronaveInfo(aeronave));
        }
        return resultado;
    }

    private static Linha obterLinha(
        Map<String, Linha> linhasPorChave,
        AggregateResult agregado
    ) {
        String aeronave = (String) agregado.get('aeronave');
        Integer ano = (Integer) agregado.get('ano');
        Integer mes = (Integer) agregado.get('mes');
        String tipo = (String) agregado.get('tipo');
        String chave = aeronave + '|' + ano + '|' + mes + '|' + tipo;
        Linha linha = linhasPorChave.get(chave);
        if (linha == null) {
            linha = new Linha(aeronave, ano, mes, tipo);
            linhasPorChave.put(chave, linha);
        }
        return linha;
    }

    private static Decimal decimalOuZero(AggregateResult agregado, String alias) {
        Object valor = agregado.get(alias);
        return valor == null ? 0 : (Decimal) valor;
    }

    public class Linha implements Comparable {
        public String aeronave { get; set; }
        public Integer ano { get; set; }
        public Integer mes { get; set; }
        public String tipo { get; set; }
        public Decimal horas { get; set; }
        public Decimal litros { get; set; }
        public Decimal litrosComCusto { get; set; }
        public Decimal custo { get; set; }

        public Linha(String aeronave, Integer ano, Integer mes, String tipo) {
            this.aeronave = aeronave;
            this.ano = ano;
            this.mes = mes;
            this.tipo = tipo;
            this.horas = 0;
            this.litros = 0;
            this.litrosComCusto = 0;
            this.custo = 0;
        }

        public Integer compareTo(Object outro) {
            Linha comparada = (Linha) outro;
            if (aeronave != comparada.aeronave) {
                return aeronave > comparada.aeronave ? 1 : -1;
            }
            if (ano != comparada.ano) {
                return ano > comparada.ano ? 1 : -1;
            }
            if (mes != comparada.mes) {
                return mes > comparada.mes ? 1 : -1;
            }
            String tipoAtual = tipo == null ? '' : tipo;
            String tipoComparado = comparada.tipo == null ? '' : comparada.tipo;
            return tipoAtual.compareTo(tipoComparado);
        }
    }

    public class AeronaveInfo {
        public String nome { get; set; }
        public Boolean ativa { get; set; }
        public String modelo { get; set; }

        public AeronaveInfo(Aeronave__c aeronave) {
            this.nome = aeronave.Name;
            this.ativa = aeronave.Ativo__c == true;
            this.modelo = aeronave.Modelo__c;
        }
    }

    public class ConsumoResult {
        public List<Linha> linhas { get; set; }
        public List<AeronaveInfo> aeronaves { get; set; }
        public Decimal fatorCo2 { get; set; }
        public Datetime geradoEm { get; set; }
    }

    public class Response {
        public Boolean success { get; set; }
        public String message { get; set; }
        public ConsumoResult data { get; set; }

        public Response() {
            success = false;
            message = '';
        }
    }
}
