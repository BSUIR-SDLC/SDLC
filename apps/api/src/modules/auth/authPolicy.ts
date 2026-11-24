/**
 * Политика входа и доступа (F02, UC-01, REQ-FUNC-001, REQ-SEC-001, REQ-SEC-003).
 * Чистые функции без БД и HTTP: маршрут /auth/login вызывает их и сохраняет результат через repo.
 * Сценарий — диаграмма uml/models/sequence-login.puml (альтернативы А1 «неверный пароль», А2 «блокировка»).
 */

export type Role = 'CONTROLLER' | 'ADMIN';

export interface UserAuthState {
  failedAttempts: number;
  lockedUntil: number | null; // мс epoch
}

export const MAX_FAILED_ATTEMPTS = 5;
export const LOCK_MS = 15 * 60 * 1000;
export const SESSION_MS = 12 * 60 * 60 * 1000;

export type LoginOutcome =
  | { kind: 'locked'; retryAfter: number; state: UserAuthState }
  | { kind: 'rejected'; state: UserAuthState }
  | { kind: 'ok'; sessionExpiresAt: number; state: UserAuthState };

/** Решение по попытке входа: passwordOk вычисляется адаптером bcrypt (cost ≥ 12) до вызова. */
export function evaluateLogin(state: UserAuthState, passwordOk: boolean, now: number): LoginOutcome {
  if (state.lockedUntil !== null && now < state.lockedUntil) {
    return { kind: 'locked', retryAfter: state.lockedUntil, state };
  }
  const base = state.lockedUntil !== null ? { failedAttempts: 0, lockedUntil: null } : state;
  if (!passwordOk) {
    const failedAttempts = base.failedAttempts + 1;
    const lockedUntil = failedAttempts >= MAX_FAILED_ATTEMPTS ? now + LOCK_MS : null;
    return { kind: 'rejected', state: { failedAttempts: lockedUntil ? 0 : failedAttempts, lockedUntil } };
  }
  return { kind: 'ok', sessionExpiresAt: now + SESSION_MS, state: { failedAttempts: 0, lockedUntil: null } };
}

export function isSessionValid(expiresAt: number, now: number): boolean {
  return now < expiresAt;
}

export type Action =
  | 'validate'
  | 'evacuation:read'
  | 'occupancy:read'
  | 'passes:write'
  | 'log:read'
  | 'settings:write'
  | 'counter:reset';

const PERMISSIONS: Record<Role, ReadonlySet<Action>> = {
  CONTROLLER: new Set<Action>(['validate', 'evacuation:read', 'occupancy:read']),
  ADMIN: new Set<Action>(['evacuation:read', 'occupancy:read', 'passes:write', 'log:read', 'settings:write', 'counter:reset']),
};

/**
 * Проверка доступа (SUP-F-03, BR-10): 'allow' или HTTP-код отказа.
 * Контролёр выполняет validate только на назначенных ему точках прохода.
 */
export function authorize(
  user: { role: Role; checkpointIds: readonly string[] },
  action: Action,
  checkpointId?: string,
): 'allow' | 403 {
  if (!PERMISSIONS[user.role].has(action)) return 403;
  if (action === 'validate' && (!checkpointId || !user.checkpointIds.includes(checkpointId))) return 403;
  return 'allow';
}
