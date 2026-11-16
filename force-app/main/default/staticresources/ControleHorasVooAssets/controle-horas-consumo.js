/**
 * Aba "Consumo": consumo de combustível, média L/h e emissões de CO2 por
 * aeronave e ano. Os dados chegam de uma vez (agregados por aeronave, mês e
 * tipo de voo) e todos os filtros rodam no navegador, sem nova ida ao servidor.
 */
(function () {
    'use strict';

    const MESES = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    const CORES = {
        tr: '#007bff',
        trSuave: 'rgba(0, 123, 255, 0.32)',
        sa: '#28a745',
        saSuave: 'rgba(40, 167, 69, 0.32)',
        co2: '#d9480f',
        co2Suave: 'rgba(217, 72, 15, 0.3)',
        co2Fundo: 'rgba(217, 72, 15, 0.12)',
        texto: '#2e2e2e',
        textoSuave: '#5c5c5c',
        grade: '#e6e9ec',
        tooltip: '#003349'
    };
    const FORMATO = {
        inteiro: new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 0 }),
        decimal: new Intl.NumberFormat('pt-BR', { minimumFractionDigits: 1, maximumFractionDigits: 1 }),
        moeda: new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' })
    };
    const SEM_VALOR = '–';
    const FATOR_PADRAO = 2.31;

    const estado = {
        dados: null,
        carregando: false,
        erro: '',
        ano: null,
        aeronaves: null, // null = todas as aeronaves
        visao: 'mensal',
        carregadoEm: null,
        exportando: false,
        avisoExportacao: ''
    };
    const graficos = {};
    let raiz = null;
    let refs = {};

    // ------------------------------------------------------------------
    // Utilidades
    // ------------------------------------------------------------------

    function reduzMovimento() {
        return typeof window.matchMedia === 'function'
            && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    }

    function criar(tag, classe, texto) {
        const elemento = document.createElement(tag);
        if (classe) elemento.className = classe;
        if (texto != null) elemento.textContent = texto;
        return elemento;
    }

    function formatar(valor, formato) {
        return valor == null || !isFinite(valor) ? SEM_VALOR : formato.format(valor);
    }

    function formatarOuTraco(valor, formato) {
        return valor == null || !isFinite(valor) || valor === 0 ? SEM_VALOR : formato.format(valor);
    }

    function fator() {
        return (estado.dados && estado.dados.fatorCo2) || FATOR_PADRAO;
    }

    // ------------------------------------------------------------------
    // Cálculos
    // ------------------------------------------------------------------

    function grupoDoTipo(tipo) {
        if (tipo === 'TR') return 'tr';
        if (tipo === 'SA') return 'sa';
        return 'outros';
    }

    function acumulador() {
        return {
            horasTr: 0, litrosTr: 0,
            horasSa: 0, litrosSa: 0,
            horasOutros: 0, litrosOutros: 0,
            custo: 0, litrosComCusto: 0
        };
    }

    function acumular(acc, linha) {
        const grupo = grupoDoTipo(linha.tipo);
        const sufixo = grupo === 'tr' ? 'Tr' : grupo === 'sa' ? 'Sa' : 'Outros';
        acc['horas' + sufixo] += linha.horas || 0;
        acc['litros' + sufixo] += linha.litros || 0;
        acc.custo += linha.custo || 0;
        acc.litrosComCusto += linha.litrosComCusto || 0;
        return acc;
    }

    function derivar(acc) {
        const litros = acc.litrosTr + acc.litrosSa + acc.litrosOutros;
        return {
            horasTr: acc.horasTr,
            litrosTr: acc.litrosTr,
            mediaTr: acc.horasTr > 0 ? acc.litrosTr / acc.horasTr : null,
            horasSa: acc.horasSa,
            litrosSa: acc.litrosSa,
            mediaSa: acc.horasSa > 0 ? acc.litrosSa / acc.horasSa : null,
            horasOutros: acc.horasOutros,
            litrosOutros: acc.litrosOutros,
            horas: acc.horasTr + acc.horasSa + acc.horasOutros,
            litros: litros,
            custo: acc.custo,
            preco: acc.litrosComCusto > 0 ? acc.custo / acc.litrosComCusto : null,
            co2: litros * fator()
        };
    }

    function linhasDados() {
        return (estado.dados && estado.dados.linhas) || [];
    }

    function anosDisponiveis() {
        const anos = new Set();
        linhasDados().forEach(function (linha) { anos.add(linha.ano); });
        return Array.from(anos).sort(function (a, b) { return a - b; });
    }

    function nomesAeronaves() {
        if (!estado.dados) return [];
        const comDados = new Set(linhasDados().map(function (linha) { return linha.aeronave; }));
        return (estado.dados.aeronaves || [])
            .filter(function (aeronave) { return aeronave.ativa || comDados.has(aeronave.nome); })
            .map(function (aeronave) { return aeronave.nome; });
    }

    function aeronavesSelecionadas() {
        const todas = nomesAeronaves();
        if (!estado.aeronaves) return todas;
        return todas.filter(function (nome) { return estado.aeronaves.has(nome); });
    }

    function linhasDaSelecao(ano) {
        const nomes = new Set(aeronavesSelecionadas());
        return linhasDados().filter(function (linha) {
            return nomes.has(linha.aeronave) && (ano == null || linha.ano === ano);
        });
    }

    function somar(linhas) {
        return linhas.reduce(acumular, acumulador());
    }

    function porAno() {
        const mapa = new Map();
        anosDisponiveis().forEach(function (ano) { mapa.set(ano, acumulador()); });
        linhasDaSelecao(null).forEach(function (linha) { acumular(mapa.get(linha.ano), linha); });
        return mapa;
    }

    function co2PorMes(ano) {
        const meses = new Array(12).fill(0);
        linhasDaSelecao(ano).forEach(function (linha) {
            meses[linha.mes - 1] += (linha.litros || 0) * fator();
        });
        return meses;
    }

    function agruparLinhas(linhas, chaveDe, rotuloDe) {
        const grupos = new Map();
        linhas.forEach(function (linha) {
            const chave = chaveDe(linha);
            if (!grupos.has(chave)) {
                grupos.set(chave, { aeronave: linha.aeronave, ano: linha.ano, mes: linha.mes, acc: acumulador() });
            }
            acumular(grupos.get(chave).acc, linha);
        });
        return Array.from(grupos.values())
            .sort(function (a, b) {
                if (a.aeronave !== b.aeronave) return a.aeronave < b.aeronave ? -1 : 1;
                if (a.ano !== b.ano) return a.ano - b.ano;
                return (a.mes || 0) - (b.mes || 0);
            })
            .map(function (grupo) {
                return { aeronave: grupo.aeronave, periodo: rotuloDe(grupo), valores: derivar(grupo.acc) };
            });
    }

    // ------------------------------------------------------------------
    // Esqueleto da tela (HTML estático; os dados entram só via textContent)
    // ------------------------------------------------------------------

    const ESQUELETO = '' +
        '<header class="consumo-topo">' +
            '<div>' +
                '<h2 class="consumo-titulo">Consumo e emissões</h2>' +
                '<p class="consumo-descricao">Combustível abastecido, média L/h e CO₂ por aeronave e ano.</p>' +
            '</div>' +
            '<div class="consumo-acoes">' +
                '<span class="consumo-atualizado" data-ref="atualizado"></span>' +
                '<button type="button" class="consumo-botao-exportar" data-acao="exportar" data-ref="exportar" hidden>' +
                    '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" focusable="false"><path d="M12 4v10m0 0-4-4m4 4 4-4M5 19h14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>' +
                    '<span data-ref="exportarTexto">Exportar Excel</span>' +
                '</button>' +
                '<button type="button" class="consumo-botao-icone" data-acao="atualizar" data-ref="atualizar" aria-label="Atualizar dados">' +
                    '<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true" focusable="false"><path d="M20 12a8 8 0 1 1-2.34-5.66M20 4v5h-5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>' +
                '</button>' +
            '</div>' +
        '</header>' +
        '<section class="consumo-filtros" aria-label="Filtros">' +
            '<div class="consumo-filtro consumo-filtro-aeronaves">' +
                '<span class="consumo-rotulo" id="consumoRotuloAeronaves">Aeronaves</span>' +
                '<div class="consumo-chips" role="group" aria-labelledby="consumoRotuloAeronaves" data-ref="chips"></div>' +
            '</div>' +
            '<div class="consumo-filtro">' +
                '<span class="consumo-rotulo" id="consumoRotuloAno">Ano</span>' +
                '<div class="consumo-segmentado" role="radiogroup" aria-labelledby="consumoRotuloAno" data-ref="anos"></div>' +
            '</div>' +
        '</section>' +
        '<div class="consumo-estado" data-ref="estado" role="status"></div>' +
        '<div class="consumo-conteudo" data-ref="conteudo" hidden>' +
            '<section class="consumo-kpis" aria-label="Indicadores do ano selecionado">' +
                '<article class="consumo-cartao consumo-kpi" style="--i:0">' +
                    '<h3 class="consumo-kpi-titulo">Consumo</h3>' +
                    '<p class="consumo-kpi-valor"><span data-kpi="litros">0</span><small>L</small></p>' +
                    '<p class="consumo-kpi-sub" data-kpi="litrosSub"></p>' +
                '</article>' +
                '<article class="consumo-cartao consumo-kpi" style="--i:1">' +
                    '<h3 class="consumo-kpi-titulo">Horas de voo</h3>' +
                    '<p class="consumo-kpi-valor"><span data-kpi="horas">0</span><small>h</small></p>' +
                    '<p class="consumo-kpi-sub" data-kpi="horasSub"></p>' +
                '</article>' +
                '<article class="consumo-cartao consumo-kpi" style="--i:2">' +
                    '<h3 class="consumo-kpi-titulo">Média L/h</h3>' +
                    '<div class="consumo-kpi-pares">' +
                        '<p class="consumo-kpi-par"><span class="consumo-ponto consumo-ponto-sa"></span><span class="consumo-kpi-sigla">SA</span><strong data-kpi="mediaSa">–</strong><small>L/h</small></p>' +
                        '<p class="consumo-kpi-par"><span class="consumo-ponto consumo-ponto-tr"></span><span class="consumo-kpi-sigla">TR</span><strong data-kpi="mediaTr">–</strong><small>L/h</small></p>' +
                    '</div>' +
                    '<p class="consumo-kpi-sub">Serviço aéreo e translado</p>' +
                '</article>' +
                '<article class="consumo-cartao consumo-kpi consumo-kpi-co2" style="--i:3">' +
                    '<h3 class="consumo-kpi-titulo">Emissão de CO₂</h3>' +
                    '<p class="consumo-kpi-valor"><span data-kpi="co2">0</span><small>kg</small></p>' +
                    '<p class="consumo-kpi-sub" data-kpi="co2Sub"></p>' +
                '</article>' +
            '</section>' +
            '<section class="consumo-graficos" aria-label="Gráficos">' +
                '<article class="consumo-cartao consumo-grafico-cartao" style="--i:4">' +
                    '<header class="consumo-cartao-topo">' +
                        '<h3>Média L/h por ano</h3>' +
                        '<ul class="consumo-legenda"><li><span class="consumo-ponto consumo-ponto-tr"></span>TR</li><li><span class="consumo-ponto consumo-ponto-sa"></span>SA</li></ul>' +
                    '</header>' +
                    '<div class="consumo-grafico"><canvas data-ref="graficoMedia" role="img" aria-label="Média de litros por hora por ano"></canvas></div>' +
                '</article>' +
                '<article class="consumo-cartao consumo-grafico-cartao" style="--i:5">' +
                    '<header class="consumo-cartao-topo">' +
                        '<h3>Emissão de CO₂ por ano</h3>' +
                        '<span class="consumo-dica">kg · clique numa barra para escolher o ano</span>' +
                    '</header>' +
                    '<div class="consumo-grafico"><canvas data-ref="graficoCo2Ano" role="img" aria-label="Emissão de CO2 por ano"></canvas></div>' +
                '</article>' +
                '<article class="consumo-cartao consumo-grafico-cartao consumo-grafico-largo" style="--i:6">' +
                    '<header class="consumo-cartao-topo">' +
                        '<h3 data-ref="tituloMes">Emissões de CO₂ por mês</h3>' +
                        '<span class="consumo-dica">kg</span>' +
                    '</header>' +
                    '<div class="consumo-grafico"><canvas data-ref="graficoCo2Mes" role="img" aria-label="Emissão de CO2 por mês"></canvas></div>' +
                '</article>' +
            '</section>' +
            '<section class="consumo-cartao consumo-tabela-cartao" style="--i:7">' +
                '<header class="consumo-cartao-topo">' +
                    '<h3 data-ref="tituloTabela">Consumo mensal</h3>' +
                    '<div class="consumo-segmentado" role="radiogroup" aria-label="Agrupamento da tabela" data-ref="visao"></div>' +
                '</header>' +
                '<div class="consumo-tabela-rolagem" tabindex="0" role="region" aria-label="Tabela de consumo" data-ref="rolagem">' +
                    '<table class="consumo-tabela" data-ref="tabela"></table>' +
                '</div>' +
            '</section>' +
        '</div>' +
        '<p class="consumo-nota" data-ref="nota"></p>' +
        '<div class="consumo-sr" aria-live="polite" data-ref="anuncio"></div>';

    // ------------------------------------------------------------------
    // Controle segmentado (ano e agrupamento da tabela)
    // ------------------------------------------------------------------

    function construirSegmentado(container, nome, opcoes, aoMudar) {
        const chaveOpcoes = opcoes.map(function (opcao) { return opcao.valor; }).join('|');
        if (container.dataset.opcoes === chaveOpcoes) return;
        container.dataset.opcoes = chaveOpcoes;
        container.textContent = '';

        const indicador = criar('span', 'consumo-seg-indicador sem-transicao');
        indicador.setAttribute('aria-hidden', 'true');
        container.appendChild(indicador);

        opcoes.forEach(function (opcao) {
            const rotulo = criar('label', 'consumo-seg-opcao');
            const entrada = document.createElement('input');
            entrada.type = 'radio';
            entrada.name = nome;
            entrada.value = String(opcao.valor);
            entrada.addEventListener('change', function () {
                if (entrada.checked) aoMudar(opcao.valor);
            });
            rotulo.appendChild(entrada);
            rotulo.appendChild(criar('span', 'consumo-seg-texto', opcao.rotulo));
            container.appendChild(rotulo);
        });

        if (typeof ResizeObserver === 'function') {
            if (container._observador) container._observador.disconnect();
            container._observador = new ResizeObserver(function () { posicionarIndicador(container, false); });
            container._observador.observe(container);
        }
    }

    function selecionarSegmentado(container, valor) {
        Array.from(container.querySelectorAll('input')).forEach(function (entrada) {
            const ativo = entrada.value === String(valor);
            entrada.checked = ativo;
            entrada.parentElement.classList.toggle('ativo', ativo);
        });
        posicionarIndicador(container, true);
    }

    function posicionarIndicador(container, animar) {
        const indicador = container.querySelector('.consumo-seg-indicador');
        const ativo = container.querySelector('.consumo-seg-opcao.ativo');
        if (!indicador || !ativo || !ativo.offsetWidth) return;
        // A primeira colocação e os ajustes de layout são imediatos; só a troca
        // de opção pelo usuário desliza (senão o indicador sairia do zero).
        const imediato = !animar || !indicador.dataset.colocado;
        indicador.dataset.colocado = '1';
        if (imediato) indicador.classList.add('sem-transicao');
        indicador.style.width = ativo.offsetWidth + 'px';
        indicador.style.transform = 'translateX(' + ativo.offsetLeft + 'px)';
        if (imediato) {
            requestAnimationFrame(function () {
                requestAnimationFrame(function () { indicador.classList.remove('sem-transicao'); });
            });
        }
    }

    // ------------------------------------------------------------------
    // Filtros
    // ------------------------------------------------------------------

    function renderizarChips() {
        const nomes = nomesAeronaves();
        const selecionadas = new Set(aeronavesSelecionadas());
        const todasAtivas = selecionadas.size === nomes.length;
        const chaveChips = nomes.join('|');

        if (refs.chips.dataset.nomes !== chaveChips) {
            refs.chips.dataset.nomes = chaveChips;
            refs.chips.textContent = '';
            const todas = criar('button', 'consumo-chip', 'Todas');
            todas.type = 'button';
            todas.dataset.acao = 'todas';
            refs.chips.appendChild(todas);
            nomes.forEach(function (nome) {
                const chip = criar('button', 'consumo-chip', nome);
                chip.type = 'button';
                chip.dataset.aeronave = nome;
                const modelo = ((estado.dados.aeronaves || []).filter(function (a) { return a.nome === nome; })[0] || {}).modelo;
                if (modelo) chip.title = modelo;
                refs.chips.appendChild(chip);
            });
        }

        Array.from(refs.chips.children).forEach(function (chip) {
            const pressionado = chip.dataset.acao === 'todas'
                ? todasAtivas
                : !todasAtivas && selecionadas.has(chip.dataset.aeronave);
            chip.setAttribute('aria-pressed', pressionado ? 'true' : 'false');
        });
    }

    function renderizarAnos() {
        const anos = anosDisponiveis();
        construirSegmentado(refs.anos, 'consumoAno', anos.map(function (ano) {
            return { valor: ano, rotulo: String(ano) };
        }), selecionarAno);
        selecionarSegmentado(refs.anos, estado.ano);
    }

    function aoClicarAeronave(nome) {
        const todas = nomesAeronaves();
        const atual = estado.aeronaves ? new Set(estado.aeronaves) : new Set(todas);
        if (atual.size === todas.length) {
            // Com todas ligadas, o clique isola a aeronave escolhida.
            estado.aeronaves = new Set([nome]);
        } else if (atual.has(nome)) {
            atual.delete(nome);
            estado.aeronaves = atual.size ? atual : null;
        } else {
            atual.add(nome);
            estado.aeronaves = atual;
        }
        if (estado.aeronaves && estado.aeronaves.size === todas.length) estado.aeronaves = null;
        renderizar();
    }

    function selecionarAno(ano) {
        const valor = Number(ano);
        if (valor === estado.ano) return;
        estado.ano = valor;
        renderizar();
    }

    // ------------------------------------------------------------------
    // Indicadores
    // ------------------------------------------------------------------

    function animarNumero(elemento, para, formato) {
        if (para == null || !isFinite(para)) {
            if (elemento._raf) cancelAnimationFrame(elemento._raf);
            elemento._valor = null;
            elemento.textContent = SEM_VALOR;
            return;
        }
        const de = elemento._valor == null ? 0 : elemento._valor;
        elemento._valor = para;
        if (elemento._raf) cancelAnimationFrame(elemento._raf);
        if (reduzMovimento() || de === para) {
            elemento.textContent = formato.format(para);
            return;
        }
        const inicio = performance.now();
        const duracao = 300;
        function passo(agora) {
            const progresso = Math.min(1, (agora - inicio) / duracao);
            const suave = 1 - Math.pow(1 - progresso, 3);
            elemento.textContent = formato.format(de + (para - de) * suave);
            if (progresso < 1) elemento._raf = requestAnimationFrame(passo);
        }
        elemento._raf = requestAnimationFrame(passo);
    }

    function kpi(nome) {
        return refs.conteudo.querySelector('[data-kpi="' + nome + '"]');
    }

    function renderizarKpis() {
        const soma = derivar(somar(linhasDaSelecao(estado.ano)));
        animarNumero(kpi('litros'), soma.litros, FORMATO.inteiro);
        animarNumero(kpi('horas'), soma.horas, FORMATO.decimal);
        animarNumero(kpi('mediaSa'), soma.mediaSa, FORMATO.decimal);
        animarNumero(kpi('mediaTr'), soma.mediaTr, FORMATO.decimal);
        animarNumero(kpi('co2'), soma.co2, FORMATO.inteiro);

        kpi('litrosSub').textContent =
            'SA ' + FORMATO.inteiro.format(soma.litrosSa) +
            ' · TR ' + FORMATO.inteiro.format(soma.litrosTr) +
            ' · Outros ' + FORMATO.inteiro.format(soma.litrosOutros);
        kpi('horasSub').textContent =
            'SA ' + FORMATO.decimal.format(soma.horasSa) +
            ' · TR ' + FORMATO.decimal.format(soma.horasTr) +
            ' · Outros ' + FORMATO.decimal.format(soma.horasOutros);
        kpi('co2Sub').textContent =
            '≈ ' + FORMATO.decimal.format(soma.co2 / 1000) + ' t · ' +
            new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 2 }).format(fator()) + ' kg/L';
    }

    // ------------------------------------------------------------------
    // Gráficos (Chart.js)
    // ------------------------------------------------------------------

    const pluginRotulos = {
        id: 'consumoRotulos',
        afterDatasetsDraw: function (grafico, args, opcoes) {
            if (!opcoes || typeof opcoes.formatar !== 'function') return;
            const ctx = grafico.ctx;
            ctx.save();
            ctx.font = '600 12px ' + (grafico.options.font && grafico.options.font.family || 'sans-serif');
            ctx.fillStyle = CORES.texto;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'bottom';
            grafico.data.datasets.forEach(function (conjunto, indice) {
                const meta = grafico.getDatasetMeta(indice);
                if (meta.hidden) return;
                meta.data.forEach(function (barra, posicao) {
                    const valor = conjunto.data[posicao];
                    if (valor == null || valor === 0) return;
                    ctx.fillText(opcoes.formatar(valor), barra.x, barra.y - 6);
                });
            });
            ctx.restore();
        }
    };

    function opcoesBase(primeira) {
        const fonte = getComputedStyle(raiz).fontFamily;
        return {
            responsive: true,
            maintainAspectRatio: false,
            font: { family: fonte },
            animation: {
                duration: reduzMovimento() ? 0 : primeira ? 480 : 280,
                easing: 'easeOutQuart'
            },
            layout: { padding: { top: 22 } },
            interaction: { mode: 'index', intersect: false },
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: CORES.tooltip,
                    padding: 10,
                    cornerRadius: 8,
                    boxPadding: 4,
                    usePointStyle: true,
                    titleFont: { family: fonte, size: 12, weight: '600' },
                    bodyFont: { family: fonte, size: 13 }
                }
            },
            scales: {
                x: {
                    grid: { display: false },
                    border: { color: '#ced4da' },
                    ticks: { color: CORES.textoSuave, font: { family: fonte, size: 12 } }
                },
                y: {
                    beginAtZero: true,
                    grace: '12%',
                    grid: { color: CORES.grade },
                    border: { display: false },
                    ticks: {
                        color: CORES.textoSuave,
                        font: { family: fonte, size: 12 },
                        callback: function (valor) { return FORMATO.inteiro.format(valor); }
                    }
                }
            }
        };
    }

    function corPorAno(anos, cheia, suave) {
        return anos.map(function (ano) {
            return anos.length === 1 || ano === estado.ano ? cheia : suave;
        });
    }

    function aoClicarBarra(evento, itens, grafico) {
        if (!itens.length) return;
        selecionarAno(grafico.data.labels[itens[0].index]);
    }

    function aoPassarSobreBarra(evento, itens) {
        if (evento.native && evento.native.target) {
            evento.native.target.style.cursor = itens.length ? 'pointer' : 'default';
        }
    }

    function sincronizarGrafico(chave, canvas, criarConfig, atualizar) {
        let grafico = graficos[chave];
        if (grafico && grafico.canvas !== canvas) {
            grafico.destroy();
            grafico = null;
        }
        if (!grafico) {
            graficos[chave] = new window.Chart(canvas.getContext('2d'), criarConfig());
            return;
        }
        atualizar(grafico);
        grafico.options.animation.duration = reduzMovimento() ? 0 : 280;
        grafico.update();
    }

    function renderizarGraficos() {
        if (typeof window.Chart !== 'function') return;
        const mapaAnos = porAno();
        const anos = Array.from(mapaAnos.keys());
        const derivados = anos.map(function (ano) { return derivar(mapaAnos.get(ano)); });
        const primeira = !graficos.media;

        const dadosMedia = function () {
            return [
                {
                    label: 'TR',
                    data: derivados.map(function (item) { return item.mediaTr; }),
                    backgroundColor: corPorAno(anos, CORES.tr, CORES.trSuave)
                },
                {
                    label: 'SA',
                    data: derivados.map(function (item) { return item.mediaSa; }),
                    backgroundColor: corPorAno(anos, CORES.sa, CORES.saSuave)
                }
            ];
        };
        sincronizarGrafico('media', refs.graficoMedia, function () {
            const opcoes = opcoesBase(primeira);
            opcoes.onClick = aoClicarBarra;
            opcoes.onHover = aoPassarSobreBarra;
            opcoes.plugins.tooltip.callbacks = {
                label: function (contexto) {
                    return contexto.dataset.label + ': ' + formatar(contexto.parsed.y, FORMATO.decimal) + ' L/h';
                }
            };
            opcoes.plugins.consumoRotulos = { formatar: function (valor) { return FORMATO.decimal.format(valor); } };
            return {
                type: 'bar',
                plugins: [pluginRotulos],
                data: {
                    labels: anos,
                    datasets: dadosMedia().map(function (conjunto) {
                        return Object.assign(conjunto, { borderRadius: { topLeft: 6, topRight: 6 }, borderSkipped: false, barPercentage: 0.8, categoryPercentage: 0.7 });
                    })
                },
                options: opcoes
            };
        }, function (grafico) {
            grafico.data.labels = anos;
            dadosMedia().forEach(function (novo, indice) {
                Object.assign(grafico.data.datasets[indice], novo);
            });
        });

        const dadosCo2Ano = function () { return derivados.map(function (item) { return item.co2; }); };
        sincronizarGrafico('co2Ano', refs.graficoCo2Ano, function () {
            const opcoes = opcoesBase(primeira);
            opcoes.onClick = aoClicarBarra;
            opcoes.onHover = aoPassarSobreBarra;
            opcoes.plugins.tooltip.callbacks = {
                label: function (contexto) { return FORMATO.inteiro.format(contexto.parsed.y) + ' kg de CO₂'; }
            };
            opcoes.plugins.consumoRotulos = { formatar: function (valor) { return FORMATO.inteiro.format(valor); } };
            return {
                type: 'bar',
                plugins: [pluginRotulos],
                data: {
                    labels: anos,
                    datasets: [{
                        label: 'CO₂ (kg)',
                        data: dadosCo2Ano(),
                        backgroundColor: corPorAno(anos, CORES.co2, CORES.co2Suave),
                        borderRadius: { topLeft: 6, topRight: 6 },
                        borderSkipped: false,
                        barPercentage: 0.6,
                        categoryPercentage: 0.7
                    }]
                },
                options: opcoes
            };
        }, function (grafico) {
            grafico.data.labels = anos;
            grafico.data.datasets[0].data = dadosCo2Ano();
            grafico.data.datasets[0].backgroundColor = corPorAno(anos, CORES.co2, CORES.co2Suave);
        });

        sincronizarGrafico('co2Mes', refs.graficoCo2Mes, function () {
            const opcoes = opcoesBase(primeira);
            opcoes.plugins.tooltip.callbacks = {
                label: function (contexto) { return FORMATO.inteiro.format(contexto.parsed.y) + ' kg de CO₂'; }
            };
            return {
                type: 'line',
                data: {
                    labels: MESES,
                    datasets: [{
                        label: 'CO₂ (kg)',
                        data: co2PorMes(estado.ano),
                        borderColor: CORES.co2,
                        backgroundColor: CORES.co2Fundo,
                        borderWidth: 2.5,
                        fill: true,
                        tension: 0.35,
                        cubicInterpolationMode: 'monotone',
                        pointRadius: 3.5,
                        pointHoverRadius: 6,
                        pointBackgroundColor: '#ffffff',
                        pointBorderColor: CORES.co2,
                        pointBorderWidth: 2
                    }]
                },
                options: opcoes
            };
        }, function (grafico) {
            grafico.data.datasets[0].data = co2PorMes(estado.ano);
        });

        refs.tituloMes.textContent = 'Emissões de CO₂ por mês · ' + estado.ano;
        refs.graficoMedia.setAttribute('aria-label', 'Média de litros por hora por ano. ' + anos.map(function (ano, indice) {
            return ano + ': TR ' + formatar(derivados[indice].mediaTr, FORMATO.decimal) +
                ', SA ' + formatar(derivados[indice].mediaSa, FORMATO.decimal);
        }).join('; ') + '.');
        refs.graficoCo2Ano.setAttribute('aria-label', 'Emissão de CO2 por ano em kg. ' + anos.map(function (ano, indice) {
            return ano + ': ' + FORMATO.inteiro.format(derivados[indice].co2);
        }).join('; ') + '.');
        refs.graficoCo2Mes.setAttribute('aria-label', 'Emissão de CO2 por mês em ' + estado.ano + ', em kg.');
    }

    // ------------------------------------------------------------------
    // Tabela
    // ------------------------------------------------------------------

    const COLUNAS = [
        { rotulo: 'Aeronave', texto: true },
        { rotulo: 'PERIODO', texto: true },
        { rotulo: 'Horas TR', grupo: 'tr', valor: 'horasTr', formato: FORMATO.decimal },
        { rotulo: 'Consumo TR (L)', grupo: 'tr', valor: 'litrosTr', formato: FORMATO.inteiro },
        { rotulo: 'Média TR (L/h)', grupo: 'tr', valor: 'mediaTr', formato: FORMATO.decimal },
        { rotulo: 'Horas SA', grupo: 'sa', valor: 'horasSa', formato: FORMATO.decimal },
        { rotulo: 'Consumo SA (L)', grupo: 'sa', valor: 'litrosSa', formato: FORMATO.inteiro },
        { rotulo: 'Média SA (L/h)', grupo: 'sa', valor: 'mediaSa', formato: FORMATO.decimal },
        { rotulo: 'Outros (L)', grupo: 'outros', valor: 'litrosOutros', formato: FORMATO.inteiro },
        { rotulo: 'Preço médio (R$/L)', grupo: 'preco', valor: 'preco', formato: FORMATO.moeda },
        { rotulo: 'CO₂ (kg)', grupo: 'co2', valor: 'co2', formato: FORMATO.inteiro }
    ];

    // Registros da seleção atual (aeronaves e ano), usados pela tabela e pela exportação.
    function montarRegistros(mensal) {
        const linhas = linhasDaSelecao(mensal ? estado.ano : null);
        const registros = mensal
            ? agruparLinhas(linhas,
                function (linha) { return linha.aeronave + '|' + linha.ano + '|' + linha.mes; },
                function (grupo) { return MESES[grupo.mes - 1] + '/' + grupo.ano; })
            : agruparLinhas(linhas,
                function (linha) { return linha.aeronave + '|' + linha.ano; },
                function (grupo) { return String(grupo.ano); });
        return { registros: registros, total: derivar(somar(linhas)) };
    }

    function renderizarTabela() {
        const mensal = estado.visao === 'mensal';
        const montado = montarRegistros(mensal);
        const registros = montado.registros;
        const total = montado.total;

        refs.tituloTabela.textContent = mensal
            ? 'Consumo mensal · ' + estado.ano
            : 'Consumo anual';

        const tabela = refs.tabela;
        tabela.textContent = '';

        const legenda = criar('caption', 'consumo-sr', mensal
            ? 'Consumo mensal de combustível por aeronave em ' + estado.ano
            : 'Consumo anual de combustível por aeronave');
        tabela.appendChild(legenda);

        const cabecalho = criar('thead');
        const linhaCabecalho = criar('tr');
        COLUNAS.forEach(function (coluna) {
            const th = criar('th', coluna.texto ? 'consumo-col-texto' : '',
                coluna.rotulo === 'PERIODO' ? (mensal ? 'Mês/Ano' : 'Ano') : coluna.rotulo);
            th.scope = 'col';
            if (coluna.grupo) th.dataset.grupo = coluna.grupo;
            linhaCabecalho.appendChild(th);
        });
        cabecalho.appendChild(linhaCabecalho);
        tabela.appendChild(cabecalho);

        const corpo = criar('tbody');
        if (!registros.length) {
            const vazia = criar('tr');
            const celula = criar('td', 'consumo-tabela-vazia',
                'Nenhum voo ou abastecimento para esta seleção.');
            celula.colSpan = COLUNAS.length;
            vazia.appendChild(celula);
            corpo.appendChild(vazia);
        }
        registros.forEach(function (registro) {
            const tr = criar('tr');
            tr.appendChild(criar('th', 'consumo-col-texto consumo-col-fixa', registro.aeronave));
            tr.lastChild.scope = 'row';
            tr.appendChild(criar('td', 'consumo-col-texto', registro.periodo));
            COLUNAS.slice(2).forEach(function (coluna) {
                tr.appendChild(criar('td', '', formatarOuTraco(registro.valores[coluna.valor], coluna.formato)));
            });
            corpo.appendChild(tr);
        });
        tabela.appendChild(corpo);

        if (registros.length > 1) {
            const rodape = criar('tfoot');
            const tr = criar('tr');
            tr.appendChild(criar('th', 'consumo-col-texto consumo-col-fixa', 'Total'));
            tr.lastChild.scope = 'row';
            tr.appendChild(criar('td', 'consumo-col-texto', ''));
            COLUNAS.slice(2).forEach(function (coluna) {
                tr.appendChild(criar('td', '', formatarOuTraco(total[coluna.valor], coluna.formato)));
            });
            rodape.appendChild(tr);
            tabela.appendChild(rodape);
        }

        corpo.classList.remove('consumo-corpo-troca');
        void corpo.offsetWidth;
        corpo.classList.add('consumo-corpo-troca');
    }

    // ------------------------------------------------------------------
    // Exportação para Excel (seleção atual de aeronaves e ano)
    // ------------------------------------------------------------------

    const XLSX_TIPO = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    const EXCEL = {
        brand: 'FF003349',
        branco: 'FFFFFFFF',
        texto: 'FF2E2E2E',
        muted: 'FF5C5C5C',
        linha: 'FFEEF1F4',
        total: 'FFE7F3EA',
        totalBorda: 'FF2E844A',
        premissa: 'FFFFF2CC',
        premissaTexto: 'FF0000FF',
        grupos: { tr: 'FF007BFF', sa: 'FF28A745', co2: 'FFD9480F', outros: 'FF00B3DC', preco: 'FF00B3DC' }
    };
    const FORMATO_EXCEL = {
        horas: '#,##0.0;-#,##0.0;"–"',
        litros: '#,##0;-#,##0;"–"',
        preco: '"R$" #,##0.00;-"R$" #,##0.00;"–"'
    };
    const COLUNAS_EXCEL = [
        { titulo: 'Aeronave', largura: 14 },
        { titulo: 'PERIODO', largura: 12 },
        { titulo: 'Horas TR', largura: 11, grupo: 'tr', formato: FORMATO_EXCEL.horas },
        { titulo: 'Consumo TR (L)', largura: 16, grupo: 'tr', formato: FORMATO_EXCEL.litros },
        { titulo: 'Média TR (L/h)', largura: 15, grupo: 'tr', formato: FORMATO_EXCEL.horas },
        { titulo: 'Horas SA', largura: 11, grupo: 'sa', formato: FORMATO_EXCEL.horas },
        { titulo: 'Consumo SA (L)', largura: 16, grupo: 'sa', formato: FORMATO_EXCEL.litros },
        { titulo: 'Média SA (L/h)', largura: 15, grupo: 'sa', formato: FORMATO_EXCEL.horas },
        { titulo: 'Outros (L)', largura: 12, grupo: 'outros', formato: FORMATO_EXCEL.litros },
        { titulo: 'Preço médio (R$/L)', largura: 18, grupo: 'preco', formato: FORMATO_EXCEL.preco },
        { titulo: 'Emissões CO₂ (kg)', largura: 18, grupo: 'co2', formato: FORMATO_EXCEL.litros }
    ];
    const LINHA_FATOR = 3;
    const LINHA_CABECALHO = 5;
    let bibliotecaExcel = null;

    function carregarExcel() {
        if (window.ExcelJS) return Promise.resolve(window.ExcelJS);
        if (bibliotecaExcel) return bibliotecaExcel;
        bibliotecaExcel = new Promise(function (resolve, reject) {
            const url = window.controleHorasVooReportLibraryUrl;
            if (!url) {
                reject(new Error('A biblioteca de exportação não está configurada.'));
                return;
            }
            const script = document.createElement('script');
            script.src = url;
            script.async = true;
            script.onload = function () {
                if (window.ExcelJS) {
                    resolve(window.ExcelJS);
                } else {
                    reject(new Error('A biblioteca de exportação não pôde ser iniciada.'));
                }
            };
            script.onerror = function () {
                reject(new Error('Não foi possível carregar a biblioteca de exportação.'));
            };
            document.head.appendChild(script);
        }).catch(function (erro) {
            bibliotecaExcel = null;
            throw erro;
        });
        return bibliotecaExcel;
    }

    // Evita que um valor vindo dos dados seja lido como fórmula no Excel.
    function textoSeguro(valor) {
        const texto = String(valor == null ? '' : valor);
        return /^[=+\-@]/.test(texto.trim()) ? "'" + texto : texto;
    }

    function preencher(celula, argb) {
        celula.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: argb } };
    }

    function adicionarAba(workbook, opcoes) {
        const aba = workbook.addWorksheet(opcoes.nome, {
            views: [{ state: 'frozen', xSplit: 1, ySplit: LINHA_CABECALHO }],
            pageSetup: { orientation: 'landscape', fitToPage: true, fitToWidth: 1, fitToHeight: 0 }
        });
        const total = COLUNAS_EXCEL.length;
        COLUNAS_EXCEL.forEach(function (coluna, indice) {
            aba.getColumn(indice + 1).width = coluna.largura;
        });

        aba.mergeCells(1, 1, 1, total);
        const titulo = aba.getCell(1, 1);
        titulo.value = textoSeguro(opcoes.titulo);
        titulo.font = { bold: true, size: 18, color: { argb: EXCEL.branco } };
        titulo.alignment = { vertical: 'middle', horizontal: 'left' };
        preencher(titulo, EXCEL.brand);
        aba.getRow(1).height = 30;

        aba.mergeCells(2, 1, 2, total);
        const subtitulo = aba.getCell(2, 1);
        subtitulo.value = textoSeguro(opcoes.subtitulo);
        subtitulo.font = { size: 10, color: { argb: EXCEL.muted } };
        subtitulo.alignment = { vertical: 'middle', wrapText: true };
        aba.getRow(2).height = 28;

        // Premissa editável: as emissões são recalculadas a partir desta célula.
        aba.mergeCells(LINHA_FATOR, 1, LINHA_FATOR, 2);
        const rotuloFator = aba.getCell(LINHA_FATOR, 1);
        rotuloFator.value = 'Fator de emissão (kg CO₂/L)';
        rotuloFator.font = { bold: true, color: { argb: EXCEL.texto } };
        const celulaFator = aba.getCell(LINHA_FATOR, 3);
        celulaFator.value = opcoes.fator;
        celulaFator.numFmt = '0.00';
        celulaFator.font = { bold: true, color: { argb: EXCEL.premissaTexto } };
        celulaFator.alignment = { horizontal: 'center' };
        preencher(celulaFator, EXCEL.premissa);
        aba.mergeCells(LINHA_FATOR, 4, LINHA_FATOR, total);
        const notaFator = aba.getCell(LINHA_FATOR, 4);
        notaFator.value = 'Premissa da planilha de índice ambiental. Altere o valor para recalcular as emissões.';
        notaFator.font = { italic: true, size: 10, color: { argb: EXCEL.muted } };

        const cabecalho = aba.getRow(LINHA_CABECALHO);
        COLUNAS_EXCEL.forEach(function (coluna, indice) {
            const celula = cabecalho.getCell(indice + 1);
            celula.value = coluna.titulo === 'PERIODO' ? opcoes.rotuloPeriodo : coluna.titulo;
            celula.font = { bold: true, color: { argb: EXCEL.branco } };
            celula.alignment = {
                vertical: 'middle',
                horizontal: indice < 2 ? 'left' : 'center',
                wrapText: true
            };
            preencher(celula, EXCEL.brand);
            if (coluna.grupo) {
                celula.border = { bottom: { style: 'thick', color: { argb: EXCEL.grupos[coluna.grupo] } } };
            }
        });
        cabecalho.height = 32;

        const primeira = LINHA_CABECALHO + 1;
        let linha = primeira;
        if (!opcoes.registros.length) {
            aba.mergeCells(linha, 1, linha, total);
            const vazia = aba.getCell(linha, 1);
            vazia.value = 'Nenhum voo ou abastecimento para esta seleção.';
            vazia.font = { italic: true, color: { argb: EXCEL.muted } };
            return aba;
        }

        opcoes.registros.forEach(function (registro) {
            const v = registro.valores;
            const r = aba.getRow(linha);
            r.getCell(1).value = textoSeguro(registro.aeronave);
            r.getCell(2).value = registro.periodo;
            r.getCell(3).value = v.horasTr;
            r.getCell(4).value = v.litrosTr;
            r.getCell(5).value = { formula: 'IFERROR(D' + linha + '/C' + linha + ',0)', result: v.mediaTr || 0 };
            r.getCell(6).value = v.horasSa;
            r.getCell(7).value = v.litrosSa;
            r.getCell(8).value = { formula: 'IFERROR(G' + linha + '/F' + linha + ',0)', result: v.mediaSa || 0 };
            r.getCell(9).value = v.litrosOutros;
            r.getCell(10).value = v.preco || 0;
            r.getCell(11).value = {
                formula: '(D' + linha + '+G' + linha + '+I' + linha + ')*$C$' + LINHA_FATOR,
                result: v.co2
            };
            COLUNAS_EXCEL.forEach(function (coluna, indice) {
                const celula = r.getCell(indice + 1);
                if (coluna.formato) celula.numFmt = coluna.formato;
                celula.font = { color: { argb: EXCEL.texto }, bold: indice === 0 };
                celula.border = { bottom: { style: 'thin', color: { argb: EXCEL.linha } } };
            });
            linha += 1;
        });

        const ultima = linha - 1;
        const t = opcoes.total;
        const rodape = aba.getRow(linha);
        rodape.getCell(1).value = 'Total';
        [[3, 'C', t.horasTr], [4, 'D', t.litrosTr], [6, 'F', t.horasSa], [7, 'G', t.litrosSa], [9, 'I', t.litrosOutros]]
            .forEach(function (coluna) {
                rodape.getCell(coluna[0]).value = {
                    formula: 'SUM(' + coluna[1] + primeira + ':' + coluna[1] + ultima + ')',
                    result: coluna[2]
                };
            });
        rodape.getCell(5).value = { formula: 'IFERROR(D' + linha + '/C' + linha + ',0)', result: t.mediaTr || 0 };
        rodape.getCell(8).value = { formula: 'IFERROR(G' + linha + '/F' + linha + ',0)', result: t.mediaSa || 0 };
        rodape.getCell(10).value = t.preco || 0;
        rodape.getCell(11).value = {
            formula: '(D' + linha + '+G' + linha + '+I' + linha + ')*$C$' + LINHA_FATOR,
            result: t.co2
        };
        COLUNAS_EXCEL.forEach(function (coluna, indice) {
            const celula = rodape.getCell(indice + 1);
            if (coluna.formato) celula.numFmt = coluna.formato;
            celula.font = { bold: true, color: { argb: EXCEL.texto } };
            preencher(celula, EXCEL.total);
            celula.border = { top: { style: 'thin', color: { argb: EXCEL.totalBorda } } };
        });
        return aba;
    }

    function nomeArquivo() {
        const nomes = aeronavesSelecionadas();
        const parte = !estado.aeronaves ? 'Todas' : nomes.length <= 3 ? nomes.join('_') : 'Selecao';
        return ('Consumo_Combustivel_' + parte + '_' + estado.ano + '.xlsx').replace(/[^A-Za-z0-9_.-]/g, '');
    }

    function baixarArquivo(buffer, nome) {
        const blob = new Blob([buffer], { type: XLSX_TIPO });
        const url = URL.createObjectURL(blob);
        const ancora = document.createElement('a');
        ancora.href = url;
        ancora.download = nome;
        document.body.appendChild(ancora);
        ancora.click();
        ancora.remove();
        window.setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
    }

    function definirBotaoExportar(texto, ocupado) {
        const botao = document.querySelector('#consumoApp [data-ref="exportar"]');
        const rotulo = document.querySelector('#consumoApp [data-ref="exportarTexto"]');
        if (rotulo) rotulo.textContent = texto;
        if (botao) {
            botao.disabled = ocupado;
            botao.classList.toggle('ocupado', ocupado);
        }
    }

    async function exportar() {
        if (estado.exportando || !estado.dados) return;
        estado.exportando = true;
        estado.avisoExportacao = '';
        definirBotaoExportar('Preparando…', true);
        let sucesso = false;
        try {
            const Excel = await carregarExcel();
            const workbook = new Excel.Workbook();
            workbook.creator = 'Engemap - Controle de Horas de Voo';
            workbook.created = new Date();
            workbook.modified = new Date();

            const nomes = aeronavesSelecionadas();
            const filtro = (estado.aeronaves ? 'Aeronaves: ' : 'Todas as aeronaves: ') + nomes.join(', ');
            const geradoEm = new Date().toLocaleString('pt-BR', { dateStyle: 'short', timeStyle: 'short' });
            const rodapeTexto = ' | Gerado em: ' + geradoEm + ' | Fonte: abastecimentos do Controle de Horas de Voo';
            const mensal = montarRegistros(true);
            const anual = montarRegistros(false);

            adicionarAba(workbook, {
                nome: 'CONSUMO MENSAL',
                titulo: 'Consumo mensal · ' + estado.ano,
                subtitulo: filtro + ' | Ano: ' + estado.ano + rodapeTexto,
                rotuloPeriodo: 'Mês/Ano',
                registros: mensal.registros,
                total: mensal.total,
                fator: fator()
            });
            adicionarAba(workbook, {
                nome: 'CONSUMO ANUAL',
                titulo: 'Consumo anual',
                subtitulo: filtro + ' | Todos os anos disponíveis' + rodapeTexto,
                rotuloPeriodo: 'Ano',
                registros: anual.registros,
                total: anual.total,
                fator: fator()
            });

            const nome = nomeArquivo();
            baixarArquivo(await workbook.xlsx.writeBuffer(), nome);
            sucesso = true;
            definirBotaoExportar('Exportado', true);
            const anuncio = document.querySelector('#consumoApp [data-ref="anuncio"]');
            if (anuncio) anuncio.textContent = 'Planilha exportada: ' + nome + '.';
            window.setTimeout(function () { definirBotaoExportar('Exportar Excel', false); }, 1800);
        } catch (erro) {
            estado.avisoExportacao = (erro && erro.message)
                || 'Não foi possível exportar a planilha. Tente novamente.';
        } finally {
            estado.exportando = false;
            if (!sucesso) definirBotaoExportar('Exportar Excel', false);
            renderizar();
        }
    }

    // ------------------------------------------------------------------
    // Estados e orquestração
    // ------------------------------------------------------------------

    function renderizarEstado() {
        const bloco = refs.estado;
        bloco.textContent = '';
        bloco.className = 'consumo-estado';
        refs.atualizar.classList.toggle('girando', estado.carregando);
        refs.atualizar.disabled = estado.carregando;

        if (estado.dados) {
            bloco.hidden = !estado.erro && !estado.avisoExportacao;
            if (estado.erro) bloco.appendChild(blocoErro(estado.erro));
            if (estado.avisoExportacao) bloco.appendChild(blocoAviso(estado.avisoExportacao));
            return;
        }

        bloco.hidden = false;
        if (estado.erro) {
            bloco.appendChild(blocoErro(estado.erro));
        } else {
            bloco.classList.add('consumo-carregando');
            bloco.setAttribute('aria-busy', 'true');
            for (let i = 0; i < 4; i += 1) bloco.appendChild(criar('span', 'consumo-esqueleto'));
            bloco.appendChild(criar('span', 'consumo-sr', 'Carregando consumo de combustível'));
        }
    }

    function blocoErro(mensagem) {
        const erro = criar('div', 'consumo-aviso');
        erro.setAttribute('role', 'alert');
        erro.appendChild(criar('p', '', mensagem));
        const botao = criar('button', 'consumo-botao', 'Tentar novamente');
        botao.type = 'button';
        botao.dataset.acao = 'atualizar';
        erro.appendChild(botao);
        return erro;
    }

    function blocoAviso(mensagem) {
        const aviso = criar('div', 'consumo-aviso');
        aviso.setAttribute('role', 'alert');
        aviso.appendChild(criar('p', '', mensagem));
        const botao = criar('button', 'consumo-botao', 'Fechar');
        botao.type = 'button';
        botao.dataset.acao = 'fechar-aviso';
        aviso.appendChild(botao);
        return aviso;
    }

    function renderizarNota() {
        if (!estado.dados) {
            refs.nota.textContent = '';
            return;
        }
        const linhas = linhasDados();
        let inicio = null;
        linhas.forEach(function (linha) {
            const chave = linha.ano * 100 + linha.mes;
            if (inicio == null || chave < inicio) inicio = chave;
        });
        const desde = inicio == null
            ? ''
            : ' Dados disponíveis desde ' + MESES[(inicio % 100) - 1] + '/' + Math.floor(inicio / 100) + '.';
        refs.nota.textContent =
            'Consumo = soma dos abastecimentos (litros) no mês e no tipo do voo. ' +
            'CO₂ = litros × ' + new Intl.NumberFormat('pt-BR', { maximumFractionDigits: 2 }).format(fator()) +
            ' kg/L. “Outros” reúne PV, EX, TT, AB e voos sem tipo.' + desde;
    }

    function renderizar() {
        if (!raiz || !raiz.isConnected) return;
        renderizarEstado();

        if (estado.carregadoEm) {
            refs.atualizado.textContent = 'Atualizado às ' +
                estado.carregadoEm.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
        }

        const temDados = !!estado.dados;
        refs.conteudo.hidden = !temDados;
        refs.chips.parentElement.hidden = !temDados;
        refs.anos.parentElement.hidden = !temDados;
        refs.exportar.hidden = !temDados || !linhasDados().length;
        if (!temDados) return;

        if (!linhasDados().length) {
            refs.conteudo.hidden = true;
            refs.estado.hidden = false;
            refs.estado.textContent = '';
            refs.estado.appendChild(criar('p', 'consumo-vazio',
                'Ainda não há voos ou abastecimentos registrados.'));
            return;
        }

        renderizarChips();
        renderizarAnos();
        renderizarKpis();
        renderizarGraficos();
        selecionarSegmentado(refs.visao, estado.visao);
        renderizarTabela();
        renderizarNota();

        const nomes = aeronavesSelecionadas();
        refs.anuncio.textContent = 'Exibindo ' + (estado.aeronaves ? nomes.join(', ') : 'todas as aeronaves') +
            ' em ' + estado.ano + '.';

        if (!raiz.dataset.entrada) {
            raiz.dataset.entrada = '1';
            raiz.classList.add('consumo-entrando');
            window.setTimeout(function () { raiz.classList.remove('consumo-entrando'); }, 1100);
        }
    }

    function inicializarSelecao() {
        const anos = anosDisponiveis();
        if (estado.ano == null || anos.indexOf(estado.ano) === -1) {
            estado.ano = anos.length ? anos[anos.length - 1] : new Date().getFullYear();
        }
        if (estado.aeronaves) {
            const validas = new Set(nomesAeronaves());
            const mantidas = new Set(Array.from(estado.aeronaves).filter(function (nome) { return validas.has(nome); }));
            estado.aeronaves = mantidas.size && mantidas.size < validas.size ? mantidas : null;
        }
    }

    function carregar() {
        if (estado.carregando) return;
        const remoto = window.controleHorasVooConsumoRemoto;
        const token = window.controleHorasVooAccessToken;
        estado.erro = '';
        if (typeof remoto !== 'function' || !token) {
            estado.erro = 'Sua sessão não permite consultar o consumo. Atualize a página e tente novamente.';
            renderizar();
            return;
        }
        estado.carregando = true;
        renderizar();
        remoto(token, function (resultado, evento) {
            estado.carregando = false;
            if (evento && evento.status && resultado && resultado.success) {
                estado.dados = resultado.data;
                estado.carregadoEm = new Date();
                estado.erro = '';
                inicializarSelecao();
            } else {
                estado.erro = (resultado && resultado.message)
                    || 'Não foi possível carregar o consumo de combustível. Tente novamente.';
            }
            atualizarTela();
        });
    }

    function atualizarTela() {
        const atual = document.getElementById('consumoApp');
        if (!atual) return;
        if (atual.dataset.montado !== '1') {
            montar();
            return;
        }
        renderizar();
    }

    function aoClicar(evento) {
        const alvo = evento.target.closest('[data-acao], [data-aeronave]');
        if (!alvo || !raiz.contains(alvo)) return;
        if (alvo.dataset.aeronave) {
            aoClicarAeronave(alvo.dataset.aeronave);
        } else if (alvo.dataset.acao === 'todas') {
            estado.aeronaves = null;
            renderizar();
        } else if (alvo.dataset.acao === 'atualizar') {
            carregar();
        } else if (alvo.dataset.acao === 'exportar') {
            exportar();
        } else if (alvo.dataset.acao === 'fechar-aviso') {
            estado.avisoExportacao = '';
            renderizar();
        }
    }

    function descartarGraficosSoltos() {
        Object.keys(graficos).forEach(function (chave) {
            if (!graficos[chave].canvas.isConnected) {
                graficos[chave].destroy();
                delete graficos[chave];
            }
        });
    }

    function montar() {
        descartarGraficosSoltos();
        const candidata = document.getElementById('consumoApp');
        if (!candidata) return;
        const painel = candidata.closest('.tab-pane');
        if (!painel || !painel.classList.contains('active')) return;
        if (candidata.dataset.montado === '1') return;

        raiz = candidata;
        raiz.dataset.montado = '1';
        raiz.innerHTML = ESQUELETO;
        refs = {};
        Array.from(raiz.querySelectorAll('[data-ref]')).forEach(function (elemento) {
            refs[elemento.dataset.ref] = elemento;
        });
        raiz.addEventListener('click', aoClicar);

        construirSegmentado(refs.visao, 'consumoVisao', [
            { valor: 'mensal', rotulo: 'Mensal' },
            { valor: 'anual', rotulo: 'Anual' }
        ], function (valor) {
            estado.visao = valor;
            selecionarSegmentado(refs.visao, valor);
            renderizarTabela();
        });

        if (estado.dados) {
            renderizar();
        } else {
            carregar();
        }
    }

    document.addEventListener('chv:initialized', montar);
    if (document.readyState !== 'loading') montar();
}());
