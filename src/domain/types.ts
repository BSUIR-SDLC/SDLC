export type Category = 'concert' | 'theatre' | 'sport' | 'exhibition' | 'conference';

export const CATEGORY_LABELS: Record<Category, string> = {
  concert: 'Концерт',
  theatre: 'Театр',
  sport: 'Спорт',
  exhibition: 'Выставка',
  conference: 'Конференция',
};

/** Тип билета на событие. Цена хранится в минимальных единицах (копейки), чтобы не копить ошибки округления. */
export interface TicketType {
  id: string;
  name: string;
  priceMinor: number;
  free: number;
}

export interface EventItem {
  id: string;
  title: string;
  city: string;
  venue: string;
  category: Category;
  /** Дата начала, ISO 8601 (UTC). */
  date: string;
  description: string;
  ticketTypes: TicketType[];
}

export interface Filters {
  query: string;
  city: string;
  category: Category | '';
  /** Границы дат в формате YYYY-MM-DD, включительно. Пустая строка — без ограничения. */
  dateFrom: string;
  dateTo: string;
  /** Границы цены в минимальных единицах; null — без ограничения. */
  priceMinMinor: number | null;
  priceMaxMinor: number | null;
}

export interface CartLine {
  eventId: string;
  ticketTypeId: string;
  eventTitle: string;
  ticketName: string;
  unitPriceMinor: number;
  quantity: number;
  /** Число свободных мест на момент добавления: верхняя граница для quantity. */
  maxAvailable: number;
}

export interface Reservation {
  id: string;
  /** Момент окончания брони по часам сервера, ISO 8601 UTC. */
  expiresAt: string;
  /** Время сервера в момент ответа, ISO 8601 UTC (нужно для поправки на часы клиента). */
  serverTime: string;
}

export type CartErrorCode = 'INVALID_QUANTITY' | 'NO_SEATS' | 'NOT_IN_CART';

export class CartError extends Error {
  constructor(public readonly code: CartErrorCode, message: string) {
    super(message);
    this.name = 'CartError';
  }
}

export function formatMoney(minor: number): string {
  const sign = minor < 0 ? '-' : '';
  const abs = Math.abs(minor);
  const whole = Math.floor(abs / 100);
  const frac = String(abs % 100).padStart(2, '0');
  return `${sign}${whole}.${frac} BYN`;
}
