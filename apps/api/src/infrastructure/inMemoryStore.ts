// Адаптер хранения в памяти для интеграционных тестов и автономного запуска (ADR-0001, ADR-0004).
import { Administrator, Operator } from '../domain/models.ts';
import type { DeliveryRecord, RuleEntity, RuleMatchRecord, Target, User } from '../domain/models.ts';
import type { UserRepository } from '../modules/auth/authService.ts';
import type { DeliveryRepository } from '../modules/dispatcher/actionDispatcher.ts';
import { step } from '../modules/dispatcher/deliveryMachine.ts';
import type { EngineTx, MatchingEngine } from '../modules/engine/matchingEngine.ts';
import type { RuleRepository } from '../modules/rules/ruleService.ts';
import type { SourceRepository, StoredSource } from '../modules/sources/sourceService.ts';
import type { TargetRepository } from '../modules/targets/targetService.ts';
import type { Deps, Tx, WebhookEvent } from '../modules/webhooks/receiveWebhook.ts';

export class InMemoryStore
  implements UserRepository, SourceRepository, TargetRepository, RuleRepository, DeliveryRepository
{
  private readonly usersByLogin = new Map<string, User>();
  private readonly sources = new Map<string, StoredSource>();
  private readonly targets = new Map<string, Target>();
  private readonly rules = new Map<string, RuleEntity>();
  private readonly events = new Map<string, WebhookEvent>();
  private readonly matches: RuleMatchRecord[] = [];
  private readonly deliveries = new Map<string, DeliveryRecord>();
  private paused = false;

  addUser(user: User): void {
    this.usersByLogin.set(user.getLogin(), user);
  }

  async findByLogin(login: string): Promise<User | null> {
    return this.usersByLogin.get(login) ?? null;
  }

  async saveLoginState(userId: string, failedAttempts: number, lockedUntil: number | null): Promise<void> {
    for (const [login, user] of this.usersByLogin.entries()) {
      if (user.getId() === userId) {
        const updated = user.getRole() === 'admin'
          ? new Administrator(user.getId(), login, user.getPasswordHash(), failedAttempts, lockedUntil)
          : new Operator(user.getId(), login, user.getPasswordHash(), failedAttempts, lockedUntil);
        this.usersByLogin.set(login, updated);
        return;
      }
    }
  }

  async getSource(id: string): Promise<StoredSource | null> {
    return this.sources.get(id) ?? null;
  }

  async listSources(): Promise<StoredSource[]> {
    return [...this.sources.values()];
  }

  async saveSource(source: StoredSource): Promise<void> {
    this.sources.set(source.id, { ...source });
  }

  async getTargetByName(name: string): Promise<Target | null> {
    return this.targets.get(name) ?? null;
  }

  async listTargets(): Promise<Target[]> {
    return [...this.targets.values()];
  }

  async saveTarget(target: Target): Promise<void> {
    this.targets.set(target.name, target);
  }

  async cancelActiveDeliveriesForTarget(targetName: string): Promise<number> {
    let count = 0;
    for (const d of this.deliveries.values()) {
      if (d.targetName === targetName && ['queued', 'sending', 'retryWait', 'paused'].includes(d.status)) {
        d.status = step(d.status, 'TARGET_DELETED', { retries: d.retries }).state;
        count += 1;
      }
    }
    return count;
  }

  async getRule(id: string): Promise<RuleEntity | null> {
    return this.rules.get(id) ?? null;
  }

  async listRules(): Promise<RuleEntity[]> {
    return [...this.rules.values()];
  }

  async saveRule(rule: RuleEntity): Promise<void> {
    this.rules.set(rule.id, rule);
  }

  async pickNextDue(now: number): Promise<DeliveryRecord | null> {
    for (const d of this.deliveries.values()) {
      if ((d.status === 'queued' || d.status === 'retryWait') && d.nextAttemptAt <= now) {
        return d;
      }
    }
    return null;
  }

  async saveDelivery(delivery: DeliveryRecord): Promise<void> {
    this.deliveries.set(delivery.id, delivery);
  }

  async isGloballyPaused(): Promise<boolean> {
    return this.paused;
  }

  async setGlobalPause(paused: boolean): Promise<number> {
    this.paused = paused;
    let changed = 0;
    for (const d of this.deliveries.values()) {
      if (paused && d.status === 'queued') {
        d.status = step('queued', 'GLOBAL_PAUSE').state;
        changed += 1;
      } else if (!paused && d.status === 'paused') {
        d.status = step('paused', 'RESUME').state;
        changed += 1;
      }
    }
    return changed;
  }

  getJournal(): { events: WebhookEvent[]; matches: RuleMatchRecord[]; deliveries: DeliveryRecord[] } {
    return {
      events: [...this.events.values()],
      matches: [...this.matches],
      deliveries: [...this.deliveries.values()],
    };
  }

  /** Собирает зависимости для handleWebhook с атомарным откатом транзакции при сбое (ADR-0004). */
  createWebhookDeps(engine: MatchingEngine, now: () => number): Deps {
    return {
      getSource: (id) => this.getSource(id),
      transaction: async <T>(fn: (tx: Tx) => Promise<T>): Promise<T> => {
        const eventsSnap = new Map(this.events);
        const matchesLen = this.matches.length;
        const deliveriesSnap = new Map(this.deliveries);
        try {
          const tx: Tx & EngineTx = {
            insertEventIfAbsent: async (e) => {
              const key = `${e.sourceId}/${e.eventId}`;
              if (this.events.has(key)) return false;
              this.events.set(key, e);
              return true;
            },
            insertMatch: async (m) => { this.matches.push(m); },
            insertDelivery: async (d) => { this.deliveries.set(d.id, d); },
            updateRule: async (r) => { this.rules.set(r.id, r); },
          };
          return await fn(tx);
        } catch (err) {
          this.events.clear();
          for (const [k, v] of eventsSnap) this.events.set(k, v);
          this.matches.length = matchesLen;
          this.deliveries.clear();
          for (const [k, v] of deliveriesSnap) this.deliveries.set(k, v);
          throw err;
        }
      },
      matchAndEnqueue: (tx, event) =>
        engine.matchAndEnqueue(tx as Tx & EngineTx, [...this.rules.values()], event, now()),
      now,
    };
  }
}
