import { test } from 'node:test';
import assert from 'node:assert/strict';
import { InMemoryStore } from '../src/infrastructure/inMemoryStore.ts';
import { Administrator, Operator, EmulatorTarget, NotifierTarget, RuleEntity } from '../src/domain/models.ts';
import { LoopGuard, MAX_TRIGGERS_PER_MINUTE } from '../src/modules/guard/loopGuard.ts';
import { MatchingEngine } from '../src/modules/engine/matchingEngine.ts';
import { RuleService } from '../src/modules/rules/ruleService.ts';
import { SourceService } from '../src/modules/sources/sourceService.ts';
import { TargetService, isPrivateOrReservedHost } from '../src/modules/targets/targetService.ts';

const baseRule = (id: string, priority = 10, cooldownSec = 0) => ({
  id,
  source: 'emulator-1',
  eventType: 'sensor.temperature',
  priority,
  cooldownSec,
  when: { all: [{ path: '$.payload.value', op: 'gt', value: 80 }] },
  then: [{ target: 'emulator', path: '/api/devices/{{payload.deviceId}}/cmd', body: { cmd: 'stop' } }],
});

test('иерархии User и Target инкапсулируют права и форматирование запросов', () => {
  const op = new Operator('u1', 'op', 'h');
  const adm = new Administrator('u2', 'adm', 'h');
  assert.equal(op.can('rules:write'), true);
  assert.equal(op.can('sources:manage'), false);
  assert.equal(adm.can('sources:manage'), true);
  assert.equal(op.isLocked(100), false);

  const emu = new EmulatorTarget('t1', 'emulator', 'http://emulator.local');
  const not = new NotifierTarget('t2', 'notifier', 'https://notifier.local');
  assert.equal(emu.validate(['emulator.local']).ok, true);
  const r1 = emu.buildRequest('/api/{{payload.id}}', { cmd: 'go' }, { payload: { id: 'd1' } }, 'del-1', 1);
  const r2 = not.buildRequest('/notify', { text: 'hi' }, {}, 'del-2', 2);
  assert.equal(r1.body.source, 'rulehook');
  assert.equal(r1.headers['idempotency-key'], 'del-1');
  assert.equal(r2.body.channel, 'default');
  assert.equal(r2.headers['x-hop'], '2');
});

test('TargetService блокирует SSRF на приватные адреса (REQ-INT-003)', async () => {
  const store = new InMemoryStore();
  const svc = new TargetService(store, ['emulator.local', '127.0.0.1', '192.168.1.5', 'localhost', '[::1]', '169.254.169.254']);
  assert.equal(isPrivateOrReservedHost('10.0.0.1'), true);
  assert.equal(isPrivateOrReservedHost('172.16.5.1'), true);
  assert.equal(isPrivateOrReservedHost('emulator.local'), false);
  await assert.rejects(() => svc.createTarget({ name: 'bad1', kind: 'EMULATOR', baseUrl: 'http://127.0.0.1:8080' }), /SSRF_PRIVATE_HOST/);
  await assert.rejects(() => svc.createTarget({ name: 'bad2', kind: 'EMULATOR', baseUrl: 'http://192.168.1.5' }), /SSRF_PRIVATE_HOST/);
  await assert.rejects(() => svc.createTarget({ name: 'bad3', kind: 'EMULATOR', baseUrl: 'not a url' }), /BAD_URL/);
  await assert.rejects(() => svc.deleteTarget('missing'), /TARGET_NOT_FOUND/);
});

test('SourceService создаёт источник, ротирует секрет и управляет состоянием', async () => {
  const store = new InMemoryStore();
  const svc = new SourceService(store);
  await assert.rejects(() => svc.createSource({ id: 'Bad', name: 'x' }), /BAD_SOURCE_ID/);
  const { source, plainSecret } = await svc.createSource({ id: 'emu-1', name: 'Эмулятор 1' });
  assert.equal(source.enabled, true);
  await assert.rejects(() => svc.createSource({ id: 'emu-1', name: 'dup' }), /SOURCE_EXISTS/);
  const rot = await svc.rotateSecret('emu-1', 1000);
  assert.notEqual(rot.plainSecret, plainSecret);
  const updated = await svc.getSource ? null : (await store.getSource('emu-1'))!;
  assert.equal(updated.previousSecret, plainSecret);
  await svc.setEnabled('emu-1', false);
  assert.equal((await store.getSource('emu-1'))!.enabled, false);
  await assert.rejects(() => svc.rotateSecret('nope', 1000), /SOURCE_NOT_FOUND/);
  await assert.rejects(() => svc.setEnabled('nope', true), /SOURCE_NOT_FOUND/);
});

