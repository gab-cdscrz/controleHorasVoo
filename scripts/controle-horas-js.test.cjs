const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const sourcePath = path.resolve(
    __dirname,
    '../force-app/main/default/staticresources/ControleHorasVooAssets/controle-horas.js'
);
const source = fs.readFileSync(sourcePath, 'utf8');
const pageSource = fs.readFileSync(
    path.resolve(
        __dirname,
        '../force-app/main/default/pages/ControleHorasVoo.page'
    ),
    'utf8'
);
const listeners = new Map();
const timers = new Map();
let nextTimerId = 1;

function flushTimers() {
    const pendingTimers = Array.from(timers.values());
    timers.clear();
    pendingTimers.forEach((callback) => callback());
}

const documentStub = {
    activeElement: null,
    readyState: 'loading',
    addEventListener(name, callback) {
        listeners.set(name, callback);
    },
    getElementById() {
        return null;
    },
    querySelector() {
        return null;
    },
    querySelectorAll() {
        return [];
    },
    contains() {
        return true;
    }
};
const windowStub = {};
const context = vm.createContext({
    Array,
    CustomEvent: class CustomEvent {},
    Event: class Event {},
    Map,
    Number,
    Set,
    String,
    cancelAnimationFrame() {},
    clearTimeout(timerId) {
        timers.delete(timerId);
    },
    console,
    document: documentStub,
    requestAnimationFrame(callback) {
        callback();
        return 1;
    },
    setTimeout(callback) {
        const timerId = nextTimerId;
        nextTimerId += 1;
        timers.set(timerId, callback);
        return timerId;
    },
    window: windowStub
});

vm.runInContext(source, context, { filename: sourcePath });

const api = windowStub.ControleHorasVoo;
assert.ok(api, 'The global page API should be available.');
assert.equal(api.formatarHorario('8'), '08:00');
assert.equal(api.formatarHorario('830'), '08:30');
assert.equal(api.formatarHorario('23:59:00.000'), '23:59');
assert.equal(api.formatarHorario('24:00'), '');
assert.equal(api.formatarHorario('12:75'), '');
assert.equal(api.formatarHorario(''), '');

const daytimeDuration = api.calcularDuracao('1400', '1530');
assert.equal(daytimeDuration.formatted, '1:30');
assert.equal(daytimeDuration.decimalHours, 1.5);

const overnightDuration = api.calcularDuracao('23:30', '01:00');
assert.equal(overnightDuration.formatted, '1:30');
assert.equal(overnightDuration.decimalHours, 1.5);

assert.equal(api.calcularCustoTotal('100', '10,50'), 1050);
assert.equal(api.calcularCustoTotal('', '10,50'), null);
assert.equal(api.calcularCustoTotal('-1', '10,50'), null);

let calendarUpdateCalls = 0;
windowStub.atualizarPeriodoCalendarioAF = () => {
    calendarUpdateCalls += 1;
};
api.agendarAtualizacaoPeriodo();
api.agendarAtualizacaoPeriodo();
assert.equal(timers.size, 1, 'Rapid period changes should be debounced.');
flushTimers();
assert.equal(calendarUpdateCalls, 1, 'The debounced period change should request one update.');

api.agendarAtualizacaoPeriodo();
flushTimers();
assert.equal(
    calendarUpdateCalls,
    1,
    'A second update should wait while the first Ajax request is active.'
);
api.finalizarAtualizacaoPeriodo();
assert.equal(timers.size, 1, 'A pending period change should be rescheduled after Ajax.');
flushTimers();
assert.equal(calendarUpdateCalls, 2, 'The latest pending period should be applied.');
api.finalizarAtualizacaoPeriodo();

assert.equal(source.includes('MutationObserver'), false);
assert.equal(source.includes('new Date(dataProximaStr)'), false);
assert.equal(
    source.includes("type: 'doughnut'"),
    true,
    'The fleet dashboard should initialize doughnut charts.'
);
assert.equal(
    pageSource.includes('$Resource.ChartJs'),
    true,
    'The Visualforce page should load the existing ChartJs static resource.'
);
assert.equal(
    pageSource.includes('flight-dashboard-legend'),
    true,
    'The dashboard should expose one shared legend after the aircraft charts.'
);
assert.equal(
    pageSource.includes('name="atualizarPeriodoCalendarioAF"'),
    true,
    'The page should expose one partial Ajax action for period changes.'
);
assert.equal(
    (pageSource.match(/onchange="ControleHorasVoo\.agendarAtualizacaoPeriodo\(\);"/g) || []).length,
    2,
    'Year and month should both schedule the automatic dashboard update.'
);
assert.ok(
    (pageSource.match(/oncomplete="[^"]*onTabChange\(\)/g) || []).length >= 10,
    'Every form-loading rerender should schedule idempotent initialization.'
);
assert.equal(
    (pageSource.match(/fuel-calculation-row/g) || []).length,
    2,
    'New and edit fuel forms should each define a calculation scope.'
);
assert.equal(
    (pageSource.match(/fuel-total-cost-field/g) || []).length,
    2,
    'New and edit fuel forms should each expose a calculated total field.'
);

console.log('controle-horas.js: tests passed');
