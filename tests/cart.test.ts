import { test } from 'node:test';
import assert from 'node:assert/strict';
import { addItem, emptyCart, removeItem, setQuantity, subtotalMinor, totalQuantity } from '../src/domain/cart';
import { CartError, formatMoney } from '../src/domain/types';

const item = { eventId: 'e01', ticketTypeId: 'std', eventTitle: 'Симфонический вечер', ticketName: 'Партер', unitPriceMinor: 4500, free: 3 };

test('добавление создаёт позицию', () => {
  const c = addItem(emptyCart, item);
  assert.equal(c.length, 1);
  assert.equal(c[0].quantity, 1);
});

test('одинаковые позиции объединяются', () => {
  const c = addItem(addItem(emptyCart, item), item);
  assert.equal(c.length, 1);
  assert.equal(c[0].quantity, 2);
});

test('нельзя превысить число свободных мест', () => {
  const c = addItem(emptyCart, item, 3);
  assert.throws(() => addItem(c, item), (e) => e instanceof CartError && e.code === 'NO_SEATS');
});

test('нельзя добавить, если мест нет', () => {
  assert.throws(() => addItem(emptyCart, { ...item, free: 0 }), (e) => e instanceof CartError && e.code === 'NO_SEATS');
});

test('количество должно быть целым и положительным', () => {
  for (const q of [0, -1, 1.5, NaN]) {
    assert.throws(() => addItem(emptyCart, item, q), (e) => e instanceof CartError && e.code === 'INVALID_QUANTITY');
  }
});

test('изменение количества в пределах свободных мест', () => {
  const c = setQuantity(addItem(emptyCart, item), 'e01', 'std', 3);
  assert.equal(c[0].quantity, 3);
  assert.throws(() => setQuantity(c, 'e01', 'std', 4), (e) => e instanceof CartError && e.code === 'NO_SEATS');
});

test('количество 0 удаляет позицию', () => {
  const c = setQuantity(addItem(emptyCart, item), 'e01', 'std', 0);
  assert.equal(c.length, 0);
});

test('изменение отсутствующей позиции — ошибка', () => {
  assert.throws(() => setQuantity(emptyCart, 'x', 'y', 1), (e) => e instanceof CartError && e.code === 'NOT_IN_CART');
});

test('удаление и итоговая сумма', () => {
  let c = addItem(emptyCart, item, 2);
  c = addItem(c, { ...item, eventId: 'e05', ticketTypeId: 'a', unitPriceMinor: 1500, free: 10 });
  assert.equal(subtotalMinor(c), 2 * 4500 + 1500);
  assert.equal(totalQuantity(c), 3);
  assert.equal(subtotalMinor(removeItem(c, 'e01', 'std')), 1500);
});

test('исходная корзина не изменяется (неизменяемость)', () => {
  const c = addItem(emptyCart, item);
  addItem(c, item);
  assert.equal(c[0].quantity, 1);
});

test('форматирование денег', () => {
  assert.equal(formatMoney(4505), '45.05 BYN');
  assert.equal(formatMoney(5), '0.05 BYN');
  assert.equal(formatMoney(0), '0.00 BYN');
});
