import { EVENTS } from '../data/events';
import { RESERVATION_TTL_MS } from '../domain/reservation';
import { EventItem, Reservation } from '../domain/types';

export class ApiError extends Error {
  constructor(public readonly status: number, public readonly code: string, message: string) {
    super(message);
    this.name = 'ApiError';
  }
}

export interface ReserveItem {
  eventId: string;
  ticketTypeId: string;
  quantity: number;
}

interface Session {
  id: string;
  expiresAtMs: number;
  items: ReserveItem[];
}

/**
 * Имитация серверной части: каталог и бронирование мест на 15 минут.
 * Часы подставляются снаружи, поэтому поведение таймера проверяется тестами без ожидания.
 * Ответы повторяют контракт REST API: 409 — мест не хватает, 410 — бронь истекла.
 */
export class MockApi {
  private sessions = new Map<string, Session>();
  private seq = 0;

  constructor(
    private readonly events: EventItem[] = EVENTS,
    private readonly now: () => number = () => Date.now(),
  ) {}

  /** GET /events */
  listEvents(): EventItem[] {
    this.sweep();
    return this.events.map((e) => ({
      ...e,
      ticketTypes: e.ticketTypes.map((t) => ({ ...t, free: this.available(e.id, t.id, undefined) })),
    }));
  }

  /**
   * PUT /reservations/{sessionId}: создаёт бронь или заменяет её состав.
   * Срок брони задаётся при создании и при изменении состава не продлевается.
   */
  reserve(sessionId: string, items: ReserveItem[]): Reservation {
    this.sweep();
    for (const it of items) {
      const type = this.findType(it.eventId, it.ticketTypeId);
      if (it.quantity < 1 || it.quantity > this.available(it.eventId, it.ticketTypeId, sessionId)) {
        throw new ApiError(409, 'SEATS_UNAVAILABLE', `Недостаточно мест: «${type.name}»`);
      }
    }
    const existing = this.sessions.get(sessionId);
    if (items.length === 0) {
      this.sessions.delete(sessionId);
      return { id: sessionId, expiresAt: new Date(this.now()).toISOString(), serverTime: new Date(this.now()).toISOString() };
    }
    const session: Session = existing ?? {
      id: `r${++this.seq}`,
      expiresAtMs: this.now() + RESERVATION_TTL_MS,
      items: [],
    };
    session.items = items.map((i) => ({ ...i }));
    this.sessions.set(sessionId, session);
    return this.toReservation(session);
  }

  /** GET /reservations/{sessionId}: 410, если бронь истекла или не существует. */
  getReservation(sessionId: string): Reservation {
    this.sweep();
    const s = this.sessions.get(sessionId);
    if (!s) throw new ApiError(410, 'RESERVATION_EXPIRED', 'Бронь истекла');
    return this.toReservation(s);
  }

  /** DELETE /reservations/{sessionId} */
  release(sessionId: string): void {
    this.sessions.delete(sessionId);
  }

  private toReservation(s: Session): Reservation {
    return {
      id: s.id,
      expiresAt: new Date(s.expiresAtMs).toISOString(),
      serverTime: new Date(this.now()).toISOString(),
    };
  }

  private sweep(): void {
    const t = this.now();
    for (const [key, s] of this.sessions) {
      if (s.expiresAtMs <= t) this.sessions.delete(key);
    }
  }

  private findType(eventId: string, ticketTypeId: string) {
    const type = this.events.find((e) => e.id === eventId)?.ticketTypes.find((t) => t.id === ticketTypeId);
    if (!type) throw new ApiError(404, 'NOT_FOUND', 'Событие или тип билета не найдены');
    return type;
  }

  /** Свободные места с учётом броней всех сессий, кроме `exceptSession`. */
  private available(eventId: string, ticketTypeId: string, exceptSession: string | undefined): number {
    const base = this.findType(eventId, ticketTypeId).free;
    let held = 0;
    for (const [key, s] of this.sessions) {
      if (key === exceptSession) continue;
      for (const it of s.items) {
        if (it.eventId === eventId && it.ticketTypeId === ticketTypeId) held += it.quantity;
      }
    }
    return Math.max(0, base - held);
  }
}
