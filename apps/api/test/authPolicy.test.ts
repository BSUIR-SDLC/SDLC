import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  applyLoginAttempt, initialLoginState, isLocked, sessionExpired, can,
  LOCK_MS, SESSION_TTL_MS, MAX_FAILED_ATTEMPTS,
} from '../src/modules/auth/authPolicy.ts';

test('верный пароль – вход и сброс счётчика ошибок', () => {
  const r = applyLoginAttempt({ failedAttempts: 3, lockedUntil: null }, true, 0);
  assert.equal(r.result, 'OK');
  assert.deepEqual(r.state, initialLoginState());
});

test('пятая неудачная попытка блокирует учётную запись на 15 минут', () => {
  let s = initialLoginState();
  let last = '';
  for (let i = 0; i < MAX_FAILED_ATTEMPTS; i++) {
    const r = applyLoginAttempt(s, false, 1000);
    s = r.state; last = r.result;
  }
  assert.equal(last, 'LOCKED');
  assert.equal(s.lockedUntil, 1000 + LOCK_MS);
  assert.equal(isLocked(s, 1000 + LOCK_MS - 1), true);
});

test('во время блокировки даже верный пароль не пускает', () => {
  const s = { failedAttempts: 5, lockedUntil: 10_000 };
  assert.equal(applyLoginAttempt(s, true, 9_999).result, 'LOCKED');
});

test('после окончания блокировки счётчик начинается заново', () => {
  const s = { failedAttempts: 5, lockedUntil: 10_000 };
  const r = applyLoginAttempt(s, false, 10_000);
  assert.equal(r.result, 'BAD_CREDENTIALS');
  assert.equal(r.state.failedAttempts, 1);
});

test('сессия действует 12 часов', () => {
  assert.equal(sessionExpired(0, SESSION_TTL_MS - 1), false);
  assert.equal(sessionExpired(0, SESSION_TTL_MS), true);
});

test('права ролей: оператор не управляет источниками, администратор – да', () => {
  assert.equal(can('operator', 'rules:write'), true);
  assert.equal(can('operator', 'deliveries:replay'), true);
  assert.equal(can('operator', 'sources:manage'), false);
  assert.equal(can('admin', 'sources:manage'), true);
  assert.equal(can('admin', 'system:pause'), true);
  assert.equal(can('guest' as any, 'rules:read'), false);
});
