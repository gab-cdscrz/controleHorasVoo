@isTest
public class TestDataStatic {
  public static Fase_do_orcamento__c getFase(String nome, Decimal nivel) {
    for (Fase_do_orcamento__c fase : fasesDoOrcamento) {
      if (fase.Name == nome && fase.Nivel__c == nivel) {
        return fase;
      }
    }

    for (Fase_do_orcamento__c fase : fasesDoOrcamento1) {
      if (fase.Name == nome && fase.Nivel__c == nivel) {
        return fase;
      }
    }

    for (Fase_do_orcamento__c fase : fasesDoOrcamento2) {
      if (fase.Name == nome && fase.Nivel__c == nivel) {
        return fase;
      }
    }
    return null;
  }

  private static void configurarTarefaParada() {
    TestUtils.instance(new List<Object>{ fapEngemap, tarefaParada });
  }

  // Default Object
  public static Account conta {
    get {
      if (conta == null) {
        conta = new Account(
          Name = 'Conta teste',
          Type = 'Tipo teste',
          contaCNPJ__c = '90.900.900/9000-99'
        );
        insert conta;
      }
      return conta;
    }
    set;
  }

  public static Aditivo_de_Projeto__c aditivo {
    get {
      if (aditivo == null) {
        aditivo = new Aditivo_de_Projeto__c(
          FAP__c = fap.Id,
          Data__c = date.today(),
          Valor__c = 1000
        );
        insert aditivo;
        update aditivo;
      }
      return aditivo;
    }
    set;
  }

  public static Afastamento__c afastamento {
    get {
      if (afastamento == null) {
        afastamento = new Afastamento__c(
          Empregado__c = empregado.Id,
          Tipo__c = 'Teste',
          Data_inicial__c = Date.today().addDays(5),
          Data_final__c = Date.today().addDays(15)
        );
        insert afastamento;
      }
      return afastamento;
    }
    set;
  }

  public static Afastamento__c afastamentoHoje {
    get {
      if (afastamentoHoje == null) {
        afastamentoHoje = new Afastamento__c(
          Empregado__c = empregado.Id,
          Tipo__c = 'Teste',
          Data_inicial__c = Date.today(),
          Data_final__c = Date.today().addDays(2)
        );
        insert afastamentoHoje;
      }
      return afastamentoHoje;
    }
    set;
  }

  private static AlertaAgendado__c alertaAgendadoValue;
  public static AlertaAgendado__c alertaAgendado {
    get {
      if (alertaAgendadoValue == null) {
        AlertaAgendado__c alerta = new AlertaAgendado__c();
        alerta.Data__c = Date.today();
        alerta.Tipo__c = 'Vencimento da FAP';
        alerta.FAP__c = fap.Id;
        insert alerta;
      }
      return alertaAgendadoValue;
    }
    private set;
  }

  private static Apontamento_Colaborador__c apontamentoValue;
  public static Apontamento_Colaborador__c apontamento {
    get {
      if (apontamentoValue == null) {
        apontamentoValue = new Apontamento_Colaborador__c(
          Data__c = Date.today(),
          Empregado__c = empregado.Id,
          FAP__c = fap.Id,
          Hora_de_producao__c = false,
          Horario_inicial__c = '08:00',
          Horario_final__c = '12:00',
          Tarefa_Realizada_do_Produto__c = tarefaRealizada.Id,
          Recurso_disponivel__c = recursoDisponivel.Id,
          Motivo__c = '',
          Observacao__c = '',
          Observacao_da_rejeicao__c = '',
          Produtividade__c = '',
          Retrabalho__c = false,
          Status__c = 'Aguardando aprovação',
          Tipo__c = 'Produtivo',
          Unidade_de_medida__c = ''
        );
        Contrato_de_trabalho__c contrato = contratoEmpregado; // forçar inicialização do contrato
        insert apontamentoValue;
      }
      return apontamentoValue;
    }
    private set;
  }

  private static Apontamento_Colaborador__c apontamentoSabadoValue;
  public static Apontamento_Colaborador__c apontamentoSabado {
    get {
      if (apontamentoSabadoValue == null) {
        apontamentoSabadoValue = new Apontamento_Colaborador__c(
          Data__c = getNextSaturday(),
          Empregado__c = empregado.Id,
          Fap__c = fap.Id,
          Horario_final__c = '16:48',
          Horario_inicial__c = '08:00',
          Status__c = 'Aguardando aprovação',
          Tarefa_Realizada_do_Produto__c = tarefaRealizada.Id,
          Tipo__c = 'Produtivo'
        );
        insert apontamentoSabadoValue;
      }
      return apontamentoSabadoValue;
    }
    private set;
  }

  private static Apontamento_Colaborador__c apontamentoColabValue;
  public static Apontamento_Colaborador__c apontamentoColab {
    get {
      if (apontamentoColabValue == null) {
        apontamentoColabValue = new Apontamento_Colaborador__c(
          Data__c = Date.today(),
          Empregado__c = empregadoApontador.Id,
          Fap__c = fap.Id,
          Horario_final__c = '16:48',
          Horario_inicial__c = '08:00',
          Status__c = 'Aguardando aprovação',
          Tarefa_Realizada_do_Produto__c = tarefaRealizada.Id,
          Tipo__c = 'Produtivo'
        );
        insert apontamentoColabValue;
      }
      return apontamentoColabValue;
    }
    private set;
  }

  public static AT_Ordem_de_Servico__c os {
    get {
      if (os == null) {
        os = new AT_Ordem_de_Servico__c();
        insert os;
      }
      return os;
    }
    set;
  }

  public static Attachment anexoAttachment {
    get {
      if (anexoAttachment == null) {
        anexoAttachment = new Attachment(
          Name = 'Teste Anexo',
          Body = Blob.valueof('Teste Anexo'),
          Description = 'Observação do Teste de Anexo',
          parentId = anexos.get(0).Id
        );
        insert anexoAttachment;
      }
      return anexoAttachment;
    }
    set;
  }

  public static Attachment anexoEngC {
    get {
      if (anexoEngC == null) {
        anexoEngC = new Attachment(
          Name = 'Teste',
          Body = Blob.valueof('Teste'),
          Description = 'Teste',
          parentId = engc.Id
        );
        insert anexoEngC;
      }
      return anexoEngC;
    }
    set;
  }

  private static Attachment anexoPtValue;
  public static Attachment anexoPT { // anexo plano de trabalho
    get {
      if (anexoPtValue == null) {
        anexoPtValue = new Attachment(
          Name = 'Teste',
          Body = Blob.valueof('Teste'),
          Description = 'Teste',
          parentId = planoTrabalho.Id
        );
        insert anexoPtValue;
      }
      return anexoPtValue;
    }
    private set;
  }

  public static Attachment cnhMotorista {
    get {
      if (cnhMotorista == null) {
        cnhMotorista = new Attachment(
          Name = 'CNH do motorista',
          Body = Blob.valueof('CNH do motorista'),
          Description = 'CNH do motorista',
          parentId = engc.Id
        );
        insert cnhMotorista;
      }
      return cnhMotorista;
    }
    set;
  }

  public static Avaliacao_fornecedores_servicos__c avaliacaoFS {
    get {
      if (avaliacaoFS == null) {
        avaliacaoFS = new Avaliacao_fornecedores_servicos__c(
          Fornecedor__c = fornecedor.Id,
          FAP__c = fap.Id,
          Produto__c = produto.Id,
          Servico_entregue__c = true,
          Departamento__c = 'Aerolevantamento',
          Qtde_previsto__c = 1.0,
          Qtde_realizado__c = 1.0,
          Prazo_previsto__c = 1.0,
          Prazo_realizado__c = 1.0
        );
        insert avaliacaoFS;
      }
      return avaliacaoFS;
    }
    set;
  }

  public static Avaliacao_riscos__c avaliacao {
    get {
      if (avaliacao == null) {
        avaliacao = new Avaliacao_riscos__c(
          Acao__c = 'Assumir',
          Categoria__c = 'Organizacional',
          Ate__c = 'Fechamento de semestre',
          Tipo__c = 'Risco',
          Descricao__c = 'Teste',
          Descricao_da_acao__c = 'Teste',
          Descricao_do_impacto__c = 'Teste',
          Empregado__c = empregado.Id,
          Mapeamento_de_indicadores__c = mapeamento.Id,
          Tipo_do_Risco__c = 'Comum',
          Consequencia__c = 5,
          Probabilidade__c = 5
        );

        insert avaliacao;
      }
      return avaliacao;
    }
    set;
  }

  public static Avaliacao_riscos__c avaliacaoAmbiental {
    get {
      if (avaliacaoAmbiental == null) {
        avaliacaoAmbiental = new Avaliacao_riscos__c(
          Acao__c = 'Assumir',
          Categoria__c = 'Organizacional',
          Ate__c = 'Fechamento de semestre',
          Tipo__c = 'Risco',
          Descricao__c = 'Teste',
          Descricao_da_acao__c = 'Teste',
          Descricao_do_impacto__c = 'Teste',
          Empregado__c = empregado.Id,
          Mapeamento_de_indicadores__c = mapeamento.Id,
          Tipo_do_Risco__c = 'Ambiental',
          Consequencia__c = 5,
          Probabilidade__c = 5,
          Frequencia__c = 2
        );

        insert avaliacaoAmbiental;
      }
      return avaliacaoAmbiental;
    }
    set;
  }

  public static Bloco_Projeto__c bloco {
    get {
      if (bloco == null) {
        bloco = new Bloco_Projeto__c(
          Name = 'Bloco teste',
          Planejamento_Projeto__c = planejamento.Id
        );
        insert bloco;
      }
      return bloco;
    }
    set;
  }

  public static Centro_de_Custo__c cc {
    get {
      if (cc == null) {
        cc = new Centro_de_Custo__c(
          Name = 'Centro Teste',
          Percentual_efetividade_producao__c = 85
        );
        insert cc;
      }
      return cc;
    }
    set;
  }

