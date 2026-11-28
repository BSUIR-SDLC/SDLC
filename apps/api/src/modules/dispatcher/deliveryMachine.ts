// Автомат состояний доставки действия (F06, ADR-0010).
// Таблица переходов повторяет uml/models/state-delivery.puml; их совпадение
// проверяет тест deliveryMachine.test.ts. Изменение одного без другого
// приводит к ошибке сборки в CI.

export const MAX_RETRIES = 4; // 5 попыток: первая + 4 повтора (ADR-0006, BR-09)
export const REQUEST_TIMEOUT_MS = 5_000;

export type DeliveryState =
  | 'queued' | 'sending' | 'retryWait' | 'paused' // составное «В обработке»
  | 'delivered' | 'skipped' | 'failed' | 'cancelled' | 'purged';

export type DeliveryEvent =
  | 'WORKER_PICKED' | 'RETRYABLE_ERROR' | 'BACKOFF_ELAPSED' | 'GLOBAL_PAUSE' | 'RESUME'
  | 'RESPONSE_2XX' | 'PERMANENT_ERROR' | 'REPLAY' | 'TARGET_DELETED' | 'RETENTION_EXPIRED';

export type Ctx = { retries: number };

export type Transition = {
  from: DeliveryState;
  event: DeliveryEvent;
  to: DeliveryState;
  guard?: (c: Ctx) => boolean;
  action?: (c: Ctx) => Ctx;
};

/** Подсостояния составного состояния «В обработке» (active). */
export const ACTIVE_STATES: readonly DeliveryState[] = ['queued', 'sending', 'retryWait', 'paused'];
export const ACTIVE_INITIAL: DeliveryState = 'queued';

export const TRANSITIONS: readonly Transition[] = [
  { from: 'queued', event: 'WORKER_PICKED', to: 'sending' },
  { from: 'sending', event: 'RETRYABLE_ERROR', to: 'retryWait',
    guard: (c) => c.retries < MAX_RETRIES, action: (c) => ({ retries: c.retries + 1 }) },
  { from: 'retryWait', event: 'BACKOFF_ELAPSED', to: 'sending' },
  { from: 'queued', event: 'GLOBAL_PAUSE', to: 'paused' },
  { from: 'paused', event: 'RESUME', to: 'queued' },
  { from: 'sending', event: 'RESPONSE_2XX', to: 'delivered' },
  { from: 'sending', event: 'RETRYABLE_ERROR', to: 'failed', guard: (c) => c.retries >= MAX_RETRIES },
  { from: 'sending', event: 'PERMANENT_ERROR', to: 'failed' },
  // переход в составное состояние ведёт в его начальное подсостояние
  { from: 'failed', event: 'REPLAY', to: ACTIVE_INITIAL, action: () => ({ retries: 0 }) },
  { from: 'delivered', event: 'RETENTION_EXPIRED', to: 'purged' },
  { from: 'skipped', event: 'RETENTION_EXPIRED', to: 'purged' },
  { from: 'cancelled', event: 'RETENTION_EXPIRED', to: 'purged' },
  { from: 'failed', event: 'RETENTION_EXPIRED', to: 'purged' },
];

/** Переходы, заданные один раз для составного состояния и действующие из любого подсостояния. */
export const COMPOSITE_TRANSITIONS: readonly { event: DeliveryEvent; to: DeliveryState }[] = [
  { event: 'TARGET_DELETED', to: 'cancelled' },
];

/** Псевдосостояние выбора при создании доставки (BR-06, BR-07). */
export function initialState(guardPassed: boolean): DeliveryState {
  return guardPassed ? ACTIVE_INITIAL : 'skipped';
}

export function step(
  state: DeliveryState,
  event: DeliveryEvent,
  ctx: Ctx = { retries: 0 },
): { state: DeliveryState; ctx: Ctx } {
  for (const t of TRANSITIONS) {
    if (t.from === state && t.event === event && (!t.guard || t.guard(ctx))) {
      return { state: t.to, ctx: t.action ? t.action(ctx) : ctx };
    }
  }
  if (ACTIVE_STATES.includes(state)) {
    const c = COMPOSITE_TRANSITIONS.find((t) => t.event === event);
    if (c) return { state: c.to, ctx };
  }
  throw new Error(`Недопустимый переход: ${state} --${event}-->`);
}

/** Классификация результата POST (BR-09): 408, 429, 5xx и сетевые ошибки повторяются. */
export function classify(result: { status?: number; networkError?: boolean }): DeliveryEvent {
  if (result.networkError || result.status === undefined) return 'RETRYABLE_ERROR';
  const s = result.status;
  if (s >= 200 && s < 300) return 'RESPONSE_2XX';
  if (s === 408 || s === 429 || s >= 500) return 'RETRYABLE_ERROR';
  return 'PERMANENT_ERROR';
}

/** Пауза перед повтором: 2^retries секунд (2, 4, 8, 16 с). */
export function backoffMs(retries: number): number {
  return 2 ** retries * 1000;
}
