import { test } from 'node:test';
import assert from 'node:assert/strict';
import { ApiError, MockApi } from '../src/api/mockApi';
import { EVENTS } from '../src/data/events';
import { RESERVATION_TTL_MS } from '../src/domain/reservation';

function setup() {
  let t = Date.parse('2026-12-01T10:00:00Z');
  const api = new MockApi(EVENTS, () => t);
  return { api, advance: (ms: number) => { t += ms; }, now: () => t };
}
const free = (api: MockApi, ev: string, ty: string) => api.listEvents().find((e) => e.id === ev)!.ticketTypes.find((x) => x.id === ty)!.free;

test('бронь удерживает места и сообщает срок 15 минут по часам сервера', () => {
  const { api, now } = setup();
  const r = api.reserve('A', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 3 }]);
  assert.equal(Date.parse(r.expiresAt) - now(), RESERVATION_TTL_MS);
  assert.equal(free(api, 'e09', 'std'), 1);
});

test('409, если мест не хватает с учётом чужих броней', () => {
  const { api } = setup();
  api.reserve('A', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 3 }]);
  assert.throws(() => api.reserve('B', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 2 }]), (e) => e instanceof ApiError && e.status === 409);
  const ok = api.reserve('B', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 1 }]);
  assert.ok(ok.id);
});

test('несколько вкладок одной сессии не удваивают бронь', () => {
  const { api } = setup();
  api.reserve('A', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 3 }]);
  api.reserve('A', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 4 }]);
  assert.equal(free(api, 'e09', 'std'), 0);
});

test('изменение состава брони не продлевает срок', () => {
  const { api, advance } = setup();
  const r1 = api.reserve('A', [{ eventId: 'e01', ticketTypeId: 'std', quantity: 1 }]);
  advance(5 * 60_000);
  const r2 = api.reserve('A', [{ eventId: 'e01', ticketTypeId: 'std', quantity: 2 }]);
  assert.equal(r2.expiresAt, r1.expiresAt);
});

test('по истечении 15 минут места возвращаются в продажу, getReservation отвечает 410', () => {
  const { api, advance } = setup();
  api.reserve('A', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 4 }]);
  assert.equal(free(api, 'e09', 'std'), 0);
  advance(RESERVATION_TTL_MS);
  assert.equal(free(api, 'e09', 'std'), 4);
  assert.throws(() => api.getReservation('A'), (e) => e instanceof ApiError && e.status === 410);
});

test('после истечения чужой брони другой посетитель может забронировать те же места', () => {
  const { api, advance } = setup();
  api.reserve('A', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 4 }]);
  advance(RESERVATION_TTL_MS + 1);
  assert.doesNotThrow(() => api.reserve('B', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 4 }]));
});

test('освобождение и пустой состав снимают бронь', () => {
  const { api } = setup();
  api.reserve('A', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 2 }]);
  api.release('A');
  assert.equal(free(api, 'e09', 'std'), 4);
  api.reserve('A', [{ eventId: 'e09', ticketTypeId: 'std', quantity: 2 }]);
  api.reserve('A', []);
  assert.equal(free(api, 'e09', 'std'), 4);
});

test('неизвестное событие — 404, нулевое количество — 409', () => {
  const { api } = setup();
  assert.throws(() => api.reserve('A', [{ eventId: 'zz', ticketTypeId: 'std', quantity: 1 }]), (e) => e instanceof ApiError && e.status === 404);
  assert.throws(() => api.reserve('A', [{ eventId: 'e01', ticketTypeId: 'std', quantity: 0 }]), (e) => e instanceof ApiError && e.status === 409);
});
