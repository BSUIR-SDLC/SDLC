/**
 * Сверка проектных диаграмм классов с кодом (ADR-0011).
 * Пакет диаграммы с именем-путём ("apps/api/src/modules/validation") соответствует каталогу репозитория.
 * Проверяется: 1) каждый класс, интерфейс и перечисление пакета экспортируется кодом каталога;
 * 2) каждая операция класса есть в коде; для <<utility>> — экспортируемая функция;
 * 3) каждый экспортируемый класс каталога есть на диаграмме (код не обгоняет модель).
 */
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';

const ROOT = fileURLToPath(new URL('../../../', import.meta.url));
const DIAGRAMS = ['class-validation.puml', 'class-passes.puml'];

interface ModelClass {
  name: string;
  path: string;
  utility: boolean;
  ops: string[];
  diagram: string;
}

function parse(diagram: string): ModelClass[] {
  const text = readFileSync(join(ROOT, 'uml', 'models', diagram), 'utf8');
  const result: ModelClass[] = [];
  const stack: Array<{ kind: 'package'; path: string | null } | { kind: 'class'; cls: ModelClass | null }> = [];
  const currentPath = () => {
    for (let i = stack.length - 1; i >= 0; i--) {
      const f = stack[i];
      if (f.kind === 'package') return f.path;
    }
    return null;
  };
  const currentClass = () => {
    const f = stack[stack.length - 1];
    return f && f.kind === 'class' ? f.cls : null;
  };
  for (const raw of text.split(/\r?\n/)) {
    const line = raw.trim();
    if (line.startsWith("'")) continue;
    const pkg = /^package\s+"([^"]+)"/.exec(line);
    if (pkg) {
      stack.push({ kind: 'package', path: pkg[1].includes('/') ? pkg[1] : null });
      continue;
    }
    const cls = /^(?:abstract\s+class|class|interface|enum)\s+(\w+)/.exec(line);
    if (cls && !currentClass()) {
      const path = currentPath();
      const model = path
        ? { name: cls[1], path, utility: line.includes('<<utility>>'), ops: [], diagram }
        : null;
      if (model) result.push(model);
      if (line.endsWith('{')) stack.push({ kind: 'class', cls: model });
      continue;
    }
    const owner = currentClass();
    if (owner) {
      const op = /^(?:\{(?:static|abstract)\}\s*)?[+\-#~]\s*(\w+)\s*(?:<[^>]*>)?\(/.exec(line);
      if (op) owner.ops.push(op[1]);
    }
    if (line === '}') stack.pop();
  }
  return result;
}

function sourceOf(dir: string): string {
  const abs = join(ROOT, dir);
  return readdirSync(abs)
    .filter((f) => f.endsWith('.ts'))
    .map((f) => readFileSync(join(abs, f), 'utf8'))
    .join('\n');
}

const model = DIAGRAMS.flatMap(parse);

test('диаграммы классов разобраны: пакеты-каталоги и операции найдены', () => {
  assert.ok(model.length >= 30, `классов на диаграммах: ${model.length}`);
  const service = model.find((c) => c.name === 'ValidationService');
  assert.deepEqual(service?.ops, ['validate', 'validateManual', 'denyBadSignature', 'run', 'event']);
  assert.ok(model.find((c) => c.name === 'CheckChain')?.ops.includes('standard'));
});

test('каждый класс диаграммы существует в коде своего каталога вместе с операциями', () => {
  const missing: string[] = [];
  for (const c of model) {
    const src = sourceOf(c.path);
    if (c.utility) {
      for (const op of c.ops) {
        if (!new RegExp(`export\\s+(?:async\\s+)?function\\s+${op}\\b`).test(src)) missing.push(`${c.path}: function ${op}`);
      }
      continue;
    }
    if (!new RegExp(`export\\s+(?:abstract\\s+)?(?:class|interface|type|enum)\\s+${c.name}\\b`).test(src)) {
      missing.push(`${c.path}: ${c.name}`);
    }
    for (const op of c.ops) {
      if (!new RegExp(`\\b${op}\\s*(?:<[^>]*>)?\\(`).test(src)) missing.push(`${c.path}: ${c.name}.${op}()`);
    }
  }
  assert.deepEqual(missing, []);
});

test('каждый экспортируемый класс каталогов модели есть на диаграмме', () => {
  const extra: string[] = [];
  for (const dir of new Set(model.map((c) => c.path))) {
    const names = new Set(model.filter((c) => c.path === dir).map((c) => c.name));
    for (const m of sourceOf(dir).matchAll(/export\s+(?:abstract\s+)?class\s+(\w+)/g)) {
      if (!names.has(m[1])) extra.push(`${dir}: ${m[1]}`);
    }
  }
  assert.deepEqual(extra, []);
});
