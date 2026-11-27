import { test } from 'node:test';
import assert from 'node:assert/strict';
import { sign, verify } from '../src/index.ts';

const SECRET = 'test-secret-0123456789abcdef0123456789';
const OTHER = 'other-secret-0123456789abcdef012345678';

test('подписанный токен проходит проверку и возвращает passId и version', () => {
  const token = sign({ passId: 'P-000123', version: 1 }, SECRET);
  assert.deepEqual(verify(token, SECRET), { passId: 'P-000123', version: 1 });
});

test('токен не содержит персональных данных и короче 100 символов', () => {
  const token = sign({ passId: '7f3c9a', version: 12 }, SECRET);
  assert.ok(token.length < 100);
  assert.match(token, /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/);
});

test('изменение любого символа токена даёт null (DENY_BAD_SIGNATURE)', () => {
  const token = sign({ passId: 'G-000777', version: 3 }, SECRET);
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  for (let i = 0; i < token.length; i++) {
    if (token[i] === '.') continue;
    const replacement = alphabet[(alphabet.indexOf(token[i]) + 1) % alphabet.length];
    const tampered = token.slice(0, i) + replacement + token.slice(i + 1);
    assert.equal(verify(tampered, SECRET), null, `символ ${i}`);
  }
});

test('токен, подписанный другим ключом, отклоняется', () => {
  assert.equal(verify(sign({ passId: 'P-000001', version: 1 }, OTHER), SECRET), null);
});

test('перевыпуск: новая версия даёт другой токен, старый остаётся подписанным (отказ по версии — в БД)', () => {
  const v1 = sign({ passId: 'P-000001', version: 1 }, SECRET);
  const v2 = sign({ passId: 'P-000001', version: 2 }, SECRET);
  assert.notEqual(v1, v2);
  assert.equal(verify(v1, SECRET)?.version, 1);
  assert.equal(verify(v2, SECRET)?.version, 2);
});

test('мусор и неверный формат отклоняются', () => {
  for (const bad of ['', '.', 'abc', 'a.b.c', 'a b.c', 'x'.repeat(300), 'UC0wMDAwMDEuMQ.']) {
    assert.equal(verify(bad, SECRET), null, JSON.stringify(bad));
  }
});

test('короткий секрет и неверная полезная нагрузка вызывают ошибку', () => {
  assert.throws(() => sign({ passId: 'P-1', version: 1 }, 'short'));
  assert.throws(() => sign({ passId: 'P 1', version: 1 }, SECRET));
  assert.throws(() => sign({ passId: 'P-1', version: 0 }, SECRET));
});
