import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  LOCK_MS, SESSION_MS, authorize, evaluateLogin, isSessionValid, type UserAuthState,
} from '../src/modules/auth/authPolicy.ts';

const T0 = Date.UTC(2026, 10, 5, 8, 0);
const fresh: UserAuthState = { failedAttempts: 0, lockedUntil: null };

test('верный пароль создаёт сессию на 12 ч и обнуляет счётчик попыток', () => {
  const r = evaluateLogin({ failedAttempts: 3, lockedUntil: null }, true, T0);
  assert.equal(r.kind, 'ok');
  if (r.kind === 'ok') assert.equal(r.sessionExpiresAt, T0 + SESSION_MS);
  assert.deepEqual(r.state, fresh);
});

test('5 неверных попыток подряд блокируют учётную запись на 15 мин (REQ-SEC-003)', () => {
  let state = fresh;
  for (let i = 1; i <= 4; i++) {
    const r = evaluateLogin(state, false, T0 + i);
    assert.equal(r.kind, 'rejected');
    state = r.state;
    assert.equal(state.lockedUntil, null);
  }
  const fifth = evaluateLogin(state, false, T0 + 5);
  assert.equal(fifth.state.lockedUntil, T0 + 5 + LOCK_MS);

  const whileLocked = evaluateLogin(fifth.state, true, T0 + 10 * 60 * 1000);
  assert.equal(whileLocked.kind, 'locked');

  const after = evaluateLogin(fifth.state, true, T0 + 5 + LOCK_MS);
  assert.equal(after.kind, 'ok');
});

test('после окончания блокировки счёт попыток начинается заново', () => {
  const locked: UserAuthState = { failedAttempts: 0, lockedUntil: T0 };
  const r = evaluateLogin(locked, false, T0 + 1);
  assert.deepEqual(r.state, { failedAttempts: 1, lockedUntil: null });
});

test('сессия истекает через 12 ч (REQ-FUNC-001)', () => {
  assert.equal(isSessionValid(T0 + SESSION_MS, T0 + SESSION_MS - 1), true);
  assert.equal(isSessionValid(T0 + SESSION_MS, T0 + SESSION_MS), false);
});

test('контролёр: validate только на своих точках, API администратора — 403 (REQ-SEC-001)', () => {
  const controller = { role: 'CONTROLLER' as const, checkpointIds: ['cp-1'] };
  assert.equal(authorize(controller, 'validate', 'cp-1'), 'allow');
  assert.equal(authorize(controller, 'validate', 'cp-2'), 403);
  assert.equal(authorize(controller, 'validate'), 403);
  assert.equal(authorize(controller, 'evacuation:read'), 'allow');
  assert.equal(authorize(controller, 'passes:write'), 403);
  assert.equal(authorize(controller, 'counter:reset'), 403);
});

test('администратор управляет пропусками и настройками, но не сканирует', () => {
  const admin = { role: 'ADMIN' as const, checkpointIds: [] };
  for (const a of ['passes:write', 'settings:write', 'log:read', 'counter:reset', 'evacuation:read'] as const) {
    assert.equal(authorize(admin, a), 'allow', a);
  }
  assert.equal(authorize(admin, 'validate', 'cp-1'), 403);
});
