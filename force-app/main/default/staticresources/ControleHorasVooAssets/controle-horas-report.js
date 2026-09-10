(function () {
    'use strict';

    const COLORS = {
        brand: 'FF003349',
        accent: 'FF00B3DC',
        success: 'FF2E844A',
        surface: 'FFF5F7F9',
        border: 'FFC9C9C9',
        white: 'FFFFFFFF',
        text: 'FF2E2E2E',
        muted: 'FF5C5C5C'
    };

    let lastOpener = null;
    let selectedMode = 'PILOTO';
    let excelLibraryPromise = null;

    function query(selector, root) {
        return (root || document).querySelector(selector);
    }

    function queryAll(selector, root) {
        return Array.from((root || document).querySelectorAll(selector));
    }

    function localIsoDate(year, month, day) {
        return String(year).padStart(4, '0') + '-'
            + String(month).padStart(2, '0') + '-'
            + String(day).padStart(2, '0');
    }

    function getCalendarPeriod() {
        const yearField = query('.calendar-year');
        const monthField = query('.calendar-month');
        const today = new Date();
        const year = Number(yearField && yearField.value) || today.getFullYear();
        const month = Number(monthField && monthField.value) || today.getMonth() + 1;
        const lastDay = new Date(year, month, 0).getDate();
        return {
            startDate: localIsoDate(year, month, 1),
            endDate: localIsoDate(year, month, lastDay)
        };
    }

    function setDefaultFilters(modal) {
        const period = getCalendarPeriod();
        const startDate = query('.report-start-date', modal);
        const endDate = query('.report-end-date', modal);
        if (startDate) startDate.value = period.startDate;
        if (endDate) endDate.value = period.endDate;

        const calendarAircraft = query('.filtro-aeronave .form-select');
        const reportAircraft = query('.report-aircraft', modal);
        if (
            calendarAircraft
            && reportAircraft
            && Array.from(reportAircraft.options).some(function (option) {
                return option.value === calendarAircraft.value;
            })
        ) {
            reportAircraft.value = calendarAircraft.value;
        }
    }

    function focusableElements(modal) {
        return queryAll(
            'button:not([disabled]), input:not([disabled]), select:not([disabled]), '
            + '[tabindex]:not([tabindex="-1"])',
            modal
        ).filter(function (element) {
            return !element.hidden && element.offsetParent !== null;
        });
    }

    function showFeedback(modal, message, type) {
        const feedback = query('.report-feedback', modal);
        if (!feedback) return;
        feedback.textContent = message || '';
        feedback.className = 'report-feedback'
            + (type ? ' report-feedback--' + type : '');
        feedback.hidden = !message;
    }

    function openModal(opener) {
        const overlay = query('#flightReportModal');
        if (!overlay) return;
        lastOpener = opener || document.activeElement;
        setDefaultFilters(overlay);
        showFeedback(overlay, '', '');
        overlay.hidden = false;
        document.body.classList.add('report-modal-open');
        const modal = query('.report-modal', overlay);
        requestAnimationFrame(function () {
            if (modal) modal.focus();
        });
    }

    function closeModal() {
        const overlay = query('#flightReportModal');
        if (!overlay || overlay.hidden) return;
        overlay.hidden = true;
        document.body.classList.remove('report-modal-open');
        if (lastOpener && document.contains(lastOpener)) {
            lastOpener.focus();
        }
    }

    function setMode(modal, mode) {
        selectedMode = mode;
        queryAll('.report-mode-option', modal).forEach(function (button) {
            const active = button.dataset.reportMode === mode;
            button.classList.toggle('is-active', active);
            button.setAttribute('aria-checked', String(active));
            button.tabIndex = active ? 0 : -1;
        });
        const pilotField = query('.report-pilot-field', modal);
        const operatorField = query('.report-operator-field', modal);
        if (pilotField) pilotField.hidden = mode !== 'PILOTO';
        if (operatorField) operatorField.hidden = mode !== 'OPERADOR';
    }

    function buildRequest(modal) {
        const startDate = query('.report-start-date', modal);
        const endDate = query('.report-end-date', modal);
        const aircraft = query('.report-aircraft', modal);
        const responsible = query(
            selectedMode === 'PILOTO' ? '.report-pilot' : '.report-operator',
            modal
        );
        const flightTypes = queryAll(
            '.report-flight-types input[type="checkbox"]:checked',
            modal
        ).map(function (field) {
            return field.value;
        });

        if (!startDate || !startDate.value || !endDate || !endDate.value) {
            throw new Error('Informe a data inicial e a data final.');
        }
        if (startDate.value > endDate.value) {
            throw new Error('A data inicial não pode ser posterior à data final.');
        }
        if (!flightTypes.length) {
            throw new Error('Selecione ao menos um tipo de voo.');
        }

        return {
            reportMode: selectedMode,
            responsibleId: responsible ? responsible.value : '',
            aircraftId: aircraft ? aircraft.value : '',
            startDate: startDate.value,
            endDate: endDate.value,
            flightTypes: flightTypes
        };
    }

    function safeText(value) {
        if (value == null || value === '') return null;
        const textValue = String(value);
        return /^[=+\-@]/.test(textValue.trim())
            ? "'" + textValue
            : textValue;
    }

    function ensureExcelLibrary() {
        if (window.ExcelJS) return Promise.resolve(window.ExcelJS);
        if (excelLibraryPromise) return excelLibraryPromise;

        excelLibraryPromise = new Promise(function (resolve, reject) {
            const libraryUrl = window.controleHorasVooReportLibraryUrl;
            if (!libraryUrl) {
                reject(new Error('A biblioteca de exportação não está configurada.'));
                return;
            }
            const script = document.createElement('script');
            script.src = libraryUrl;
            script.async = true;
            script.onload = function () {
                if (window.ExcelJS) {
                    resolve(window.ExcelJS);
                    return;
                }
                reject(new Error('A biblioteca de exportação não pôde ser iniciada.'));
            };
            script.onerror = function () {
                reject(new Error('Não foi possível carregar a biblioteca de exportação.'));
            };
            document.head.appendChild(script);
        }).catch(function (error) {
            excelLibraryPromise = null;
            throw error;
        });
        return excelLibraryPromise;
    }

    function parseLocalDate(isoValue) {
        const parts = String(isoValue || '').split('-').map(Number);
        return parts.length === 3
            ? new Date(parts[0], parts[1] - 1, parts[2], 12)
            : null;
    }

    function styleTitle(worksheet, title, subtitle, columnCount) {
        worksheet.mergeCells(1, 1, 1, columnCount);
        const titleCell = worksheet.getCell(1, 1);
        titleCell.value = safeText(title);
        titleCell.font = { bold: true, size: 18, color: { argb: COLORS.white } };
        titleCell.fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: COLORS.brand }
        };
        titleCell.alignment = { vertical: 'middle', horizontal: 'left' };
        worksheet.getRow(1).height = 30;

        worksheet.mergeCells(2, 1, 2, columnCount);
        const subtitleCell = worksheet.getCell(2, 1);
        subtitleCell.value = safeText(subtitle);
        subtitleCell.font = { size: 10, color: { argb: COLORS.muted } };
        subtitleCell.alignment = { vertical: 'middle', wrapText: true };
        worksheet.getRow(2).height = 25;
    }

    function styleHeader(row) {
        row.eachCell(function (cell) {
            cell.font = { bold: true, color: { argb: COLORS.white } };
            cell.fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: COLORS.brand }
            };
            cell.alignment = { vertical: 'middle', horizontal: 'left' };
            cell.border = {
                bottom: { style: 'thin', color: { argb: COLORS.accent } }
            };
        });
        row.height = 24;
    }

    function styleTotal(row) {
        row.eachCell(function (cell) {
            cell.font = { bold: true, color: { argb: COLORS.text } };
            cell.fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFE7F3EA' }
            };
            cell.border = {
                top: { style: 'thin', color: { argb: COLORS.success } }
            };
        });
    }

    function addSummarySheet(workbook, report) {
        const sheet = workbook.addWorksheet('Resumo por responsável', {
            views: [{ state: 'frozen', ySplit: 5 }]
        });
        const typeText = (report.flightTypes || []).join(', ');
        styleTitle(
            sheet,
            report.reportTitle,
            'Período: ' + report.startDate + ' a ' + report.endDate
                + ' | Tipos: ' + typeText
                + ' | Gerado em: ' + report.generatedAt,
            5
        );

        sheet.addRow([]);
        const metricRow = sheet.addRow([
            'Total de voos',
            report.totalFlights,
            'Horas de voo',
            report.totalFlightHours,
            'TOT ' + report.totalTotDisplay
        ]);
        metricRow.eachCell(function (cell, columnNumber) {
            cell.font = {
                bold: columnNumber % 2 === 1,
                color: { argb: COLORS.text }
            };
            cell.fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: COLORS.surface }
            };
        });

        const header = sheet.addRow([
            report.responsibleLabel,
            'Voos',
            'Horas de voo',
            'TOT',
            'Aeronaves'
        ]);
        styleHeader(header);

        (report.summaries || []).forEach(function (summary) {
            const row = sheet.addRow([
                safeText(summary.responsibleName),
                summary.flightCount,
                summary.flightHours,
                summary.totMinutes / 1440,
                safeText((summary.aircraft || []).join(', '))
            ]);
            row.getCell(3).numFmt = '0.0';
            row.getCell(4).numFmt = '[h]:mm';
        });

        const totalRow = sheet.addRow([
            'TOTAL GERAL',
            report.totalFlights,
            report.totalFlightHours,
            report.totalTotMinutes / 1440,
            null
        ]);
        totalRow.getCell(3).numFmt = '0.0';
        totalRow.getCell(4).numFmt = '[h]:mm';
        styleTotal(totalRow);

        sheet.columns = [
            { width: 34 },
            { width: 12 },
            { width: 16 },
            { width: 14 },
            { width: 38 }
        ];
        sheet.autoFilter = {
            from: { row: 5, column: 1 },
            to: { row: Math.max(5, totalRow.number - 1), column: 5 }
        };
        sheet.pageSetup = {
            orientation: 'landscape',
            fitToPage: true,
            fitToWidth: 1,
            fitToHeight: 0
        };
        return sheet;
    }

    function addDetailSheet(workbook, report) {
        const sheet = workbook.addWorksheet('Detalhamento', {
            views: [{ state: 'frozen', ySplit: 4 }]
        });
        styleTitle(
            sheet,
            report.reportTitle + ' - Detalhamento',
            'Período: ' + report.startDate + ' a ' + report.endDate
                + ' | Gerado em: ' + report.generatedAt,
            11
        );
        sheet.addRow([]);
        const header = sheet.addRow([
            'Aeronave',
            'Data',
            report.responsibleLabel,
            'Tipo',
            'Acionamento',
            'Corte',
            'Horas de voo',
            'TOT',
            'DEP',
            'ARR',
            'Descrição'
        ]);
        styleHeader(header);

        let currentResponsible = null;
        let currentResponsibleKey = null;
        let groupCount = 0;
        let groupHours = 0;
        let groupMinutes = 0;

        function addGroupTotal() {
            if (currentResponsibleKey == null) return;
            const row = sheet.addRow([
                'Subtotal ' + safeText(currentResponsible),
                null,
                null,
                groupCount + ' voos',
                null,
                null,
                groupHours,
                groupMinutes / 1440,
                null,
                null,
                null
            ]);
            sheet.mergeCells(row.number, 1, row.number, 3);
            row.getCell(7).numFmt = '0.0';
            row.getCell(8).numFmt = '[h]:mm';
            styleTotal(row);
        }

        (report.details || []).forEach(function (detail) {
            const responsibleKey = detail.responsibleId || 'SEM_RESPONSAVEL';
            if (
                currentResponsibleKey != null
                && currentResponsibleKey !== responsibleKey
            ) {
                addGroupTotal();
                groupCount = 0;
                groupHours = 0;
                groupMinutes = 0;
            }
            currentResponsibleKey = responsibleKey;
            currentResponsible = detail.responsibleName;

            const row = sheet.addRow([
                safeText(detail.aircraftName),
                parseLocalDate(detail.flightDate),
                safeText(detail.responsibleName),
                safeText(detail.flightType + ' - ' + detail.flightTypeLabel),
                safeText(detail.startTime),
                safeText(detail.endTime),
                detail.flightHours,
                detail.totMinutes / 1440,
                safeText(detail.departure),
                safeText(detail.arrival),
                safeText(detail.description)
            ]);
            row.getCell(2).numFmt = 'dd/mm/yyyy';
            row.getCell(7).numFmt = '0.0';
            row.getCell(8).numFmt = '[h]:mm';
            row.getCell(11).alignment = { vertical: 'top', wrapText: true };
            groupCount++;
            groupHours += Number(detail.flightHours) || 0;
            groupMinutes += Number(detail.totMinutes) || 0;
        });
        addGroupTotal();

        const totalRow = sheet.addRow([
            'TOTAL GERAL',
            null,
            null,
            report.totalFlights + ' voos',
            null,
            null,
            report.totalFlightHours,
            report.totalTotMinutes / 1440,
            null,
            null,
            null
        ]);
        sheet.mergeCells(totalRow.number, 1, totalRow.number, 3);
        totalRow.getCell(7).numFmt = '0.0';
        totalRow.getCell(8).numFmt = '[h]:mm';
        styleTotal(totalRow);

        sheet.columns = [
            { width: 14 },
            { width: 13 },
            { width: 32 },
            { width: 22 },
            { width: 14 },
            { width: 12 },
            { width: 16 },
            { width: 13 },
            { width: 12 },
            { width: 12 },
            { width: 48 }
        ];
        sheet.pageSetup = {
            orientation: 'landscape',
            fitToPage: true,
            fitToWidth: 1,
            fitToHeight: 0
        };
        return sheet;
    }

    async function downloadWorkbook(report) {
        const ExcelLibrary = await ensureExcelLibrary();
        const workbook = new ExcelLibrary.Workbook();
        workbook.creator = 'Engemap - Controle de Horas de Voo';
        workbook.created = new Date();
        workbook.modified = new Date();
        addSummarySheet(workbook, report);
        addDetailSheet(workbook, report);

        const buffer = await workbook.xlsx.writeBuffer();
        const blob = new Blob(
            [buffer],
            {
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            }
        );
        const url = URL.createObjectURL(blob);
        const anchor = document.createElement('a');
        anchor.href = url;
        anchor.download = safeText(report.fileName || 'Relatorio_Horas_Voo.xlsx')
            .replace(/^'/, '');
        document.body.appendChild(anchor);
        anchor.click();
        anchor.remove();
        setTimeout(function () {
            URL.revokeObjectURL(url);
        }, 1000);
    }

    function setGenerating(modal, generating) {
        const button = query('.report-generate', modal);
        if (!button) return;
        button.disabled = generating;
        button.classList.toggle('is-loading', generating);
        button.lastChild.textContent = generating
            ? ' Preparando...'
            : ' Gerar Excel';
    }

    function generateReport(modal) {
        let requestValue;
        try {
            requestValue = buildRequest(modal);
        } catch (error) {
            showFeedback(modal, error.message, 'error');
            return;
        }

        const accessTokenField = query('.report-access-token', modal);
        if (
            !accessTokenField
            || !accessTokenField.value
            || typeof window.gerarRelatorioHorasVooRemoto !== 'function'
        ) {
            showFeedback(
                modal,
                'Sua sessão não permite exportar. Atualize a página e tente novamente.',
                'error'
            );
            return;
        }

        showFeedback(modal, 'Consultando os voos do período...', 'progress');
        setGenerating(modal, true);
        window.gerarRelatorioHorasVooRemoto(
            accessTokenField.value,
            JSON.stringify(requestValue),
            function (response, event) {
                if (!event || !event.status || !response || !response.success) {
                    const message = response && response.message
                        ? response.message
                        : 'Não foi possível consultar os dados do relatório.';
                    showFeedback(modal, message, 'error');
                    setGenerating(modal, false);
                    return;
                }

                showFeedback(modal, 'Montando o arquivo Excel...', 'progress');
                downloadWorkbook(response.data)
                    .then(function () {
                        showFeedback(
                            modal,
                            'Relatório gerado com sucesso: '
                                + response.data.totalFlights + ' voos.',
                            'success'
                        );
                    })
                    .catch(function (error) {
                        showFeedback(modal, error.message, 'error');
                    })
                    .finally(function () {
                        setGenerating(modal, false);
                    });
            }
        );
    }

    function handleModalKeydown(event, modal) {
        if (event.key === 'Escape') {
            event.preventDefault();
            closeModal();
            return;
        }
        if (event.key !== 'Tab') return;
        const focusable = focusableElements(modal);
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
        const overlay = query('#flightReportModal');
        if (!overlay) return;

        queryAll('.flight-report-open').forEach(function (button) {
            if (button.dataset.reportBound === 'true') return;
            button.dataset.reportBound = 'true';
            button.addEventListener('click', function () {
                openModal(button);
            });
        });

        if (overlay.dataset.reportBound === 'true') return;
        overlay.dataset.reportBound = 'true';
        const modal = query('.report-modal', overlay);
        query('.report-modal-close', overlay).addEventListener('click', closeModal);
        query('.report-cancel', overlay).addEventListener('click', closeModal);
        query('.report-generate', overlay).addEventListener('click', function () {
            generateReport(overlay);
        });
        overlay.addEventListener('click', function (event) {
            if (event.target === overlay) closeModal();
        });
        modal.addEventListener('keydown', function (event) {
            handleModalKeydown(event, modal);
        });

        queryAll('.report-mode-option', overlay).forEach(function (button) {
            button.addEventListener('click', function () {
                setMode(overlay, button.dataset.reportMode);
            });
            button.addEventListener('keydown', function (event) {
                if (!['ArrowLeft', 'ArrowRight'].includes(event.key)) return;
                event.preventDefault();
                const nextMode = selectedMode === 'PILOTO'
                    ? 'OPERADOR'
                    : 'PILOTO';
                setMode(overlay, nextMode);
                query(
                    '.report-mode-option[data-report-mode="' + nextMode + '"]',
                    overlay
                ).focus();
            });
        });
        setMode(overlay, selectedMode);
    }

    document.addEventListener('chv:initialized', initialize);
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initialize, { once: true });
    } else {
        initialize();
    }
}());
