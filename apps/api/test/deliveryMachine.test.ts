import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import {
  TRANSITIONS, COMPOSITE_TRANSITIONS, ACTIVE_STATES, ACTIVE_INITIAL,
  step, classify, backoffMs, initialState, MAX_RETRIES,
} from '../src/modules/dispatcher/deliveryMachine.ts';
import type { DeliveryState } from '../src/modules/dispatcher/deliveryMachine.ts';

// --- Сверка диаграммы и кода (ADR-0010) --------------------------------------
function transitionsFromModel(path: string): Set<string> {
  const text = readFileSync(new URL(path, import.meta.url), 'utf8');
  const lines = text.split('\n').map((l) => l.trim());
  // состав составного состояния active и его начальное подсостояние
  const members: string[] = [];
  let initial = '';
  let depth = 0;
  for (const line of lines) {
    if (/^state .* as active \{$/.test(line)) { depth = 1; continue; }
    if (depth && line === '}') { depth = 0; continue; }
    if (!depth) continue;
    const m = line.match(/^state ".*" as (\w+)/);
    if (m) members.push(m[1]);
    const i = line.match(/^\[\*\] --> (\w+)/);
    if (i) initial = i[1];
  }
  const result = new Set<string>();
  for (const line of lines) {
    const m = line.match(/^(\w+) --> (\w+) : ([A-Z0-9_]+)/);
    if (!m) continue;
    const [, from, to0, event] = m;
    const to = to0 === 'active' ? initial : to0;
    const sources = from === 'active' ? members : [from];
    for (const s of sources) result.add(`${s} --${event}--> ${to}`);
  }
  return result;
}

function transitionsFromCode(): Set<string> {
  const result = new Set<string>();
  for (const t of TRANSITIONS) result.add(`${t.from} --${t.event}--> ${t.to}`);
  for (const s of ACTIVE_STATES)
    for (const c of COMPOSITE_TRANSITIONS) result.add(`${s} --${c.event}--> ${c.to}`);
  return result;
}

test('переходы state-delivery.puml совпадают с таблицей переходов в коде', () => {
  const model = transitionsFromModel('../../../uml/models/state-delivery.puml');
  assert.ok(model.size >= 15, 'модель не разобрана');
  assert.deepEqual([...transitionsFromCode()].sort(), [...model].sort());
});

// --- Поведение автомата --------------------------------------------------------
test('успешная доставка: queued → sending → delivered', () => {
  let s: DeliveryState = initialState(true);
  assert.equal(s, ACTIVE_INITIAL);
  s = step(s, 'WORKER_PICKED').state;
  s = step(s, 'RESPONSE_2XX').state;
  assert.equal(s, 'delivered');
});

test('защита не пройдена – доставка сразу в состоянии skipped', () => {
  assert.equal(initialState(false), 'skipped');
});

test('5 попыток: 4 повтора с паузой 2, 4, 8, 16 с, после пятой ошибки – failed (ADR-0006)', () => {
  let r = { state: 'sending' as DeliveryState, ctx: { retries: 0 } };
  const waits: number[] = [];
  for (let i = 0; i < MAX_RETRIES; i++) {
    r = step(r.state, 'RETRYABLE_ERROR', r.ctx);
    assert.equal(r.state, 'retryWait');
    waits.push(backoffMs(r.ctx.retries));
    r = step(r.state, 'BACKOFF_ELAPSED', r.ctx);
  }
  assert.deepEqual(waits, [2000, 4000, 8000, 16000]);
  r = step(r.state, 'RETRYABLE_ERROR', r.ctx);
  assert.equal(r.state, 'failed');
});

test('ошибка 4xx не повторяется; повтор недоставленного сбрасывает счётчик', () => {
  const r = step('sending', 'PERMANENT_ERROR', { retries: 1 });
  assert.equal(r.state, 'failed');
  const replay = step(r.state, 'REPLAY', r.ctx);
  assert.deepEqual(replay, { state: 'queued', ctx: { retries: 0 } });
});

test('глобальная пауза и возобновление', () => {
  assert.equal(step('queued', 'GLOBAL_PAUSE').state, 'paused');
  assert.equal(step('paused', 'RESUME').state, 'queued');
});

test('удаление цели отменяет доставку из любого подсостояния «В обработке»', () => {
  for (const s of ACTIVE_STATES) assert.equal(step(s, 'TARGET_DELETED').state, 'cancelled');
  assert.throws(() => step('delivered', 'TARGET_DELETED'), /Недопустимый переход/);
});

test('из delivered нет перехода обратно в отправку (доставка не повторяется)', () => {
  assert.throws(() => step('delivered', 'WORKER_PICKED'));
  assert.equal(step('delivered', 'RETENTION_EXPIRED').state, 'purged');
});

test('классификация ответов цели (BR-09)', () => {
  assert.equal(classify({ status: 204 }), 'RESPONSE_2XX');
  assert.equal(classify({ status: 503 }), 'RETRYABLE_ERROR');
  assert.equal(classify({ status: 429 }), 'RETRYABLE_ERROR');
  assert.equal(classify({ status: 408 }), 'RETRYABLE_ERROR');
  assert.equal(classify({ status: 404 }), 'PERMANENT_ERROR');
  assert.equal(classify({ networkError: true }), 'RETRYABLE_ERROR');
  assert.equal(classify({}), 'RETRYABLE_ERROR');
});
