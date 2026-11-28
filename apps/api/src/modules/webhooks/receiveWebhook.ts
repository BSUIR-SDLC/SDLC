// Приём вебхука (F03, UC-02). Шаги совпадают с действиями диаграммы
// uml/models/activity-webhook.puml и сообщениями sequence-webhook.puml.
// Модуль не зависит от Fastify и PostgreSQL: хранилище и движок передаются
// через порты, поэтому логика проверяется модульными тестами.
import { verify, activeSecrets, SIGNATURE_HEADER } from '../../../../../packages/webhook-signature/src/index.ts';
import type { SourceSecrets } from '../../../../../packages/webhook-signature/src/index.ts';

export const MAX_BODY_BYTES = 1024 * 1024; // 1 МиБ, BR-02
export const HOP_HEADER = 'x-hop';

export type Source = SourceSecrets & { id: string; enabled: boolean };

export type WebhookEvent = {
  sourceId: string;
  eventId: string;
  type: string;
  hop: number;
  payload: unknown;
  receivedAt: number;
};

export type Tx = {
  /** INSERT ... ON CONFLICT (source_id, event_id) DO NOTHING; false – дубликат. */
  insertEventIfAbsent(event: WebhookEvent): Promise<boolean>;
};

export type Deps = {
  getSource(id: string): Promise<Source | null>;
  /** BEGIN … COMMIT; при исключении – ROLLBACK (ADR-0004). */
  transaction<T>(fn: (tx: Tx) => Promise<T>): Promise<T>;
  /** Сопоставление и постановка доставок в очередь в той же транзакции (F05, I2). */
  matchAndEnqueue(tx: Tx, event: WebhookEvent): Promise<number>;
  now(): number;
};

export type Reply = { status: number; body: Record<string, unknown> };

const reply = (status: number, code: string, extra: Record<string, unknown> = {}): Reply => ({
  status,
  body: { code, ...extra },
});

function parseHop(value: string | undefined): number | null {
  if (value === undefined || value === '') return 0;
  return /^\d{1,3}$/.test(value) ? Number(value) : null;
}

export async function handleWebhook(
  deps: Deps,
  sourceId: string,
  rawBody: Buffer,
  headers: Record<string, string | undefined>,
): Promise<Reply> {
  // 1. Источник существует и включён
  const source = await deps.getSource(sourceId);
  if (!source || !source.enabled) return reply(404, 'SOURCE_NOT_FOUND');

  // 2. Размер тела (BR-02)
  if (rawBody.length > MAX_BODY_BYTES) return reply(413, 'PAYLOAD_TOO_LARGE');

  // 3. Подпись по сырому телу, без обращения к правилам (BR-01, ADR-0003)
  const secrets = activeSecrets(source, deps.now());
  if (!verify(secrets, rawBody, headers[SIGNATURE_HEADER])) return reply(401, 'BAD_SIGNATURE');

  // 4. Разбор события
  let parsed: any;
  try {
    parsed = JSON.parse(rawBody.toString('utf8'));
  } catch {
    return reply(400, 'INVALID_JSON');
  }
  if (
    !parsed || typeof parsed !== 'object' ||
    typeof parsed.id !== 'string' || parsed.id === '' ||
    typeof parsed.type !== 'string' || parsed.type === ''
  ) {
    return reply(400, 'INVALID_EVENT');
  }
  const hop = parseHop(headers[HOP_HEADER]);
  if (hop === null) return reply(400, 'INVALID_HOP');

  const event: WebhookEvent = {
    sourceId,
    eventId: parsed.id,
    type: parsed.type,
    hop,
    payload: parsed.payload ?? null,
    receivedAt: deps.now(),
  };

  // 5. Одна транзакция: событие + совпадения + доставки (BR-05, ADR-0004)
  try {
    return await deps.transaction(async (tx) => {
      const inserted = await tx.insertEventIfAbsent(event);
      if (!inserted) return reply(200, 'DUPLICATE', { eventId: event.eventId }); // BR-03
      const queued = await deps.matchAndEnqueue(tx, event);
      return reply(202, 'ACCEPTED', { eventId: event.eventId, queued });
    });
  } catch {
    return reply(503, 'STORAGE_UNAVAILABLE'); // событие не принято, эмулятор повторит
  }
}
