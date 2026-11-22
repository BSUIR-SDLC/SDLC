import { Reservation } from './types';

/** Время удержания места в корзине (FEAT-02): 15 минут по часам сервера. */
export const RESERVATION_TTL_MS = 15 * 60 * 1000;

/**
 * Поправка на расхождение часов клиента и сервера: serverTime − clientNow на момент получения ответа.
 * Оставшееся время считается по часам сервера, поэтому перевод часов на компьютере не продлевает бронь.
 */
export function clockOffsetMs(res: Reservation, clientNowMs: number): number {
  return Date.parse(res.serverTime) - clientNowMs;
}

export function remainingMs(res: Reservation, clientNowMs: number, offsetMs: number): number {
  return Math.max(0, Date.parse(res.expiresAt) - (clientNowMs + offsetMs));
}

export function isExpired(res: Reservation, clientNowMs: number, offsetMs: number): boolean {
  return remainingMs(res, clientNowMs, offsetMs) === 0;
}

export function formatCountdown(ms: number): string {
  const totalSec = Math.ceil(Math.max(0, ms) / 1000);
  const m = Math.floor(totalSec / 60);
  const s = totalSec % 60;
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
}
