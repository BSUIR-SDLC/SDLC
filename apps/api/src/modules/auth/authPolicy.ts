// Политика входа и ролей (F02, UC-01, REQ-FUNC-001, REQ-SEC-003).
// Связи: sequence-login.puml (фрагмент alt «учётная запись заблокирована»).
export const MAX_FAILED_ATTEMPTS = 5;
export const LOCK_MS = 15 * 60 * 1000;
export const SESSION_TTL_MS = 12 * 60 * 60 * 1000;

export type Role = 'operator' | 'admin';

export type LoginState = {
  failedAttempts: number;
  lockedUntil: number | null;
};

export const initialLoginState = (): LoginState => ({ failedAttempts: 0, lockedUntil: null });

export function isLocked(state: LoginState, now: number): boolean {
  return state.lockedUntil !== null && now < state.lockedUntil;
}

/** Результат попытки входа: новое состояние учётной записи и решение. */
export function applyLoginAttempt(
  state: LoginState,
  passwordOk: boolean,
  now: number,
): { state: LoginState; result: 'OK' | 'BAD_CREDENTIALS' | 'LOCKED' } {
  if (isLocked(state, now)) return { state, result: 'LOCKED' };
  // блокировка истекла – счётчик начинается заново
  const base = state.lockedUntil !== null ? initialLoginState() : state;
  if (passwordOk) return { state: initialLoginState(), result: 'OK' };
  const failedAttempts = base.failedAttempts + 1;
  if (failedAttempts >= MAX_FAILED_ATTEMPTS) {
    return { state: { failedAttempts, lockedUntil: now + LOCK_MS }, result: 'LOCKED' };
  }
  return { state: { failedAttempts, lockedUntil: null }, result: 'BAD_CREDENTIALS' };
}

export function sessionExpired(createdAt: number, now: number): boolean {
  return now - createdAt >= SESSION_TTL_MS;
}

export const PERMISSIONS: Record<Role, readonly string[]> = {
  operator: [
    'rules:read', 'rules:write', 'rules:dry-run', 'rules:import',
    'journal:read', 'deliveries:read', 'deliveries:replay',
  ],
  admin: [
    'rules:read', 'rules:write', 'rules:dry-run', 'rules:import',
    'journal:read', 'deliveries:read', 'deliveries:replay',
    'sources:manage', 'targets:manage', 'system:pause', 'users:manage',
  ],
};

export function can(role: Role, permission: string): boolean {
  return PERMISSIONS[role]?.includes(permission) ?? false;
}
