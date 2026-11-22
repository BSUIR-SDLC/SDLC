import { CartError, CartLine } from './types';

export interface CartItemInput {
  eventId: string;
  ticketTypeId: string;
  eventTitle: string;
  ticketName: string;
  unitPriceMinor: number;
  free: number;
}

export type Cart = readonly CartLine[];

export const emptyCart: Cart = [];

function sameLine(l: CartLine, eventId: string, ticketTypeId: string): boolean {
  return l.eventId === eventId && l.ticketTypeId === ticketTypeId;
}

/** Добавляет билеты в корзину; одинаковые позиции объединяются, количество ограничено числом свободных мест. */
export function addItem(cart: Cart, item: CartItemInput, quantity = 1): Cart {
  if (!Number.isInteger(quantity) || quantity < 1) {
    throw new CartError('INVALID_QUANTITY', 'Количество должно быть целым числом не меньше 1');
  }
  const existing = cart.find((l) => sameLine(l, item.eventId, item.ticketTypeId));
  const newQty = (existing?.quantity ?? 0) + quantity;
  if (item.free < 1 || newQty > item.free) {
    throw new CartError('NO_SEATS', `Свободных мест: ${item.free}`);
  }
  if (existing) {
    return cart.map((l) => (l === existing ? { ...l, quantity: newQty, maxAvailable: item.free } : l));
  }
  return [
    ...cart,
    {
      eventId: item.eventId,
      ticketTypeId: item.ticketTypeId,
      eventTitle: item.eventTitle,
      ticketName: item.ticketName,
      unitPriceMinor: item.unitPriceMinor,
      quantity: newQty,
      maxAvailable: item.free,
    },
  ];
}

/** Устанавливает количество; 0 удаляет позицию. */
export function setQuantity(cart: Cart, eventId: string, ticketTypeId: string, quantity: number): Cart {
  const line = cart.find((l) => sameLine(l, eventId, ticketTypeId));
  if (!line) throw new CartError('NOT_IN_CART', 'Позиции нет в корзине');
  if (!Number.isInteger(quantity) || quantity < 0) {
    throw new CartError('INVALID_QUANTITY', 'Количество должно быть целым числом не меньше 0');
  }
  if (quantity === 0) return removeItem(cart, eventId, ticketTypeId);
  if (quantity > line.maxAvailable) {
    throw new CartError('NO_SEATS', `Свободных мест: ${line.maxAvailable}`);
  }
  return cart.map((l) => (l === line ? { ...l, quantity } : l));
}

export function removeItem(cart: Cart, eventId: string, ticketTypeId: string): Cart {
  return cart.filter((l) => !sameLine(l, eventId, ticketTypeId));
}

export function subtotalMinor(cart: Cart): number {
  return cart.reduce((sum, l) => sum + l.unitPriceMinor * l.quantity, 0);
}

export function totalQuantity(cart: Cart): number {
  return cart.reduce((sum, l) => sum + l.quantity, 0);
}
