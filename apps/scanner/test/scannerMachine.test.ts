import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  INITIAL_STATE, SESSION_INITIAL, SESSION_STATES, SESSION_TRANSITIONS, TRANSITIONS,
  createDuplicateFilter, isCameraActive, isValidManualCode, nextState, timerFor,
  type ScannerEvent, type ScannerState,
} from '../src/state/scannerMachine.ts';

const PUML = fileURLToPath(new URL('../../../uml/models/state-scanner.puml', import.meta.url));

/** Разбор переходов диаграммы: «источник --> цель : СОБЫТИЕ ...». Составное состояние session раскрывается. */
function diagramTransitions(): Set<string> {
  const text = readFileSync(PUML, 'utf8');
  const result = new Set<string>();
  let initial: string | null = null;
  for (const line of text.split(/\r?\n/)) {
    const init = /^\s+\[\*\]\s*-+>\s*(\w+)\s*$/.exec(line);
    if (init) initial = init[1];
    const m = /^\s*(\w+)\s*-+>\s*(\w+)\s*:\s*([A-Z_]+)/.exec(line);
    if (!m) continue;
    const [, from, to, event] = m;
    const target = to === 'session' ? initial ?? to : to;
    const sources = from === 'session' ? [...SESSION_STATES] : [from];
    for (const s of sources) result.add(`${s} --${event}--> ${target}`);
  }
  return result;
}

function codeTransitions(): Set<string> {
  const result = new Set<string>();
  for (const [from, row] of Object.entries(TRANSITIONS)) {
    for (const [event, to] of Object.entries(row)) result.add(`${from} --${event}--> ${to}`);
  }
  for (const s of SESSION_STATES) {
    for (const [event, to] of Object.entries(SESSION_TRANSITIONS)) result.add(`${s} --${event}--> ${to}`);
  }
  return result;
}

test('таблица переходов в коде совпадает с диаграммой состояний (ADR-0010)', () => {
  const fromDiagram = [...diagramTransitions()].sort();
  const fromCode = [...codeTransitions()].sort();
  assert.ok(fromDiagram.length >= 20, `разобрано переходов: ${fromDiagram.length}`);
  assert.deepEqual(fromCode, fromDiagram);
  assert.equal(SESSION_INITIAL, 'selectCheckpoint');
});

test('основной поток UC-02: вход → точка → скан → проверка → ALLOW → автовозврат', () => {
  const path: [ScannerEvent, ScannerState][] = [
    ['LOGIN_OK', 'selectCheckpoint'],
    ['CHECKPOINT_SELECTED', 'scanning'],
    ['QR_DECODED', 'validating'],
    ['ALLOW', 'allowed'],
    ['AUTO_RETURN', 'scanning'],
  ];
  let s: ScannerState = INITIAL_STATE;
  for (const [event, expected] of path) {
    s = nextState(s, event);
    assert.equal(s, expected, event);
  }
});

test('fail-closed: из «Нет связи» нельзя попасть в «Проход разрешён» (REQ-REL-001)', () => {
  const events = Object.keys({ ...TRANSITIONS.validating, ...SESSION_TRANSITIONS, NEXT: 1, RETRY: 1, ALLOW: 1 }) as ScannerEvent[];
  for (const e of events) assert.notEqual(nextState('offline', e), 'allowed', e);
  assert.equal(nextState('offline', 'ALLOW'), 'offline');
  assert.equal(nextState('validating', 'TIMEOUT'), 'offline');
});

test('отказ требует явного «Следующий», автовозврата нет (REQ-FUNC-007)', () => {
  assert.equal(nextState('denied', 'AUTO_RETURN'), 'denied');
  assert.equal(nextState('denied', 'NEXT'), 'scanning');
});

test('401 в любом состоянии сеанса переводит на экран входа', () => {
  for (const s of SESSION_STATES) assert.equal(nextState(s, 'UNAUTHORIZED'), 'login', s);
  assert.equal(nextState('login', 'UNAUTHORIZED'), 'login');
});

test('во время проверки повторный QR игнорируется, камера выключена', () => {
  assert.equal(nextState('validating', 'QR_DECODED'), 'validating');
  assert.equal(isCameraActive('validating'), false);
  assert.equal(isCameraActive('scanning'), true);
});

test('таймеры: 5 с ожидания ответа, 3 с показа ALLOW', () => {
  assert.deepEqual(timerFor('validating'), { ms: 5000, event: 'TIMEOUT' });
  assert.deepEqual(timerFor('allowed'), { ms: 3000, event: 'AUTO_RETURN' });
  assert.equal(timerFor('denied'), null);
});

test('ручной ввод: формат P-/G-NNNNNN (BR-02)', () => {
  for (const ok of ['P-000123', 'G-999999', ' p-000001 ']) assert.ok(isValidManualCode(ok), ok);
  for (const bad of ['P-12345', 'X-000001', 'P000001', 'G-0000001', '']) assert.ok(!isValidManualCode(bad), bad);
});

test('повтор того же токена в течение 3 с отбрасывается (BR-06)', () => {
  const accept = createDuplicateFilter();
  assert.equal(accept('tok', 0), true);
  assert.equal(accept('tok', 2999), false);
  assert.equal(accept('other', 3000), true);
  assert.equal(accept('tok', 6500), true);
});
