/**
 * qr-token — формирование и проверка подписанного QR-токена (F03, REQ-FUNC-005, ADR-0003).
 *
 * Формат токена: base64url("<passId>.<version>") + "." + base64url(HMAC-SHA256(secret, "<passId>.<version>")).
 * Пакет не зависит от Express и БД (SRS 3.5.5) и используется сервером и, в будущем, турникетами.
 */
import { createHmac, timingSafeEqual } from 'node:crypto';

export interface TokenPayload {
  passId: string;
  version: number;
}

const PASS_ID = /^[A-Za-z0-9-]{1,64}$/;
const MIN_SECRET_BYTES = 32;

function b64url(buf: Buffer): string {
  return buf.toString('base64url');
}

function assertSecret(secret: Buffer | string): Buffer {
  const key = typeof secret === 'string' ? Buffer.from(secret, 'utf8') : secret;
  if (key.length < MIN_SECRET_BYTES) {
    throw new Error(`QR secret must be at least ${MIN_SECRET_BYTES} bytes`);
  }
  return key;
}

function mac(key: Buffer, body: string): Buffer {
  return createHmac('sha256', key).update(body, 'utf8').digest();
}

/** Подписать полезную нагрузку пропуска. */
export function sign(payload: TokenPayload, secret: Buffer | string): string {
  const key = assertSecret(secret);
  if (!PASS_ID.test(payload.passId)) throw new Error('invalid passId');
  if (!Number.isInteger(payload.version) || payload.version < 1) throw new Error('invalid version');
  const body = `${payload.passId}.${payload.version}`;
  return `${b64url(Buffer.from(body, 'utf8'))}.${b64url(mac(key, body))}`;
}

/**
 * Проверить токен. Возвращает полезную нагрузку или null, если формат или подпись неверны
 * (сервер отвечает DENY_BAD_SIGNATURE без обращения к БД). Сравнение подписи — за постоянное время.
 */
export function verify(token: string, secret: Buffer | string): TokenPayload | null {
  const key = assertSecret(secret);
  if (typeof token !== 'string' || token.length > 256) return null;
  const parts = token.split('.');
  if (parts.length !== 2 || !parts[0] || !parts[1]) return null;
  const [bodyPart, sigPart] = parts;
  if (!/^[A-Za-z0-9_-]+$/.test(bodyPart) || !/^[A-Za-z0-9_-]+$/.test(sigPart)) return null;

  const body = Buffer.from(bodyPart, 'base64url').toString('utf8');
  // base64url допускает разные записи одних байтов — принимаем только каноническую
  if (b64url(Buffer.from(body, 'utf8')) !== bodyPart) return null;
  const given = Buffer.from(sigPart, 'base64url');
  if (b64url(given) !== sigPart) return null;
  const expected = mac(key, body);
  if (given.length !== expected.length || !timingSafeEqual(given, expected)) return null;

  const m = /^([A-Za-z0-9-]{1,64})\.([1-9]\d{0,9})$/.exec(body);
  if (!m) return null;
  return { passId: m[1], version: Number(m[2]) };
}
