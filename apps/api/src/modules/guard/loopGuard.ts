// Защита от петель (F21, ADR-0008, BR-06, BR-07, BR-08).
// Проверяет глубину переходов X-Hop < 3, паузу повторного срабатывания cooldownSec
// и автоотключение правила при более чем 20 срабатываниях за 60 секунд.
import type { RuleEntity } from '../../domain/models.ts';

export const MAX_HOPS = 3;
export const RATE_WINDOW_MS = 60_000;
export const MAX_TRIGGERS_PER_MINUTE = 20;

export type GuardVerdict =
  | { allow: true; autoDisabled: boolean }
  | { allow: false; reason: 'HOP_LIMIT' | 'COOLDOWN' | 'RULE_DISABLED'; autoDisabled: boolean };

export class LoopGuard {
  private readonly triggerLog = new Map<string, number[]>();

  check(rule: RuleEntity, hop: number, now: number): GuardVerdict {
    if (!rule.isEnabled()) {
      return { allow: false, reason: 'RULE_DISABLED', autoDisabled: false };
    }
    if (hop >= MAX_HOPS) {
      return { allow: false, reason: 'HOP_LIMIT', autoDisabled: false };
    }
    if (rule.state === 'cooldown' && now < rule.cooldownUntil) {
      return { allow: false, reason: 'COOLDOWN', autoDisabled: false };
    }
    if (rule.state === 'cooldown' && now >= rule.cooldownUntil) {
      rule.state = 'ready';
    }
    if (rule.cooldownSec > 0) {
      rule.state = 'cooldown';
      rule.cooldownUntil = now + rule.cooldownSec * 1000;
    }

    const autoDisabled = this.recordAndCheckRate(rule, now);
    return { allow: true, autoDisabled };
  }

  private recordAndCheckRate(rule: RuleEntity, now: number): boolean {
    const key = `${rule.sourceId}:${rule.id}`;
    const recent = (this.triggerLog.get(key) ?? []).filter((ts) => now - ts < RATE_WINDOW_MS);
    recent.push(now);
    this.triggerLog.set(key, recent);
    if (recent.length > MAX_TRIGGERS_PER_MINUTE) {
      rule.autoDisable(`RATE_EXCEEDED: ${recent.length} срабатываний за 60 с`);
      return true;
    }
    return false;
  }
}
