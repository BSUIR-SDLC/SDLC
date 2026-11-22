import { test } from 'node:test';
import assert from 'node:assert/strict';
import { applyFilters, emptyFilters, minPriceMinor, paginate, uniqueCities, validateFilters } from '../src/domain/catalog';
import { EVENTS } from '../src/data/events';

const f = (patch: Partial<typeof emptyFilters>) => ({ ...emptyFilters, ...patch });

test('без фильтров возвращаются все события, отсортированные по дате', () => {
  const r = applyFilters(EVENTS, emptyFilters);
  assert.equal(r.length, EVENTS.length);
  for (let i = 1; i < r.length; i++) assert.ok(r[i - 1].date <= r[i].date);
});

test('поиск по названию не зависит от регистра и пробелов по краям', () => {
  assert.deepEqual(applyFilters(EVENTS, f({ query: '  гАмЛеТ ' })).map((e) => e.id), ['e03']);
});

test('поиск без совпадений даёт пустой список', () => {
  assert.equal(applyFilters(EVENTS, f({ query: 'нет такого' })).length, 0);
});

test('фильтр по городу', () => {
  const r = applyFilters(EVENTS, f({ city: 'Гродно' }));
  assert.deepEqual(r.map((e) => e.id).sort(), ['e04', 'e09']);
});

test('фильтр по категории', () => {
  const r = applyFilters(EVENTS, f({ category: 'sport' }));
  assert.deepEqual(r.map((e) => e.id).sort(), ['e05', 'e06']);
});

test('границы дат включительные', () => {
  const r = applyFilters(EVENTS, f({ dateFrom: '2026-12-05', dateTo: '2026-12-05' }));
  assert.deepEqual(r.map((e) => e.id), ['e01']);
});

test('диапазон цен: событие подходит, если есть тип билета в диапазоне', () => {
  const r = applyFilters(EVENTS, f({ priceMinMinor: 1000, priceMaxMinor: 2000 }));
  const ids = r.map((e) => e.id);
  assert.ok(ids.includes('e05')); // сектор A 15.00
  assert.ok(ids.includes('e06')); // 18.00
  assert.ok(!ids.includes('e08')); // 40.00 и 120.00
});

test('условия объединяются логическим И', () => {
  const r = applyFilters(EVENTS, f({ city: 'Минск', category: 'concert', query: 'рок' }));
  assert.deepEqual(r.map((e) => e.id), ['e02']);
});

test('сброс фильтров возвращает полный список', () => {
  const filtered = applyFilters(EVENTS, f({ city: 'Брест' }));
  assert.ok(filtered.length < EVENTS.length);
  assert.equal(applyFilters(EVENTS, emptyFilters).length, EVENTS.length);
});

test('противоречивые фильтры дают ошибку и пустой результат', () => {
  assert.match(validateFilters(f({ dateFrom: '2026-12-10', dateTo: '2026-12-01' }))!, /Дата/);
  assert.match(validateFilters(f({ priceMinMinor: 500, priceMaxMinor: 100 }))!, /цена/i);
  assert.equal(applyFilters(EVENTS, f({ priceMinMinor: 500, priceMaxMinor: 100 })).length, 0);
  assert.equal(validateFilters(emptyFilters), null);
});

test('минимальная цена события', () => {
  assert.equal(minPriceMinor(EVENTS[0]), 4500);
  assert.equal(minPriceMinor({ ...EVENTS[0], ticketTypes: [] }), null);
});

test('постраничная выдача: границы страниц', () => {
  const p1 = paginate(EVENTS, 1, 5);
  assert.equal(p1.items.length, 5);
  assert.equal(p1.totalPages, 3);
  assert.equal(paginate(EVENTS, 3, 5).items.length, 2);
  assert.equal(paginate(EVENTS, 99, 5).page, 3);
  assert.equal(paginate(EVENTS, -4, 5).page, 1);
  assert.equal(paginate([], 1, 5).totalPages, 1);
});

test('список городов без повторов', () => {
  assert.deepEqual(uniqueCities(EVENTS), ['Брест', 'Гродно', 'Минск']);
});
