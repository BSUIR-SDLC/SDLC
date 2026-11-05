/**
 * Автомат состояний сканера (F05, SDD 007, ADR-0010).
 * Таблица переходов — точная копия диаграммы uml/models/state-scanner.puml; соответствие проверяет
 * тест scannerMachine.test.ts. В React используется как редьюсер: useReducer(scannerReducer, initialState).
 */

export type ScannerState =
  | 'login'
  | 'selectCheckpoint'
  | 'scanning'
  | 'manual'
  | 'validating'
  | 'allowed'
  | 'denied'
  | 'offline'
  | 'evacuation';

export type ScannerEvent =
  | 'LOGIN_OK'
  | 'CHECKPOINT_SELECTED'
  | 'QR_DECODED'
  | 'MANUAL_REQUESTED'
  | 'CODE_ENTERED'
  | 'CANCEL'
  | 'ALLOW'
  | 'DENY'
  | 'TIMEOUT'
  | 'AUTO_RETURN'
  | 'NEXT'
  | 'RETRY'
  | 'CHANGE_CHECKPOINT'
  | 'EVACUATION_OPENED'
  | 'BACK'
  | 'UNAUTHORIZED'
  | 'LOGOUT';

export const INITIAL_STATE: ScannerState = 'login';

/** Подсостояния составного состояния «Сеанс контролёра» (session). */
export const SESSION_STATES: readonly ScannerState[] = [
  'selectCheckpoint', 'scanning', 'manual', 'validating', 'allowed', 'denied', 'offline', 'evacuation',
];
export const SESSION_INITIAL: ScannerState = 'selectCheckpoint';

/** Переходы внутри сеанса и из состояния login. */
export const TRANSITIONS: Readonly<Record<ScannerState, Partial<Record<ScannerEvent, ScannerState>>>> = {
  login: { LOGIN_OK: SESSION_INITIAL },
  selectCheckpoint: { CHECKPOINT_SELECTED: 'scanning' },
  scanning: {
    QR_DECODED: 'validating',
    MANUAL_REQUESTED: 'manual',
    CHANGE_CHECKPOINT: 'selectCheckpoint',
    EVACUATION_OPENED: 'evacuation',
  },
  manual: { CODE_ENTERED: 'validating', CANCEL: 'scanning' },
  validating: { ALLOW: 'allowed', DENY: 'denied', TIMEOUT: 'offline' },
  allowed: { AUTO_RETURN: 'scanning' },
  denied: { NEXT: 'scanning' },
  offline: { RETRY: 'scanning' },
  evacuation: { BACK: 'scanning' },
};

/** Переходы составного состояния session — действуют из любого подсостояния. */
export const SESSION_TRANSITIONS: Readonly<Partial<Record<ScannerEvent, ScannerState>>> = {
  UNAUTHORIZED: 'login',
  LOGOUT: 'login',
};

/** Следующее состояние; событие, не предусмотренное диаграммой, игнорируется (состояние не меняется). */
export function nextState(state: ScannerState, event: ScannerEvent): ScannerState {
  const direct = TRANSITIONS[state][event];
  if (direct) return direct;
  if (SESSION_STATES.includes(state)) {
    const viaSession = SESSION_TRANSITIONS[event];
    if (viaSession) return viaSession;
  }
  return state;
}

/** Камера включена только в состоянии «Сканирование» (entry/exit на диаграмме). */
export function isCameraActive(state: ScannerState): boolean {
  return state === 'scanning';
}

/** Мс до таймера: 5 с ожидания ответа (fail-closed, ADR-0006), 3 с показа ALLOW. */
export function timerFor(state: ScannerState): { ms: number; event: ScannerEvent } | null {
  if (state === 'validating') return { ms: 5000, event: 'TIMEOUT' };
  if (state === 'allowed') return { ms: 3000, event: 'AUTO_RETURN' };
  return null;
}

const MANUAL_CODE = /^[PG]-\d{6}$/;

/** Формат номера пропуска для ручного ввода (BR-02, guard перехода CODE_ENTERED). */
export function isValidManualCode(code: string): boolean {
  return MANUAL_CODE.test(code.trim().toUpperCase());
}

/** Защита от повторной отправки того же токена в течение 3 с (BR-06). */
export function createDuplicateFilter(windowMs = 3000) {
  let lastToken: string | null = null;
  let lastAt = -Infinity;
  return (token: string, now: number): boolean => {
    if (token === lastToken && now - lastAt < windowMs) return false;
    lastToken = token;
    lastAt = now;
    return true;
  };
}
