import { test } from 'node:test';
import assert from 'node:assert/strict';
import { applyPromo } from '../src/domain/promo';

test('процентная скидка', () => {
  const r = applyPromo('welcome10', 5000);
  assert.deepEqual(r, { ok: true, code: 'WELCOME10', discountMinor: 500, totalMinor: 4500 });
});

test('округление скидки вниз до минимальной единицы', () => {
  const r = applyPromo('WELCOME10', 1999);
  assert.equal(r.ok && r.discountMinor, 199);
});

test('фиксированная скидка при достаточной сумме', () => {
  const r = applyPromo('SAVE5', 3000);
  assert.deepEqual(r, { ok: true, code: 'SAVE5', discountMinor: 500, totalMinor: 2500 });
});

test('минимальная сумма заказа для промокода', () => {
  assert.deepEqual(applyPromo('SAVE5', 1000), { ok: false, reason: 'MIN_SUBTOTAL' });
});

test('скидка не превышает сумму корзины', () => {
  const r = applyPromo('X', 300, [{ code: 'X', kind: 'fixed', value: 1000 }]);
  assert.deepEqual(r, { ok: true, code: 'X', discountMinor: 300, totalMinor: 0 });
});

test('неизвестный, пустой код и пустая корзина', () => {
  assert.deepEqual(applyPromo('NOPE', 5000), { ok: false, reason: 'UNKNOWN_CODE' });
  assert.deepEqual(applyPromo('  ', 5000), { ok: false, reason: 'EMPTY_CODE' });
  assert.deepEqual(applyPromo('WELCOME10', 0), { ok: false, reason: 'EMPTY_CART' });
});
