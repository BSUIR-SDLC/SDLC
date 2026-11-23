import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateTarget, renderPath, joinUrl } from '../src/modules/targets/targetPolicy.ts';

const hosts = ['emulator.local', 'notifier.local'];

test('корректная цель из списка разрешённых хостов принимается', () => {
  assert.deepEqual(validateTarget({ name: 'emulator', baseUrl: 'http://emulator.local:8080/api' }, hosts), { ok: true });
});

test('цель отклоняется: имя, URL, протокол, учётные данные, хост, query', () => {
  const bad = (name: string, baseUrl: string) => (validateTarget({ name, baseUrl }, hosts) as any).error;
  assert.equal(bad('Bad Name', 'http://emulator.local'), 'BAD_NAME');
  assert.equal(bad('emu', 'not a url'), 'BAD_URL');
  assert.equal(bad('emu', 'ftp://emulator.local'), 'BAD_PROTOCOL');
  assert.equal(bad('emu', 'http://u:p@emulator.local'), 'CREDENTIALS_IN_URL');
  assert.equal(bad('emu', 'http://evil.example'), 'HOST_NOT_ALLOWED');
  assert.equal(bad('emu', 'http://emulator.local/?a=1'), 'QUERY_NOT_ALLOWED');
});

test('шаблон пути подставляет поля события с URL-кодированием', () => {
  const ev = { payload: { deviceId: 'd 7/a' } };
  assert.equal(renderPath('/api/devices/{{payload.deviceId}}/command', ev), '/api/devices/d%207%2Fa/command');
});

test('шаблон без подстановок возвращается как есть', () => {
  assert.equal(renderPath('/notify', {}), '/notify');
});

test('отсутствующее поле или объект вместо значения – ошибка', () => {
  assert.throws(() => renderPath('/x/{{payload.nope}}', { payload: {} }), /MISSING_VALUE/);
  assert.throws(() => renderPath('/x/{{payload}}', { payload: { a: 1 } }), /MISSING_VALUE/);
  assert.throws(() => renderPath('/x/{{a.b.c}}', {}), /MISSING_VALUE/);
});

test('путь должен начинаться с / и не содержать ..', () => {
  assert.throws(() => renderPath('api', {}), /BAD_PATH/);
  assert.throws(() => renderPath('/a/../b', {}), /BAD_PATH/);
  assert.equal(joinUrl('http://emulator.local/api/', '/devices'), 'http://emulator.local/api/devices');
});
