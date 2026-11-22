import { test } from 'node:test';
import assert from 'node:assert/strict';
import { renderToStaticMarkup } from 'react-dom/server';
import { CartPanel } from '../src/ui/CartPanel';
import { CatalogPage } from '../src/ui/CatalogPage';
import { FilterPanel } from '../src/ui/FilterPanel';
import { EVENTS } from '../src/data/events';
import { emptyFilters } from '../src/domain/catalog';
import { addItem, emptyCart } from '../src/domain/cart';

const noop = () => {};

test('каталог показывает карточки и постраничную навигацию', () => {
  const html = renderToStaticMarkup(<CatalogPage events={EVENTS} filters={emptyFilters} page={1} onPage={noop} onAdd={noop} />);
  assert.match(html, /Каталог событий/);
  assert.match(html, /Симфонический вечер/);
  assert.match(html, /1 \/ 2/);
});

test('пустой результат: сообщение вместо списка', () => {
  const html = renderToStaticMarkup(<CatalogPage events={EVENTS} filters={{ ...emptyFilters, query: 'zzz' }} page={1} onPage={noop} onAdd={noop} />);
  assert.match(html, /События не найдены/);
});

test('тип билета без мест недоступен для добавления', () => {
  const html = renderToStaticMarkup(<CatalogPage events={EVENTS} filters={{ ...emptyFilters, query: 'гамлет' }} page={1} onPage={noop} onAdd={noop} />);
  assert.match(html, /disabled[^>]*>Балкон: 20\.00 BYN \(нет мест\)/);
});

test('панель фильтров показывает ошибку при противоречивых датах', () => {
  const html = renderToStaticMarkup(<FilterPanel filters={{ ...emptyFilters, dateFrom: '2026-12-10', dateTo: '2026-12-01' }} cities={['Минск']} onChange={noop} />);
  assert.match(html, /role="alert"/);
});

test('корзина показывает таймер, скидку и итог', () => {
  const cart = addItem(emptyCart, { eventId: 'e01', ticketTypeId: 'std', eventTitle: 'Симфонический вечер', ticketName: 'Партер', unitPriceMinor: 4500, free: 5 }, 2);
  const html = renderToStaticMarkup(<CartPanel cart={cart} remainingMs={14 * 60_000 + 59_000} promoMessage="" discountMinor={900} onQuantity={noop} onRemove={noop} onPromo={noop} />);
  assert.match(html, /14:59/);
  assert.match(html, /Скидка: −9\.00 BYN/);
  assert.match(html, /Итого: 81\.00 BYN/);
});

test('пустая корзина', () => {
  const html = renderToStaticMarkup(<CartPanel cart={emptyCart} remainingMs={null} promoMessage="" discountMinor={0} onQuantity={noop} onRemove={noop} onPromo={noop} />);
  assert.match(html, /Корзина пуста/);
});
