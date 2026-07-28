(function () {
    'use strict';

    const FIELD_SUFFIXES = {
        acionamento: 'acionamento',
        corte: 'corte',
        tot: 'tot',
        horasVoo: 'horasVoo',
        abQtd: 'abQtd',
        abCustoUnit: 'abCustoUnit',
        abCustoTotal: 'abCustoTotal',
        abMedia: 'abMedia'
    };

    let lastFocusedId = null;
    let initializationFrame = null;
    let calculatedFlightHours = 0;
    let calendarPeriodUpdateTimer = null;
    let calendarPeriodUpdateInFlight = false;
    let calendarPeriodUpdatePending = false;
    const dashboardCharts = new Map();
    const CALENDAR_PERIOD_DEBOUNCE_MS = 250;

    function findField(name) {
        const suffix = FIELD_SUFFIXES[name] || name;
        return document.querySelector('.' + suffix + '-field')
            || document.querySelector('[id$=":' + suffix + '"]')
            || document.querySelector('[id$="' + suffix + '"]')
            || document.getElementById(suffix);
    }

    function dispatchValueChange(field) {
        field.dispatchEvent(new Event('input', { bubbles: true }));
        field.dispatchEvent(new Event('change', { bubbles: true }));
    }

    function executeCalendarPeriodUpdate() {
        calendarPeriodUpdateTimer = null;
        if (calendarPeriodUpdateInFlight) {
            calendarPeriodUpdatePending = true;
            return;
        }

        const updateAction = window.atualizarPeriodoCalendarioAF;
        if (typeof updateAction !== 'function') return;

        calendarPeriodUpdateInFlight = true;
        calendarPeriodUpdatePending = false;
        try {
            updateAction();
        } catch (error) {
            calendarPeriodUpdateInFlight = false;
            throw error;
        }
    }

    function scheduleCalendarPeriodUpdate() {
        if (calendarPeriodUpdateTimer != null) {
            clearTimeout(calendarPeriodUpdateTimer);
        }
        calendarPeriodUpdateTimer = setTimeout(
            executeCalendarPeriodUpdate,
            CALENDAR_PERIOD_DEBOUNCE_MS
        );
    }

    function finishCalendarPeriodUpdate() {
        calendarPeriodUpdateInFlight = false;
        if (!calendarPeriodUpdatePending) return;

        calendarPeriodUpdatePending = false;
        scheduleCalendarPeriodUpdate();
    }

    function parseTime(value) {
        if (!value) return null;
        const digits = String(value).trim().replace(/[^\d:]/g, '');
        let hours;
        let minutes;

        if (digits.includes(':')) {
            const parts = digits.split(':');
            hours = Number(parts[0]);
            minutes = Number((parts[1] || '0').substring(0, 2));
        } else {
            const normalized = digits.padStart(digits.length <= 2 ? 2 : 4, '0');
            hours = Number(normalized.length <= 2 ? normalized : normalized.slice(0, 2));
            minutes = Number(normalized.length <= 2 ? 0 : normalized.slice(2, 4));
        }

        if (!Number.isInteger(hours) || !Number.isInteger(minutes)
            || hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
            return null;
        }
        return {
            hours,
            minutes,
            formatted: String(hours).padStart(2, '0') + ':' + String(minutes).padStart(2, '0')
        };
    }

    function formatTimeField(field) {
        if (!field || !field.value) return true;
        const parsed = parseTime(field.value);
        field.setCustomValidity(parsed ? '' : 'Informe um horário válido entre 00:00 e 23:59.');
        if (!parsed) return false;
        field.value = parsed.formatted;
        return true;
    }

    function calculateElapsedTime(startValue, endValue) {
        const start = parseTime(startValue);
        const end = parseTime(endValue);
        if (!start || !end) return null;

        let minutes = (end.hours * 60 + end.minutes)
            - (start.hours * 60 + start.minutes);
        if (minutes < 0) minutes += 24 * 60;
        return {
            minutes,
            decimalHours: minutes / 60,
            formatted: Math.floor(minutes / 60)
                + ':' + String(minutes % 60).padStart(2, '0')
        };
    }

    function clearFlightPreview() {
        const totalField = findField('tot');
        const hoursField = findField('horasVoo');
        const displayField = document.getElementById('totDisplay')
            || document.querySelector('.tot-field-display');
        if (displayField) displayField.value = '';
        if (totalField) totalField.value = '';
        if (hoursField) hoursField.value = '';
        calculatedFlightHours = 0;
    }

    function calculateFlightPreview() {
        const startField = findField('acionamento');
        const endField = findField('corte');
        if (!startField || !endField || !startField.value || !endField.value) {
            clearFlightPreview();
            return;
        }

        const elapsed = calculateElapsedTime(startField.value, endField.value);
        if (!elapsed) {
            clearFlightPreview();
            return;
        }
        const totalField = findField('tot');
        const hoursField = findField('horasVoo');
        const displayField = document.getElementById('totDisplay')
            || document.querySelector('.tot-field-display');

        if (displayField) {
            displayField.value = elapsed.formatted;
        }
        if (totalField) {
            totalField.value = elapsed.decimalHours.toFixed(2);
            dispatchValueChange(totalField);
        }
        if (hoursField) {
            hoursField.value = elapsed.decimalHours.toFixed(1);
            dispatchValueChange(hoursField);
        }
        calculatedFlightHours = elapsed.decimalHours;
    }

    function parseDecimal(value) {
        if (value == null || value === '') return null;
        const parsed = Number(String(value).replace(',', '.'));
        return Number.isFinite(parsed) ? parsed : null;
    }

    function calculateFuelRow(row) {
        const quantityField = row
            ? row.querySelector('.fuel-quantity-field')
            : findField('abQtd');
        const unitCostField = row
            ? row.querySelector('.fuel-unit-cost-field')
            : findField('abCustoUnit');
        const totalCostField = row
            ? row.querySelector('.fuel-total-cost-field')
            : findField('abCustoTotal');
        if (!quantityField || !unitCostField || !totalCostField) return;

        const quantity = parseDecimal(quantityField.value);
        const unitCost = parseDecimal(unitCostField.value);
        const valid = quantity != null && unitCost != null && quantity >= 0 && unitCost >= 0;
        totalCostField.value = valid ? (quantity * unitCost).toFixed(2) : '';
        dispatchValueChange(totalCostField);

        const averageField = row
            ? row.querySelector('.fuel-average-field')
            : findField('abMedia');
        if (averageField) {
            averageField.value = quantity != null
                && quantity > 0
                && calculatedFlightHours > 0
                ? (quantity / calculatedFlightHours).toFixed(2)
                : '';
        }
    }

    function calculateFuelPreview() {
        const rows = document.querySelectorAll('.fuel-calculation-row');
        if (rows.length) {
            rows.forEach(calculateFuelRow);
            return;
        }
        calculateFuelRow(null);
    }

    function bindField(field, eventName, key, handler) {
        if (!field || field.dataset[key] === 'true') return;
        field.dataset[key] = 'true';
        field.addEventListener(eventName, handler);
    }

    function bindFormEvents() {
        ['acionamento', 'corte'].forEach(function (name) {
            const field = findField(name);
            if (!field) return;

            if (field.type === 'time') field.type = 'text';
            field.inputMode = 'numeric';
            field.autocomplete = 'off';
            field.placeholder = 'HH:MM';

            const finalizeTime = function () {
                if (formatTimeField(field)) {
                    calculateFlightPreview();
                    calculateFuelPreview();
                }
            };
            bindField(field, 'blur', 'chvTimeBlurBound', finalizeTime);
            bindField(field, 'change', 'chvTimeChangeBound', finalizeTime);
            bindField(field, 'input', 'chvTimeInputBound', function () {
                const rawValue = String(field.value || '');
                const digits = rawValue.replace(/\D/g, '');
                if (!rawValue.includes(':') && digits.length === 4) {
                    formatTimeField(field);
                }
                calculateFlightPreview();
                calculateFuelPreview();
            });
            if (field.value) formatTimeField(field);
        });

        document.querySelectorAll(
            '.fuel-quantity-field, .fuel-unit-cost-field'
        ).forEach(function (field) {
            bindField(field, 'input', 'chvFuelInputBound', calculateFuelPreview);
            bindField(field, 'change', 'chvFuelChangeBound', calculateFuelPreview);
            bindField(field, 'blur', 'chvFuelBlurBound', calculateFuelPreview);
        });

        ['abLocal', 'abTipoCombustivel', 'dep', 'arr'].forEach(function (name) {
            const field = findField(name);
            bindField(field, 'input', 'chvUpperBound', function () {
                field.value = field.value.toUpperCase();
            });
        });
    }

    function initializeInspectionCards() {
        document.querySelectorAll('.inspecao-card, .inspecao-card-mini').forEach(function (card) {
            const status = card.getAttribute('data-status') || 'SEM DADOS';
            card.setAttribute('aria-label', 'Inspeção com status ' + status.toLowerCase());
        });
    }

    function destroyDetachedDashboardCharts() {
        dashboardCharts.forEach(function (chart, canvas) {
            if (document.contains(canvas)) return;
            chart.destroy();
            dashboardCharts.delete(canvas);
        });
    }

    function initializeDashboardCharts() {
        destroyDetachedDashboardCharts();
        const canvases = document.querySelectorAll('.flight-dashboard-chart');
        if (!canvases.length || typeof window.Chart !== 'function') return;

        const reduceMotion = typeof window.matchMedia === 'function'
            && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

        canvases.forEach(function (canvas) {
            if (dashboardCharts.has(canvas)) return;

            const card = canvas.closest('.flight-dashboard-card');
            const metricElements = card
                ? card.querySelectorAll('[data-flight-code]')
                : [];
            const metrics = Array.from(metricElements).map(function (element) {
                return {
                    label: element.dataset.flightLabel,
                    color: element.dataset.flightColor,
                    hours: parseDecimal(element.dataset.flightHours) || 0
                };
            });
            const hasHours = metrics.some(function (metric) {
                return metric.hours > 0;
            });

            if (!hasHours) return;

            const chart = new window.Chart(canvas.getContext('2d'), {
                type: 'doughnut',
                data: {
                    labels: metrics.map(function (metric) { return metric.label; }),
                    datasets: [{
                        data: metrics.map(function (metric) { return metric.hours; }),
                        backgroundColor: metrics.map(function (metric) { return metric.color; }),
                        borderColor: '#ffffff',
                        borderWidth: 3,
                        hoverOffset: 5
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    cutout: '72%',
                    animation: {
                        duration: reduceMotion ? 0 : 420
                    },
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            callbacks: {
                                label: function (context) {
                                    return context.label + ': '
                                        + Number(context.raw).toLocaleString('pt-BR', {
                                            minimumFractionDigits: 1,
                                            maximumFractionDigits: 1
                                        })
                                        + ' h';
                                }
                            }
                        }
                    }
                }
            });
            dashboardCharts.set(canvas, chart);
        });
    }

    function bindTabKeyboard() {
        const tabList = document.querySelector('[role="tablist"]');
        if (!tabList || tabList.dataset.chvTabsBound === 'true') return;
        tabList.dataset.chvTabsBound = 'true';
        tabList.addEventListener('keydown', function (event) {
            if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
            const tabs = Array.from(tabList.querySelectorAll('[role="tab"]'));
            const currentIndex = tabs.indexOf(document.activeElement);
            if (currentIndex < 0 || !tabs.length) return;

            event.preventDefault();
            let targetIndex = currentIndex;
            if (event.key === 'Home') targetIndex = 0;
            if (event.key === 'End') targetIndex = tabs.length - 1;
            if (event.key === 'ArrowLeft') {
                targetIndex = (currentIndex - 1 + tabs.length) % tabs.length;
            }
            if (event.key === 'ArrowRight') {
                targetIndex = (currentIndex + 1) % tabs.length;
            }
            tabs[targetIndex].focus();
        });
    }

    function getFocusableElements(modal) {
        return Array.from(modal.querySelectorAll(
            'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), '
            + 'textarea:not([disabled]), [tabindex]:not([tabindex="-1"])'
        )).filter(function (element) {
            return element.offsetParent !== null;
        });
    }

    function initializeModal() {
        const modal = document.querySelector('.modal-content[role="dialog"]');
        if (!modal || modal.dataset.chvModalReady === 'true') return;
        modal.dataset.chvModalReady = 'true';
        const focusable = getFocusableElements(modal);
        if (focusable.length) focusable[0].focus();
    }

    function trapModalKeyboard(event) {
        const modal = document.querySelector('.modal-content[role="dialog"]');
        if (!modal) return;

        if (event.key === 'Escape') {
            event.preventDefault();
            window.fecharModalJs();
            return;
        }
        if (event.key !== 'Tab') return;

        const focusable = getFocusableElements(modal);
        if (!focusable.length) {
            event.preventDefault();
            modal.focus();
            return;
        }
        const first = focusable[0];
        const last = focusable[focusable.length - 1];
        if (event.shiftKey && document.activeElement === first) {
            event.preventDefault();
            last.focus();
        } else if (!event.shiftKey && document.activeElement === last) {
            event.preventDefault();
            first.focus();
        }
    }

    function initialize() {
        initializationFrame = null;
        bindFormEvents();
        calculateFlightPreview();
        calculateFuelPreview();
        bindTabKeyboard();
        initializeInspectionCards();
        initializeDashboardCharts();
        initializeModal();
    }

    function scheduleInitialization() {
        if (initializationFrame != null) cancelAnimationFrame(initializationFrame);
        initializationFrame = requestAnimationFrame(function () {
            initializationFrame = requestAnimationFrame(initialize);
        });
    }

    const ControleHorasVoo = {
        get horasDecimais() {
            return calculatedFlightHours;
        },
        set horasDecimais(value) {
            calculatedFlightHours = value;
        },
        buscarCampo: findField,
        formatarHorario: function (value) {
            const parsed = parseTime(value);
            return parsed ? parsed.formatted : '';
        },
        calcularDuracao: function (startValue, endValue) {
            return calculateElapsedTime(startValue, endValue);
        },
        calcularCustoTotal: function (quantity, unitCost) {
            const parsedQuantity = parseDecimal(quantity);
            const parsedUnitCost = parseDecimal(unitCost);
            return parsedQuantity != null
                && parsedUnitCost != null
                && parsedQuantity >= 0
                && parsedUnitCost >= 0
                ? parsedQuantity * parsedUnitCost
                : null;
        },
        calcularTOT: calculateFlightPreview,
        calcularAbastecimentoTotal: calculateFuelPreview,
        executarCalculos: function () {
            calculateFlightPreview();
            calculateFuelPreview();
        },
        agendarAtualizacaoPeriodo: scheduleCalendarPeriodUpdate,
        finalizarAtualizacaoPeriodo: finishCalendarPeriodUpdate,
        inicializar: scheduleInitialization,
        reinicializar: scheduleInitialization
    };

    window.ControleHorasVoo = ControleHorasVoo;
    window.onTabChange = scheduleInitialization;
    window.calcularHorasRestantesInspecoes = initializeInspectionCards;
    window.calcularInspecoesProximasCalendario = initializeInspectionCards;
    window.executarCalculosAntesDeSalvar = function () {
        ControleHorasVoo.executarCalculos();
        return true;
    };

    window.fecharModalJs = function () {
        const closeButton = document.querySelector('.btn-fechar-modal');
        if (closeButton) closeButton.click();
    };

    window.toggleModoAbastecimento = function (isRefuelOnly) {
        const alertElement = document.getElementById('alertaAbastecimento');
        if (alertElement) alertElement.hidden = !isRefuelOnly;

        ['acionamento', 'corte', 'tot', 'dep', 'arr', 'tipo'].forEach(function (fieldName) {
            const field = findField(fieldName);
            const group = field ? field.closest('.form-group') : null;
            if (!field || !group) return;
            group.classList.toggle('campo-oculto-abastecimento', isRefuelOnly);
            field.disabled = isRefuelOnly;
            if (isRefuelOnly) field.value = '';
        });
        scheduleInitialization();
    };

    document.addEventListener('keydown', trapModalKeyboard);
    document.addEventListener('focusin', function (event) {
        if (!event.target.closest('.modal-content') && event.target.id) {
            lastFocusedId = event.target.id;
        }
    });
    document.addEventListener('chv:modal-closed', function () {
        if (!lastFocusedId) return;
        const previousElement = document.getElementById(lastFocusedId);
        if (previousElement) previousElement.focus();
    });

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', scheduleInitialization, { once: true });
    } else {
        scheduleInitialization();
    }
}());
