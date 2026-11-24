import { test } from 'node:test';
import assert from 'node:assert/strict';
import { REASONS, type ValidationResponse } from '../../../packages/contracts/src/index.ts';
import { ALLOW_AUTO_CLOSE_MS, REASON_TEXT, offlineCard, toResultCard } from '../src/result/resultCard.ts';
import { nextState } from '../src/state/scannerMachine.ts';

const pass = { code: 'G-000042', holderName: 'Петрова Анна', type: 'GUEST' as const, validTo: Date.UTC(2026, 10, 25), photoId: null };

test('ALLOW: зелёная карточка с ФИО, автозакрытие через 3 с (UC-02, шаг 6)', () => {
  const res: ValidationResponse = { decision: 'ALLOW', reason: 'OK', pass, occupancy: 12, capacity: 400 };
  const card = toResultCard(res);
  assert.equal(card.tone, 'allow');
  assert.equal(card.title, 'Петрова Анна');
  assert.deepEqual(card.details, ['Гость G-000042', 'Действует до 25.11.2026', 'Внутри: 12 из 400']);
  assert.equal(card.autoCloseMs, ALLOW_AUTO_CLOSE_MS);
  assert.equal(card.button, null);
});

test('DENY: красная карточка, причина по-русски, вибрация, только кнопка «Следующий» (А2)', () => {
  const card = toResultCard({ decision: 'DENY', reason: 'DENY_ZONE', pass, occupancy: null, capacity: null });
  assert.equal(card.tone, 'deny');
  assert.equal(card.message, 'Нет доступа в эту зону');
  assert.equal(card.vibrateMs, 200);
  assert.equal(card.autoCloseMs, null);
  assert.equal(card.button?.event, 'NEXT');
  assert.equal(nextState('denied', card.button!.event), 'scanning');
});

test('для каждого кода причины есть текст; несогласованный ответ трактуется как отказ (fail-closed)', () => {
  for (const r of REASONS) assert.ok(REASON_TEXT[r].length > 0, r);
  const odd = toResultCard({ decision: 'ALLOW', reason: 'DENY_CAPACITY', pass: null, occupancy: 400, capacity: 400 });
  assert.equal(odd.tone, 'deny');
  assert.equal(odd.message, REASON_TEXT.DENY_CAPACITY);
});

test('«Нет связи» (Е1): кнопка «Повторить» ведёт обратно в сканирование, не в allowed', () => {
  const card = offlineCard();
  assert.equal(card.tone, 'offline');
  assert.equal(card.button?.event, 'RETRY');
  assert.equal(nextState('offline', card.button!.event), 'scanning');
});
