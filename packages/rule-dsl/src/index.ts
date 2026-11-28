// Пакет rule-dsl: разбор путей JSONPath-lite, 10 операторов сравнения (Strategy),
// вычисление условий all / any / not и проверка правил по схеме (F04, F05, ADR-0002).
// Не зависит от HTTP-фреймворка и БД (SUP-S-01).

export type OperatorName =
  | 'eq' | 'ne' | 'gt' | 'gte' | 'lt' | 'lte'
  | 'in' | 'contains' | 'regex' | 'exists';

export type LeafCondition = {
  path: string;
  op: OperatorName;
  value?: unknown;
};

export type ConditionExpr =
  | LeafCondition
  | { all: ConditionExpr[] }
  | { any: ConditionExpr[] }
  | { not: ConditionExpr };

export type ActionDefinition = {
  target: string;
  path: string;
  body: Record<string, unknown>;
};

export type RuleDefinition = {
  id: string;
  source: string;
  eventType: string;
  priority: number;
  when: ConditionExpr;
  then: ActionDefinition[];
  cooldownSec?: number;
};

export type ExplainEntry = {
  path: string;
  op: OperatorName;
  expected: unknown;
  actual: unknown;
  matched: boolean;
};

export type RuleValidationError = { path: string; message: string };
export type RuleValidationResult =
  | { ok: true; rule: RuleDefinition }
  | { ok: false; errors: RuleValidationError[] };

export const MAX_CONDITION_DEPTH = 3;

/** Интерфейс стратегии оператора сравнения (SDD 011-patterns: Strategy). */
export interface ComparisonOperator {
  readonly name: OperatorName;
  evaluate(actual: unknown, expected: unknown): boolean;
}

export class EqOperator implements ComparisonOperator {
  readonly name: OperatorName = 'eq';
  evaluate(actual: unknown, expected: unknown): boolean {
    return actual === expected;
  }
}

export class NeOperator implements ComparisonOperator {
  readonly name: OperatorName = 'ne';
  evaluate(actual: unknown, expected: unknown): boolean {
    return actual !== expected;
  }
}

export class NumericOperator implements ComparisonOperator {
  readonly name: OperatorName;
  private readonly cmp: (a: number, b: number) => boolean;
  constructor(name: 'gt' | 'gte' | 'lt' | 'lte', cmp: (a: number, b: number) => boolean) {
    this.name = name;
    this.cmp = cmp;
  }
  evaluate(actual: unknown, expected: unknown): boolean {
    return typeof actual === 'number' && typeof expected === 'number' &&
      Number.isFinite(actual) && Number.isFinite(expected) && this.cmp(actual, expected);
  }
}

export class InOperator implements ComparisonOperator {
  readonly name: OperatorName = 'in';
  evaluate(actual: unknown, expected: unknown): boolean {
    return Array.isArray(expected) && expected.includes(actual);
  }
}

export class ContainsOperator implements ComparisonOperator {
  readonly name: OperatorName = 'contains';
  evaluate(actual: unknown, expected: unknown): boolean {
    if (typeof actual === 'string' && typeof expected === 'string') return actual.includes(expected);
    if (Array.isArray(actual)) return actual.includes(expected);
    return false;
  }
}

export class RegexOperator implements ComparisonOperator {
  readonly name: OperatorName = 'regex';
  evaluate(actual: unknown, expected: unknown): boolean {
    if (typeof actual !== 'string' || typeof expected !== 'string' || expected.length > 256) return false;
    try {
      return new RegExp(expected).test(actual);
    } catch {
      return false;
    }
  }
}

export class ExistsOperator implements ComparisonOperator {
  readonly name: OperatorName = 'exists';
  evaluate(actual: unknown, expected: unknown): boolean {
    const present = actual !== undefined && actual !== null;
    return typeof expected === 'boolean' ? present === expected : present;
  }
}

export const OPERATORS: Record<OperatorName, ComparisonOperator> = {
  eq: new EqOperator(),
  ne: new NeOperator(),
  gt: new NumericOperator('gt', (a, b) => a > b),
  gte: new NumericOperator('gte', (a, b) => a >= b),
  lt: new NumericOperator('lt', (a, b) => a < b),
  lte: new NumericOperator('lte', (a, b) => a <= b),
  in: new InOperator(),
  contains: new ContainsOperator(),
  regex: new RegexOperator(),
  exists: new ExistsOperator(),
};

const PATH_RE = /^\$(?:\.[a-zA-Z_][a-zA-Z0-9_]*)+$/;
const RULE_ID_RE = /^[a-z][a-z0-9-]{1,63}$/;

/** Извлекает значение из объекта события по пути JSONPath-lite вида $.payload.value. */
export function resolvePath(root: unknown, path: string): unknown {
  if (!PATH_RE.test(path)) return undefined;
  const segments = path.slice(2).split('.');
  let cur: unknown = root;
  for (const seg of segments) {
    if (cur === null || typeof cur !== 'object' || Array.isArray(cur)) return undefined;
    cur = (cur as Record<string, unknown>)[seg];
  }
  return cur;
}

