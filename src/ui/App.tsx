import { useEffect, useMemo, useState } from 'react';
import { ApiError, MockApi } from '../api/mockApi';
import { Cart, addItem, emptyCart, removeItem, setQuantity, subtotalMinor } from '../domain/cart';
import { emptyFilters, uniqueCities } from '../domain/catalog';
import { applyPromo } from '../domain/promo';
import { CartError, EventItem, Filters, Reservation, formatMoney } from '../domain/types';
import { CartPanel } from './CartPanel';
import { CatalogPage } from './CatalogPage';
import { FilterPanel } from './FilterPanel';
import { useCountdown } from './hooks';

const SESSION_ID = 'local-session';

export function App({ api = new MockApi() }: { api?: MockApi }) {
  const [events, setEvents] = useState<EventItem[]>(() => api.listEvents());
  const [filters, setFilters] = useState<Filters>(emptyFilters);
  const [page, setPage] = useState(1);
  const [cart, setCart] = useState<Cart>(emptyCart);
  const [reservation, setReservation] = useState<Reservation | null>(null);
  const [promoCode, setPromoCode] = useState('');
  const [promoMessage, setPromoMessage] = useState('');
  const [error, setError] = useState('');
  const remaining = useCountdown(reservation);

  const cities = useMemo(() => uniqueCities(events), [events]);

  // Бронь истекла: очищаем корзину, места возвращаются в продажу (UC-10)
  useEffect(() => {
    if (reservation && remaining === 0) {
      api.release(SESSION_ID);
      setCart(emptyCart);
      setReservation(null);
      setPromoCode('');
      setPromoMessage('');
      setEvents(api.listEvents());
      setError('Время брони истекло, места возвращены в продажу');
    }
  }, [remaining, reservation, api]);

  const sync = (next: Cart) => {
    try {
      const res = api.reserve(SESSION_ID, next.map((l) => ({ eventId: l.eventId, ticketTypeId: l.ticketTypeId, quantity: l.quantity })));
      setCart(next);
      setReservation(next.length === 0 ? null : res);
      setEvents(api.listEvents());
      setError('');
    } catch (e) {
      setError(e instanceof ApiError || e instanceof CartError ? e.message : 'Неизвестная ошибка');
    }
  };

  const onAdd = (event: EventItem, ticketTypeId: string) => {
    const t = event.ticketTypes.find((x) => x.id === ticketTypeId);
    if (!t) return;
    try {
      sync(addItem(cart, { eventId: event.id, ticketTypeId, eventTitle: event.title, ticketName: t.name, unitPriceMinor: t.priceMinor, free: t.free + (cart.find((l) => l.eventId === event.id && l.ticketTypeId === ticketTypeId)?.quantity ?? 0) }));
    } catch (e) {
      setError(e instanceof CartError ? e.message : 'Неизвестная ошибка');
    }
  };

  const promo = promoCode ? applyPromo(promoCode, subtotalMinor(cart)) : null;
  const discount = promo && promo.ok ? promo.discountMinor : 0;

  return (
    <main>
      <h1>EventPass</h1>
      {error && <p role="alert" className="error">{error}</p>}
      <FilterPanel filters={filters} cities={cities} onChange={(f) => { setFilters(f); setPage(1); }} />
      <CatalogPage events={events} filters={filters} page={page} onPage={setPage} onAdd={onAdd} />
      <CartPanel
        cart={cart}
        remainingMs={remaining}
        promoMessage={promoMessage}
        discountMinor={discount}
        onQuantity={(ev, t, q) => { try { sync(setQuantity(cart, ev, t, q)); } catch (e) { setError(e instanceof CartError ? e.message : 'Ошибка'); } }}
        onRemove={(ev, t) => sync(removeItem(cart, ev, t))}
        onPromo={(code) => {
          const r = applyPromo(code, subtotalMinor(cart));
          setPromoCode(r.ok ? r.code : '');
          setPromoMessage(r.ok ? `Промокод применён: −${formatMoney(r.discountMinor)}` : PROMO_ERRORS[r.reason]);
        }}
      />
    </main>
  );
}

const PROMO_ERRORS = {
  EMPTY_CODE: 'Введите промокод',
  UNKNOWN_CODE: 'Промокод не найден',
  MIN_SUBTOTAL: 'Сумма заказа меньше минимальной для этого промокода',
  EMPTY_CART: 'Добавьте билеты в корзину',
} as const;
