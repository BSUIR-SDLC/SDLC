import { test } from 'node:test';
import assert from 'node:assert/strict';
import { RESERVATION_TTL_MS, clockOffsetMs, formatCountdown, isExpired, remainingMs } from '../src/domain/reservation';

const T0 = Date.parse('2026-12-01T10:00:00Z');
const res = { id: 'r1', expiresAt: new Date(T0 + RESERVATION_TTL_MS).toISOString(), serverTime: new Date(T0).toISOString() };

test('TTL брони — 15 минут', () => {
  assert.equal(RESERVATION_TTL_MS, 900_000);
});

test('остаток времени при совпадающих часах', () => {
  assert.equal(remainingMs(res, T0 + 60_000, 0), RESERVATION_TTL_MS - 60_000);
});

test('часы клиента спешат на час: остаток всё равно считается по серверу', () => {
  const clientNow = T0 + 3_600_000;
  const offset = clockOffsetMs(res, clientNow);
  assert.equal(offset, -3_600_000);
  assert.equal(remainingMs(res, clientNow + 120_000, offset), RESERVATION_TTL_MS - 120_000);
});

test('остаток не бывает отрицательным; истечение определяется точно', () => {
  assert.equal(remainingMs(res, T0 + RESERVATION_TTL_MS + 5000, 0), 0);
  assert.equal(isExpired(res, T0 + RESERVATION_TTL_MS - 1, 0), false);
  assert.equal(isExpired(res, T0 + RESERVATION_TTL_MS, 0), true);
});

test('формат обратного отсчёта мм:сс', () => {
  assert.equal(formatCountdown(RESERVATION_TTL_MS), '15:00');
  assert.equal(formatCountdown(61_000), '01:01');
  assert.equal(formatCountdown(500), '00:01');
  assert.equal(formatCountdown(0), '00:00');
  assert.equal(formatCountdown(-5), '00:00');
});
