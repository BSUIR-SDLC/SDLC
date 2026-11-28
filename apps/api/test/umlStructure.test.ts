import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readdirSync, readFileSync } from 'node:fs';

const ROOT = new URL('../../..', import.meta.url);

function collectTsSources(dir: URL): string {
  let combined = '';
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const child = new URL(entry.name + (entry.isDirectory() ? '/' : ''), dir);
    if (entry.isDirectory()) {
      if (entry.name !== 'test') combined += collectTsSources(child);
    } else if (entry.name.endsWith('.ts')) {
      combined += '\n' + readFileSync(child, 'utf8');
    }
  }
  return combined;
}

function parseDiagramEntities(pumlText: string): string[] {
  const names: string[] = [];
  for (const rawLine of pumlText.split('\n')) {
    const line = rawLine.trim();
    const m = line.match(/^(?:abstract\s+class|class|interface)\s+([A-Z]\w+)/);
    if (m) names.push(m[1]);
  }
  return names;
}

test('классы и интерфейсы class-domain.puml и class-services.puml соответствуют коду TypeScript', () => {
  const code =
    collectTsSources(new URL('apps/api/src/', ROOT)) +
    collectTsSources(new URL('packages/rule-dsl/src/', ROOT)) +
    collectTsSources(new URL('packages/webhook-signature/src/', ROOT));

  for (const file of ['class-domain.puml', 'class-services.puml']) {
    const puml = readFileSync(new URL(`uml/models/${file}`, ROOT), 'utf8');
    const entities = parseDiagramEntities(puml);
    assert.ok(entities.length >= 10, `${file}: мало сущностей`);
    for (const name of entities) {
      if (name === 'DeliveryMachine') {
        assert.ok(existsSync(new URL('apps/api/src/modules/dispatcher/deliveryMachine.ts', ROOT)));
        continue;
      }
      const re = new RegExp(`export\\s+(?:abstract\\s+)?(?:class|interface|type)\\s+${name}\\b`);
      assert.match(code, re, `${file}: сущность ${name} не найдена в коде TypeScript`);
    }
  }
});

test('артефакты deployment-artifacts.puml и файлы конфигурации существуют в репозитории', () => {
  const puml = readFileSync(new URL('uml/models/deployment-artifacts.puml', ROOT), 'utf8');
  const expectedPaths = [
    'deploy/docker-compose.yml',
    'deploy/nginx.conf',
    'db/migrations/001_init.sql',
    'apps/api/src/server.ts',
    'apps/api/src/modules/webhooks/receiveWebhook.ts',
    'apps/api/src/modules/engine/matchingEngine.ts',
    'apps/api/src/modules/dispatcher/deliveryMachine.ts',
    'apps/api/src/modules/guard/loopGuard.ts',
    'packages/webhook-signature/src/index.ts',
    'packages/rule-dsl/src/index.ts',
  ];
  for (const rel of expectedPaths) {
    assert.ok(existsSync(new URL(rel, ROOT)), `отсутствует ${rel}`);
    const base = rel.split('/').pop()!;
    if (!base.endsWith('index.ts')) {
      assert.ok(puml.includes(base), `deployment-artifacts.puml не упоминает ${base}`);
    }
  }
});

test('все модели PlantUML имеют комментарий «Связи» и актуальный PNG в uml/img', () => {
  const modelsDir = new URL('uml/models/', ROOT);
  const imgDir = new URL('uml/img/', ROOT);
  const models = readdirSync(modelsDir).filter((n) => n.endsWith('.puml'));
  assert.ok(models.length >= 12);
  for (const m of models) {
    const lines = readFileSync(new URL(m, modelsDir), 'utf8').split('\n');
    assert.ok(lines[1]?.startsWith("' Связи"), `${m}: отсутствует комментарий «Связи» во 2-й строке`);
    const png = m.replace(/\.puml$/, '.png');
    assert.ok(existsSync(new URL(png, imgDir)), `${m}: отсутствует изображение ${png}`);
  }
});
