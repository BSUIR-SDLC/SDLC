// Подпись входящих вебхуков HMAC-SHA256 (ADR-0003, REQ-SEC-001, BR-01).
// Связи: UC-02 шаг 3, activity-webhook.puml «Подпись верна?», sequence-webhook.puml сообщение 3.
import { createHmac, timingSafeEqual } from 'node:crypto';

export const SIGNATURE_HEADER = 'x-rulehook-signature';
export const PREFIX = 'sha256=';
/** Сколько после ротации секрета ещё принимается подпись старым секретом (BR-01). */
export const ROTATION_GRACE_MS = 24 * 60 * 60 * 1000;

export type SourceSecrets = {
  secret: string;
  previousSecret?: string | null;
  rotatedAt?: number | null; // мс, время ротации
};

function digest(secret: string, rawBody: Buffer | string): Buffer {
  return createHmac('sha256', secret).update(rawBody).digest();
}

/** Значение заголовка подписи для тела запроса: "sha256=<hex>". */
export function sign(secret: string, rawBody: Buffer | string): string {
  return PREFIX + digest(secret, rawBody).toString('hex');
}

/** Секреты, подписью которых сейчас можно подтвердить вебхук источника. */
export function activeSecrets(source: SourceSecrets, now: number): string[] {
  const list = [source.secret];
  if (
    source.previousSecret &&
    source.rotatedAt != null &&
    now - source.rotatedAt < ROTATION_GRACE_MS
  ) {
    list.push(source.previousSecret);
  }
  return list;
}

/**
 * Проверяет подпись по сырому телу. Сравнение выполняется за постоянное время
 * (timingSafeEqual), проверяются все активные секреты, чтобы время ответа
 * не зависело от того, каким секретом подписан запрос.
 */
export function verify(
  secrets: string[],
  rawBody: Buffer | string,
  header: string | undefined | null,
): boolean {
  if (typeof header !== 'string' || !header.startsWith(PREFIX)) return false;
  const hex = header.slice(PREFIX.length);
  if (!/^[0-9a-f]{64}$/i.test(hex)) return false;
  const received = Buffer.from(hex, 'hex');
  let ok = false;
  for (const secret of secrets) {
    if (timingSafeEqual(digest(secret, rawBody), received)) ok = true;
  }
  return ok;
}
