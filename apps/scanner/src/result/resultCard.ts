/**
 * Карточка решения на экране сканера (F06; UC-02 шаг 6, А2, Е1; REQ-FUNC-007, REQ-INT-002; SDD 007, 016).
 * Чистая функция: ответ сервера → то, что показывает компонент React ResultScreen.
 * Событие выхода из карточки совпадает с переходами автомата scannerMachine.ts:
 * ALLOW → автовозврат через 3 с (AUTO_RETURN), DENY → только кнопка «Следующий» (NEXT),
 * нет связи → кнопка «Повторить» (RETRY). Fail-closed: без ответа карточка ALLOW невозможна.
 */
import type { PassType, Reason, ValidationResponse } from '../../../../packages/contracts/src/index.ts';
import type { ScannerEvent } from '../state/scannerMachine.ts';

export type Tone = 'allow' | 'deny' | 'offline';

export interface ResultCard {
  tone: Tone;
  title: string;
  message: string;
  details: string[];
  sound: 'ok' | 'error';
  vibrateMs: number;
  /** Через сколько мс карточка закрывается сама; null — только по кнопке. */
  autoCloseMs: number | null;
  button: { label: string; event: ScannerEvent } | null;
}

/** Причины отказа на русском языке (REQ-FUNC-007, SUP-U-02). */
export const REASON_TEXT: Readonly<Record<Reason, string>> = {
  OK: 'Проход разрешён',
  DENY_BAD_SIGNATURE: 'QR-код поддельный или повреждён',
  DENY_NOT_FOUND: 'Пропуск не найден',
  DENY_REVOKED: 'Пропуск отозван или перевыпущен',
  DENY_EXPIRED: 'Срок действия пропуска истёк или не наступил',
  DENY_ZONE: 'Нет доступа в эту зону',
  DENY_ALREADY_INSIDE: 'Владелец уже находится внутри',
  DENY_NOT_INSIDE: 'Владелец не отмечен на входе',
  DENY_CAPACITY: 'Объект заполнен, вход закрыт',
};

const TYPE_TEXT: Readonly<Record<PassType, string>> = { EMPLOYEE: 'Сотрудник', GUEST: 'Гость' };

export const ALLOW_AUTO_CLOSE_MS = 3000;
export const DENY_VIBRATE_MS = 200;

function formatDate(ms: number): string {
  const d = new Date(ms);
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${pad(d.getUTCDate())}.${pad(d.getUTCMonth() + 1)}.${d.getUTCFullYear()}`;
}

/** Карточка по ответу сервера. */
export function toResultCard(res: ValidationResponse): ResultCard {
  const details: string[] = [];
  if (res.pass) {
    details.push(`${TYPE_TEXT[res.pass.type]} ${res.pass.code}`);
    details.push(`Действует до ${formatDate(res.pass.validTo)}`);
  }
  if (res.occupancy !== null && res.capacity !== null) details.push(`Внутри: ${res.occupancy} из ${res.capacity}`);

  if (res.decision === 'ALLOW' && res.reason === 'OK') {
    return {
      tone: 'allow',
      title: res.pass?.holderName ?? REASON_TEXT.OK,
      message: REASON_TEXT.OK,
      details,
      sound: 'ok',
      vibrateMs: 0,
      autoCloseMs: ALLOW_AUTO_CLOSE_MS,
      button: null,
    };
  }
  // любое несогласованное сочетание (ALLOW с кодом отказа) трактуется как отказ — fail-closed
  const reason: Reason = res.reason === 'OK' ? 'DENY_NOT_FOUND' : res.reason;
  return {
    tone: 'deny',
    title: 'Отказ в проходе',
    message: REASON_TEXT[reason],
    details: res.pass ? [res.pass.holderName, ...details] : details,
    sound: 'error',
    vibrateMs: DENY_VIBRATE_MS,
    autoCloseMs: null,
    button: { label: 'Следующий', event: 'NEXT' },
  };
}

/** Карточка «Нет связи» (Е1): тайм-аут 5 с, ошибка сети или 5xx. */
export function offlineCard(): ResultCard {
  return {
    tone: 'offline',
    title: 'Нет связи с сервером',
    message: 'Проверка невозможна. Пропуск не пропускать',
    details: [],
    sound: 'error',
    vibrateMs: DENY_VIBRATE_MS,
    autoCloseMs: null,
    button: { label: 'Повторить', event: 'RETRY' },
  };
}
