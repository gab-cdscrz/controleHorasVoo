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
    console,
    document: documentStub,
    requestAnimationFrame(callback) {
        callback();
        return 1;
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
assert.equal(source.includes('MutationObserver'), false);
assert.equal(source.includes('new Date(dataProximaStr)'), false);
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
