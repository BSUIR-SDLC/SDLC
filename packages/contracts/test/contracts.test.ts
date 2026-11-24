import { test } from 'node:test';
import assert from 'node:assert/strict';
import { REASONS, decisionOf, normalizePassCode } from '../src/index.ts';

test('номер пропуска нормализуется: регистр и пробелы по краям (BR-02)', () => {
  assert.equal(normalizePassCode(' p-000123 '), 'P-000123');
  assert.equal(normalizePassCode('G-999999'), 'G-999999');
});

test('неверные номера пропуска отклоняются', () => {
  for (const bad of ['', 'P-12345', 'P-1234567', 'X-000001', 'P000001', 'P-00012a', 'P - 000001']) {
    assert.equal(normalizePassCode(bad), null, bad);
  }
});

test('ALLOW только при OK, все остальные коды — DENY (BR-01)', () => {
  assert.equal(REASONS.length, 9);
  for (const r of REASONS) assert.equal(decisionOf(r), r === 'OK' ? 'ALLOW' : 'DENY', r);
});
