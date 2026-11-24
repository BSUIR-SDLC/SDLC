import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sign, verify } from '../../../packages/qr-token/src/index.ts';
import {
  CheckChain, InMemoryValidationRepository, InvalidPassCodeError, CheckpointNotFoundError, ValidationService,
  type CheckpointInfo, type OccupancyEvent, type PassRecord, type ValidationContext,
} from '../src/modules/validation/index.ts';

const SECRET = 'validation-test-secret-0123456789abcdef';
const T0 = Date.UTC(2026, 10, 24, 9, 0);
const DAY = 24 * 60 * 60 * 1000;

function site(over: Partial<CheckpointInfo['site']> = {}): CheckpointInfo['site'] {
  return { id: 'site-1', capacity: 400, antipassbackStrict: true, capacityLock: true, ...over };
}

function passRecord(over: Partial<PassRecord> = {}): PassRecord {
  return {
    id: 'pass-1', code: 'P-000001', holderName: 'Иванов Иван', photoId: null, type: 'EMPLOYEE',
    validFrom: T0 - DAY, validTo: T0 + 30 * DAY, status: 'ACTIVE', version: 1, zoneIds: ['zone-main'], ...over,
  };
}

function setup(opts: { site?: Partial<CheckpointInfo['site']>; passes?: PassRecord[]; counter?: number } = {}) {
  const repo = new InMemoryValidationRepository();
  const s = site(opts.site);
  repo.addCheckpoint({ id: 'cp-in', zoneId: 'zone-main', site: s });
  repo.addCheckpoint({ id: 'cp-lab', zoneId: 'zone-lab', site: s });
  for (const p of opts.passes ?? [passRecord()]) repo.addPass(p);
  if (opts.counter !== undefined) repo.setCounter(s.id, opts.counter);
  const published: OccupancyEvent[] = [];
  let now = T0;
  let verifyCalls = 0;
  const service = new ValidationService({
    repo,
    tokens: { verify: (t) => { verifyCalls += 1; return verify(t, SECRET); } },
    publisher: { publish: (e) => published.push(e) },
    clock: { now: () => now },
  });
  return {
    repo, service, published,
    tick: (ms: number) => { now += ms; },
    verifyCalls: () => verifyCalls,
    token: (passId = 'pass-1', version = 1) => sign({ passId, version }, SECRET),
  };
}

const cmd = { checkpointId: 'cp-in', controllerId: 'u-ctrl' };

function ctx(over: Partial<ValidationContext> = {}): ValidationContext {
  return {
    pass: passRecord(), presentedVersion: 1, checkpoint: { id: 'cp-in', zoneId: 'zone-main', site: site() },
    direction: 'IN', inside: false, occupancy: 0, now: T0, ...over,
  };
}

test('цепочка проверок идёт в порядке BR-01 и возвращает первую нарушенную', () => {
  const chain = CheckChain.standard();
  assert.deepEqual(chain.names(), ['существование', 'отзыв и версия', 'срок', 'зона', 'anti-passback', 'вместимость']);
  assert.equal(chain.evaluate(ctx()), 'OK');
  assert.equal(chain.evaluate(ctx({ pass: null })), 'DENY_NOT_FOUND');
  // пропуск одновременно отозван, просрочен и не в той зоне — побеждает первая проверка
  const bad = passRecord({ status: 'REVOKED', validTo: T0 - 1, zoneIds: ['zone-lab'] });
  assert.equal(chain.evaluate(ctx({ pass: bad })), 'DENY_REVOKED');
  assert.equal(chain.evaluate(ctx({ pass: passRecord({ validTo: T0 - 1, zoneIds: ['zone-lab'] }) })), 'DENY_EXPIRED');
  assert.equal(chain.evaluate(ctx({ pass: passRecord({ validFrom: T0 + 1 }) })), 'DENY_EXPIRED');
  assert.equal(chain.evaluate(ctx({ pass: passRecord({ zoneIds: ['zone-lab'] }) })), 'DENY_ZONE');
  assert.equal(chain.evaluate(ctx({ presentedVersion: 2 })), 'DENY_REVOKED');
  assert.equal(chain.evaluate(ctx({ presentedVersion: null })), 'OK');
});

test('anti-passback и вместимость (BR-04): выход при блокировке разрешён всегда', () => {
  const chain = CheckChain.standard();
  assert.equal(chain.evaluate(ctx({ inside: true })), 'DENY_ALREADY_INSIDE');
  assert.equal(chain.evaluate(ctx({ direction: 'OUT', inside: false })), 'DENY_NOT_INSIDE');
  assert.equal(chain.evaluate(ctx({ occupancy: 400 })), 'DENY_CAPACITY');
  assert.equal(chain.evaluate(ctx({ direction: 'OUT', inside: true, occupancy: 400 })), 'OK');
  const lax = { id: 'cp-in', zoneId: 'zone-main', site: site({ antipassbackStrict: false, capacityLock: false }) };
  assert.equal(chain.evaluate(ctx({ checkpoint: lax, inside: true, occupancy: 999 })), 'OK');
});

