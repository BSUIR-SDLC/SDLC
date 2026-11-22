import { EventItem, Filters } from './types';

export const PAGE_SIZE = 6;

export const emptyFilters: Filters = {
  query: '',
  city: '',
  category: '',
  dateFrom: '',
  dateTo: '',
  priceMinMinor: null,
  priceMaxMinor: null,
};

export function minPriceMinor(e: EventItem): number | null {
  if (e.ticketTypes.length === 0) return null;
  return Math.min(...e.ticketTypes.map((t) => t.priceMinor));
}

export function freeSeats(e: EventItem): number {
  return e.ticketTypes.reduce((sum, t) => sum + t.free, 0);
}

/** Возвращает текст ошибки или null, если фильтры согласованы. */
export function validateFilters(f: Filters): string | null {
  if (f.dateFrom && f.dateTo && f.dateFrom > f.dateTo) {
    return 'Дата «с» позже даты «по»';
  }
  if (f.priceMinMinor !== null && f.priceMaxMinor !== null && f.priceMinMinor > f.priceMaxMinor) {
    return 'Минимальная цена больше максимальной';
  }
  if ((f.priceMinMinor !== null && f.priceMinMinor < 0) || (f.priceMaxMinor !== null && f.priceMaxMinor < 0)) {
    return 'Цена не может быть отрицательной';
  }
  return null;
}

function matchesPrice(e: EventItem, f: Filters): boolean {
  if (f.priceMinMinor === null && f.priceMaxMinor === null) return true;
  return e.ticketTypes.some(
    (t) =>
      (f.priceMinMinor === null || t.priceMinor >= f.priceMinMinor) &&
      (f.priceMaxMinor === null || t.priceMinor <= f.priceMaxMinor),
  );
}

/** Применяет текстовый поиск по названию и все фильтры (логическое И). */
export function applyFilters(events: EventItem[], f: Filters): EventItem[] {
  if (validateFilters(f) !== null) return [];
  const q = f.query.trim().toLowerCase();
  return events
    .filter((e) => (q === '' ? true : e.title.toLowerCase().includes(q)))
    .filter((e) => (f.city === '' ? true : e.city === f.city))
    .filter((e) => (f.category === '' ? true : e.category === f.category))
    .filter((e) => (f.dateFrom === '' ? true : e.date.slice(0, 10) >= f.dateFrom))
    .filter((e) => (f.dateTo === '' ? true : e.date.slice(0, 10) <= f.dateTo))
    .filter((e) => matchesPrice(e, f))
    .sort((a, b) => a.date.localeCompare(b.date));
}

export interface Page<T> {
  items: T[];
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
}

/** Постраничная выдача; номер страницы приводится к допустимому диапазону. */
export function paginate<T>(items: T[], page: number, pageSize: number = PAGE_SIZE): Page<T> {
  const total = items.length;
  const totalPages = Math.max(1, Math.ceil(total / pageSize));
  const p = Math.min(Math.max(1, Math.floor(page) || 1), totalPages);
  return { items: items.slice((p - 1) * pageSize, p * pageSize), page: p, pageSize, total, totalPages };
}

export function uniqueCities(events: EventItem[]): string[] {
  return [...new Set(events.map((e) => e.city))].sort((a, b) => a.localeCompare(b, 'ru'));
}
