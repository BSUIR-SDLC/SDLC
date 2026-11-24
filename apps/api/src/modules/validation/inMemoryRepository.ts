/**
 * Адаптер хранилища в памяти для порта ValidationRepository (ADR-0012).
 * Используется в модульных тестах и для локального запуска без PostgreSQL. Поведение повторяет
 * PostgreSQL-адаптер: транзакции выполняются строго по очереди (аналог блокировки строки счётчика
 * FOR UPDATE, ADR-0004), при исключении все изменения откатываются.
 */
import type { CheckpointInfo, PassRecord } from './checks.ts';
import type { AccessEventRecord, ValidationRepository, ValidationTx } from './validationService.ts';

interface State {
  checkpoints: Map<string, CheckpointInfo>;
  passes: Map<string, PassRecord>;
  presence: Map<string, { inside: boolean; changedAt: number }>; // ключ `${passId}|${siteId}`
  counters: Map<string, number>;
  events: AccessEventRecord[];
}

function clone(s: State): State {
  return {
    checkpoints: new Map(s.checkpoints),
    passes: new Map(s.passes),
    presence: new Map(s.presence),
    counters: new Map(s.counters),
    events: [...s.events],
  };
}

export class InMemoryValidationRepository implements ValidationRepository {
  private state: State = {
    checkpoints: new Map(), passes: new Map(), presence: new Map(), counters: new Map(), events: [],
  };
  private queue: Promise<unknown> = Promise.resolve();

  addCheckpoint(cp: CheckpointInfo): void {
    this.state.checkpoints.set(cp.id, cp);
    if (!this.state.counters.has(cp.site.id)) this.state.counters.set(cp.site.id, 0);
  }

  addPass(pass: PassRecord): void {
    this.state.passes.set(pass.id, pass);
  }

  setCounter(siteId: string, value: number): void {
    this.state.counters.set(siteId, value);
  }

  counter(siteId: string): number {
    return this.state.counters.get(siteId) ?? 0;
  }

  events(): readonly AccessEventRecord[] {
    return this.state.events;
  }

  transaction<T>(work: (tx: ValidationTx) => Promise<T>): Promise<T> {
    const run = async (): Promise<T> => {
      const draft = clone(this.state);
      const result = await work(createTx(draft));
      this.state = draft; // COMMIT
      return result;
    };
    const next = this.queue.then(run, run);
    this.queue = next.catch(() => undefined);
    return next;
  }
}

function createTx(s: State): ValidationTx {
  const key = (passId: string, siteId: string) => `${passId}|${siteId}`;
  return {
    async findCheckpoint(id) {
      return s.checkpoints.get(id) ?? null;
    },
    async lockCounter(siteId) {
      return s.counters.get(siteId) ?? 0;
    },
    async findPassById(id) {
      return s.passes.get(id) ?? null;
    },
    async findPassByCode(code) {
      for (const p of s.passes.values()) if (p.code === code) return p;
      return null;
    },
    async isInside(passId, siteId) {
      return s.presence.get(key(passId, siteId))?.inside ?? false;
    },
    async insertEvent(event) {
      s.events.push(event);
    },
    async setInside(passId, siteId, inside, at) {
      s.presence.set(key(passId, siteId), { inside, changedAt: at });
    },
    async addToCounter(siteId, delta) {
      const value = Math.max(0, (s.counters.get(siteId) ?? 0) + delta);
      s.counters.set(siteId, value);
      return value;
    },
  };
}