test('ALLOW на вход: присутствие и счётчик изменены, событие записано, публикация после COMMIT', async () => {
  const t = setup({ counter: 10 });
  t.tick(0);
  const res = await t.service.validate({ ...cmd, direction: 'IN', token: t.token() });
  assert.equal(res.decision, 'ALLOW');
  assert.equal(res.reason, 'OK');
  assert.equal(res.occupancy, 11);
  assert.deepEqual(res.pass, { code: 'P-000001', holderName: 'Иванов Иван', type: 'EMPLOYEE', validTo: T0 + 30 * DAY, photoId: null });
  assert.equal(t.repo.counter('site-1'), 11);
  assert.equal(t.repo.events().length, 1);
  assert.equal(t.published.length, 1);
  assert.equal(t.published[0].occupancy, 11);
  assert.equal(t.published[0].event.reason, 'OK');

  const again = await t.service.validate({ ...cmd, direction: 'IN', token: t.token() });
  assert.equal(again.reason, 'DENY_ALREADY_INSIDE');
  const out = await t.service.validate({ ...cmd, direction: 'OUT', token: t.token() });
  assert.equal(out.reason, 'OK');
  assert.equal(t.repo.counter('site-1'), 10);
});

test('неверная подпись: DENY_BAD_SIGNATURE без чтения пропуска, событие в журнале (BR-11)', async () => {
  const t = setup();
  const forged = sign({ passId: 'pass-1', version: 1 }, 'another-secret-0123456789abcdef01234');
  const res = await t.service.validate({ ...cmd, direction: 'IN', token: forged });
  assert.deepEqual(res, { decision: 'DENY', reason: 'DENY_BAD_SIGNATURE', pass: null, occupancy: null, capacity: null });
  assert.equal(t.verifyCalls(), 1);
  assert.equal(t.repo.events()[0].reason, 'DENY_BAD_SIGNATURE');
  assert.equal(t.published.length, 0);
});

test('QR прежней версии после перевыпуска получает DENY_REVOKED (BR-05)', async () => {
  const t = setup({ passes: [passRecord({ version: 2 })] });
  const old = await t.service.validate({ ...cmd, direction: 'IN', token: t.token('pass-1', 1) });
  assert.equal(old.reason, 'DENY_REVOKED');
  const fresh = await t.service.validate({ ...cmd, direction: 'IN', token: t.token('pass-1', 2) });
  assert.equal(fresh.reason, 'OK');
});

test('ручной ввод номера (F07, UC-03): та же цепочка, событие помечено manual', async () => {
  const t = setup();
  const res = await t.service.validateManual({ ...cmd, direction: 'IN', code: ' p-000001 ' });
  assert.equal(res.reason, 'OK');
  assert.equal(t.repo.events()[0].manual, true);
  const missing = await t.service.validateManual({ ...cmd, direction: 'IN', code: 'G-000009' });
  assert.equal(missing.reason, 'DENY_NOT_FOUND');
  await assert.rejects(t.service.validateManual({ ...cmd, direction: 'IN', code: 'abc' }), InvalidPassCodeError);
});

test('неизвестная точка прохода — ошибка 404, транзакция откатывается, публикации нет', async () => {
  const t = setup();
  await assert.rejects(
    t.service.validate({ checkpointId: 'nope', controllerId: 'u', direction: 'IN', token: t.token() }),
    CheckpointNotFoundError,
  );
  assert.equal(t.repo.events().length, 0);
  assert.equal(t.published.length, 0);
});

test('гонка за последнее место: два одновременных входа — один ALLOW, второй DENY_CAPACITY (SDD 010)', async () => {
  const t = setup({
    site: { capacity: 400 },
    counter: 399,
    passes: [passRecord(), passRecord({ id: 'pass-2', code: 'P-000002' })],
  });
  const results = await Promise.all([
    t.service.validate({ ...cmd, direction: 'IN', token: t.token('pass-1') }),
    t.service.validate({ ...cmd, direction: 'IN', token: t.token('pass-2') }),
  ]);
  assert.deepEqual(results.map((r) => r.reason).sort(), ['DENY_CAPACITY', 'OK']);
  assert.equal(t.repo.counter('site-1'), 400);
});

test('доступ в чужую зону и задержка фиксируется в latencyMs', async () => {
  const t = setup();
  const res = await t.service.validate({ checkpointId: 'cp-lab', controllerId: 'u', direction: 'IN', token: t.token() });
  assert.equal(res.reason, 'DENY_ZONE');
  assert.equal(res.decision, 'DENY');
  assert.ok(t.repo.events()[0].latencyMs >= 0);
});