test('LoopGuard проверяет X-Hop, cooldown и автоотключение > 20 срабатываний/мин', () => {
  const guard = new LoopGuard();
  const rule = new RuleEntity(baseRule('r-loop', 10, 30) as any, 'u1', 0);
  assert.equal(guard.check(rule, 0, 1000).reason, 'RULE_DISABLED');

  rule.enable();
  assert.deepEqual(guard.check(rule, 3, 1000), { allow: false, reason: 'HOP_LIMIT', autoDisabled: false });

  const first = guard.check(rule, 0, 10_000);
  assert.equal(first.allow, true);
  assert.deepEqual(guard.check(rule, 0, 20_000), { allow: false, reason: 'COOLDOWN', autoDisabled: false });
  // после истечения cooldown (30 с) снова разрешено
  assert.equal(guard.check(rule, 0, 45_000).allow, true);

  // проверка rate limiter (> 20 срабатываний за 60 с)
  const fastRule = new RuleEntity(baseRule('r-fast', 10, 0) as any, 'u1', 0);
  fastRule.enable();
  for (let i = 0; i < MAX_TRIGGERS_PER_MINUTE; i++) {
    assert.equal(guard.check(fastRule, 0, 100_000 + i * 100).autoDisabled, false);
  }
  const tripped = guard.check(fastRule, 0, 103_000);
  assert.equal(tripped.autoDisabled, true);
  assert.equal(fastRule.state, 'auto_disabled');
});

test('MatchingEngine сортирует по приоритету и RuleService выполняет CRUD, импорт и dryRun', async () => {
  const store = new InMemoryStore();
  const sources = new SourceService(store);
  const targets = new TargetService(store, ['emulator.local']);
  const engine = new MatchingEngine(new LoopGuard());
  const ruleSvc = new RuleService(store, store, store, engine);

  await sources.createSource({ id: 'emulator-1', name: 'Emu' });
  await targets.createTarget({ name: 'emulator', kind: 'EMULATOR', baseUrl: 'http://emulator.local' });

  // ошибка ссылки на цель
  const badRef = await ruleSvc.createRule({
    ...baseRule('r1'),
    then: [{ target: 'unknown-target', path: '/a', body: {} }],
  }, 'u1', 1);
  assert.equal(badRef.ok, false);

  const c1 = await ruleSvc.createRule(baseRule('b-rule', 10), 'u1', 1);
  assert.equal(c1.ok, true);
  assert.equal((await ruleSvc.createRule(baseRule('b-rule', 10), 'u1', 1)).ok, false);

  await ruleSvc.createRule(baseRule('a-rule', 10), 'u1', 1);
  await ruleSvc.enableRule('b-rule');
  await ruleSvc.enableRule('a-rule');

  const selected = engine.selectRules(await ruleSvc.listRules(), 'emulator-1', 'sensor.temperature');
  assert.deepEqual(selected.map((r) => r.id), ['a-rule', 'b-rule']);

  const upd = await ruleSvc.updateRule('a-rule', baseRule('a-rule', 5), 'u1', 2);
  assert.equal(upd.ok, true);
  if (upd.ok) assert.equal(upd.rule.version, 2);
  assert.equal((await ruleSvc.updateRule('missing', baseRule('a-rule'), 'u1', 2)).ok, false);

  const dry = await ruleSvc.dryRun('a-rule', {
    sourceId: 'emulator-1', eventId: 'e1', type: 'sensor.temperature', hop: 0, payload: { value: 95, deviceId: 'd1' }, receivedAt: 3,
  });
  assert.equal(dry.matched, true);
  assert.equal(dry.actions.length, 1);

  const imp = await ruleSvc.importRules([
    baseRule('a-rule', 1), // существует -> skip
    baseRule('c-rule', 30), // новое -> created (выключено)
    { id: 'bad' }, // ошибка схемы
    { ...baseRule('d-rule'), source: 'nope' }, // неизвестная ссылка
  ], 'skip', 'u1', 4);
  assert.deepEqual({ created: imp.created, updated: imp.updated, skipped: imp.skipped, errs: imp.errors.length },
    { created: 1, updated: 0, skipped: 1, errs: 2 });

  const impReplace = await ruleSvc.importRules([baseRule('a-rule', 2)], 'replace', 'u1', 5);
  assert.equal(impReplace.updated, 1);

  await assert.rejects(() => ruleSvc.archiveRule('a-rule'), /DISABLE_BEFORE_ARCHIVE/);
  await ruleSvc.disableRule('a-rule');
  await ruleSvc.archiveRule('a-rule');
  await assert.rejects(() => ruleSvc.enableRule('a-rule'), /RULE_ARCHIVED/);
  await assert.rejects(() => ruleSvc.updateRule('a-rule', baseRule('a-rule'), 'u1', 6), /RULE_ARCHIVED/);
  await assert.rejects(() => ruleSvc.enableRule('nope'), /RULE_NOT_FOUND/);
  await assert.rejects(() => ruleSvc.disableRule('nope'), /RULE_NOT_FOUND/);
  await assert.rejects(() => ruleSvc.archiveRule('nope'), /RULE_NOT_FOUND/);
  await assert.rejects(() => ruleSvc.dryRun('nope', {} as any), /RULE_NOT_FOUND/);
});
