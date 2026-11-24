/**
 * contracts — типы запросов и ответов, общие для сканера, панели и сервера (SDD 003, 005; REQ-INT-005).
 * Пакет не зависит от Express, БД и React. Формат ответа /api/v1/validate — контракт REQ-INT-005.
 */

export type Direction = 'IN' | 'OUT';
export type Decision = 'ALLOW' | 'DENY';
export type PassType = 'EMPLOYEE' | 'GUEST';

/** Код причины (глоссарий, термин 30): первая нарушенная проверка цепочки BR-01. */
export type Reason =
  | 'OK'
  | 'DENY_BAD_SIGNATURE'
  | 'DENY_NOT_FOUND'
  | 'DENY_REVOKED'
  | 'DENY_EXPIRED'
  | 'DENY_ZONE'
  | 'DENY_ALREADY_INSIDE'
  | 'DENY_NOT_INSIDE'
  | 'DENY_CAPACITY';

export const REASONS: readonly Reason[] = [
  'OK', 'DENY_BAD_SIGNATURE', 'DENY_NOT_FOUND', 'DENY_REVOKED', 'DENY_EXPIRED',
  'DENY_ZONE', 'DENY_ALREADY_INSIDE', 'DENY_NOT_INSIDE', 'DENY_CAPACITY',
];

/** Тело POST /api/v1/validate. */
export interface ValidateRequest {
  token: string;
  checkpointId: string;
  direction: Direction;
}

/** Тело POST /api/v1/validate/manual (F07, UC-03). */
export interface ManualValidateRequest {
  code: string;
  checkpointId: string;
  direction: Direction;
}

/** Сведения о пропуске в ответе: только то, что нужно контролёру (REQ-SEC-005). */
export interface PassSummary {
  code: string;
  holderName: string;
  type: PassType;
  validTo: number; // мс epoch
  photoId: string | null;
}

/** Ответ POST /api/v1/validate и /validate/manual. */
export interface ValidationResponse {
  decision: Decision;
  reason: Reason;
  pass: PassSummary | null;
  occupancy: number | null;
  capacity: number | null;
}

const PASS_CODE = /^[PG]-\d{6}$/;

/**
 * Номер пропуска для ручного ввода (BR-02): `P-NNNNNN` — сотрудник, `G-NNNNNN` — гость.
 * Возвращает нормализованный номер или null. Допускаются пробелы по краям и строчная буква.
 */
export function normalizePassCode(input: string): string | null {
  if (typeof input !== 'string') return null;
  const code = input.trim().toUpperCase();
  return PASS_CODE.test(code) ? code : null;
}

/** Решение по коду причины: ALLOW только при OK (BR-01). */
export function decisionOf(reason: Reason): Decision {
  return reason === 'OK' ? 'ALLOW' : 'DENY';
}
