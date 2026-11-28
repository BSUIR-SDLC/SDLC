import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  sign,
  verify,
  activeSecrets,
  ROTATION_GRACE_MS,
} from '../src/index.ts';

const body = JSON.stringify({ id: 'e-1', type: 'sensor.temperature', payload: { value: 81 } });

test('подпись своим секретом проходит проверку', () => {
  assert.equal(verify(['s1'], body, sign('s1', body)), true);
});

test('изменённое тело не проходит проверку', () => {
  assert.equal(verify(['s1'], body + ' ', sign('s1', body)), false);
});

test('чужой секрет не проходит проверку', () => {
  assert.equal(verify(['s1'], body, sign('other', body)), false);
});

test('отсутствующий или неверный по формату заголовок отклоняется', () => {
  assert.equal(verify(['s1'], body, undefined), false);
  assert.equal(verify(['s1'], body, 'md5=abc'), false);
  assert.equal(verify(['s1'], body, 'sha256=xyz'), false);
  assert.equal(verify(['s1'], body, 'sha256=' + 'a'.repeat(62)), false);
});

test('проверка работает для Buffer и в верхнем регистре hex', () => {
  const buf = Buffer.from(body);
  const header = 'sha256=' + sign('s1', buf).slice(7).toUpperCase();
  assert.equal(verify(['s1'], buf, header), true);
});

test('во время ротации принимается подпись старым секретом не дольше 24 ч', () => {
  const source = { secret: 'new', previousSecret: 'old', rotatedAt: 1_000 };
  assert.deepEqual(activeSecrets(source, 1_000 + ROTATION_GRACE_MS - 1), ['new', 'old']);
  assert.deepEqual(activeSecrets(source, 1_000 + ROTATION_GRACE_MS), ['new']);
  assert.equal(verify(activeSecrets(source, 2_000), body, sign('old', body)), true);
});

test('без ротации активен только текущий секрет', () => {
  assert.deepEqual(activeSecrets({ secret: 's1' }, Date.now()), ['s1']);
});
