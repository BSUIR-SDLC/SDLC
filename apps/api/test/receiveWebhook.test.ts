import { test } from 'node:test';
import assert from 'node:assert/strict';
import { handleWebhook, MAX_BODY_BYTES } from '../src/modules/webhooks/receiveWebhook.ts';
import type { Deps, WebhookEvent } from '../src/modules/webhooks/receiveWebhook.ts';
import { sign } from '../../../packages/webhook-signature/src/index.ts';

function makeDeps(opts: { failTx?: boolean; matches?: number } = {}) {
  const stored = new Map<string, WebhookEvent>();
  const calls: string[] = [];
  const deps: Deps = {
    async getSource(id) {
      if (id === 'emulator-1') return { id, enabled: true, secret: 'top-secret' };
      if (id === 'off') return { id, enabled: false, secret: 'x' };
      return null;
    },
    async transaction(fn) {
      if (opts.failTx) throw new Error('db down');
      calls.push('BEGIN');
      const r = await fn({
        async insertEventIfAbsent(e) {
          const key = e.sourceId + '/' + e.eventId;
          if (stored.has(key)) return false;
          stored.set(key, e);
          return true;
        },
      });
      calls.push('COMMIT');
      return r;
    },
    async matchAndEnqueue() {
      calls.push('MATCH');
      return opts.matches ?? 0;
    },
    now: () => 1_700_000_000_000,
  };
  return { deps, stored, calls };
}

const event = { id: 'e-1', type: 'sensor.temperature', payload: { deviceId: 'd7', value: 81 } };
const raw = (o: unknown) => Buffer.from(JSON.stringify(o));
const signed = (b: Buffer, extra: Record<string, string> = {}) => ({
  'x-rulehook-signature': sign('top-secret', b),
  ...extra,
});

test('верный вебхук принимается: 202, событие сохранено в транзакции', async () => {
  const { deps, stored, calls } = makeDeps({ matches: 2 });
  const b = raw(event);
  const r = await handleWebhook(deps, 'emulator-1', b, signed(b));
  assert.equal(r.status, 202);
  assert.equal(r.body.queued, 2);
  assert.equal(stored.size, 1);
  assert.deepEqual(calls, ['BEGIN', 'MATCH', 'COMMIT']);
});

test('повторная доставка того же события – 200 без повторного сопоставления (BR-03)', async () => {
  const { deps, calls } = makeDeps();
  const b = raw(event);
  await handleWebhook(deps, 'emulator-1', b, signed(b));
  const r = await handleWebhook(deps, 'emulator-1', b, signed(b));
  assert.equal(r.status, 200);
  assert.equal(r.body.code, 'DUPLICATE');
  assert.equal(calls.filter((c) => c === 'MATCH').length, 1);
});

test('неизвестный или выключенный источник – 404', async () => {
  const { deps } = makeDeps();
  const b = raw(event);
  assert.equal((await handleWebhook(deps, 'nope', b, signed(b))).status, 404);
  assert.equal((await handleWebhook(deps, 'off', b, signed(b))).status, 404);
});

test('тело больше 1 МиБ – 413 до проверки подписи (BR-02)', async () => {
  const { deps } = makeDeps();
  const b = Buffer.alloc(MAX_BODY_BYTES + 1, 0x20);
  const r = await handleWebhook(deps, 'emulator-1', b, {});
  assert.equal(r.status, 413);
});

test('неверная подпись – 401, в хранилище ничего не пишется (BR-01)', async () => {
  const { deps, calls } = makeDeps();
  const b = raw(event);
  const r = await handleWebhook(deps, 'emulator-1', b, { 'x-rulehook-signature': sign('wrong', b) });
  assert.equal(r.status, 401);
  assert.deepEqual(calls, []);
});

test('некорректный JSON или событие без id/type – 400', async () => {
  const { deps } = makeDeps();
  const bad = Buffer.from('{not json');
  assert.equal((await handleWebhook(deps, 'emulator-1', bad, signed(bad))).body.code, 'INVALID_JSON');
  const noId = raw({ type: 't' });
  assert.equal((await handleWebhook(deps, 'emulator-1', noId, signed(noId))).body.code, 'INVALID_EVENT');
  const arr = raw(null);
  assert.equal((await handleWebhook(deps, 'emulator-1', arr, signed(arr))).body.code, 'INVALID_EVENT');
});

test('заголовок X-Hop: по умолчанию 0, число сохраняется, мусор – 400', async () => {
  const { deps, stored } = makeDeps();
  const b1 = raw({ ...event, id: 'h0' });
  await handleWebhook(deps, 'emulator-1', b1, signed(b1));
  const b2 = raw({ ...event, id: 'h2' });
  await handleWebhook(deps, 'emulator-1', b2, signed(b2, { 'x-hop': '2' }));
  assert.equal(stored.get('emulator-1/h0')!.hop, 0);
  assert.equal(stored.get('emulator-1/h2')!.hop, 2);
  const b3 = raw({ ...event, id: 'h3' });
  assert.equal((await handleWebhook(deps, 'emulator-1', b3, signed(b3, { 'x-hop': '-1' }))).status, 400);
});

test('ошибка хранилища – 503, событие не подтверждается', async () => {
  const { deps } = makeDeps({ failTx: true });
  const b = raw(event);
  const r = await handleWebhook(deps, 'emulator-1', b, signed(b));
  assert.equal(r.status, 503);
});
