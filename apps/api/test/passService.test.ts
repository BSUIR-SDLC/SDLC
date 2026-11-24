import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sign, verify } from '../../../packages/qr-token/src/index.ts';
import {
  DAY_MS, InMemoryPassRepository, PassNotFoundError, PassRuleError, PassService, formatPassCode, lifecycleOf,
} from '../src/modules/passes/index.ts';

const SECRET = 'passes-test-secret-0123456789abcdef0123';
const T0 = Date.UTC(2026, 10, 24, 9, 0);

function setup() {
  let n = 0;
  const service = new PassService({
    repo: new InMemoryPassRepository(),
    signer: { sign: (p) => sign(p, SECRET) },
    ids: { newId: () => `id-${++n}` },
  });
  return service;
}

const employee = { holderId: 'h-1', type: 'EMPLOYEE' as const, validFrom: T0, validTo: T0 + 30 * DAY_MS, zoneIds: ['z1', 'z1'] };

test('выпуск: номер P-000001, version = 1, QR подписан и проверяется (UC-04, BR-02)', async () => {
  const s = setup();
  const { pass, token } = await s.issue(employee);
  assert.equal(pass.code, 'P-000001');
  assert.equal(pass.version, 1);
  assert.deepEqual(pass.zoneIds, ['z1']);
  assert.deepEqual(verify(token, SECRET), { passId: pass.id, version: 1 });
  const guest = await s.issue({ ...employee, type: 'GUEST', validTo: T0 + DAY_MS });
  assert.equal(guest.pass.code, 'G-000001');
  assert.equal(formatPassCode('EMPLOYEE', 123), 'P-000123');
});

test('ограничения срока BR-03: гость — до суток, сотрудник — до года', async () => {
  const s = setup();
  await assert.rejects(s.issue({ ...employee, type: 'GUEST', validTo: T0 + DAY_MS + 1 }), PassRuleError);
  await assert.rejects(s.issue({ ...employee, validTo: T0 + 366 * DAY_MS }), PassRuleError);
  await assert.rejects(s.issue({ ...employee, validTo: T0 }), PassRuleError);
  await assert.rejects(s.issue({ ...employee, zoneIds: [] }), PassRuleError);
});

test('отзыв и перевыпуск увеличивают версию, номер сохраняется (BR-05, диаграмма состояний пропуска)', async () => {
  const s = setup();
  const { pass } = await s.issue(employee);
  const revoked = await s.revoke(pass.id);
  assert.equal(revoked.status, 'REVOKED');
  assert.equal(revoked.version, 2);
  assert.equal((await s.revoke(pass.id)).version, 2, 'повторный отзыв не меняет версию');
  await assert.rejects(s.extend(pass.id, T0 + 60 * DAY_MS), PassRuleError);
  const re = await s.reissue(pass.id);
  assert.equal(re.pass.status, 'ACTIVE');
  assert.equal(re.pass.version, 3);
  assert.equal(re.pass.code, pass.code);
  assert.deepEqual(verify(re.token, SECRET), { passId: pass.id, version: 3 });
});

test('продление не меняет версию; поиск по номеру; удаление', async () => {
  const s = setup();
  const { pass } = await s.issue(employee);
  const ext = await s.extend(pass.id, T0 + 300 * DAY_MS);
  assert.equal(ext.version, 1);
  assert.equal((await s.findByCode(' p-000001'))?.id, pass.id);
  assert.equal(await s.findByCode('bad'), null);
  await s.remove(pass.id);
  await assert.rejects(s.revoke(pass.id), PassNotFoundError);
});

test('статус жизненного цикла вычисляется по времени: ожидает → активен → просрочен', () => {
  const p = { status: 'ACTIVE' as const, validFrom: T0, validTo: T0 + DAY_MS };
  assert.equal(lifecycleOf(p, T0 - 1), 'PENDING');
  assert.equal(lifecycleOf(p, T0), 'ACTIVE');
  assert.equal(lifecycleOf(p, T0 + DAY_MS + 1), 'EXPIRED');
  assert.equal(lifecycleOf({ ...p, status: 'REVOKED' }, T0), 'REVOKED');
});
