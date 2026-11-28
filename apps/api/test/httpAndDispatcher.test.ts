import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { AddressInfo } from 'node:net';
import { createRuleHookApp } from '../src/server.ts';
import { Administrator, Operator } from '../src/domain/models.ts';
import { sign } from '../../../packages/webhook-signature/src/index.ts';

async function reqJson(base: string, method: string, path: string, body?: unknown, headers: Record<string, string> = {}) {
  const res = await fetch(base + path, {
    method,
    headers: {
      ...(body !== undefined ? { 'content-type': 'application/json' } : {}),
      ...headers,
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const json = await res.json();
  return { status: res.status, json: json as any };
}

test('сквозной HTTP-сценарий: вход, источники, цели, правила, вебхук, воркер и повторы', async () => {
  let clock = 1_700_000_000_000;
  const sent: { url: string; headers: Record<string, string>; body: Record<string, unknown> }[] = [];
  let nextHttpReply: { status?: number; networkError?: boolean } = { status: 503 };

  const app = createRuleHookApp({
    now: () => clock,
    allowedHosts: ['emulator.local', 'notifier.local'],
    httpClient: {
      async post(url, headers, body) {
        sent.push({ url, headers, body });
        return nextHttpReply;
      },
    },
  });

  app.store.addUser(new Administrator('adm-1', 'admin', app.hasher.hash('admin-pass')));
  app.store.addUser(new Operator('op-1', 'operator', app.hasher.hash('op-pass')));

  await new Promise<void>((resolve) => app.server.listen(0, '127.0.0.1', () => resolve()));
  const { port } = app.server.address() as AddressInfo;
  const base = `http://127.0.0.1:${port}`;

  try {
    // 1. /health
    const h = await reqJson(base, 'GET', '/health');
    assert.equal(h.status, 200);

    // 2. Авторизация, блокировка после 5 ошибок и RBAC
    assert.equal((await reqJson(base, 'POST', '/api/v1/auth/login', { login: 'nobody', password: 'x' })).status, 401);
    for (let i = 0; i < 5; i++) {
      const fail = await reqJson(base, 'POST', '/api/v1/auth/login', { login: 'operator', password: 'wrong' });
      assert.equal(fail.status, i < 4 ? 401 : 423);
    }
    const admLogin = await reqJson(base, 'POST', '/api/v1/auth/login', { login: 'admin', password: 'admin-pass' });
    assert.equal(admLogin.status, 200);
    const admToken = admLogin.json.token as string;

    // 3. Создание источника, цели, правила и включение
    const srcRes = await reqJson(base, 'POST', '/api/v1/sources', { id: 'emulator-1', name: 'Стенд' }, { authorization: `Bearer ${admToken}` });
    assert.equal(srcRes.status, 201);
    const secret = srcRes.json.secret as string;

    const tgtRes = await reqJson(base, 'POST', '/api/v1/targets', { name: 'emulator', kind: 'EMULATOR', baseUrl: 'http://emulator.local' }, { authorization: `Bearer ${admToken}` });
    assert.equal(tgtRes.status, 201);

    const ruleRes = await reqJson(base, 'POST', '/api/v1/rules', {
      id: 'overheat-alert',
      source: 'emulator-1',
      eventType: 'sensor.temperature',
      priority: 10,
      when: { all: [{ path: '$.payload.value', op: 'gt', value: 80 }] },
      then: [{ target: 'emulator', path: '/api/devices/{{payload.deviceId}}/command', body: { command: 'shutdown', temp: '{{payload.value}}' } }],
    }, { authorization: `Bearer ${admToken}` });
    assert.equal(ruleRes.status, 201);
    assert.equal((await reqJson(base, 'POST', '/api/v1/rules/overheat-alert/enable', {}, { authorization: `Bearer ${admToken}` })).status, 200);

    // 4. Приём вебхука (UC-02 -> UC-10)
    const rawEvent = Buffer.from(JSON.stringify({ id: 'ev-1', type: 'sensor.temperature', payload: { deviceId: 'd-7', value: 92 } }));
    const hookRes = await fetch(`${base}/hooks/emulator-1`, {
      method: 'POST',
      headers: { 'x-rulehook-signature': sign(secret, rawEvent), 'x-hop': '1' },
      body: rawEvent,
    });
    assert.equal(hookRes.status, 202);
    const hookJson = await hookRes.json() as any;
    assert.equal(hookJson.queued, 1);

    // 5. Доставка: 503 -> retryWait (+2s) -> 204 -> delivered
    const firstTry = await app.worker.tick(clock);
    assert.equal(firstTry?.status, 'retryWait');
    assert.equal(firstTry?.retries, 1);
    assert.equal(await app.worker.tick(clock + 1000), null); // ещё не наступило время повтора

    nextHttpReply = { status: 204 };
    clock += 2000;
    const secondTry = await app.worker.tick(clock);
    assert.equal(secondTry?.status, 'delivered');
    assert.equal(sent.length, 2);
    assert.equal(sent[0].headers['idempotency-key'], sent[1].headers['idempotency-key']);
    assert.equal(sent[1].headers['x-hop'], '2');
    assert.equal(sent[1].url, 'http://emulator.local/api/devices/d-7/command');
    assert.equal(sent[1].body.temp, '92');

    // 6. Журнал, глобальная пауза и удаление цели
    const journal = await reqJson(base, 'GET', '/api/v1/journal', undefined, { authorization: `Bearer ${admToken}` });
    assert.equal(journal.status, 200);
    assert.equal(journal.json.events.length, 1);
    assert.equal(journal.json.deliveries[0].status, 'delivered');

    // создадим ещё событие и проверим pause -> resume -> delete target
    const rawEvent2 = Buffer.from(JSON.stringify({ id: 'ev-2', type: 'sensor.temperature', payload: { deviceId: 'd-8', value: 99 } }));
    await fetch(`${base}/hooks/emulator-1`, {
      method: 'POST',
      headers: { 'x-rulehook-signature': sign(secret, rawEvent2) },
      body: rawEvent2,
    });
    const p1 = await reqJson(base, 'POST', '/api/v1/system/pause', {}, { authorization: `Bearer ${admToken}` });
    assert.equal(p1.json.changed, 1);
    assert.equal(await app.worker.tick(clock), null);
    const p2 = await reqJson(base, 'POST', '/api/v1/system/resume', {}, { authorization: `Bearer ${admToken}` });
    assert.equal(p2.json.changed, 1);

    const delTgt = await reqJson(base, 'DELETE', '/api/v1/targets/emulator', undefined, { authorization: `Bearer ${admToken}` });
    assert.equal(delTgt.json.cancelledDeliveries, 1);

    // 7. Проверка 401/403/404/ротации секрета/импорта
    assert.equal((await reqJson(base, 'GET', '/api/v1/rules')).status, 401);
    assert.equal((await reqJson(base, 'GET', '/api/v1/rules', undefined, { authorization: 'Bearer bad.tok.en' })).status, 401);
    assert.equal((await reqJson(base, 'GET', '/api/v1/unknown', undefined, { authorization: `Bearer ${admToken}` })).status, 404);
    const rot = await reqJson(base, 'POST', '/api/v1/sources/emulator-1/rotate-secret', {}, { authorization: `Bearer ${admToken}` });
    assert.equal(rot.status, 200);
    const imp = await reqJson(base, 'POST', '/api/v1/rules/import', { mode: 'skip', rules: [] }, { authorization: `Bearer ${admToken}` });
    assert.equal(imp.status, 200);
    assert.equal((await reqJson(base, 'GET', '/api/v1/sources', undefined, { authorization: `Bearer ${admToken}` })).status, 200);
    assert.equal((await reqJson(base, 'GET', '/api/v1/targets', undefined, { authorization: `Bearer ${admToken}` })).status, 200);
    assert.equal((await reqJson(base, 'GET', '/api/v1/rules', undefined, { authorization: `Bearer ${admToken}` })).status, 200);
    assert.equal((await reqJson(base, 'POST', '/api/v1/rules/overheat-alert/disable', {}, { authorization: `Bearer ${admToken}` })).status, 200);
  } finally {
    app.server.close();
  }
});