function validateCondition(
  node: unknown,
  jsonPath: string,
  depth: number,
  errors: RuleValidationError[],
): void {
  if (depth > MAX_CONDITION_DEPTH) {
    errors.push({ path: jsonPath, message: `превышена максимальная вложенность (${MAX_CONDITION_DEPTH})` });
    return;
  }
  if (!node || typeof node !== 'object' || Array.isArray(node)) {
    errors.push({ path: jsonPath, message: 'ожидался объект условия' });
    return;
  }
  const obj = node as Record<string, unknown>;
  if ('all' in obj || 'any' in obj) {
    const key = 'all' in obj ? 'all' : 'any';
    const items = obj[key];
    if (!Array.isArray(items) || items.length === 0) {
      errors.push({ path: `${jsonPath}.${key}`, message: 'должен быть непустой массив условий' });
      return;
    }
    items.forEach((child, idx) => validateCondition(child, `${jsonPath}.${key}[${idx}]`, depth + 1, errors));
    return;
  }
  if ('not' in obj) {
    validateCondition(obj.not, `${jsonPath}.not`, depth + 1, errors);
    return;
  }
  if (typeof obj.path !== 'string' || !PATH_RE.test(obj.path)) {
    errors.push({ path: `${jsonPath}.path`, message: 'ожидался путь вида $.payload.field' });
  }
  if (typeof obj.op !== 'string' || !(obj.op in OPERATORS)) {
    errors.push({ path: `${jsonPath}.op`, message: 'неизвестный оператор' });
  } else if (obj.op !== 'exists' && obj.value === undefined) {
    errors.push({ path: `${jsonPath}.value`, message: 'отсутствует ожидаемое значение' });
  }
}

/** Проверяет JSON-документ правила (F04, SUP-U-02, REQ-INT-005). */
export function validateRuleDefinition(input: unknown): RuleValidationResult {
  const errors: RuleValidationError[] = [];
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    return { ok: false, errors: [{ path: '$', message: 'ожидался JSON-объект правила' }] };
  }
  const r = input as Record<string, unknown>;
  if (typeof r.id !== 'string' || !RULE_ID_RE.test(r.id)) {
    errors.push({ path: '$.id', message: 'некорректный идентификатор правила' });
  }
  if (typeof r.source !== 'string' || r.source.trim() === '') {
    errors.push({ path: '$.source', message: 'не указан источник' });
  }
  if (typeof r.eventType !== 'string' || r.eventType.trim() === '') {
    errors.push({ path: '$.eventType', message: 'не указан тип события' });
  }
  if (typeof r.priority !== 'number' || !Number.isInteger(r.priority) || r.priority < 0) {
    errors.push({ path: '$.priority', message: 'приоритет должен быть целым числом >= 0' });
  }
  if (r.cooldownSec !== undefined && (typeof r.cooldownSec !== 'number' || !Number.isInteger(r.cooldownSec) || r.cooldownSec < 0)) {
    errors.push({ path: '$.cooldownSec', message: 'cooldownSec должен быть целым числом >= 0' });
  }
  validateCondition(r.when, '$.when', 1, errors);
  if (!Array.isArray(r.then) || r.then.length === 0) {
    errors.push({ path: '$.then', message: 'должно быть задано хотя бы одно действие' });
  } else {
    r.then.forEach((act, idx) => {
      const a = act as Record<string, unknown>;
      if (!a || typeof a !== 'object') {
        errors.push({ path: `$.then[${idx}]`, message: 'ожидался объект действия' });
        return;
      }
      if (typeof a.target !== 'string' || a.target.trim() === '') {
        errors.push({ path: `$.then[${idx}].target`, message: 'не указана цель' });
      }
      if (typeof a.path !== 'string' || !a.path.startsWith('/') || a.path.includes('..')) {
        errors.push({ path: `$.then[${idx}].path`, message: 'путь действия должен начинаться с /' });
      }
      if (!a.body || typeof a.body !== 'object' || Array.isArray(a.body)) {
        errors.push({ path: `$.then[${idx}].body`, message: 'тело действия должно быть объектом' });
      }
    });
  }
  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, rule: input as RuleDefinition };
}

/** Вычислитель условий правила с построением трассы explain (F05, F07). */
export class RuleEvaluator {
  private readonly operators: Record<OperatorName, ComparisonOperator>;

  constructor(operators: Record<OperatorName, ComparisonOperator> = OPERATORS) {
    this.operators = operators;
  }

  evaluate(expr: ConditionExpr, event: unknown): { matched: boolean; explain: ExplainEntry[] } {
    const explain: ExplainEntry[] = [];
    const matched = this.evalNode(expr, event, explain);
    return { matched, explain };
  }

  private evalNode(node: ConditionExpr, event: unknown, explain: ExplainEntry[]): boolean {
    if ('all' in node) return node.all.every((c) => this.evalNode(c, event, explain));
    if ('any' in node) return node.any.some((c) => this.evalNode(c, event, explain));
    if ('not' in node) return !this.evalNode(node.not, event, explain);
    const actual = resolvePath(event, node.path);
    const operator = this.operators[node.op];
    const matched = operator.evaluate(actual, node.value);
    explain.push({ path: node.path, op: node.op, expected: node.value, actual, matched });
    return matched;
  }
}