  public static Checklist_Aerolevantamento__c checkAero {
    get {
      if (checkAero == null) {
        checkAero = new Checklist_aerolevantamento__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo'
        );
        insert checkAero;
      }
      return checkAero;
    }
    set;
  }

  public static Checklist_aerotriangulacao__c checkAerotri {
    get {
      if (checkAerotri == null) {
        checkAerotri = new Checklist_aerotriangulacao__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Saida_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo',
          Saida_localizacao__c = 'HD Externo'
        );
        insert checkAerotri;
      }
      return checkAerotri;
    }
    set;
  }

  public static Checklist_edicao__c checkEdicao {
    get {
      if (checkEdicao == null) {
        checkEdicao = new Checklist_edicao__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Saida_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo',
          Saida_localizacao__c = 'HD Externo'
        );
        insert checkEdicao;
      }
      return checkEdicao;
    }
    set;
  }

  public static Checklist_engenharia__c checkEnge {
    get {
      if (checkEnge == null) {
        checkEnge = new Checklist_engenharia__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Saida_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo',
          Saida_localizacao__c = 'HD Externo'
        );
        insert checkEnge;
      }
      return checkEnge;
    }
    set;
  }

  public static Checklist_gestao__c checkGestao {
    get {
      if (checkGestao == null) {
        checkGestao = new Checklist_gestao__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Saida_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo',
          Saida_localizacao__c = 'HD Externo'
        );
        insert checkGestao;
      }
      return checkGestao;
    }
    set;
  }

  public static Checklist_Laser__c checkLaser {
    get {
      if (checkLaser == null) {
        checkLaser = new Checklist_laser__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Saida_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo',
          Saida_localizacao__c = 'HD Externo'
        );
        insert checkLaser;
      }
      return checkLaser;
    }
    set;
  }

  public static Checklist_linhas__c checkLinhas {
    get {
      if (checkLinhas == null) {
        checkLinhas = new Checklist_linhas__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Saida_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo',
          Saida_localizacao__c = 'HD Externo'
        );
        insert checkLinhas;
      }
      return checkLinhas;
    }
    set;
  }

  public static Checklist_pdi__c checkPdi {
    get {
      if (checkPdi == null) {
        checkPdi = new Checklist_pdi__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Saida_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo',
          Saida_localizacao__c = 'HD Externo'
        );
        insert checkPdi;
      }
      return checkPdi;
    }
    set;
  }

  public static Checklist_restituicao__c checkRest {
    get {
      if (checkRest == null) {
        checkRest = new Checklist_restituicao__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Saida_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo',
          Saida_localizacao__c = 'HD Externo'
        );
        insert checkRest;
      }
      return checkRest;
    }
    set;
  }

  public static Checklist_solucoes__c checkSolu {
    get {
      if (checkSolu == null) {
        checkSolu = new Checklist_solucoes__c(
          Entrada_data_preenchimento__c = Date.TODAY(),
          Saida_data_preenchimento__c = Date.TODAY(),
          Grupo_checklist__c = grupoCheck.Id,
          Entrada_localizacao__c = 'HD Externo',
          Saida_localizacao__c = 'HD Externo'
        );
        insert checkSolu;
      }
      return checkSolu;
    }
    set;
  }

  private static Colaborador_do_Projeto__c colaboradorValue;
  public static Colaborador_do_Projeto__c colaborador {
    get {
      if (colaboradorValue == null) {
        colaboradorValue = new Colaborador_do_Projeto__c(
          Plano_de_trabalho__c = planoTrabalho.Id,
          Empregado__c = empregado.Id,
          Principal__c = true
        );
        insert colaboradorValue;
      }
      return colaboradorValue;
    }
    private set;
  }

  public static Contact contato {
    get {
      if (contato == null) {
        contato = new Contact(
          AccountId = conta.Id,
          LastName = 'Teste',
          Email = 'teste@teste.com.br',
          Login__c = login.Id
        );
        insert contato;
      }
      return contato;
    }
    set;
  }

  private static Contact outroContatoValue;
  public static Contact outroContato {
    get {
      if (outroContatoValue == null) {
        outroContatoValue = new Contact(
          AccountId = conta.Id,
          FirstName = 'Outro',
          LastName = 'Test',
          Email = 'outrotest@teste.com.br'
        );
        insert outroContatoValue;
      }
      return outroContatoValue;
    }
    private set;
  }

  private static Contrato_de_trabalho__c contratoPjEmpregadoValue;
  public static Contrato_de_trabalho__c contratoPjEmpregado {
    get {
      if (contratoPjEmpregadoValue == null) {
        contratoPjEmpregadoValue = new Contrato_de_trabalho__c(
          CNAE_Principal__c = '12345 - CNAE Test',
          CNAE_Secundario__c = '43847 - CNAE Test 2, 85769 - CNAE Test 3',
          CNPJ__c = '1254888000130',
          Data_de_inicio__c = Date.today().addDays(-10),
          Empregado__c = empregadoApontador.Id,
          Empresa__c = empresa.Id,
          Inscricao_estadual__c = '12344',
          Inscricao_municipal__c = '33334',
          Razao_social__c = 'Empregado Mei 123',
          Salario_base__c = 2500,
          Status__c = 'Ativo',
          Tipo__c = 'PJ'
        );

        insert contratoPjEmpregadoValue;
      }
      return contratoPjEmpregadoValue;
    }
    private set;
  }

  private static Contrato_de_trabalho__c contratoCltEmpregadoValue;
  public static Contrato_de_trabalho__c contratoCltEmpregado {
    get {
      if (contratoCltEmpregadoValue == null) {
        contratoCltEmpregadoValue = new Contrato_de_trabalho__c(
          Data_de_inicio__c = Date.today().addDays(-8),
          Empregado__c = empregadoApontador.Id,
          Empresa__c = empresa.Id,
          Salario_base__c = 2500,
          Status__c = 'Ativo',
          Tipo__c = 'CLT'
        );

        insert contratoCltEmpregadoValue;
      }
      return contratoCltEmpregadoValue;
    }
    private set;
  }

  private static Contrato_de_trabalho__c contratoEmpregadoValue;
  public static Contrato_de_trabalho__c contratoEmpregado {
    get {
      if (contratoEmpregadoValue == null) {
        contratoEmpregadoValue = new Contrato_de_trabalho__c(
          Data_de_inicio__c = Date.today().addDays(-8),
          Empregado__c = empregado.Id,
          Empresa__c = empresa.Id,
          Salario_base__c = 1000,
          Status__c = 'Ativo',
          Tipo__c = 'CLT'
        );
        insert contratoEmpregadoValue;
      }
      return contratoEmpregadoValue;
    }
    private set;
  }

  private static OpportunityContactRole oppContactRoleValue;
  public static OpportunityContactRole oppContactRole {
    get {
      if (oppContactRoleValue == null) {
        oppContactRoleValue = new OpportunityContactRole(
          OpportunityId = op.Id,
          ContactId = outroContato.Id,
          Role = 'Usuário empresarial'
        );
        insert oppContactRoleValue;
      }
      return oppContactRoleValue;
    }
    private set;
  }

  public static ContentVersion cnhEmpregadoContentVersion {
    get {
      if (cnhEmpregadoContentVersion == null) {
        Blob fileBody = Blob.valueOf('Isto é um texto de teste.');
        String fileName = 'arquivo_de_teste.txt';
        cnhEmpregadoContentVersion = new ContentVersion(
          VersionData = fileBody,
          Title = fileName,
          PathOnClient = fileName,
          FirstPublishLocationId = empregado.Id
        );
        insert cnhEmpregadoContentVersion;

        // Reconsultar para obter o ContentDocumentId
        cnhEmpregadoContentVersion = [
          SELECT
            Id,
            ContentDocumentId,
            VersionData,
            Title,
            PathOnClient,
            FirstPublishLocationId
          FROM ContentVersion
          WHERE Id = :cnhEmpregadoContentVersion.Id
        ];
      }
      return cnhEmpregadoContentVersion;
    }
    set;
  }

  private static Cronograma_Projeto__c cronogramaValue;
  public static Cronograma_Projeto__c cronograma {
    get {
      if (cronogramaValue == null) {
        Id planejamentoId = planejamento.Id;
        cronogramaValue = [
          SELECT Id, Versao__c, Planejamento_projeto__c
          FROM Cronograma_Projeto__c
          WHERE Planejamento_projeto__c = :planejamentoId
        ]; //select porque ao criar um planejamento se cria 1 cronograma, 1 previsao de despesa e 1 previsao de receita
      }
      return cronogramaValue;
    }
    private set;
  }

  private static Cronograma_Manual__c cronogramaManualValue;
  public static Cronograma_Manual__c cronogramaManual {
    get {
      if (cronogramaManualValue == null) {
        Id planejamentoId = planejamentoManual.Id;
        cronogramaManualValue = new Cronograma_Manual__c(
          Planejamento_do_Projeto__c = planejamentoId
        );
        insert cronogramaManualValue;
      }
      return cronogramaManualValue;
    }
    private set;
  }

  private static Item_Previsao_Manual__c itemPrevisaoManualValue;
  public static Item_Previsao_Manual__c itemPrevisaoManual {
    get {
      if (itemPrevisaoManualValue == null) {
        itemPrevisaoManualValue = new Item_Previsao_Manual__c(
          Cronograma_Manual__c = cronogramaManual.Id,
          Data_Final__c = Date.today().addDays(30),
          Data_Inicial__c = Date.today(),
          Producao__c = 12,
          Horas__c = 10,
          Tarefa__c = 'teste',
          Unidade_de_medida__c = 'un'
        );
        insert itemPrevisaoManualValue;
      }
      return itemPrevisaoManualValue;
    }
    private set;
  }

  private static Item_Realizado_Manual__c itemRealizadoManualValue;
  public static Item_Realizado_Manual__c itemRealizadoManual {
    get {
      if (itemRealizadoManualValue == null) {
        itemRealizadoManualValue = new Item_Realizado_Manual__c(
          Data__c = Date.today().addDays(30),
          Hora_Final__c = '08:00',
          Hora_Inicial__c = '12:00',
          Item_Previsao_Manual__c = itemPrevisaoManual.Id,
          Producao__c = 12,
          Quantidade_de_horas__c = 10
        );
        insert itemRealizadoManualValue;
      }
      return itemRealizadoManualValue;
    }
    private set;
  }

  public static Despesa_de_revisao__c despRev {
    get {
      if (despRev == null) {
        Despesa_Projeto__c desp = new Despesa_Projeto__c(
          Id = despesasProj[0].Id,
          isEmRevisao__c = true,
          Gerente_Revisao__c = 'Gerente teste'
        );

        update desp;

        despRev = [
          SELECT Id
          FROM Despesa_de_revisao__c
          WHERE Despesa_Projeto__c = :desp.Id
        ];
      }
      return despRev;
    }
    set;
  }

  public static Despesa_orcada__c despOrcada {
    get {
      if (despOrcada == null) {
        despOrcada = new Despesa_orcada__c(
          Oportunidade__c = op.Id,
          Name = 'Teste'
        );
        insert despOrcada;
      }
      return despOrcada;
    }
    set;
  }

  public static Dependente__c dependente {
    get {
      if (dependente == null) {
        dependente = new Dependente__c(
          Name = 'Dependente Teste',
          Data_de_nascimento__c = Date.today().addDays(-60),
          Empregado__c = empregado.Id,
          Tipo__c = 'Filho(a) ou enteado(a)'
        );

        insert dependente;
      }
      return dependente;
    }
    set;
  }

  public static List<Beneficios__c> beneficios {
    get {
      if (beneficios == null) {
        beneficios = new List<Beneficios__c>();

        Beneficios__c valeTransporte = new Beneficios__c(
          Funcionario__c = empregado.Id,
          Quantidade__c = 1,
          Tipo_do_Beneficio__c = 'Vale transporte',
          Valor_Unitario__c = 50
        );
        Beneficios__c valeRefeicao = new Beneficios__c(
          Funcionario__c = empregado.Id,
          Quantidade__c = 1,
          Tipo_do_Beneficio__c = 'Vale refeição',
          Valor_Unitario__c = 50
        );
        Beneficios__c seguroVida = new Beneficios__c(
          Funcionario__c = empregado.Id,
          Quantidade__c = 1,
          Tipo_do_Beneficio__c = 'Seguro de vida',
          Valor_Unitario__c = 50
        );

        beneficios.add(valeTransporte);
        beneficios.add(valeRefeicao);
        beneficios.add(seguroVida);
        insert beneficios;
      }
      return beneficios;
    }
    set;
  }

  public static List<Despesa_Projeto__c> despesasProj {
    get {
      if (despesasProj == null) {
        despesasProj = new List<Despesa_Projeto__c>();
        for (Integer i = 0; i < 10; i++) {
          Despesa_Projeto__c despesa = new Despesa_Projeto__c(
            Centro_de_Custo__c = cc.Id,
            Data__c = Date.today(),
            Descricao__c = 'descrição',
            FAP__c = fap.Id,
            Fornecedor__c = fornecedor.Id,
            Historico__c = 'histórico teste',
            Previsao_vinculada__c = null,
            Titulo__c = '00099ee',
            Valor__c = 1100
          );
          despesasProj.add(despesa);
        }
        insert despesasProj;
      }
      return despesasProj;
    }
    set;
  }

  public static List<Receita_Projeto__c> receitasProj {
    get {
      if (receitasProj == null) {
        receitasProj = new List<Receita_Projeto__c>();
        for (Integer i = 0; i < 10; i++) {
          Receita_Projeto__c receita = new Receita_Projeto__c(
            Centro_de_Custo__c = cc.Id,
            Data_da_emissao__c = Date.today(),
            Data_do_vencimento__c = Date.today().addDays(7),
            FAP__c = fap.Id,
            Historico__c = 'histórico teste',
            Numero_da_nota__c = '00099ee',
            Valor__c = 1100
          );
          receitasProj.add(receita);
        }
        insert receitasProj;
      }
      return receitasProj;
    }
    set;
  }

  public static Despesa_Viagem__c despesaViagem {
    get {
      if (despesaViagem == null) {
        despesaViagem = new Despesa_Viagem__c(
          Solicitacao_Viagem__c = frmSolViagem.Id
        );
        insert despesaViagem;
      }
      return despesaViagem;
    }
    set;
  }

  public static Diretoria__c diretoria {
    get {
      if (diretoria == null) {
        diretoria = [
          SELECT Id, Planejamento_do_Projeto__c
          FROM Diretoria__c
          WHERE Planejamento_do_Projeto__c = :planejamento.id
        ];
        //insert diretoria;
      }
      return diretoria;
    }
    set;
  }

  public static Documento_do_Empregado__c cnhEmpregado {
    get {
      if (cnhEmpregado == null) {
        cnhEmpregado = new Documento_do_Empregado__c(
          Classe__c = 'Documentos Pessoais',
          ContentDocumentId__c = cnhEmpregadoContentVersion.ContentDocumentId,
          ContentVersionId__c = cnhEmpregadoContentVersion.id,
          Empregado__c = empregado.Id,
          Extensao_do_arquivo__c = 'PDF',
          Name = 'CNH teste',
          Tipo__c = 'CNH'
        );
        insert cnhEmpregado;
      }
      return cnhEmpregado;
    }
    set;
  }

  public static Empresa__c empresa {
    get {
      if (empresa == null) {
        empresa = new Empresa__c(
          Cnpj__c = '61.027.717/0001-11',
          Name = 'Empresa Teste'
        );
        insert empresa;
      }
      return empresa;
    }
    set;
  }

  private static Empregado__c empregadoValue;
  public static Empregado__c empregado {
    get {
      if (empregadoValue == null) {
        empregadoValue = new Empregado__c(
          Name = 'Empregado teste',
          Funcao__c = funcao.Id,
          Email__c = 'teste@teste.com.br',
          Centro_custo__c = cc.Id,
          Login__c = login.Id,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Turno__c = turno.Id,
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Qtde_horas_semanais__c = 44,
          valor_hora_producao__c = 30,
          Perfil_de_Gerente_de_Projetos__c = true,
          Realiza_apontamentos__c = true,
          Criar_EngC__c = true,
          Redator__c = true,
          Valida_planejamento__c = true,
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id,
          Gerencia_orcamentos__c = true,
          Usuario_salesforce__c = usuario.Id
        );
        insert empregadoValue;
      }
      return empregadoValue;
    }
    private set;
  }

  private static Empregado__c empregadoAprovadorValue;
  public static Empregado__c empregadoAprovador {
    get {
      if (empregadoAprovadorValue == null) {
        empregadoAprovadorValue = new Empregado__c(
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          Centro_custo__c = cc.Id,
          CPF_DadosPessoais__c = '792.195.088-42',
          Criar_EngC__c = true,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Email__c = 'Aprovadorteste@teste.com.br',
          Funcao__c = funcao.Id,
          Gestor_checkbox__c = true,
          Login__c = loginAprovador.Id,
          Name = 'Empregado Aprovador teste',
          Perfil_de_Gerente_de_Projetos__c = true,
          Qtde_horas_semanais__c = 44,
          Realiza_apontamentos__c = true,
          Redator__c = true,
          RG_DadosPessoais__c = '567463328',
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Telefone__c = '1834212525',
          Turno__c = turno.Id,
          Valida_planejamento__c = true,
          valor_hora_producao__c = 30,
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id
        );
        insert empregadoAprovadorValue;
      }
      return empregadoAprovadorValue;
    }
    private set;
  }

  private static Empregado__c empregadoApontadorValue;
  public static Empregado__c empregadoApontador {
    get {
      if (empregadoApontadorValue == null) {
        empregadoApontadorValue = new Empregado__c(
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          Centro_custo__c = cc.Id,
          CPF_DadosPessoais__c = '792.195.088-42',
          Criar_EngC__c = true,
          Data_admissao__c = Date.today().addDays(-150),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Email__c = 'teste@teste.com.br',
          empresa_contratante__c = empresa.Id,
          Funcao__c = funcaoProducao.Id,
          Gestor_do_apontamento__c = empregadoAprovador.Id,
          Login__c = loginApontador.Id,
          Name = 'Empregado Apontador teste',
          Perfil_de_Gerente_de_Projetos__c = true,
          Qtde_horas_semanais__c = 44,
          Realiza_apontamentos__c = true,
          Redator__c = true,
          RG_DadosPessoais__c = '567463328',
          Salario__c = 2500,
          Salario_PJ__c = 0,
          Telefone__c = '1834212525',
          Turno__c = turno.Id,
          Valida_planejamento__c = true,
          valor_hora_producao__c = 30,
          Vencimento_da_CNH__c = Date.today().addDays(250)
        );
        insert empregadoApontadorValue;

        Contrato_de_trabalho__c contrato = contratoPjEmpregado; // forçar inicialização do contrato
      }
      return empregadoApontadorValue;
    }
    private set;
  }

  public static Empregado__c empregadoSuperior {
    get {
      if (empregadoSuperior == null) {
        empregadoSuperior = new Empregado__c(
          Name = 'Empregado Superior teste',
          Funcao__c = funcao.Id,
          Email__c = 'teste@teste.com.br',
          Centro_custo__c = cc.Id,
          Login__c = loginSuperior.Id,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Turno__c = turno.Id,
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Qtde_horas_semanais__c = 44,
          valor_hora_producao__c = 30,
          Perfil_de_Gerente_de_Projetos__c = true,
          Realiza_apontamentos__c = true,
          Criar_EngC__c = true,
          Redator__c = true,
          Valida_planejamento__c = true,
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id
        );
        insert empregadoSuperior;
      }
      return empregadoSuperior;
    }
    set;
  }

  //Empregado Depto pessoal
  public static Empregado__c empregadoDeptoPessoal {
    get {
      if (empregadoDeptoPessoal == null) {
        empregadoDeptoPessoal = new Empregado__c(
          Name = 'Empregado Do RH',
          Funcao__c = funcao.Id,
          Email__c = 'teste@teste.com.br',
          Centro_custo__c = 'a0FSG000001C8Av2AK',
          Login__c = loginRh.Id,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Turno__c = turno.Id,
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Qtde_horas_semanais__c = 44,
          valor_hora_producao__c = 30,
          Perfil_de_Gerente_de_Projetos__c = true,
          Realiza_apontamentos__c = true,
          Criar_EngC__c = true,
          Redator__c = true,
          Valida_planejamento__c = true,
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id
        );
        insert empregadoDeptoPessoal;
      }
      return empregadoDeptoPessoal;
    }
    set;
  }

  //Classe empregado Manutenção
  public static Empregado__c empregadoComprador {
    get {
      if (empregadoComprador == null) {
        empregadoComprador = new Empregado__c(
          Name = 'Empregado Comprador teste',
          Funcao__c = funcao.Id,
          Email__c = 'teste@teste.com.br',
          Centro_custo__c = cc.Id,
          Login__c = loginComprador.Id,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Turno__c = turno.Id,
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Qtde_horas_semanais__c = 44,
          valor_hora_producao__c = 30,
          Perfil_de_Gerente_de_Projetos__c = true,
          Realiza_apontamentos__c = true,
          Criar_EngC__c = true,
          Redator__c = true,
          Valida_planejamento__c = true,
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id
        );
        insert empregadoComprador;
      }
      return empregadoComprador;
    }
    set;
  }

  public static Empregado__C empregadoGestaoTi {
    get {
      if (empregadoGestaoTi == null) {
        empregadoGestaoTi = new Empregado__c(
          Name = 'Empregado manutencao teste',
          Funcao__c = funcao.Id,
          Email__c = 'teste@teste.com.br',
          Centro_custo__c = cc.Id,
          Login__c = loginGestorTi.Id,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Turno__c = turno.Id,
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Qtde_horas_semanais__c = 44,
          valor_hora_producao__c = 30,
          Perfil_de_Gerente_de_Projetos__c = true,
          Realiza_apontamentos__c = true,
          Criar_EngC__c = true,
          Redator__c = true,
          Valida_planejamento__c = true,
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id
        );
        insert empregadoGestaoTi;
      }
      return empregadoGestaoTi;
    }
    set;
  }

  public static Empregado__C empregadoManutencao {
    get {
      if (empregadoManutencao == null) {
        empregadoManutencao = new Empregado__c(
          Name = 'Empregado manutencao teste',
          Funcao__c = funcao.Id,
          Email__c = 'teste@teste.com.br',
          Centro_custo__c = cc.Id,
          Login__c = loginManutencao.Id,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Turno__c = turno.Id,
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Qtde_horas_semanais__c = 44,
          valor_hora_producao__c = 30,
          Perfil_de_Gerente_de_Projetos__c = true,
          Realiza_apontamentos__c = true,
          Criar_EngC__c = true,
          Redator__c = true,
          Valida_planejamento__c = true,
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id
        );
        insert empregadoManutencao;
      }
      return empregadoManutencao;
    }
    set;
  }

  public static Empregado__c empregadoSuporteTi {
    get {
      if (empregadoSuporteTi == null) {
        empregadoSuporteTi = new Empregado__c(
          Name = 'Empregado Suporte Ti',
          Funcao__c = funcao.Id,
          Email__c = 'empregadoSuporteTi@teste.com.br',
          Centro_custo__c = cc.Id,
          Login__c = loginSuporteTi.Id,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Turno__c = turno.Id,
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Qtde_horas_semanais__c = 44,
          valor_hora_producao__c = 30,
          Perfil_de_Gerente_de_Projetos__c = true,
          Realiza_apontamentos__c = true,
          Criar_EngC__c = true,
          Redator__c = true,
          Valida_planejamento__c = true,
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id
        );
        insert empregadoSuporteTi;
      }
      return empregadoSuporteTi;
    }
    set;
  }

  private static Empregado__c empregadoValidadorValue;
  public static Empregado__c empregadoValidador {
    get {
      if (empregadoValidadorValue == null) {
        empregadoValidadorValue = new Empregado__c(
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          Centro_custo__c = cc.Id,
          CPF_DadosPessoais__c = '792.195.088-42',
          Criar_EngC__c = true,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Email__c = 'empregadoValidador@teste.com.br',
          Empresa_contratante__c = empresa.Id,
          Funcao__c = funcao.Id,
          Login__c = loginValidador.Id,
          Name = 'Empregado Suporte Ti',
          Perfil_de_Gerente_de_Projetos__c = true,
          Qtde_horas_semanais__c = 44,
          Realiza_apontamentos__c = true,
          Redator__c = true,
          RG_DadosPessoais__c = '567463328',
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Telefone__c = '1834212525',
          Turno__c = turno.Id,
          Valor_hora_producao__c = 30,
          Valida_planejamento__c = true,
          Vencimento_da_CNH__c = Date.today().addDays(250)
        );
        insert empregadoValidadorValue;
      }
      return empregadoValidadorValue;
    }
    private set;
  }

  private static Empregado__c gerenteProjetoValue;
  public static Empregado__c gerenteProjeto {
    get {
      if (gerenteProjetoValue == null) {
        gerenteProjetoValue = new Empregado__c(
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Centro_custo__c = cc.Id,
          Celular__c = '18789666999',
          Criar_EngC__c = true,
          Redator__c = true,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Email__c = 'teste@teste.com.br',
          Funcao__c = funcao.Id,
          Login__c = loginGerenteProjeto.Id,
          Name = 'Gerente do projeto',
          Perfil_de_Gerente_de_Projetos__c = true,
          Qtde_horas_semanais__c = 44,
          Realiza_apontamentos__c = true,
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Turno__c = turno.Id,
          Salario__c = 1000,
          Vencimento_da_CNH__c = Date.today().addDays(250),
          Valida_planejamento__c = true,
          empresa_contratante__c = empresa.Id
        );
        insert gerenteProjetoValue;
      }
      return gerenteProjetoValue;
    }
    private set;
  }

  public static EmpregadoFuncionalidade__c efApontamento {
    get {
      if (efApontamento == null) {
        efApontamento = new EmpregadoFuncionalidade__c(
          Empregado__c = empregadoApontador.Id,
          Funcionalidade__c = funcionalidadeApontamento.Id,
          Pode_acessar__c = true,
          Pode_gerenciar_proprios__c = true
        );
        insert efApontamento;
      }
      return efApontamento;
    }
    set;
  }

  public static EngC__c engc {
    get {
      if (engc == null) {
        engc = new EngC__c(
          Data__c = date.today(),
          Empregado__c = empregado.Id,
          FAP__c = fap.Id
        );
        insert engc;
      }
      return engc;
    }
    set;
  }

  public static Entrada_Retirada_de_Equipamento__c ere {
    get {
      if (ere == null) {
        ere = new Entrada_Retirada_de_Equipamento__c(
          Categoria__c = 'Entrada',
          Ordem_de_Servico__c = os.Id
        );
        insert ere;
      }
      return ere;
    }
    set;
  }

  private static Estrutura__c estruturaValue;
  public static Estrutura__c estrutura {
    get {
      if (estruturaValue == null) {
        estruturaValue = new Estrutura__c(
          Criado_pelo_login__c = login.Id,
          Cronograma_projeto__c = cronograma.Id,
          Data_inicial__c = date.today(),
          Data_final__c = date.today().addDays(10),
          Modificado_pelo_login__c = login.Id,
          Producao__c = 40,
          Status__c = 'Aberto',
          Tarefa_projeto__c = tarefa.Id
        );
        insert estruturaValue;
      }
      return estruturaValue;
    }
    private set;
  }

  private static Estrutura__c estruturaTValue;
  public static Estrutura__c estruturaT {
    get {
      if (estruturaTValue == null) {
        estruturaTValue = new Estrutura__c(
          Criado_pelo_login__c = login.Id,
          Cronograma_projeto__c = cronograma.Id,
          Data_inicial__c = date.today(),
          Data_final__c = date.today().addDays(10),
          Modificado_pelo_login__c = login.Id,
          Producao__c = 40,
          Status__c = 'Aberto',
          Tarefa_projeto__c = tarefa.Id,
          Terceirizado__c = true
        );
        insert estruturaTValue;
      }
      return estruturaTValue;
    }
    private set;
  }

  private static Estrutura_Recurso__c estruturaRecursoValue;
  public static Estrutura_Recurso__c estruturaRecurso {
    get {
      if (estruturaRecursoValue == null) {
        estruturaRecursoValue = new Estrutura_Recurso__c(
          Estrutura__c = estrutura.Id,
          Empregado__c = empregado.Id,
          Quantidade_de_horas__c = 8,
          Custo_medio_da_hora_com_encargos__c = 12
        );
        insert estruturaRecursoValue;
      }
      return estruturaRecursoValue;
    }
    private set;
  }

  private static Estrutura_Recurso_Item__c itemEstruturaRecursoValue;
  public static Estrutura_Recurso_Item__c itemEstruturaRecurso {
    get {
      if (itemEstruturaRecursoValue == null) {
        itemEstruturaRecursoValue = new Estrutura_Recurso_Item__c(
          Recurso_disponivel__c = recursoDisponivel.Id,
          Recursos_da_estrutura__c = estruturaRecurso.Id
        );
        insert itemEstruturaRecursoValue;
      }
      return itemEstruturaRecursoValue;
    }
    private set;
  }

  private static FAP__c fapValue;
  public static FAP__c fap {
    get {
      if (fapValue == null) {
        fapValue = new FAP__c(
          Name = 'FAP Teste',
          fapTipoFAP__c = 'FAP Final',
          fapMotivoTipoFAP__c = 'Fechado e ganho por melhor preço',
          fapNomeContrato__c = 'Contrato teste',
          fapDataVigenciaContrato__c = Date.today(),
          fapDataTerminoVigenciaContrato__c = Date.today().addMonths(3),
          fapPrazoExecucaoEntrega__c = Date.today().addMonths(4),
          fapNumeroParcelas__c = 3,
          fapFormaPagamento__c = 'Parcelado em 3x com entrada',
          fapDataVencimentoParcelas__c = Date.today().addDays(3),
          fapOportunidade__c = op.Id,
          fapConta__c = conta.Id,
          Solicitacao_ART__c = 'Não'
        );
        insert fapValue;
      }
      return fapValue;
    }
    private set;
  }

  private static FAP__c fapEngemapValue;
  public static FAP__c fapEngemap {
    get {
      if (fapEngemapValue == null) {
        fapEngemapValue = new FAP__c(
          Name = 'PROJETO ENGEMAP',
          fapTipoFAP__c = 'FAP Final',
          fapMotivoTipoFAP__c = 'Fechado e ganho por melhor preço',
          fapNomeContrato__c = 'Contrato teste',
          fapDataVigenciaContrato__c = Date.today(),
          fapDataTerminoVigenciaContrato__c = Date.today().addMonths(3),
          fapPrazoExecucaoEntrega__c = Date.today().addMonths(4),
          fapNumeroParcelas__c = 3,
          fapFormaPagamento__c = 'Parcelado em 3x com entrada',
          fapDataVencimentoParcelas__c = Date.today().addDays(3),
          fapOportunidade__c = op.Id,
          fapConta__c = conta.Id,
          Solicitacao_ART__c = 'Não'
        );
        insert fapEngemapValue;
      }
      return fapEngemapValue;
    }
    set;
  }

  public static FAP__c fapManual {
    get {
      if (fapManual == null) {
        fapManual = new FAP__c(
          Name = 'FAP Teste Manual',
          fapTipoFAP__c = 'FAP Final',
          fapMotivoTipoFAP__c = 'Fechado e ganho por melhor preço',
          fapNomeContrato__c = 'Contrato teste',
          fapDataVigenciaContrato__c = Date.today(),
          fapDataTerminoVigenciaContrato__c = Date.today().addMonths(3),
          fapPrazoExecucaoEntrega__c = Date.today().addMonths(4),
          fapNumeroParcelas__c = 3,
          fapFormaPagamento__c = 'Parcelado em 2x com entrada',
          fapDataVencimentoParcelas__c = Date.today().addDays(3),
          fapOportunidade__c = op.Id,
          fapConta__c = conta.Id,
          Solicitacao_ART__c = 'Não'
        );
        insert fapManual;
      }
      return fapManual;
    }
    set;
  }

  public static Feriado__c feriado {
    get {
      if (feriado == null) {
        feriado = new Feriado__c(
          Data__c = Date.valueOf('2018-05-04'),
          Observacao__c = 'T1'
        );
        insert feriado;
      }
      return feriado;
    }
    set;
  }

  public static Fornecedor__c fornecedor {
    get {
      if (fornecedor == null) {
        fornecedor = new Fornecedor__c(Name = 'Teste', Codigo__c = '123');
        insert fornecedor;
      }
      return fornecedor;
    }
    set;
  }

  public static Funcao__c funcao {
    get {
      if (funcao == null) {
        funcao = new Funcao__c(Name = 'Função teste');
        insert funcao;
      }
      return funcao;
    }
    set;
  }

  // função que realiza apontamentos
  public static Funcao__c funcaoProducao {
    get {
      if (funcaoProducao == null) {
        funcaoProducao = new Funcao__c(Name = 'Função de produção');
        insert funcaoProducao;
      }
      return funcao;
    }
    set;
  }

  public static FuncaoFuncionalidade__c ffApontamento {
    get {
      if (ffApontamento == null) {
        ffApontamento = new FuncaoFuncionalidade__c(
          Funcao__c = funcaoProducao.Id,
          Funcionalidade__c = funcionalidadeApontamento.Id,
          Pode_acessar__c = true,
          Pode_gerenciar_proprios__c = true
        );
        insert ffApontamento;
      }
      return ffApontamento;
    }
    set;
  }

  private static Funcao_orcada__c funcaoOrcamentoValue;
  public static Funcao_orcada__c funcaoOrcamento {
    get {
      if (funcaoOrcamentoValue == null) {
        Fase_do_orcamento__c faseA = getFase('A', 0);
        String faseAName = faseA.Name + ' - Nível ' + faseA.Nivel__c;
        funcaoOrcamentoValue = new Funcao_orcada__c(
          Beneficios__c = '[{"name":"Vale refeição","value":674.73}]',
          Custo_mensal__c = 9327.46,
          Custo_por_colaborador__c = 55964.76,
          Custo_total__c = 111929.52,
          Data_final__c = Date.today().addDays(10),
          Data_inicial__c = Date.today(),
          Disponibilidade__c = 100,
          Encargos_CLT__c = 73,
          Encargos_PJ__c = 16,
          Fase_do_orcamento__c = faseA.Id,
          Nome_da_fase__c = faseAName,
          Name = 'funcao orcada',
          Quantidade__c = 2,
          Quantidade_de_colaboradores__c = 2,
          Salario__c = 1300,
          Salario_PJ__c = 1500,
          Unidade__c = 'mês(es)'
        );
        insert funcaoOrcamentoValue;
      }
      return funcaoOrcamentoValue;
    }
    private set;
  }

  private static Funcao_orcada__c funcaoOrcadaValue;
  public static Funcao_orcada__c funcaoOrcada {
    get {
      if (funcaoOrcadaValue == null) {
        funcaoOrcadaValue = new Funcao_orcada__c(
          Beneficios__c = 'nenhum',
          Custo_mensal__c = 1,
          Custo_por_colaborador__c = 1,
          Custo_total__c = 1,
          Data_final__c = Date.today().addDays(10),
          Data_inicial__c = Date.today(),
          Disponibilidade__c = 1,
          Encargos_CLT__c = 1,
          Encargos_PJ__c = 1,
          Fase_do_orcamento__c = fasesDoOrcamento[0].Id,
          Nome_da_fase__c = fasesDoOrcamento[0].Name,
          Name = 'funcao orcada',
          Quantidade__c = 1,
          Quantidade_de_colaboradores__c = 1,
          Salario__c = 1,
          Salario_PJ__c = 1,
          Unidade__c = 'un'
        );
        insert funcaoOrcadaValue;
      }
      return funcaoOrcadaValue;
    }
    private set;
  }

  public static Funcao_planejada__c funcaoPlanejada {
    get {
      if (funcaoPlanejada == null) {
        funcaoPlanejada = new Funcao_planejada__c(
          Name = 'Função teste',
          Beneficios__c = '[{"name": "Vale transporte", "value": "100"}]',
          Cronograma_do_Projeto__c = cronograma.Id,
          Custo_mensal__c = 200,
          Custo_por_colaborador__c = 200,
          Custo_total__c = 200,
          Data_final__c = Date.today().addDays(30),
          Data_inicial__c = Date.today(),
          Quantidade_de_colaboradores__c = 1,
          Salario__c = 50,
          Salario_PJ__c = 100
        );
        insert funcaoPlanejada;
      }
      return funcaoPlanejada;
    }
    set;
  }

  public static Funcionalidade__c funcionalidadeApontamento {
    get {
      if (funcionalidadeApontamento == null) {
        funcionalidadeApontamento = new Funcionalidade__c(Name = 'Apontamento');
        insert funcionalidadeApontamento;
      }
      return funcionalidadeApontamento;
    }
    set;
  }

  public static Funcionario_Tarefa_do_Produto__c ftp {
    get {
      if (ftp == null) {
        ftp = new Funcionario_Tarefa_do_Produto__c(
          Funcionario__c = empregado.Id,
          Tarefa_do_Produto__c = tarefaProduto.Id
        );
        insert ftp;
      }
      return ftp;
    }
    set;
  }

  public static Grupo__c grupoSuperiores {
    get {
      if (grupoSuperiores == null) {
        grupoSuperiores = new Grupo__c(Name = 'Superiores');
        insert grupoSuperiores;
      }
      return grupoSuperiores;
    }
    set;
  }

  public static Grupo__c grupoManutencao {
    get {
      if (grupoManutencao == null) {
        grupoManutencao = new Grupo__c(Name = 'Manutenção');
        insert grupoManutencao;
      }
      return grupoManutencao;
    }
    set;
  }

  public static Grupo__c grupoCompradores {
    get {
      if (grupoCompradores == null) {
        grupoCompradores = new Grupo__c(Name = 'Compradores');
        insert grupoCompradores;
      }
      return grupoCompradores;
    }
    set;
  }

  public static Grupo__c grupoGestorTi {
    get {
      if (grupoGestorTi == null) {
        grupoGestorTi = new Grupo__c(Name = 'Gestores de TI');
        insert grupoGestorTi;
      }
      return grupoGestorTi;
    }
    set;
  }

  public static Grupo__c grupoGI {
    get {
      if (grupoGI == null) {
        grupoGI = new Grupo__c(Name = 'Gi');
        insert grupoGI;
      }
      return grupoGI;
    }
    set;
  }

  public static Grupo__c grupoOrcamentoValue;
  public static Grupo__c grupoOrcamento {
    get {
      if (grupoOrcamentoValue == null) {
        grupoOrcamentoValue = new Grupo__c(Name = 'Orçamento');
        insert grupoOrcamentoValue;
      }
      return grupoOrcamentoValue;
    }
    private set;
  }

  public static Grupo__c grupoTI {
    get {
      if (grupoTI == null) {
        grupoTI = new Grupo__c(Name = 'Ti');
        insert grupoTI;
      }
      return grupoTI;
    }
    set;
  }

  public static Grupo__c grupoFinanceiro {
    get {
      if (grupoFinanceiro == null) {
        grupoFinanceiro = new Grupo__c(Name = 'Financeiro');
        insert grupoFinanceiro;
      }
      return grupoFinanceiro;
    }
    set;
  }

  public static Grupo_Funcionarios__c funcionariosGi {
    get {
      if (funcionariosGi == null) {
        funcionariosGi = new Grupo_Funcionarios__c(
          Grupo__c = grupoGI.Id,
          Empregado__c = empregadoSuporteTi.Id
        );
        insert funcionariosGi;
      }
      return funcionariosGi;
    }
    set;
  }

  public static Grupo_Funcionarios__c funcionariosFinanceiro {
    get {
      if (funcionariosFinanceiro == null) {
        funcionariosFinanceiro = new Grupo_Funcionarios__c(
          Grupo__c = grupoFinanceiro.Id,
          Empregado__c = empregado.Id
        );
        insert funcionariosFinanceiro;
      }
      return funcionariosFinanceiro;
    }
    set;
  }

  private static Grupo_Funcionarios__c funcionariosOrcamentoValue;
  public static Grupo_Funcionarios__c funcionariosOrcamento {
    get {
      if (funcionariosOrcamentoValue == null) {
        funcionariosOrcamentoValue = new Grupo_Funcionarios__c(
          Grupo__c = grupoOrcamento.Id,
          Empregado__c = empregado.Id
        );
        insert funcionariosOrcamentoValue;
      }
      return funcionariosOrcamentoValue;
    }
    private set;
  }

  public static Grupo_Funcionarios__c funcionariosTi {
    get {
      if (funcionariosTi == null) {
        funcionariosTi = new Grupo_Funcionarios__c(
          Grupo__c = grupoTI.Id,
          Empregado__c = empregadoSuporteTi.Id
        );
        insert funcionariosTi;
      }
      return funcionariosTi;
    }
    set;
  }

  public static Grupo_Funcionarios__c funcionariosSuperiores {
    get {
      if (funcionariosSuperiores == null) {
        funcionariosSuperiores = new Grupo_Funcionarios__c(
          Grupo__c = grupoSuperiores.Id,
          Empregado__c = empregadoSuperior.Id
        );
        insert funcionariosSuperiores;
      }
      return funcionariosSuperiores;
    }
    set;
  }

  public static Grupo_Funcionarios__c GestorTi {
    get {
      if (funcionariosManutencao == null) {
        funcionariosManutencao = new Grupo_Funcionarios__c(
          Grupo__c = grupoGestorTi.Id,
          empregado__c = empregadoGestaoTi.Id
        );
        insert GestorTi;
      }
      return GestorTi;
    }
    set;
  }

  public static Grupo_Funcionarios__c funcionariosManutencao {
    get {
      if (funcionariosManutencao == null) {
        funcionariosManutencao = new Grupo_Funcionarios__c(
          Grupo__c = grupoManutencao.Id,
          Empregado__c = empregadoManutencao.Id
        );
        insert funcionariosManutencao;
      }
      return funcionariosSuperiores;
    }
    set;
  }

  public static Grupo_Funcionarios__c funcionariosCompradores {
    get {
      if (funcionariosCompradores == null) {
        funcionariosCompradores = new Grupo_Funcionarios__c(
          Grupo__c = grupoCompradores.Id,
          Empregado__c = empregadoComprador.Id
        );
        insert funcionariosCompradores;
      }
      return funcionariosCompradores;
    }
    set;
  }

  public static Grupo_checklist__c grupoCheck {
    get {
      if (grupoCheck == null) {
        grupoCheck = new Grupo_checklist__c(
          Planejamento_projeto__c = planejamento.Id
        );
        insert grupoCheck;
      }
      return grupoCheck;
    }
    set;
  }

  public static Grupo_de_Produtos__c gp {
    get {
      if (gp == null) {
        gp = new Grupo_de_Produtos__c(Name = 'AEROTRIANGULAÇÃO');
        insert gp;
      }
      return gp;
    }
    set;
  }

  private static Grupo_tarefa__c getGroupByName(String groupName) {
    // tenta encontrar no gruposTarefas
    for (Grupo_tarefa__c grupo : gruposTarefas) {
      if (grupo.Name.toLowerCase() == groupName.toLowerCase()) {
        return grupo;
      }
    }

    // se não encontra então lança um novo
    Grupo_tarefa__c newGrupo = new Grupo_tarefa__c(
      Name = groupName,
      Centro_de_Custo__c = cc.Id
    );
    insert newGrupo;
    return newGrupo;
  }

  private static List<Grupo_tarefa__c> gruposTarefasValue;
  public static List<Grupo_tarefa__c> gruposTarefas {
    get {
      if (gruposTarefasValue == null) {
        gruposTarefasValue = new List<Grupo_tarefa__c>();
        gruposTarefasValue.add(
          new Grupo_tarefa__c(Name = 'GRUPO TESTE', Centro_de_Custo__c = cc.Id)
        );
        gruposTarefasValue.add(
          new Grupo_tarefa__c(
            Name = 'PARADA DE ATIVIDADE',
            Centro_de_Custo__c = cc.Id
          )
        );
        gruposTarefasValue.add(
          new Grupo_tarefa__c(Name = 'GRUPO GT', Centro_de_Custo__c = cc.Id)
        );
        gruposTarefasValue.add(
          new Grupo_tarefa__c(Name = 'Aero', Centro_de_Custo__c = cc.Id)
        );
        gruposTarefasValue.add(
          new Grupo_tarefa__c(Name = 'Topo', Centro_de_Custo__c = cc.Id)
        );
        gruposTarefasValue.add(
          new Grupo_tarefa__c(
            Name = 'RECOBRIMENTO AÉREO',
            Centro_de_Custo__c = cc.Id
          )
        );
        gruposTarefasValue.add(
          new Grupo_tarefa__c(
            Name = 'AEROTRIANGULAÇÃO',
            Centro_de_Custo__c = cc.Id
          )
        );
        gruposTarefasValue.add(
          new Grupo_tarefa__c(
            Name = 'GESTÃO DE PROJETOS',
            Centro_de_Custo__c = cc.Id
          )
        );
        gruposTarefasValue.add(
          new Grupo_tarefa__c(
            Name = 'ATIVIDADES DE APOIO',
            Centro_de_Custo__c = cc.Id
          )
        );

        insert gruposTarefasValue;
      }
      return gruposTarefasValue;
    }
    private set;
  }

  private static Grupo_tarefa__c grupoTarefaValue;
  public static Grupo_tarefa__c grupoTarefa {
    get {
      if (grupoTarefaValue == null) {
        grupoTarefaValue = getGroupByName('GRUPO TESTE');
      }
      return grupoTarefaValue;
    }
    private set;
  }

  private static Grupo_tarefa__c grupoParadaValue;
  public static Grupo_tarefa__c grupoParada {
    get {
      if (grupoParadaValue == null) {
        grupoParadaValue = getGroupByName('PARADA DE ATIVIDADE');
      }
      return grupoParadaValue;
    }
    private set;
  }

  private static Grupo_tarefa__c gtValue;
  public static Grupo_tarefa__c gt {
    get {
      if (gtValue == null) {
        gtValue = getGroupByName('GRUPO GT');
      }
      return gtValue;
    }
    private set;
  }

  private static Grupo_tarefa__c aeroGtValue;
  public static Grupo_tarefa__c aeroGt {
    get {
      if (aeroGtValue == null) {
        aeroGtValue = getGroupByName('Aero');
      }
      return aeroGtValue;
    }
    private set;
  }

  private static Grupo_tarefa__c topoGtValue;
  public static Grupo_tarefa__c topoGt {
    get {
      if (topoGtValue == null) {
        topoGtValue = getGroupByName('Topo');
      }
      return topoGtValue;
    }
    private set;
  }

  private static Grupo_tarefa__c aerotriGtValue;
  public static Grupo_tarefa__c aerotriGt {
    get {
      if (aerotriGtValue == null) {
        aerotriGtValue = getGroupByName('AEROTRIANGULAÇÃO');
      }
      return aerotriGtValue;
    }
    private set;
  }

  private static Grupo_tarefa__c recAereoGtValue;
  public static Grupo_tarefa__c recAereoGt {
    get {
      if (recAereoGtValue == null) {
        recAereoGtValue = getGroupByName('RECOBRIMENTO AÉREO');
      }
      return recAereoGtValue;
    }
    private set;
  }

  private static Grupo_tarefa__c gestaoProjGtValue;
  public static Grupo_tarefa__c gestaoProjGt {
    get {
      if (gestaoProjGtValue == null) {
        gestaoProjGtValue = getGroupByName('GESTÃO DE PROJETOS');
      }
      return gestaoProjGtValue;
    }
    private set;
  }

  private static Grupo_tarefa__c atvApoioGtValue;
  public static Grupo_tarefa__c atvApoioGt {
    get {
      if (atvApoioGtValue == null) {
        atvApoioGtValue = getGroupByName('ATIVIDADES DE APOIO');
      }
      return atvApoioGtValue;
    }
    private set;
  }

  public static Item_da_despesa_orcada__c idp {
    get {
      if (idp == null) {
        idp = new Item_da_despesa_orcada__c(
          Centro_de_Custo__c = cc.Id,
          Despesa_orcada__c = despOrcada.Id,
          Grupo_de_Produtos__c = gp.Id,
          Observacao__c = 'TESTE',
          Produto__c = produto.Id,
          Quantidade__c = 0.00,
          Valor_total__c = 0.00,
          Valor_unitario__c = 0.00
        );
        insert idp;
      }
      return idp;
    }
    set;
  }

  public static Item_do_Grupo_de_Produto__c igps {
    get {
      if (igps == null) {
        igps = new Item_do_Grupo_de_Produto__c(
          Grupo_de_Produtos__c = gp.Id,
          Produto_de_Compra__c = produto.Id,
          TemplateCode__c = 'MA123'
        );
        insert igps;
      }
      return igps;
    }
    set;
  }

  public static Item_Empregado_Grupo_Tarefa__c empregadoGrupoTarefa {
    get {
      if (empregadoGrupoTarefa == null) {
        empregadoGrupoTarefa = new Item_Empregado_Grupo_Tarefa__c(
          Fixo__c = true,
          Empregado__c = empregado.Id,
          Grupo_tarefa__c = gt.Id
        );
        insert empregadoGrupoTarefa;
      }
      return empregadoGrupoTarefa;
    }
    set;
  }

  public static Item_Empregado_Grupo_Tarefa__c empregadoGrupoTarefaA {
    get {
      if (empregadoGrupoTarefaA == null) {
        empregadoGrupoTarefaA = new Item_Empregado_Grupo_Tarefa__c(
          Fixo__c = true,
          Empregado__c = empregadoApontador.Id,
          Grupo_tarefa__c = gt.Id
        );
        insert empregadoGrupoTarefaA;
      }
      return empregadoGrupoTarefaA;
    }
    set;
  }

  public static Item_Funcionario_Tarefa_Projeto__c iftp {
    get {
      if (iftp == null) {
        iftp = new Item_Funcionario_Tarefa_Projeto__c(
          Fixo__c = true,
          Funcionario__c = empregado.Id,
          Tarefa_do_Projeto__c = tarefa.Id
        );
        insert iftp;
      }
      return iftp;
    }
    set;
  }

  public static Item_Funcionario_Tarefa_Projeto__c iftpA {
    get {
      if (iftpA == null) {
        iftpA = new Item_Funcionario_Tarefa_Projeto__c(
          Fixo__c = true,
          Funcionario__c = empregadoApontador.Id,
          Tarefa_do_Projeto__c = tarefa.Id
        );
        insert iftpA;
      }
      return iftpA;
    }
    set;
  }

  public static Item_Previsao_Receita__c itemPrevRec {
    get {
      if (itemPrevRec == null) {
        itemPrevRec = new Item_Previsao_Receita__c(
          Criado_pelo_login__c = login.Id,
          Modificado_pelo_login__c = login.Id,
          Previsao_receita__c = previsaoReceita.Id,
          Data__c = date.today(),
          Valor__c = 1235.67,
          Numero_parcela__c = 1,
          Quantidade_parcela__c = 1,
          Previsao_pai__c = null,
          Rateio__c = false
        );
        insert itemPrevRec;
      }
      return itemPrevRec;
    }
    set;
  }

  public static Kpi_indicadores__c kpi {
    get {
      if (kpi == null) {
        kpi = new Kpi_indicadores__c(
          Data_preenchimento__c = Date.TODAY(),
          Mapeamento_indicadores__c = mapeamento.Id,
          Meta__c = 10,
          Metrica__c = 'Metrica teste',
          Polaridade__c = 'Maior',
          Resultado__c = 10,
          Tipo__c = 'Mensal',
          Unidade_medida__c = 'R$'
        );
        insert kpi;
      }
      return kpi;
    }
    set;
  }

  public static List<Account> accountsParceiras {
    get {
      if (accountsParceiras == null) {
        accountsParceiras = new List<Account>();
        List<String> cnpjValidos = new List<String>();
        cnpjValidos.add('52.560.191/0001-40');
        cnpjValidos.add('92.387.992/0001-70');
        cnpjValidos.add('18.099.625/0001-18');
        cnpjValidos.add('81.841.297/0001-10');
        cnpjValidos.add('44.345.365/0001-23');
        cnpjValidos.add('59.428.350/0001-04');
        cnpjValidos.add('43.458.543/0001-60');
        cnpjValidos.add('43.629.146/0001-03');
        cnpjValidos.add('67.420.543/0001-39');
        cnpjValidos.add('26.734.749/0001-56');
        for (integer i = 0; i < 10; i++) {
          Account conta = new Account(
            Id = null,
            Name = 'Conta teste' + i,
            Type = 'Parceiro',
            contaCNPJ__c = cnpjValidos[i]
          );
          accountsParceiras.add(conta);
        }
        insert accountsParceiras;
      }
      return accountsParceiras;
    }
    set;
  }

  public static List<Funcionalidade__c> funcionalidades {
    get {
      if (funcionalidades == null) {
        funcionalidades = new List<Funcionalidade__c>();
        funcionalidades.add(new Funcionalidade__c(Name = 'Processo'));
        funcionalidades.add(new Funcionalidade__c(Name = 'Empregado'));
        funcionalidades.add(new Funcionalidade__c(Name = 'Mural'));
        funcionalidades.add(new Funcionalidade__c(Name = 'Viagem'));
        funcionalidades.add(new Funcionalidade__c(Name = 'Indicador'));
        funcionalidades.add(new Funcionalidade__c(Name = 'EngC'));
        funcionalidades.add(new Funcionalidade__c(Name = 'Projeto'));
        funcionalidades.add(new Funcionalidade__c(Name = 'Apontamento'));
        insert funcionalidades;
      }
      return funcionalidades;
    }
    set;
  }

  public static List<Anexo__c> anexos {
    get {
      if (anexos == null) {
        anexos = new List<Anexo__c>();
        anexos.add(
          new Anexo__c(
            ParentName__c = 'Objeto Teste',
            ParentId__c = planoTrabalho.Id,
            ParentObjectLabel__c = 'Plano de trabalho',
            Publico__c = false
          )
        );
        anexos.add(
          new Anexo__c(
            ParentName__c = 'Objeto Teste 2',
            ParentId__c = planoTrabalho.Id,
            ParentObjectLabel__c = 'Plano de trabalho',
            Publico__c = true
          )
        );

        insert anexos;
      }
      return anexos;
    }
    set;
  }

  private static List<Apontamento_Colaborador__c> apontamentosColaboradorValue;
  public static List<Apontamento_Colaborador__c> apontamentosColaborador {
    get {
      if (apontamentosColaboradorValue == null) {
        configurarTarefaParada();
        apontamentosColaboradorValue = new List<Apontamento_Colaborador__c>();
        for (Integer i = 0; i > -30; i--) {
          apontamentosColaboradorValue.add(
            new Apontamento_Colaborador__c(
              Data__c = Date.today().addDays(i - 1),
              Empregado__c = empregadoApontador.Id,
              FAP__c = fap.Id,
              Bloco_do_Projeto__c = bloco.Id,
              Horario_inicial__c = '08:00',
              Horario_final__c = '12:00',
              Tarefa_Realizada_do_Produto__c = tarefaRealizada.Id,
              Produtividade__c = '10',
              Empregado_data__c = empregadoApontador.Id +
                '_' +
                Date.today().addDays(i - 1),
              Status__c = 'Aguardando aprovação',
              Criado_pelo_login__c = loginApontador.Id,
              Tipo__c = 'Produtivo'
            )
          );
        }
        insert apontamentosColaboradorValue;
      }
      return apontamentosColaboradorValue;
    }
    private set;
  }

  private static List<Apontamento_Colaborador__c> apontamentosColaboradorProducaoValue;
  public static List<Apontamento_Colaborador__c> apontamentosColaboradorProducao {
    get {
      if (apontamentosColaboradorProducaoValue == null) {
        apontamentosColaboradorProducaoValue = new List<Apontamento_Colaborador__c>();
        for (Integer i = 0; i > -30; i--) {
          apontamentosColaboradorProducaoValue.add(
            new Apontamento_Colaborador__c(
              Data__c = Date.today().addDays(i - 1),
              Empregado__c = empregadoApontador.Id,
              FAP__c = fap.Id,
              Horario_inicial__c = '12:01',
              Horario_final__c = '13:00',
              Tarefa_Realizada_do_Produto__c = tarefaRealizada.Id,
              Produtividade__c = '10',
              Empregado_data__c = empregadoApontador.Id +
                '_' +
                Date.today().addDays(i - 1),
              Status__c = 'Aguardando aprovação',
              Hora_de_producao__c = true,
              Tipo__c = 'Produtivo'
            )
          );
        }
        insert apontamentosColaboradorProducaoValue;
      }
      return apontamentosColaboradorProducaoValue;
    }
    private set;
  }

  public static List<Empregado__c> empregados {
    get {
      if (empregados == null) {
        empregados = new List<Empregado__c>();
        for (Integer i = 0; i < 10; i++) {
          empregados.add(
            empregado = new Empregado__c(
              Name = 'Empregado teste' + i,
              Funcao__c = funcao.Id,
              Email__c = 'teste' + i + '@teste.com.br',
              Centro_custo__c = cc.Id,
              Login__c = logins[i].Id,
              Data_admissao__c = Date.today().addDays(-10),
              Data_de_nascimento__c = Date.newInstance(
                Date.today().year() - 35,
                Date.today().month(),
                Date.today().day()
              ),
              Turno__c = turno.Id,
              Salario__c = 1000,
              Qtde_horas_semanais__c = 44,
              Perfil_de_Gerente_de_Projetos__c = true,
              Realiza_apontamentos__c = true,
              Criar_EngC__c = true,
              Redator__c = true,
              Valida_planejamento__c = true,
              Carteira_de_Habilitacao__c = '10233456',
              Categoria_cnh__c = 'AB',
              Celular__c = '18789666999',
              CPF_DadosPessoais__c = '792.195.088-42',
              RG_DadosPessoais__c = '567463328',
              Telefone__c = '1834212525',
              Vencimento_da_CNH__c = Date.today().addDays(250),
              empresa_contratante__c = empresa.Id
            )
          );
        }
        System.debug('Inserindo empregados...');
        insert empregados;
      }
      return empregados;
    }
    set;
  }

  private static List<Fase_do_orcamento__c> fasesDoOrcamentoValue;
  public static List<Fase_do_orcamento__c> fasesDoOrcamento {
    get {
      if (fasesDoOrcamentoValue == null) {
        Fase_do_orcamento__c faseA = new Fase_do_orcamento__c(
          Name = 'A',
          Grupo_de_Tarefa__c = recAereoGt.Id,
          Orcamento__c = orcamento59.Id,
          Quantidade__c = 55.3,
          Unidade__c = 'km²',
          Nivel__c = 0
        );
        Fase_do_orcamento__c faseB = new Fase_do_orcamento__c(
          Name = 'B',
          Grupo_de_Tarefa__c = aerotriGt.Id,
          Orcamento__c = orcamento59.Id,
          Quantidade__c = 12,
          Unidade__c = 'KM',
          Nivel__c = 0
        );
        Fase_do_orcamento__c faseC = new Fase_do_orcamento__c(
          Name = 'C',
          Grupo_de_Tarefa__c = aerotriGt.Id,
          Orcamento__c = orcamento59.Id,
          Quantidade__c = 15,
          Unidade__c = 'KM',
          Nivel__c = 0
        );
        Fase_do_orcamento__c faseGestao = new Fase_do_orcamento__c(
          Name = 'GESTÃO',
          Grupo_de_Tarefa__c = gestaoProjGt.Id,
          Orcamento__c = orcamento59.Id,
          Quantidade__c = 1,
          Unidade__c = 'UNIDADE',
          Nivel__c = 0
        );
        fasesDoOrcamentoValue = new List<Fase_do_orcamento__c>{
          faseA,
          faseB,
          faseC,
          faseGestao
        };
        insert fasesDoOrcamentoValue;
      }
      return fasesDoOrcamentoValue;
    }
    private set;
  }

  private static List<Fase_do_orcamento__c> fasesDoOrcamento1Value;
  public static List<Fase_do_orcamento__c> fasesDoOrcamento1 {
    get {
      if (fasesDoOrcamento1Value == null) {
        Fase_do_orcamento__c faseB1 = new Fase_do_orcamento__c(
          Name = 'B1',
          Grupo_de_Tarefa__c = aerotriGt.Id,
          Orcamento__c = orcamento59.Id,
          Quantidade__c = 100,
          Unidade__c = 'KM',
          Fase_pai__c = getFase('B', 0).Id,
          Nivel__c = 1
        );
        Fase_do_orcamento__c faseB2 = new Fase_do_orcamento__c(
          Name = 'B2',
          Grupo_de_Tarefa__c = atvApoioGt.Id,
          Orcamento__c = orcamento59.Id,
          Quantidade__c = 100,
          Unidade__c = 'KM',
          Fase_pai__c = getFase('B', 0).Id,
          Nivel__c = 1
        );
        Fase_do_orcamento__c faseC1 = new Fase_do_orcamento__c(
          Name = 'C1',
          Grupo_de_Tarefa__c = recAereoGt.Id,
          Orcamento__c = orcamento59.Id,
          Quantidade__c = 55.3,
          Unidade__c = 'km²',
          Fase_pai__c = getFase('C', 0).Id,
          Nivel__c = 1
        );
        fasesDoOrcamento1Value = new List<Fase_do_orcamento__c>{
          faseB1,
          faseB2,
          faseC1
        };
        insert fasesDoOrcamento1Value;
      }
      return fasesDoOrcamento1Value;
    }
    private set;
  }

  private static List<Fase_do_orcamento__c> fasesDoOrcamento2Value;
  public static List<Fase_do_orcamento__c> fasesDoOrcamento2 {
    get {
      if (fasesDoOrcamento2Value == null) {
        Fase_do_orcamento__c faseB11 = new Fase_do_orcamento__c(
          Name = 'B11',
          Grupo_de_Tarefa__c = aerotriGt.Id,
          Orcamento__c = orcamento59.Id,
          Quantidade__c = 45,
          Unidade__c = 'KM',
          Fase_pai__c = getFase('B1', 1).Id,
          Nivel__c = 2
        );
        fasesDoOrcamento2Value = new List<Fase_do_orcamento__c>{ faseB11 };
        insert fasesDoOrcamento2Value;
      }
      return fasesDoOrcamento2Value;
    }
    private set;
  }

  private static Fase_do_orcamento__c faseFilhaValue;
  public static Fase_do_orcamento__c faseFilha {
    get {
      if (faseFilhaValue == null) {
        faseFilhaValue = new Fase_do_orcamento__c(
          Name = 'Fase filha',
          Grupo_de_Tarefa__c = topoGt.Id,
          Orcamento__c = orcamento.Id,
          Quantidade__c = 330,
          Unidade__c = 'km',
          Fase_pai__c = fasesDoOrcamento[1].Id
        );
        insert faseFilhaValue;
      }
      return faseFilhaValue;
    }
    private set;
  }

  public static List<Grupo__c> gruposSolicitacaoCompra {
    get {
      if (gruposSolicitacaoCompra == null) {
        gruposSolicitacaoCompra = new List<Grupo__c>{
          new Grupo__c(Name = 'Aprovadores de Compras'),
          new Grupo__c(Name = 'Compradores'),
          new Grupo__c(Name = 'Gestores e Aprovadores'),
          new Grupo__c(Name = 'Assessores Jurídicos')
        };
        insert gruposSolicitacaoCompra;
      }
      return gruposSolicitacaoCompra;
    }
    set;
  }

  public static List<Grupo__c> gruposSolicitacaoSuporte {
    get {
      if (gruposSolicitacaoSuporte == null) {
        gruposSolicitacaoSuporte = new List<Grupo__c>{
          new Grupo__c(Name = 'TI'),
          new Grupo__c(Name = 'GI')
        };
        insert gruposSolicitacaoSuporte;
      }
      return gruposSolicitacaoSuporte;
    }
    set;
  }

  public static List<Grupo__c> gruposSolicitacaoViagem {
    get {
      if (gruposSolicitacaoViagem == null) {
        gruposSolicitacaoViagem = new List<Grupo__c>{
          new Grupo__c(Name = 'Gestores e Aprovadores'),
          new Grupo__c(Name = 'Financeiro'),
          new Grupo__c(Name = 'Logística')
        };
        insert gruposSolicitacaoViagem;
      }
      return gruposSolicitacaoViagem;
    }
    set;
  }

  public static List<Grupo__c> gruposSolicitacaoVeiculo {
    get {
      if (gruposSolicitacaoVeiculo == null) {
        gruposSolicitacaoVeiculo = new List<Grupo__c>{
          new Grupo__c(Name = 'Tomadores de decisão'),
          new Grupo__c(Name = 'Logística')
        };
        insert gruposSolicitacaoVeiculo;
      }
      return gruposSolicitacaoVeiculo;
    }
    set;
  }

  public static List<Grupo_Funcionarios__c> grpFuncSolCompra {
    get {
      if (grpFuncSolCompra == null) {
        grpFuncSolCompra = new List<Grupo_Funcionarios__c>();
        for (Grupo__c grp : gruposSolicitacaoCompra) {
          grpFuncSolCompra.add(
            new Grupo_Funcionarios__c(
              Empregado__c = empregado.Id,
              Grupo__c = grp.Id
            )
          );
        }
        insert grpFuncSolCompra;
      }
      return grpFuncSolCompra;
    }
    set;
  }

  public static List<Grupo_Funcionarios__c> grpFuncSolSuporte {
    get {
      if (grpFuncSolSuporte == null) {
        grpFuncSolSuporte = new List<Grupo_Funcionarios__c>();
        for (Grupo__c grp : gruposSolicitacaoSuporte) {
          grpFuncSolSuporte.add(
            new Grupo_Funcionarios__c(
              Empregado__c = empregado.Id,
              Grupo__c = grp.Id
            )
          );
          grpFuncSolSuporte.add(
            new Grupo_Funcionarios__c(
              Empregado__c = empregadoSuporteTi.Id,
              Grupo__c = grp.Id
            )
          );
        }
        insert grpFuncSolSuporte;
      }
      return grpFuncSolSuporte;
    }
    set;
  }

  public static List<Grupo_Funcionarios__c> grpFuncSolViagem {
    get {
      if (grpFuncSolViagem == null) {
        grpFuncSolViagem = new List<Grupo_Funcionarios__c>();
        for (Grupo__c grp : gruposSolicitacaoViagem) {
          grpFuncSolCompra.add(
            new Grupo_Funcionarios__c(
              Empregado__c = empregado.Id,
              Grupo__c = grp.Id
            )
          );
        }
        insert grpFuncSolViagem;
      }
      return grpFuncSolViagem;
    }
    set;
  }

  public static List<Horario__c> horarios {
    get {
      if (horarios == null) {
        horarios = new List<Horario__c>();
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Segunda',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Segunda',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Terça',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Terça',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Quarta',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Quarta',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Quinta',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Quinta',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Sexta',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios.add(
          new Horario__c(
            Turno__c = turno.Id,
            Dia__c = 'Sexta',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );

        insert horarios;
      }
      return horarios;
    }
    set;
  }

  public static List<Horario__c> horarios2 {
    get {
      if (horarios2 == null) {
        horarios2 = new List<Horario__c>();
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Segunda',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Segunda',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Terça',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Terça',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Quarta',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Quarta',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Quinta',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Quinta',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Sexta',
            Entrada__c = '08:00',
            Saida__c = '12:00'
          )
        );
        horarios2.add(
          new Horario__c(
            Turno__c = turno2.Id,
            Dia__c = 'Sexta',
            Entrada__c = '13:30',
            Saida__c = '18:18'
          )
        );

        insert horarios2;
      }
      return horarios2;
    }
    set;
  }

  private static List<Item_Previsao_Despesa__c> listItemPrevDespValue;
  public static List<Item_Previsao_Despesa__c> listItemPrevDesp {
    get {
      if (listItemPrevDespValue == null) {
        listItemPrevDespValue = new List<Item_Previsao_Despesa__c>();
        Item_Previsao_Despesa__c ipd1 = new Item_Previsao_Despesa__c(
          Centro_de_Custo__c = cc.Id,
          Criado_pelo_login__c = login.Id,
          Data__c = date.today(),
          Data_do_vencimento__c = date.today().addDays(5),
          Modificado_pelo_login__c = login.Id,
          Nome_do_Produto__c = produto.Name,
          Numero_da_parcela__c = 1,
          Prazo_para_vencimento__c = 5,
          Previsao_despesa__c = previsaoDespesa.Id,
          Produto__c = produto.Id,
          Quantidade__c = 2,
          Quantidade_de_parcela__c = 1,
          Valor_total__c = 30.50,
          Valor_unitario__c = 15.25
        );
        insert ipd1;
        listItemPrevDespValue.add(ipd1);

        Item_Previsao_Despesa__c ipd21 = new Item_Previsao_Despesa__c(
          Centro_de_Custo__c = cc.Id,
          Criado_pelo_login__c = login.Id,
          Data__c = date.today(),
          Data_do_vencimento__c = date.today(),
          Modificado_pelo_login__c = login.Id,
          Nome_do_Produto__c = produto.Name,
          Numero_da_parcela__c = 1,
          Prazo_para_vencimento__c = 0,
          Previsao_despesa__c = previsaoDespesa.Id,
          Produto__c = produto.Id,
          Quantidade__c = 2,
          Quantidade_de_parcela__c = 2,
          Realizado__c = true,
          Valor_total__c = 16.24,
          Valor_unitario__c = 16.24
        );
        insert ipd21;
        listItemPrevDespValue.add(ipd21);

        Item_Previsao_Despesa__c ipd22 = new Item_Previsao_Despesa__c(
          Centro_de_Custo__c = cc.Id,
          Criado_pelo_login__c = login.Id,
          Data__c = date.today().addMonths(1),
          Data_do_vencimento__c = date.today().addMonths(1),
          Modificado_pelo_login__c = login.Id,
          Nome_do_Produto__c = produto.Name,
          Numero_da_parcela__c = 2,
          Previsao_despesa__c = previsaoDespesa.Id,
          Previsao_pai__c = ipd21.Id,
          Prazo_para_vencimento__c = 0,
          Produto__c = produto.Id,
          Quantidade__c = 2,
          Quantidade_de_parcela__c = 2,
          Valor_total__c = 16.24,
          Valor_unitario__c = 16.24
        );
        insert ipd22;
        listItemPrevDespValue.add(ipd22);
      }
      return listItemPrevDespValue;
    }
    private set;
  }

  public static List<Login__c> logins {
    get {
      if (logins == null) {
        logins = new List<Login__c>();
        for (Integer i = 0; i < 10; i++) {
          logins.add(
            new Login__c(
              Name = 'teste' + i + '@engemap.com.br',
              Senha__c = 'teste',
              Trocar_senha__c = false
            )
          );
        }
        insert logins;
      }
      return logins;
    }
    set;
  }

  private static List<Mao_de_obra_da_fase__c> maosDeObraValue;
  public static List<Mao_de_obra_da_fase__c> maosDeObra {
    get {
      if (maosDeObraValue == null) {
        maosDeObraValue = new List<Mao_de_obra_da_fase__c>();
        Fase_do_orcamento__c faseA = getFase('A', 0);
        String faseAName = faseA.Name + ' - Nível ' + faseA.Nivel__c;
        maosDeObraValue.add(
          new Mao_de_obra_da_fase__c(
            Alias__c = 'teste',
            Custo_da_hora__c = 20,
            Custo_considerado__c = 'Médio',
            Nome_da_fase__c = faseAName,
            Fase_do_orcamento__c = faseA.Id,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Quantidade__c = 55.3,
            Horas__c = 100
          )
        );
        maosDeObraValue.add(
          new Mao_de_obra_da_fase__c(
            Alias__c = 'alias',
            Custo_da_hora__c = 10,
            Custo_considerado__c = 'Médio',
            Nome_da_fase__c = faseAName,
            Fase_do_orcamento__c = faseA.Id,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Quantidade__c = 55.3,
            Horas__c = 100
          )
        );
        maosDeObraValue.add(
          new Mao_de_obra_da_fase__c(
            Alias__c = 'teste2',
            Custo_da_hora__c = 26.53,
            Custo_considerado__c = 'Médio',
            Nome_da_fase__c = faseAName,
            Fase_do_orcamento__c = faseA.Id,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Quantidade__c = 55.3,
            Horas__c = 100
          )
        );
        Fase_do_orcamento__c faseB2 = getFase('B2', 1);
        String faseB2Name = faseB2.Name + ' - Nível ' + faseB2.Nivel__c;
        maosDeObraValue.add(
          new Mao_de_obra_da_fase__c(
            Alias__c = '',
            Custo_da_hora__c = 53.35,
            Custo_considerado__c = 'Médio',
            Nome_da_fase__c = faseB2Name,
            Fase_do_orcamento__c = faseB2.Id,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Quantidade__c = 100,
            Horas__c = 10
          )
        );
        Fase_do_orcamento__c faseB11 = getFase('B11', 2);
        String faseB11Name = faseB11.Name + ' - Nível ' + faseB11.Nivel__c;
        maosDeObraValue.add(
          new Mao_de_obra_da_fase__c(
            Alias__c = '',
            Custo_da_hora__c = 30.36,
            Custo_considerado__c = 'Médio',
            Nome_da_fase__c = faseB11Name,
            Fase_do_orcamento__c = faseB11.Id,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Quantidade__c = 45,
            Horas__c = 130
          )
        );
        Fase_do_orcamento__c faseC1 = getFase('C1', 1);
        String faseC1Name = faseC1.Name + ' - Nível ' + faseC1.Nivel__c;
        maosDeObraValue.add(
          new Mao_de_obra_da_fase__c(
            Alias__c = '',
            Custo_da_hora__c = 30.36,
            Custo_considerado__c = 'Médio',
            Nome_da_fase__c = faseC1Name,
            Fase_do_orcamento__c = faseC1.Id,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Quantidade__c = 45,
            Horas__c = 130
          )
        );
        Fase_do_orcamento__c faseGestao = getFase('GESTÃO', 0);
        String faseGestaoName =
          faseGestao.Name +
          ' - Nível ' +
          faseGestao.Nivel__c;
        maosDeObraValue.add(
          new Mao_de_obra_da_fase__c(
            Alias__c = '',
            Custo_da_hora__c = 32.95,
            Custo_considerado__c = 'Médio',
            Nome_da_fase__c = faseGestaoName,
            Fase_do_orcamento__c = faseGestao.Id,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Quantidade__c = 1,
            Horas__c = 50
          )
        );
        maosDeObraValue.add(
          new Mao_de_obra_da_fase__c(
            Alias__c = '',
            Custo_da_hora__c = 39.75,
            Custo_considerado__c = 'Médio',
            Nome_da_fase__c = faseGestaoName,
            Fase_do_orcamento__c = faseGestao.Id,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Quantidade__c = 1,
            Horas__c = 300
          )
        );

        insert maosDeObraValue;
      }
      return maosDeObraValue;
    }
    private set;
  }

  public static List<Participante_de_negocio__c> participantesNegocio {
    get {
      if (participantesNegocio == null) {
        Decimal valorParticipante1 = op.Amount * 0.54;
        Decimal valorParticipante2 = op.Amount - valorParticipante1;

        participantesNegocio = new List<Participante_de_negocio__c>();
        participantesNegocio.add(
          new Participante_de_negocio__c(
            Condicao__c = 'Líder',
            Negocio_cooperativo__c = negocioCoop.Id,
            Conta__c = accountsParceiras[0].Id,
            Percentagem__c = 54,
            valor__c = valorParticipante1
          )
        );
        participantesNegocio.add(
          new Participante_de_negocio__c(
            Condicao__c = 'Participante',
            Negocio_cooperativo__c = negocioCoop.Id,
            Conta__c = accountsParceiras[1].Id,
            Percentagem__c = 46,
            valor__c = valorParticipante2
          )
        );
        insert participantesNegocio;
      }
      return participantesNegocio;
    }
    set;
  }

  public static List<Funcao__c> funcoes {
    get {
      if (funcoes == null) {
        funcoes = new List<Funcao__c>();
        List<FuncaoFuncionalidade__c> funcoesFuncionalidades = new List<FuncaoFuncionalidade__c>();
        Funcionalidade__c funcProcesso = funcionalidades[0];
        Funcionalidade__c funcEmpregado = funcionalidades[1];
        Funcionalidade__c funcMural = funcionalidades[2];
        Funcionalidade__c funcViagem = funcionalidades[3];
        Funcionalidade__c funcIndicador = funcionalidades[4];
        Funcionalidade__c funcEngC = funcionalidades[5];
        Funcionalidade__c funcProjeto = funcionalidades[6];
        Funcionalidade__c funcApontamento = funcionalidades[7];

        funcoes.add(new Funcao__c(Name = 'Gerente de projetos'));
        funcoes.add(new Funcao__c(Name = 'Cadista'));
        funcoes.add(new Funcao__c(Name = 'Comprador'));
        funcoes.add(new Funcao__c(Name = 'Gestor de produção'));
        funcoes.add(new Funcao__c(Name = 'Gestor da qualidade'));
        funcoes.add(new Funcao__c(Name = 'Auxiliar de RH'));
        funcoes.add(new Funcao__c(Name = 'Gestor de RH'));

        insert funcoes;

        // funcionalidades do gerente de projeto
        funcoesFuncionalidades.add(
          new FuncaoFuncionalidade__c(
            Funcao__c = funcoes[0].Id,
            Funcionalidade__c = funcProcesso.Id,
            Pode_aprovar__c = true,
            Pode_gerenciar_proprios__c = true,
            Pode_acessar__c = true,
            Pode_visualizar__c = true
          )
        );

        funcoesFuncionalidades.add(
          new FuncaoFuncionalidade__c(
            Funcao__c = funcoes[0].Id,
            Funcionalidade__c = funcProjeto.Id,
            Pode_gerenciar_proprios__c = true,
            Pode_acessar__c = true,
            Pode_visualizar__c = true
          )
        );

        funcoesFuncionalidades.add(
          new FuncaoFuncionalidade__c(
            Funcao__c = funcoes[0].Id,
            Funcionalidade__c = funcApontamento.Id,
            Pode_gerenciar_proprios__c = true,
            Pode_acessar__c = true,
            Pode_visualizar__c = true
          )
        );

        // funcionalidades do auxiliar de rh
        funcoesFuncionalidades.add(
          new FuncaoFuncionalidade__c(
            Funcao__c = funcoes[5].Id,
            Funcionalidade__c = funcEmpregado.Id,
            Pode_gerenciar_proprios__c = true,
            Pode_acessar__c = true,
            Pode_editar__c = true,
            Pode_visualizar__c = true
          )
        );

        funcoesFuncionalidades.add(
          new FuncaoFuncionalidade__c(
            Funcao__c = funcoes[5].Id,
            Funcionalidade__c = funcProjeto.Id,
            Pode_acessar__c = true,
            Pode_visualizar__c = true
          )
        );

        funcoesFuncionalidades.add(
          new FuncaoFuncionalidade__c(
            Funcao__c = funcoes[5].Id,
            Funcionalidade__c = funcIndicador.Id,
            Pode_acessar__c = true,
            Pode_gerenciar_proprios__c = true,
            Pode_visualizar__c = true
          )
        );

        // funcionalidades do gestor de rh
        funcoesFuncionalidades.add(
          new FuncaoFuncionalidade__c(
            Funcao__c = funcoes[6].Id,
            Funcionalidade__c = funcEmpregado.Id,
            Pode_gerenciar_proprios__c = true,
            Pode_acessar__c = true,
            Pode_editar__c = true,
            Pode_excluir__c = true,
            Pode_visualizar__c = true
          )
        );

        funcoesFuncionalidades.add(
          new FuncaoFuncionalidade__c(
            Funcao__c = funcoes[6].Id,
            Funcionalidade__c = funcProjeto.Id,
            Pode_acessar__c = true,
            Pode_visualizar__c = true
          )
        );

        funcoesFuncionalidades.add(
          new FuncaoFuncionalidade__c(
            Funcao__c = funcoes[6].Id,
            Funcionalidade__c = funcIndicador.Id,
            Pode_acessar__c = true,
            Pode_gerenciar_proprios__c = true,
            Pode_visualizar__c = true
          )
        );
        insert funcoesFuncionalidades;
      }
      return funcoes;
    }
    set;
  }

  public static List<Rateio_Previsao_de_Receita__c> rateiosPrevRec {
    get {
      if (rateiosPrevRec == null) {
        rateiosPrevRec = new List<Rateio_Previsao_de_Receita__c>();
        rateiosPrevRec.add(
          new Rateio_Previsao_de_Receita__c(
            Centro_de_custo__c = cc.Id,
            Item_Previsao_Receita__c = itemPrevRec.Id,
            Observacao__c = 'Rateio teste',
            Valor__c = itemPrevRec.Valor__c
          )
        );
        insert rateiosPrevRec;
      }
      return rateiosPrevRec;
    }
    set;
  }

  public static List<Recurso_Disponivel__c> recursosDisponiveis {
    get {
      if (recursosDisponiveis == null) {
        recursosDisponiveis = new List<Recurso_Disponivel__c>();
        for (Integer i = 0; i > -8; i--) {
          recursosDisponiveis.add(
            new Recurso_Disponivel__c(
              Empregado__c = empregado.Id,
              Data__c = Date.today().addDays(i - 1),
              Quantidade_de_horas__c = 8
            )
          );
        }
        insert recursosDisponiveis;
      }
      return recursosDisponiveis;
    }
    set;
  }

  private static List<Tarefa_projeto__c> tarefasValue;
  public static List<Tarefa_projeto__c> tarefas {
    get {
      if (tarefasValue == null) {
        tarefasValue = new List<Tarefa_projeto__c>();
        Tarefa_projeto__c tarefa1 = new Tarefa_projeto__c(
          Name = 'Tarefa teste1',
          Grupo_tarefa__c = gt.Id,
          Unidade_de_medida__c = 'Medida teste',
          Custo_medio_da_tarefa__c = 112
        );
        Tarefa_projeto__c tarefa2 = new Tarefa_projeto__c(
          Name = 'Tarefa teste2',
          Grupo_tarefa__c = gt.Id,
          Unidade_de_medida__c = 'Medida teste',
          Custo_medio_da_tarefa__c = 112
        );
        Tarefa_projeto__c tarefa3 = new Tarefa_projeto__c(
          Name = 'Tarefa teste3',
          Grupo_tarefa__c = gt.Id,
          Unidade_de_medida__c = 'Medida teste',
          Custo_medio_da_tarefa__c = 112
        );
        Tarefa_projeto__c tarefa4 = new Tarefa_projeto__c(
          Name = 'Tarefa teste4',
          Grupo_tarefa__c = gt.Id,
          Unidade_de_medida__c = 'Medida teste',
          Custo_medio_da_tarefa__c = 112
        );
        tarefasValue.add(tarefa1);
        tarefasValue.add(tarefa2);
        tarefasValue.add(tarefa3);
        tarefasValue.add(tarefa4);
        insert tarefasValue;
      }
      return tarefasValue;
    }
    private set;
  }

  private static Login__c loginValue;
  public static Login__c login {
    get {
      if (loginValue == null) {
        loginValue = new Login__c(
          Name = 'empregado@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginValue;
      }
      return loginValue;
    }
    private set;
  }

  private static Login__c loginApontadorValue;
  public static Login__c loginApontador {
    get {
      if (loginApontadorValue == null) {
        loginApontadorValue = new Login__c(
          Name = 'loginApontador@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginApontadorValue;
      }
      return loginApontadorValue;
    }
    private set;
  }

  private static Login__c loginValidadorValue;
  public static Login__c loginValidador {
    get {
      if (loginValidadorValue == null) {
        loginValidadorValue = new Login__c(
          Name = 'loginValidador@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginValidadorValue;
      }
      return loginValidadorValue;
    }
    private set;
  }

  private static List<Permissao_de_Sistema__c> permissoesSistemaApontadorValue;
  public static List<Permissao_de_Sistema__c> permissoesSistemaApontador {
    get {
      if (permissoesSistemaApontadorValue == null) {
        permissoesSistemaApontadorValue = new List<Permissao_de_Sistema__c>();
        Permissao_de_Sistema__c permissao00 = new Permissao_de_Sistema__c(
          Name = 'Apontamentos',
          Login__c = loginApontador.Id
        );
        permissoesSistemaApontadorValue.add(permissao00);
        insert permissoesSistemaApontadorValue;
      }
      return permissoesSistemaApontadorValue;
    }
    private set;
  }

  private static List<Permissao_de_Objeto__c> permissoesObjApontadorValue;
  public static List<Permissao_de_Objeto__c> permissoesObjApontador {
    get {
      if (permissoesObjApontadorValue == null) {
        permissoesObjApontadorValue = new List<Permissao_de_Objeto__c>();
        Permissao_de_Objeto__c permissao00 = new Permissao_de_Objeto__c(
          Name = 'Apontamento_Colaborador__c',
          Criar__c = true,
          Editar__c = true,
          Excluir__c = true,
          Exibir_todos__c = false,
          Lido__c = true,
          Modificar_todos__c = false,
          Login__c = loginApontador.Id
        );
        permissoesObjApontadorValue.add(permissao00);
        Permissao_de_Objeto__c permissao01 = new Permissao_de_Objeto__c(
          Name = 'Recurso_disponivel__c',
          Criar__c = false,
          Editar__c = false,
          Excluir__c = false,
          Exibir_todos__c = false,
          Lido__c = true,
          Modificar_todos__c = false,
          Login__c = loginApontador.Id
        );
        permissoesObjApontadorValue.add(permissao01);
        Permissao_de_Objeto__c permissao02 = new Permissao_de_Objeto__c(
          Name = 'Bloco_Projeto__c',
          Criar__c = false,
          Editar__c = false,
          Excluir__c = false,
          Exibir_todos__c = true,
          Lido__c = true,
          Modificar_todos__c = false,
          Login__c = loginApontador.Id
        );
        permissoesObjApontadorValue.add(permissao02);
        insert permissoesObjApontadorValue;
      }
      return permissoesObjApontadorValue;
    }
    private set;
  }

  public static Login__c loginAprovador {
    get {
      if (loginAprovador == null) {
        loginAprovador = new Login__c(
          Name = 'loginAprovador@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginAprovador;
      }
      return loginAprovador;
    }
    set;
  }

  public static Login__c loginSuperior {
    get {
      if (loginSuperior == null) {
        loginSuperior = new Login__c(
          Name = 'empregadoSuperior@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginSuperior;
      }
      return loginSuperior;
    }
    set;
  }
  public static Login__C loginRh {
    get {
      if (loginRh == null) {
        loginRh = new Login__c(
          Name = 'empregadodeptopessoal@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginRh;
      }
      return loginRh;
    }
    set;
  }

  public static Login__c loginComprador {
    get {
      if (loginComprador == null) {
        loginComprador = new Login__c(
          Name = 'empregadoComprador@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginComprador;
      }
      return loginComprador;
    }
    set;
  }

  public static Login__c loginSuporteTi {
    get {
      if (loginSuporteTi == null) {
        loginSuporteTi = new Login__c(
          Name = 'empregadoSuporteTi@teste.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginSuporteTi;
      }
      return loginSuporteTi;
    }
    set;
  }

  public static login__c loginAerolevantemento {
    get {
      if (loginAerolevantemento == null) {
        loginAerolevantemento = new Login__c(
          Name = 'empregadoAerolevantamento@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginAerolevantemento;
      }
      return loginAerolevantemento;
    }
    set;
  }

  public static Login__c loginManutencao {
    get {
      if (loginManutencao == null) {
        loginManutencao = new Login__c(
          Name = 'empregadoManutencao@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginManutencao;
      }
      return loginManutencao;
    }
    set;
  }

  public static Login__c loginGestorTi {
    get {
      if (loginGestorTi == null) {
        loginGestorTi = new Login__c(
          Name = 'loginGestorTi@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginGestorTi;
      }
      return loginGestorTi;
    }
    set;
  }

  public static Login__c loginGerenteProjeto {
    get {
      if (loginGerenteProjeto == null) {
        loginGerenteProjeto = new Login__c(
          Name = 'gerenteProjeto@engemap.com.br',
          Senha__c = 'teste',
          Trocar_senha__c = false
        );
        insert loginGerenteProjeto;
      }
      return loginGerenteProjeto;
    }
    set;
  }

  private static Mao_de_obra_da_fase__c mofValue;
  public static Mao_de_obra_da_fase__c mof {
    get {
      if (mofValue == null) {
        mofValue = new Mao_de_obra_da_fase__c(
          Fase_do_orcamento__c = fasesDoOrcamento[0].Id,
          Tarefa_do_Projeto__c = tarefaAero.Id,
          Quantidade__c = 1,
          Horas__c = 2
        );
        insert mofValue;
      }
      return mofValue;
    }
    private set;
  }

  public static Mapeamento_indicadores__c mapeamento {
    get {
      if (mapeamento == null) {
        mapeamento = new Mapeamento_indicadores__c(
          Name = 'Teste',
          Areas_envolvidas_processo__c = 'Teste',
          Documentos_aplicaveis__c = 'Teste',
          Empregados__c = 'Teste',
          Entrada_fornecedor__c = 'Teste',
          Entrada_insumo__c = 'Teste',
          Gestor__c = 'Teste',
          Interfaces_entrada__c = 'Teste',
          Interfaces_saida__c = 'Teste',
          KPI_monitoramento__c = 'Teste',
          Processos__c = 'Teste',
          Recursos__c = 'Teste',
          Saida_clientes__c = 'Teste',
          Saida_produtos__c = 'Teste',
          Sumaria_processo__c = 'Teste'
        );
        insert mapeamento;
      }
      return mapeamento;
    }
    set;
  }

  public static Mapeamento_Processos_Sugestao__c mapeamentoSugestao {
    get {
      if (mapeamentoSugestao == null) {
        mapeamentoSugestao = new Mapeamento_Processos_Sugestao__c(
          Empregado__c = empregado.Id,
          Lido__c = false,
          Mapeamento_de_indicadores__c = mapeamento.Id,
          Sugestao__c = 'Sugestão teste'
        );

        insert mapeamentoSugestao;
      }
      return mapeamentoSugestao;
    }
    set;
  }

  private static List<Material_da_fase__c> materiaisFaseValue;
  public static List<Material_da_fase__c> materiaisFase {
    get {
      if (materiaisFaseValue == null) {
        materiaisFaseValue = new List<Material_da_fase__c>();
        Fase_do_orcamento__c faseA = getFase('A', 0);
        String faseAName = faseA.Name + ' - Nível ' + faseA.Nivel__c;
        materiaisFaseValue.add(
          new Material_da_fase__c(
            Alias__c = '',
            Custo_unitario__c = 99,
            Fase_do_orcamento__c = faseA.Id,
            Item_do_Grupo_de_Produto__c = igps.Id,
            Nome_da_fase__c = faseAName,
            Produto_Name__c = igps.Name,
            Observacao__c = 'observação',
            Quantidade__c = 12,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Unidade__c = 'SERVICOS'
          )
        );
        materiaisFaseValue.add(
          new Material_da_fase__c(
            Alias__c = '',
            Custo_unitario__c = 50000,
            Fase_do_orcamento__c = faseA.Id,
            Item_do_Grupo_de_Produto__c = igps.Id,
            Nome_da_fase__c = faseAName,
            Produto_Name__c = igps.Name,
            Observacao__c = 'observação',
            Quantidade__c = 1,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Unidade__c = 'UNIDADE'
          )
        );
        materiaisFaseValue.add(
          new Material_da_fase__c(
            Alias__c = '',
            Custo_unitario__c = 1500,
            Fase_do_orcamento__c = faseA.Id,
            Item_do_Grupo_de_Produto__c = igps.Id,
            Nome_da_fase__c = faseAName,
            Produto_Name__c = igps.Name,
            Observacao__c = 'observação',
            Quantidade__c = 12,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Unidade__c = 'SERVICOS'
          )
        );
        materiaisFaseValue.add(
          new Material_da_fase__c(
            Alias__c = '',
            Custo_unitario__c = 3500,
            Fase_do_orcamento__c = faseA.Id,
            Item_do_Grupo_de_Produto__c = igps.Id,
            Nome_da_fase__c = faseAName,
            Produto_Name__c = igps.Name,
            Observacao__c = 'observação',
            Quantidade__c = 12,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Unidade__c = 'SERVICOS'
          )
        );
        materiaisFaseValue.add(
          new Material_da_fase__c(
            Alias__c = '',
            Custo_unitario__c = 150,
            Fase_do_orcamento__c = faseA.Id,
            Item_do_Grupo_de_Produto__c = igps.Id,
            Nome_da_fase__c = faseAName,
            Produto_Name__c = igps.Name,
            Observacao__c = 'observação',
            Quantidade__c = 1,
            Tarefa_do_Projeto__c = tarefaAero.Id,
            Unidade__c = 'SERVICOS'
          )
        );
        insert materiaisFaseValue;
      }
      return materiaisFaseValue;
    }
    private set;
  }

  private static Material_da_fase__c materialFaseValue;
  public static Material_da_fase__c materialFase {
    get {
      if (materialFaseValue == null) {
        materialFaseValue = new Material_da_fase__c(
          Custo_unitario__c = 1,
          Fase_do_orcamento__c = fasesDoOrcamento[0].Id,
          Item_do_Grupo_de_Produto__c = igps.Id,
          Nome_da_fase__c = fasesDoOrcamento[0].Name,
          Produto_Name__c = igps.Name,
          Observacao__c = 'observação',
          Quantidade__c = 1,
          Tarefa_do_Projeto__c = tarefaAero.Id,
          Unidade__c = 'unid'
        );
        insert materialFaseValue;
      }
      return materialFaseValue;
    }
    private set;
  }

  public static Motorista_Terceiro__c motorista {
    get {
      if (motorista == null) {
        motorista = new Motorista_Terceiro__c(
          Categoria_da_CNH__c = 'AB',
          CNH__c = '104556476',
          CNH_Anexa__c = cnhMotorista.Id,
          CPF__c = '456.732.988-34',
          Data_de_Nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Email__c = 'motorista@teste.com.br',
          Name = 'Motorista teste',
          RG__c = '34657938-8',
          Telefone__c = '18981223334',
          Vencimento_da_CNH__c = Date.today().addDays(100)
        );
        insert motorista;
      }
      return motorista;
    }
    set;
  }

  public static Mural__c mural {
    get {
      if (mural == null) {
        mural = new Mural__c(
          Colaborador__c = empregado.Id,
          Data__c = Date.valueOf('2018-01-24'),
          Importante__c = false,
          Titulo__c = 'teste 32',
          DS_Mensagem__c = 'Teste mensagem 32.'
        );
        insert mural;
      }
      return mural;
    }
    set;
  }

  public static Noticia__c noticia {
    get {
      if (noticia == null) {
        noticia = new Noticia__c(
          Publicado_por__c = empregado.Id,
          Revisado_por__c = empregado.Id,
          Name = 'Teste noticia',
          Introducao__c = 'Teste introdução',
          Corpo__c = 'teste corpo',
          Visibilidade__c = 'Todos'
        );
        insert noticia;
      }
      return noticia;
    }
    set;
  }

  public static Negocio_cooperativo__c negocioCoop {
    get {
      if (negocioCoop == null) {
        negocioCoop = new Negocio_cooperativo__c(
          Name = 'Nova Parceria',
          Oportunidade__c = op.Id,
          Tipo_parceria__c = 'Real'
        );
        insert negocioCoop;
      }
      return negocioCoop;
    }
    set;
  }

  public static Opportunity op {
    get {
      if (op == null) {
        op = new Opportunity(
          Name = 'Oportunidade teste',
          AccountId = conta.Id,
          StageName = 'Fechado e ganho',
          Probability = 100,
          CloseDate = Date.today(),
          Empresa_do_Grupo_Engemap__c = 'ENGEMAP',
          Fornecedor__c = 'Engemap',
          oportunidadeMotivoFechamento__c = 'Motivo teste',
          Despesas_do_orcamento__c = 500,
          Custo_de_M_o_de_obra__c = 1000,
          oportunidadeAerolevantamento__c = 2000,
          oportunidadePDIAereo__c = 3000,
          oportunidadeTopografiaCadastroTecnico__c = 4000,
          oportunidadeGeoprocessamento__c = 5000,
          Amount = 14000,
          oportunidadeTotal_calc__c = 1300,
          Data_da_entrega_do_or_amento_e_proposta__c = Date.TODAY(),
          Temperatura__c = 'Alta',
          Qualificacao_da_temperatura__c = 'Teste',
          oportunidadeUnidadesNegociosEnvolvidas__c = 'Teste'
        );
        insert op;
      }
      return op;
    }
    set;
  }

  public static Opportunity opSensormap {
    get {
      if (opSensormap == null) {
        opSensormap = new Opportunity(
          Name = 'Oportunidade teste Sensormap',
          AccountId = conta.Id,
          StageName = 'Fechado e ganho',
          Probability = 100,
          CloseDate = Date.today(),
          Empresa_do_Grupo_Engemap__c = 'SENSORMAP',
          Fornecedor__c = 'Engemap',
          oportunidadeMotivoFechamento__c = 'Motivo teste',
          Despesas_do_orcamento__c = 500,
          Custo_de_M_o_de_obra__c = 1000,
          oportunidadeAerolevantamento__c = 2000,
          oportunidadePDIAereo__c = 3000,
          oportunidadeTopografiaCadastroTecnico__c = 4000,
          oportunidadeGeoprocessamento__c = 5000,
          Amount = 14000,
          oportunidadeTotal_calc__c = 1300,
          Data_da_entrega_do_or_amento_e_proposta__c = Date.TODAY(),
          Temperatura__c = 'Alta',
          Qualificacao_da_temperatura__c = 'Teste',
          oportunidadeUnidadesNegociosEnvolvidas__c = 'Teste'
        );
        insert opSensormap;
      }
      return opSensormap;
    }
    set;
  }

  public static Opportunity opSatmap {
    get {
      if (opSatmap == null) {
        opSatmap = new Opportunity(
          Name = 'Oportunidade teste Satmap',
          AccountId = conta.Id,
          StageName = 'Fechado e ganho',
          Probability = 100,
          CloseDate = Date.today(),
          Empresa_do_Grupo_Engemap__c = 'SATMAP',
          Fornecedor__c = 'Engemap',
          oportunidadeMotivoFechamento__c = 'Motivo teste',
          Despesas_do_orcamento__c = 500,
          Custo_de_M_o_de_obra__c = 1000,
          oportunidadeAerolevantamento__c = 2000,
          oportunidadePDIAereo__c = 3000,
          oportunidadeTopografiaCadastroTecnico__c = 4000,
          oportunidadeGeoprocessamento__c = 5000,
          Amount = 14000,
          oportunidadeTotal_calc__c = 1300,
          Data_da_entrega_do_or_amento_e_proposta__c = Date.TODAY(),
          Temperatura__c = 'Alta',
          Qualificacao_da_temperatura__c = 'Teste',
          oportunidadeUnidadesNegociosEnvolvidas__c = 'Teste'
        );
        insert opSatmap;
      }
      return opSatmap;
    }
    set;
  }

  private static Orcamento__c orcamentoValue;
  public static Orcamento__c orcamento {
    get {
      if (orcamentoValue == null) {
        orcamentoValue = new Orcamento__c(
          Oportunidade__c = op.Id,
          Responsavel_pelo_orcamento__c = empregado.Id,
          Observacoes__c = 'observação',
          Fechado__c = false,
          usuarios__c = login.Name
        );
        insert orcamentoValue;
      }
      return orcamentoValue;
    }
    private set;
  }

  private static Orcamento__c orcamento59Value;
  public static Orcamento__c orcamento59 {
    get {
      if (orcamento59Value == null) {
        orcamento59Value = new Orcamento__c(
          Oportunidade__c = op.Id,
          Responsavel_pelo_orcamento__c = empregado.Id,
          Observacoes__c = 'observação',
          Fechado__c = false,
          usuarios__c = login.Name
        );
        insert orcamento59Value;
      }
      return orcamento59Value;
    }
    private set;
  }

  public static Permissao_do_Anexo__c permissaoAnexo {
    get {
      if (permissaoAnexo == null) {
        permissaoAnexo = new Permissao_do_Anexo__c(
          Anexo__c = anexos.get(0).Id,
          Empregado__c = empregado.Id
        );
        insert permissaoAnexo;
      }
      return permissaoAnexo;
    }
    set;
  }

  public static Pesquisa_Satisfacao_de_Cliente__c pesquisaSatisfacao {
    get {
      if (pesquisaSatisfacao == null) {
        pesquisaSatisfacao = new Pesquisa_Satisfacao_de_Cliente__c(
          FAP__c = fap.Id,
          Contato__c = contato.Id,
          Data_da_disponibilizacao__c = date.today(),
          Data_da_pesquisa__c = date.today(),
          Preenchido__c = true,
          NA_atendimento_comercial__c = false,
          NA_gestao_de_projetos__c = false,
          NA_disponibilidade__c = false,
          NA_prazo__c = false,
          Grau_do_atendimento_comercial__c = 3,
          Grau_gestao_projetos__c = 3,
          Grau_disponibilidade__c = 3,
          Grau_Prazo__c = 3,
          Nota_do_atendimento_comercial__c = 3,
          Nota_gestao_projetos__c = 3,
          Nota_disponibilidade__c = 3,
          Nota_prazo__c = 3,
          NA_qualidade__c = false,
          NA_documentacao__c = false,
          NA_entrega__c = false,
          NA_produtos_servicos__c = false,
          Grau_qualidade__c = 3,
          Grau_documentacao__c = 3,
          Grau_entrega__c = 3,
          Grau_produtos_servicos__c = 3,
          Nota_qualidade__c = 3,
          Nota_documentacao__c = 3,
          Nota_entrega__c = 3,
          Nota_produtos_servicos__c = 3,
          NA_qualidade_comunicacao__c = false,
          NA_imagem__c = false,
          Grau_qualidade_comunicacao__c = 3,
          Grau_imagem__c = 3,
          Nota_qualidade_comunicacao__c = 3,
          Nota_imagem__c = 3,
          Email__c = 'email@example.com',
          Nome_do_Cliente__c = 'Testildo Xablau',
          Empresa_do_Cliente__c = 'Xablau company',
          Cargo_do_Cliente__c = 'Xablazista',
          Como_Conheceu__c = 'Teste conheceu',
          AtendimentoComercial__c = 3,
          ComunicacaoProjeto__c = 3,
          EquipeEngenharia__c = 3,
          CapacidadeResolucao__c = 3,
          InfoInstitucional__c = 3,
          EnvolvidoInformado__c = 3,
          PrazoCumprido__c = 3,
          ResultadoFinal__c = 3,
          QualidadeTrabalho__c = 3,
          SugestoesMelhoria__c = 'Sugestao teste',
          Recomendaria__c = 'Sim'
        );
        insert pesquisaSatisfacao;
      }
      return pesquisaSatisfacao;
    }
    set;
  }

  public static Pesquisa_Satisfacao_de_Cliente__c pesquisaSatisfacaoEmpty {
    get {
      if (pesquisaSatisfacaoEmpty == null) {
        pesquisaSatisfacaoEmpty = new Pesquisa_Satisfacao_de_Cliente__c(
          FAP__c = fap.Id,
          Contato__c = contato.Id,
          Data_da_disponibilizacao__c = date.today().addDays(5),
          Data_da_pesquisa__c = date.today().addDays(5)
        );
        insert pesquisaSatisfacaoEmpty;
      }
      return pesquisaSatisfacaoEmpty;
    }
    set;
  }

  public static Plano_acao__c planoAcao {
    get {
      if (planoAcao == null) {
        planoAcao = new Plano_acao__c(
          Analise_abrangencia__c = 'Teste',
          Causa_raiz__c = 'Teste',
          Criterio_verificacao__c = 'Teste',
          Descricao_nc__c = 'Teste',
          Efeito__c = 'Teste',
          Mao_obra__c = 'Teste',
          Maquina__c = 'Teste',
          Materia_prima__c = 'Teste',
          Medicao__c = 'Teste',
          Medida_contencao__c = 'Teste',
          Meio_ambiente__c = 'Teste',
          Prazo_verificacao__c = Date.TODAY()
        );
        insert planoAcao;
      }
      return planoAcao;
    }
    set;
  }

  public static Plano_Conta__c pc {
    get {
      if (pc == null) {
        pc = new Plano_Conta__c(
          Codigo_externo__c = '402000099',
          Name = 'Conta teste',
          Classe__c = 'Classe teste'
        );
        insert pc;
      }
      return pc;
    }
    set;
  }

  private static Planejamento_Projeto__c planejamentoValue;
  public static Planejamento_Projeto__c planejamento {
    get {
      if (planejamentoValue == null) {
        // com adição da trigger que cria planejamentos, é necessário consultar no banco de dados
        List<Planejamento_Projeto__c> planejamentoExistente = [
          SELECT
            Id,
            Termo_de_Abertura__c,
            Status_do_projeto__c,
            isCronogramaManual__c,
            Modelo_planejamento__c
          FROM Planejamento_Projeto__c
          WHERE Termo_de_Abertura__c = :termoAbertura.Id
          LIMIT 1
        ];
        if (planejamentoExistente.size() > 0)
          planejamentoValue = planejamentoExistente[0];
      }
      return planejamentoValue;
    }
    private set;
  }

  private static Planejamento_Projeto__c planejamentoManualValue;
  public static Planejamento_Projeto__c planejamentoManual {
    get {
      if (planejamentoManualValue == null) {
        // com adição da trigger que cria planejamentos, é necessário consultar no banco de dados
        List<Planejamento_Projeto__c> planejamentoExistente = [
          SELECT
            Id,
            Termo_de_Abertura__c,
            Status_do_projeto__c,
            isCronogramaManual__c,
            Modelo_planejamento__c
          FROM Planejamento_Projeto__c
          WHERE Termo_de_Abertura__c = :termoAberturaManual.Id
          LIMIT 1
        ];
        if (planejamentoExistente.size() > 0) {
          planejamentoManualValue = planejamentoExistente[0];
          planejamentoManualValue.isCronogramaManual__c = true;
          update planejamentoManualValue;
        }
      }
      return planejamentoManualValue;
    }
    private set;
  }

  private static Plano_de_Trabalho__c planoTrabalhoValue;
  public static Plano_de_Trabalho__c planoTrabalho {
    get {
      if (planoTrabalhoValue == null) {
        // seleciona o plano de trabalho ao invés de inserir porque ele é criado automaticamente
        Id planejamentoId = planejamento.Id;
        List<Plano_de_Trabalho__c> planos = [
          SELECT Id, Name
          FROM Plano_de_Trabalho__c
          WHERE Planejamento_do_projeto__c = :planejamentoId
        ];
        if (!planos.isEmpty()) {
          planoTrabalhoValue = planos[0];
        }
      }
      return planoTrabalhoValue;
    }
    private set;
  }

  private static Previsao_Despesa__c previsaoDespesaValue;
  public static Previsao_Despesa__c previsaoDespesa {
    get {
      if (previsaoDespesaValue == null) {
        // quando cria um planejamento, uma previsao de despesa é criada
        previsaoDespesaValue = [
          SELECT
            Id,
            Planejamento_projeto__c,
            Versao__c,
            isLastVersion__c,
            allowEdition__c
          FROM Previsao_Despesa__c
          WHERE Planejamento_projeto__c = :planejamento.Id
        ];
      }
      return previsaoDespesaValue;
    }
    private set;
  }

  public static Previsao_Receita__c previsaoReceita {
    get {
      if (previsaoReceita == null) {
        previsaoReceita = [
          SELECT Id, Versao__c
          FROM Previsao_Receita__c
          WHERE Planejamento_projeto__c = :planejamento.Id
        ];
      }
      return previsaoReceita;
    }
    set;
  }

  public static Produto_de_Compra__c produto {
    get {
      if (produto == null) {
        produto = new Produto_de_Compra__c(
          Name = 'Produto teste',
          Conta_contabil__c = pc.Id,
          Conta_custo__c = pc.Id,
          Tipo__c = 'SERVICO',
          Unidade_de_Medida__c = 'Unidade teste',
          Preco_medio__c = 150.67
        );
        insert produto;
      }
      return produto;
    }
    set;
  }

  public static Produto_planejado__c produtoPlanejado {
    get {
      if (produtoPlanejado == null) {
        produtoPlanejado = new Produto_planejado__c(
          Data_inicial__c = Date.today(),
          Data_final__c = Date.today(),
          Cronograma__c = cronograma.Id,
          Horas_planejadas__c = 40,
          Grupo_tarefa__c = gt.Id
        );
        insert produtoPlanejado;
      }
      return produtoPlanejado;
    }
    set;
  }

  public static Processo__c processo {
    get {
      if (processo == null) {
        processo = new Processo__c(Status__c = 'Em andamento');
        insert processo;
      }
      processo = [
        SELECT
          Id,
          Name,
          Data_Encerramento__c,
          Dono_Solicitacao__c,
          Encerrado__c,
          Pagina_Formulario__c,
          Solicitante__c,
          Status__c,
          Tipo__c
        FROM Processo__c
        WHERE Id = :processo.Id
      ];
      return processo;
    }
    set;
  }

  public static ProcessoEtapa__c processoEtapa {
    get {
      if (processoEtapa == null) {
        processoEtapa = new ProcessoEtapa__c(
          Name = 'Cadastro',
          Processo__c = processo.Id,
          Empregado__c = empregado.Id,
          Grupo__c = gruposSolicitacaoSuporte.get(0).Id
        );
        insert processoEtapa;
      }
      return processoEtapa;
    }
    set;
  }

  public static Recurso_Disponivel__c recursoDisponivel {
    get {
      if (recursoDisponivel == null) {
        recursoDisponivel = new Recurso_Disponivel__c(
          Empregado__c = empregado.Id,
          Data__c = Date.today(),
          Quantidade_de_horas__c = 8
        );
        insert recursoDisponivel;
      }
      return recursoDisponivel;
    }
    set;
  }

  /*
     * Reunião foi descontinuado
    public static Reuniao__c reuniao {
        get {
            if (reuniao == null) {
                reuniao = new Reuniao__c(
                    Solicitado_por__c = empregado.Id,
                Preenchido_por__c = empregado.Id,
                Sala__c = 'Teste',
                Motivo__c = 'Teste',
                Data__c = date.today(),
                Horario_inicial__c = '08:00',
                Horario_final__c = '12:00',
                Quantidade_de_pessoas__c = 5
                    );
                insert reuniao;
            }
            return reuniao;
        }
        set;
    }*/

  public static Setor__c setorPai {
    get {
      if (setorPai == null) {
        setorPai = new Setor__c(
          Ativo__c = true,
          Centro_de_Custo__c = cc.Id,
          Name = 'Setor pai',
          Setor_Pai__c = null
        );
        insert setorPai;
      }
      return setorPai;
    }
    set;
  }

  public static Setor__c subSetor {
    get {
      if (subSetor == null) {
        subSetor = new Setor__c(
          Ativo__c = true,
          Centro_de_Custo__c = cc.Id,
          Name = 'Sub setor',
          Setor_Pai__c = setorPai.Id
        );
        insert subSetor;
      }
      return subSetor;
    }
    set;
  }

  public static Solicitacao_apontamento__c solicitacao {
    get {
      if (solicitacao == null) {
        solicitacao = new Solicitacao_apontamento__c(
          Data_aprovacao__c = Datetime.now(),
          Data_solicitacao__c = Datetime.now(),
          Data_inicial__c = Date.today(),
          FAP__c = fap.Id,
          Funcionario__c = empregado.Id,
          Grupo_tarefa__c = gt.Id,
          Tarefa_projeto__c = tarefa.Id,
          Hora_final__c = '20:00',
          Hora_inicial__c = '18:01',
          Observacao__c = 'Teste'
        );
        insert solicitacao;
      }
      return solicitacao;
    }
    set;
  }

  public static Solicitacao_Compra__c frmSolCompra {
    get {
      if (frmSolCompra == null) {
        frmSolCompra = new Solicitacao_Compra__c(
          Processo__c = processo.Id,
          Tipo_de_Solicitacao__c = 'Cotação e Compra'
        );

        insert frmSolCompra;
      }
      return frmSolCompra;
    }
    set;
  }

  public static Solicitacao_Compra__c frmSolCompraCotacao {
    get {
      if (frmSolCompra == null) {
        frmSolCompra = new Solicitacao_Compra__c(
          Processo__c = processo.Id,
          Tipo_de_Solicitacao__c = 'Cotação'
        );

        insert frmSolCompra;
      }
      return frmSolCompra;
    }
    set;
  }

  public static Solicitacao_Veiculo__c frmSolVeiculo {
    get {
      if (frmSolVeiculo == null) {
        frmSolVeiculo = new Solicitacao_Veiculo__c(Processo__c = processo.Id);
        insert frmSolVeiculo;
      }
      return frmSolVeiculo;
    }
    set;
  }

  public static Solicitacao_de_Manutencao__c frmSolManutencao {
    get {
      if (frmSolManutencao == null) {
        frmSolManutencao = new Solicitacao_de_Manutencao__c(
          Processo__c = processo.Id
        );
        insert frmSolManutencao;
      }
      return frmSolManutencao;
    }
    set;
  }

  public static Solicitacao_Compra_Item__c itemSolCompra {
    get {
      if (itemSolCompra == null) {
        itemSolCompra = new Solicitacao_Compra_Item__c(
          Solicitacao_Compra__c = frmSolCompra.Id
        );
        insert itemSolCompra;
      }
      return itemSolCompra;
    }
    set;
  }

  public static Solicitacao_Suporte__c frmSolSuporte {
    get {
      if (frmSolSuporte == null) {
        frmSolSuporte = new Solicitacao_Suporte__c(
          Processo__c = processo.Id,
          Tipo__c = 'Suporte TI'
        );
        insert frmSolSuporte;
      }
      return frmSolSuporte;
    }
    set;
  }

  public static Solicitacao_Viagem__c frmSolViagem {
    get {
      if (frmSolViagem == null) {
        frmSolViagem = new Solicitacao_Viagem__c(
          Processo__c = processo.Id,
          Tipo_Cadastro__c = 'Adiantamento',
          fap__c = fap.Id
        );
        insert frmSolViagem;
      }
      return frmSolViagem;
    }
    set;
  }

  public static Status_do_Funcionario__c statusFuncionario {
    get {
      if (statusFuncionario == null) {
        statusFuncionario = new Status_do_Funcionario__c(
          Funcionario__c = empregado.Id,
          FAP__c = fap.Id,
          Data__c = Date.today()
        );
        insert statusFuncionario;
      }
      return statusFuncionario;
    }
    set;
  }

  private static Tarefa_projeto__c tarefaValue;
  public static Tarefa_projeto__c tarefa {
    get {
      if (tarefaValue == null) {
        tarefaValue = new Tarefa_projeto__c(
          Name = 'Tarefa teste',
          Grupo_tarefa__c = gt.Id,
          Unidade_de_medida__c = 'Medida teste',
          Provisorio__c = false,
          TemplateCode__c = 'MO12345'
        );
        insert tarefaValue;
      }
      return tarefaValue;
    }
    private set;
  }

  public static Tarefa_projeto__c tarefaAero {
    get {
      if (tarefaAero == null) {
        tarefaAero = new Tarefa_projeto__c(
          Name = 'Tarefa aero',
          Grupo_tarefa__c = aeroGt.Id,
          Unidade_de_medida__c = 'Medida teste',
          TemplateCode__c = 'MO1234'
        );
        insert tarefaAero;
      }
      return tarefaAero;
    }
    set;
  }

  private static Tarefa_projeto__c tarefaParadaValue;
  public static Tarefa_projeto__c tarefaParada {
    get {
      if (tarefaParadaValue == null) {
        tarefaParadaValue = new Tarefa_projeto__c(
          Name = 'Parada de atividade',
          Grupo_tarefa__c = grupoParada.Id,
          Unidade_de_medida__c = 'Medida teste'
        );
        insert tarefaParadaValue;
      }
      return tarefaParadaValue;
    }
    set;
  }

  public static Tarefa_projeto__c tarefaTopo {
    get {
      if (tarefaTopo == null) {
        tarefaTopo = new Tarefa_projeto__c(
          Name = 'Tarefa topo',
          Grupo_tarefa__c = topoGt.Id,
          Unidade_de_medida__c = 'Medida teste'
        );
        insert tarefaTopo;
      }
      return tarefaTopo;
    }
    set;
  }

  public static Tarefa_do_Produto__c tarefaProduto {
    get {
      if (tarefaProduto == null) {
        tarefaProduto = new Tarefa_do_Produto__c(
          Produto_planejado__c = produtoPlanejado.Id,
          Horas_planejadas__c = 100,
          Custo_medio_da_hora__c = 15,
          Tarefa_projeto__c = tarefa.Id
        );
        insert tarefaProduto;
      }
      return tarefaProduto;
    }
    set;
  }

  public static Tarefa_produto_realizada__c tarefaRealizada {
    get {
      if (tarefaRealizada == null) {
        tarefaRealizada = new Tarefa_produto_realizada__c(
          FAP__c = fap.Id,
          Tarefa_projeto__c = tarefa.Id
        );
        insert tarefaRealizada;
      }
      return tarefaRealizada;
    }
    set;
  }

  public static Tarefa_produto_realizada__c tarefaRealizadaParada {
    get {
      if (tarefaRealizadaParada == null) {
        tarefaRealizadaParada = new Tarefa_produto_realizada__c(
          FAP__c = fapEngemap.Id,
          Tarefa_projeto__c = tarefaParada.Id
        );
        insert tarefaRealizadaParada;
      }
      return tarefaRealizadaParada;
    }
    set;
  }

  public static Tarefa_produto_realizada__c trp {
    get {
      if (trp == null) {
        trp = new Tarefa_produto_realizada__c(
          FAP__c = fap.Id,
          Tarefa_projeto__c = tarefa.Id
        );
        insert trp;
      }
      return trp;
    }
    set;
  }

  private static Task taskOpValue;
  public static Task taskOp {
    get {
      if (taskOpValue == null) {
        taskOpValue = new Task(
          WhatId = op.Id,
          Status = 'Não iniciado',
          ActivityDate = Date.today().addDays(1)
        );
        insert taskOpValue;
      }
      return taskOpValue;
    }
    private set;
  }

  private static List<Terceirizacao_da_fase__c> terceirizacoesFaseValue;
  public static List<Terceirizacao_da_fase__c> terceirizacoesFase {
    get {
      if (terceirizacoesFaseValue == null) {
        terceirizacoesFaseValue = new List<Terceirizacao_da_fase__c>();
        Fase_do_orcamento__c faseA = getFase('A', 0);
        String faseAName = faseA.Name + ' - Nível ' + faseA.Nivel__c;
        terceirizacoesFaseValue.add(
          new Terceirizacao_da_fase__c(
            Custo_unitario__c = 300,
            Fase_do_orcamento__c = faseA.Id,
            Nome_da_fase__c = faseAName,
            Quantidade__c = 53.3,
            Tarefa_do_Projeto__c = tarefaAero.Id
          )
        );
        terceirizacoesFaseValue.add(
          new Terceirizacao_da_fase__c(
            Custo_unitario__c = 150,
            Fase_do_orcamento__c = faseA.Id,
            Nome_da_fase__c = faseAName,
            Quantidade__c = 55.3,
            Tarefa_do_Projeto__c = tarefaAero.Id
          )
        );
        Fase_do_orcamento__c faseC1 = getFase('C1', 1);
        String faseC1Name = faseC1.Name + ' - Nível ' + faseC1.Nivel__c;
        terceirizacoesFaseValue.add(
          new Terceirizacao_da_fase__c(
            Custo_unitario__c = 1,
            Fase_do_orcamento__c = faseC1.Id,
            Nome_da_fase__c = faseC1Name,
            Quantidade__c = 55.3,
            Tarefa_do_Projeto__c = tarefaAero.Id
          )
        );

        insert terceirizacoesFaseValue;
      }
      return terceirizacoesFaseValue;
    }
    private set;
  }

  private static Terceirizacao_da_fase__c terceirizacaoFaseValue;
  public static Terceirizacao_da_fase__c terceirizacaoFase {
    get {
      if (terceirizacaoFaseValue == null) {
        terceirizacaoFaseValue = new Terceirizacao_da_fase__c(
          Custo_unitario__c = 1,
          Fase_do_orcamento__c = fasesDoOrcamento[0].Id,
          Nome_da_fase__c = fasesDoOrcamento[0].Name,
          Quantidade__c = 1,
          Tarefa_do_Projeto__c = tarefaAero.Id
        );
        insert terceirizacaoFaseValue;
      }
      return terceirizacaoFaseValue;
    }
    private set;
  }

  private static Termo_de_Abertura__c termoAberturaValue;
  public static Termo_de_Abertura__c termoAbertura {
    get {
      if (termoAberturaValue == null) {
        termoAberturaValue = new Termo_de_Abertura__c(
          FAP__c = fap.Id,
          Gerente_do_Projeto__c = gerenteProjeto.Id
        );
        insert termoAberturaValue;
      }
      return termoAberturaValue;
    }
    private set;
  }

  public static Termo_de_Abertura__c termoAberturaManual {
    get {
      if (termoAberturaManual == null) {
        termoAberturaManual = new Termo_de_Abertura__c(
          FAP__c = fapManual.Id,
          Gerente_do_Projeto__c = empregado.Id
        );
        insert termoAberturaManual;
      }
      return termoAberturaManual;
    }
    set;
  }

  public static Tratativa_plano_acao__c tratativaPlano {
    get {
      if (tratativaPlano == null) {
        tratativaPlano = new Tratativa_plano_acao__c(
          Acao__c = 'Teste',
          Plano_acao__c = planoAcao.Id,
          Prazo__c = Date.TODAY()
        );
        insert tratativaPlano;
      }
      return tratativaPlano;
    }
    set;
  }

  public static Turno__c turno {
    get {
      if (turno == null) {
        turno = new Turno__c(Name = 'Turno teste');
        insert turno;
        // força criar os horários
        List<Horario__c> horariosCriados = horarios;
      }
      return turno;
    }
    set;
  }

  public static Turno__c turno2 {
    get {
      if (turno2 == null) {
        turno2 = new Turno__c(Name = 'Turno teste');
        insert turno2;
        // força criar os horários
        List<Horario__c> horariosCriados = horarios2;
      }
      return turno2;
    }
    set;
  }

  private static Profile profileComumValue;
  public static Profile profileComum {
    get {
      if (profileComumValue == null) {
        profileComumValue = [
          SELECT Id
          FROM Profile
          WHERE Name = 'Usuário Padrão'
          LIMIT 1
        ];
      }
      return profileComumValue;
    }
    private set;
  }

  private static User usuarioValue;
  public static User usuario {
    get {
      if (usuarioValue == null) {
        usuarioValue = new User(
          Alias = 'tuser',
          Email = 'testeuser@example.com',
          EmailEncodingKey = 'UTF-8',
          LastName = 'Usuário',
          LanguageLocaleKey = 'pt_BR',
          LocaleSidKey = 'pt_BR',
          ProfileId = profileComum.Id,
          TimeZoneSidKey = 'America/Sao_Paulo',
          Username = 'testeuser' + DateTime.now().getTime() + '@example.com'
        );
        insert usuarioValue;
      }
      return usuarioValue;
    }
    private set;
  }

  public static Viagem__c viagem {
    get {
      if (viagem == null) {
        viagem = new Viagem__c(
          Empregado__c = empregado.Id,
          FAP__c = fap.Id,
          Data_de_partida__c = Date.today(),
          Data_de_retorno__c = Date.today()
        );
        insert viagem;
      }
      return viagem;
    }
    set;
  }

  //APP GEO
  public static List<Opportunity> listaOpEmAndamento { get; set; }
  public static List<Opportunity> listaOpFechadoPerdido { get; set; }
  public static List<Opportunity> listaOpFechadoGanho { get; set; }
  public static List<FAP__c> listaFap { get; set; }

  //SITE
  public static Termo_de_abertura__c termoCliente { get; set; }
  public static Planejamento_projeto__c planejamentoCliente { get; set; }
  public static Cronograma_projeto__c cronogramaCliente { get; set; }
  public static Estrutura__c estruturaCliente { get; set; }
  public static Apontamento__c apontamentoCliente { get; set; }

  public static void carregaDadosSite() {
  }

  public static Date getNextSaturday() {
    for (Integer i = 0; i < 7; i++) {
      Date dataAtual = Date.today().addDays(i);
      if (Util.getDayName(dataAtual) == 'Sat') {
        return dataAtual;
      }
    }
    return null;
  }

  //NOVOS PARA TESTAR CONTROLEHORASVOO
  //Classe empregado Piloto
  public static Empregado__c empregadoPiloto {
    get {
      if (empregadoPiloto == null) {
        empregadoPiloto = new Empregado__c(
          Name = 'Empregado Piloto',
          Funcao__c = funcaoPiloto.id,
          Email__c = 'empregadoPiloto@teste.com.br',
          Centro_custo__c = cc.Id,
          Login__c = loginAerolevantemento.Id,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Turno__c = turno.Id,
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Qtde_horas_semanais__c = 44,
          valor_hora_producao__c = 30,
          Perfil_de_Gerente_de_Projetos__c = true,
          Realiza_apontamentos__c = true,
          Criar_EngC__c = true,
          Redator__c = true,
          Valida_planejamento__c = true,
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id
        );
        insert empregadoPiloto;
      }
      return empregadoPiloto;
    }
    set;
  }

  //Classe empregado operador eq esp
  public static Empregado__c empregadoOpEquipEsp {
    get {
      if (empregadoOpEquipEsp == null) {
        empregadoOpEquipEsp = new Empregado__c(
          Name = 'Empregado OPERADOR DE EQUIP ESPECIAIS',
          Funcao__c = funcaoOperadorDeEquipEspeciais.id,
          Email__c = 'empregadoOpEquipEsp@teste.com.br',
          Centro_custo__c = cc.Id,
          Login__c = loginAerolevantemento.Id,
          Data_admissao__c = Date.today().addDays(-10),
          Data_de_nascimento__c = Date.newInstance(
            Date.today().year() - 35,
            Date.today().month(),
            Date.today().day()
          ),
          Turno__c = turno.Id,
          Salario__c = 1000,
          Salario_PJ__c = 0,
          Qtde_horas_semanais__c = 44,
          valor_hora_producao__c = 30,
          Perfil_de_Gerente_de_Projetos__c = true,
          Realiza_apontamentos__c = true,
          Criar_EngC__c = true,
          Redator__c = true,
          Valida_planejamento__c = true,
          Carteira_de_Habilitacao__c = '10233456',
          Categoria_cnh__c = 'AB',
          Celular__c = '18789666999',
          CPF_DadosPessoais__c = '792.195.088-42',
          RG_DadosPessoais__c = '567463328',
          Telefone__c = '1834212525',
          Vencimento_da_CNH__c = Date.today().addDays(250),
          empresa_contratante__c = empresa.Id
        );
        insert empregadoOpEquipEsp;
      }
      return empregadoOpEquipEsp;
    }
    set;
  }

  public static Funcao__c funcaoPiloto {
    get {
      if (funcaoPiloto == null) {
        funcaoPiloto = new Funcao__c(Name = 'PILOTO');
        insert funcaoPiloto;
      }
      return funcaoPiloto;
    }
    set;
  }

  public static Funcao__c funcaoOperadorDeEquipEspeciais {
    get {
      if (funcaoOperadorDeEquipEspeciais == null) {
        funcaoOperadorDeEquipEspeciais = new Funcao__c(
          Name = 'OPERADOR DE EQUIP ESPECIAIS'
        );
        insert funcaoOperadorDeEquipEspeciais;
      }
      return funcaoOperadorDeEquipEspeciais;
    }
    set;
  }

  public static Grupo__c grupoAerolevantamento {
    get {
      if (grupoAerolevantamento == null) {
        grupoAerolevantamento = new Grupo__c(Name = 'Aerolevantamento');
        insert grupoAerolevantamento;
      }
      return grupoAerolevantamento;
    }
    set;
  }

  public static Grupo_Funcionarios__c funcionariosAero {
    get {
      if (funcionariosAero == null) {
        funcionariosAero = new Grupo_Funcionarios__c(
          Grupo__c = grupoAerolevantamento.Id,
          Empregado__c = funcionariosAero.Id
        );
        insert funcionariosAero;
      }
      return funcionariosAero;
    }
    set;
  }

  public static Aeronave__c aeronaveTeste {
    get {
      if (aeronaveTeste == null) {
        aeronaveTeste = new Aeronave__c(
          Name = 'PT-ABC',
          Modelo__c = 'EMB-810C',
          Fabricante__c = 'EMBRAER',
          Ano_de_Fabricacao__c = 1982,
          Ativo__c = true,
          Horas_Totais_de_Voo__c = 7040.7,
          Consumo__c = 80,
          Consumo_translado__c = 105,
          Velocidade_media__c = 230,
          Velocidade_media_translado__c = 230,
          Hora_Ultima_Revisao__c = 100
        );
        insert aeronaveTeste;
      }
      return aeronaveTeste;
    }
    set;
  }

  // ── Mocks HTTP reutilizáveis (Nextcloud) ──────────────────────────────────

  /** Mock: API de pasta retorna criação bem-sucedida (HTTP 201 + success:true) */
  public class MockPastaSucesso implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(201);
      res.setBody('{"success":true}');
      return res;
    }
  }

  /** Mock: API retorna falha de permissão (HTTP 200 + success:false) */
  public class MockFalhaPermissao implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(200);
      res.setBody('{"success":false,"error":"Permissão negada"}');
      return res;
    }
  }

  /** Mock: API de pasta (mkdir) retorna falha (HTTP 201 + success:false) */
  public class MockFalhaPasta implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(201);
      res.setBody('{"success":false,"error":"Permissão negada"}');
      return res;
    }
  }

  /** Mock: Servidor retorna HTTP 500 */
  public class MockErroServidor implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
      HttpResponse res = new HttpResponse();
      res.setStatusCode(500);
      res.setStatus('Internal Server Error');
      res.setBody('');
      return res;
    }
  }

  // ── Factories de Documento_do_Empregado__c (não inseridos) ────────────────

  /** Retorna Documento_do_Empregado__c com Caminho_Arquivo_Nuvem__c (sem insert) */
  public static Documento_do_Empregado__c getDocumentoNuvem(Id empregadoId) {
    return new Documento_do_Empregado__c(
      Name = 'Documento Nuvem Teste',
      Classe__c = 'Classe teste Nuvem',
      Tipo__c = 'Tipo teste Nuvem',
      Caminho_Arquivo_Nuvem__c = '/RH-DP/Colaboradores/Teste/Admissao/documento_teste.pdf',
      Empregado__c = empregadoId,
      Extensao_do_arquivo__c = 'PDF',
      Data_de_Criacao__c = Date.today(),
      Data_de_Validade__c = Date.today().addYears(1)
    );
  }

  /** Retorna Documento_do_Empregado__c completo (contrato de admissão) para testes de fluxo integrado (sem insert) */
  public static Documento_do_Empregado__c getDocumentoContrato(Id empregadoId) {
    return new Documento_do_Empregado__c(
      Name = 'Contrato_Admissao.pdf',
      Empregado__c = empregadoId,
      Caminho_Arquivo_Nuvem__c = '/RH-DP/Colaboradores/Teste/Admissao/Contrato_Admissao.pdf',
      Extensao_do_arquivo__c = 'PDF',
      Classe__c = 'Admissao',
      Tipo__c = 'Contrato',
      Descricao__c = 'Contrato de admissão do empregado',
      Data_de_Validade__c = Date.today().addYears(1),
      Comentarios_Versao__c = 'Versão inicial',
      Tamanho_Arquivo__c = 102400
    );
  }

  /** Retorna Documento_do_Empregado__c legado com ContentVersion (sem insert do documento) */
  public static Documento_do_Empregado__c getDocumentoLegado(Id empregadoId) {
    Blob fileBody = Blob.valueOf('Conteúdo de teste para documento legado.');
    ContentVersion cv = new ContentVersion();
    cv.VersionData = fileBody;
    cv.Title = 'arquivo_legado_teste.txt';
    cv.PathOnClient = 'arquivo_legado_teste.txt';
    cv.FirstPublishLocationId = empregadoId;
    insert cv;
    cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    return new Documento_do_Empregado__c(
      Name = 'Documento Legado Teste',
      Classe__c = 'Classe teste Legado',
      Tipo__c = 'Tipo teste Legado',
      ContentDocumentId__c = cv.ContentDocumentId,
      ContentVersionId__c = cv.Id,
      Empregado__c = empregadoId,
      Extensao_do_arquivo__c = 'TXT',
      Data_de_Criacao__c = Date.today(),
      Data_de_Validade__c = Date.today().addYears(1)
    );
  }
}