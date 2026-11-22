import { Cart, subtotalMinor } from '../domain/cart';
import { formatCountdown } from '../domain/reservation';
import { formatMoney } from '../domain/types';

interface Props {
  cart: Cart;
  remainingMs: number | null;
  promoMessage: string;
  discountMinor: number;
  onQuantity: (eventId: string, ticketTypeId: string, qty: number) => void;
  onRemove: (eventId: string, ticketTypeId: string) => void;
  onPromo: (code: string) => void;
}

export function CartPanel({ cart, remainingMs, promoMessage, discountMinor, onQuantity, onRemove, onPromo }: Props) {
  if (cart.length === 0) return <aside aria-label="Корзина"><p>Корзина пуста</p></aside>;
  const subtotal = subtotalMinor(cart);
  return (
    <aside aria-label="Корзина">
      {remainingMs !== null && <p className="timer">Бронь действует: {formatCountdown(remainingMs)}</p>}
      <ul>
        {cart.map((l) => (
          <li key={l.eventId + l.ticketTypeId}>
            {l.eventTitle} — {l.ticketName}
            <input
              type="number" min={0} max={l.maxAvailable} value={l.quantity}
              onChange={(e) => onQuantity(l.eventId, l.ticketTypeId, Number(e.target.value))}
            />
            <button onClick={() => onRemove(l.eventId, l.ticketTypeId)}>Удалить</button>
          </li>
        ))}
      </ul>
      <form onSubmit={(e) => { e.preventDefault(); onPromo(String(new FormData(e.currentTarget).get('promo') ?? '')); }}>
        <input name="promo" placeholder="Промокод" />
        <button type="submit">Применить</button>
      </form>
      {promoMessage && <p>{promoMessage}</p>}
      <p>Сумма: {formatMoney(subtotal)}</p>
      {discountMinor > 0 && <p>Скидка: −{formatMoney(discountMinor)}</p>}
      <p><strong>Итого: {formatMoney(subtotal - discountMinor)}</strong></p>
    </aside>
  );
}
