import { useEffect, useState } from 'react';
import { clockOffsetMs, remainingMs } from '../domain/reservation';
import { Reservation } from '../domain/types';

/** Оставшееся время брони в мс; обновляется раз в секунду, считается по часам сервера. */
export function useCountdown(reservation: Reservation | null): number | null {
  const [now, setNow] = useState(() => Date.now());
  const [offset, setOffset] = useState(0);

  useEffect(() => {
    if (!reservation) return;
    const t = Date.now();
    setNow(t);
    setOffset(clockOffsetMs(reservation, t));
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, [reservation]);

  return reservation ? remainingMs(reservation, now, offset) : null;
}
