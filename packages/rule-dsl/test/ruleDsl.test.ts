import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  OPERATORS, resolvePath, validateRuleDefinition, RuleEvaluator,
} from '../src/index.ts';

test('все 10 операторов сравнения работают корректно (Strategy)', () => {
  assert.equal(OPERATORS.eq.evaluate(80, 80), true);
  assert.equal(OPERATORS.ne.evaluate('A', 'B'), true);
  assert.equal(OPERATORS.gt.evaluate(81, 80), true);
  assert.equal(OPERATORS.gt.evaluate('81', 80), false);
  assert.equal(OPERATORS.gte.evaluate(80, 80), true);
  assert.equal(OPERATORS.lt.evaluate(10, 20), true);
  assert.equal(OPERATORS.lte.evaluate(20, 20), true);
  assert.equal(OPERATORS.in.evaluate('crit', ['warn', 'crit']), true);
  assert.equal(OPERATORS.in.evaluate('crit', 'not-array'), false);
  assert.equal(OPERATORS.contains.evaluate('sensor-cpu-1', 'cpu'), true);
  assert.equal(OPERATORS.contains.evaluate(['a', 'b'], 'b'), true);
  assert.equal(OPERATORS.contains.evaluate(123, '1'), false);
  assert.equal(OPERATORS.regex.evaluate('dev-42', '^dev-\\d+$'), true);
  assert.equal(OPERATORS.regex.evaluate('dev-42', '[unclosed'), false);
  assert.equal(OPERATORS.regex.evaluate(42, '42'), false);
  assert.equal(OPERATORS.exists.evaluate(0, true), true);
  assert.equal(OPERATORS.exists.evaluate(undefined, false), true);
  assert.equal(OPERATORS.exists.evaluate('ok', 'ignored'), true);
});

test('resolvePath извлекает вложенные поля и игнорирует некорректные пути', () => {
  const ev = { payload: { deviceId: 'd1', value: 85 }, type: 'sensor.temperature' };
  assert.equal(resolvePath(ev, '$.payload.value'), 85);
  assert.equal(resolvePath(ev, '$.payload.missing'), undefined);
  assert.equal(resolvePath(ev, 'payload.value'), undefined);
  assert.equal(resolvePath({ arr: [1] }, '$.arr.0'), undefined);
});

test('RuleEvaluator вычисляет all / any / not и формирует explain', () => {
  const evaluator = new RuleEvaluator();
  const expr = {
    all: [
      { path: '$.payload.value', op: 'gt' as const, value: 80 },
      { any: [{ path: '$.payload.unit', op: 'eq' as const, value: 'C' }, { path: '$.payload.unit', op: 'eq' as const, value: 'K' }] },
      { not: { path: '$.payload.muted', op: 'eq' as const, value: true } },
    ],
  };
  const ok = evaluator.evaluate(expr, { payload: { value: 90, unit: 'C', muted: false } });
  assert.equal(ok.matched, true);
  assert.equal(ok.explain.length, 3);
  const miss = evaluator.evaluate(expr, { payload: { value: 70, unit: 'C', muted: false } });
  assert.equal(miss.matched, false);
});

test('validateRuleDefinition проверяет схему правила и возвращает пути ошибок (SUP-U-02)', () => {
  const valid = validateRuleDefinition({
    id: 'overheat-alert',
    source: 'emulator-1',
    eventType: 'sensor.temperature',
    priority: 20,
    cooldownSec: 60,
    when: { all: [{ path: '$.payload.value', op: 'gt', value: 80 }] },
    then: [{ target: 'emulator', path: '/api/cmd', body: { command: 'shutdown' } }],
  });
  assert.equal(valid.ok, true);

  assert.equal(validateRuleDefinition(null).ok, false);
  const bad = validateRuleDefinition({
    id: 'Bad ID',
    source: '',
    eventType: '',
    priority: -1,
    cooldownSec: -5,
    when: {
      all: [{
        any: [{
          not: { path: '$.a', op: 'eq', value: 1 },
        }],
      }],
    },
    then: [{ target: '', path: 'relative', body: [] }],
  });
  assert.equal(bad.ok, false);
  if (!bad.ok) {
    const paths = bad.errors.map((e) => e.path);
    assert.ok(paths.includes('$.id'));
    assert.ok(paths.includes('$.when.all[0].any[0].not'));
    assert.ok(paths.includes('$.then[0].path'));
  }

  const badLeaf = validateRuleDefinition({
    id: 'bad-op',
    source: 's1',
    eventType: 't1',
    priority: 1,
    when: { all: [{ path: 'bad', op: 'unknown' }] },
    then: [],
  });
  assert.equal(badLeaf.ok, false);
  if (!badLeaf.ok) {
    assert.ok(badLeaf.errors.some((e) => e.path === '$.when.all[0].op'));
    assert.ok(badLeaf.errors.some((e) => e.path === '$.when.all[0].path'));
    assert.ok(badLeaf.errors.some((e) => e.path === '$.then'));
  }

  const missingVal = validateRuleDefinition({
    id: 'no-val',
    source: 's1',
    eventType: 't1',
    priority: 1,
    when: { all: [] },
    then: [null],
  });
  assert.equal(missingVal.ok, false);
  const noValLeaf = validateRuleDefinition({
    id: 'no-val-leaf',
    source: 's1',
    eventType: 't1',
    priority: 1,
    when: { path: '$.payload.x', op: 'eq' },
    then: [{ target: 'emu', path: '/a', body: {} }],
  });
  assert.equal(noValLeaf.ok, false);
  const nonObjCond = validateRuleDefinition({
    id: 'non-obj',
    source: 's1',
    eventType: 't1',
    priority: 1,
    when: 'bad',
    then: [{ target: 'emu', path: '/a', body: {} }],
  });
  assert.equal(nonObjCond.ok, false);
});
