// Движок сопоставления событий с правилами (F05, UC-10, BR-04, BR-05).
// Сортирует активные правила по (priority, id), вычисляет условия через RuleEvaluator,
// проверяет защиту в LoopGuard и создаёт совпадения и доставки в рамках транзакции.
import { randomUUID } from 'node:crypto';
import { RuleEvaluator } from '../../../../../packages/rule-dsl/src/index.ts';
import type { DeliveryRecord, RuleEntity, RuleMatchRecord } from '../../domain/models.ts';
import { initialState } from '../dispatcher/deliveryMachine.ts';
import type { LoopGuard } from '../guard/loopGuard.ts';
import type { WebhookEvent } from '../webhooks/receiveWebhook.ts';

export interface EngineTx {
  insertMatch(match: RuleMatchRecord): Promise<void>;
  insertDelivery(delivery: DeliveryRecord): Promise<void>;
  updateRule(rule: RuleEntity): Promise<void>;
}

export class MatchingEngine {
  private readonly evaluator: RuleEvaluator;
  private readonly guard: LoopGuard;

  constructor(guard: LoopGuard, evaluator: RuleEvaluator = new RuleEvaluator()) {
    this.guard = guard;
    this.evaluator = evaluator;
  }

  /** Выбирает активные правила источника и типа события в порядке возрастания (priority, id). */
  selectRules(rules: readonly RuleEntity[], sourceId: string, eventType: string): RuleEntity[] {
    return rules
      .filter((r) => r.sourceId === sourceId && r.eventType === eventType && r.isEnabled())
      .sort((a, b) => (a.priority - b.priority) || a.id.localeCompare(b.id));
  }

  /** Пробный прогон правила без сохранения (UC-12, F07). */
  dryRun(rule: RuleEntity, event: WebhookEvent) {
    const result = this.evaluator.evaluate(rule.definition.when, event);
    return {
      ruleId: rule.id,
      matched: result.matched,
      explain: result.explain,
      actions: result.matched ? rule.definition.then : [],
    };
  }

  async matchAndEnqueue(
    tx: EngineTx,
    rules: readonly RuleEntity[],
    event: WebhookEvent,
    now: number,
  ): Promise<number> {
    let queued = 0;
    const candidates = this.selectRules(rules, event.sourceId, event.type);

    for (const rule of candidates) {
      const { matched, explain } = this.evaluator.evaluate(rule.definition.when, event);
      if (!matched) continue;

      const verdict = this.guard.check(rule, event.hop, now);
      if (verdict.autoDisabled || rule.cooldownSec > 0) {
        await tx.updateRule(rule);
      }

      const matchId = randomUUID();
      await tx.insertMatch({
        id: matchId,
        eventId: event.eventId,
        ruleId: rule.id,
        ruleVersion: rule.version,
        explain,
      });

      const status = initialState(verdict.allow);
      for (const action of rule.definition.then) {
        await tx.insertDelivery({
          id: randomUUID(),
          matchId,
          eventId: event.eventId,
          ruleId: rule.id,
          targetName: action.target,
          action,
          eventSnapshot: { id: event.eventId, type: event.type, payload: event.payload },
          hop: event.hop,
          status,
          retries: 0,
          nextAttemptAt: now,
          skipReason: verdict.allow ? undefined : verdict.reason,
        });
        if (verdict.allow) queued += 1;
      }
    }
    return queued;
  }
}
