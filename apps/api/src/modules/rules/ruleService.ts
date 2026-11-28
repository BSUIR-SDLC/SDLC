// Сервис управления правилами: CRUD, версионирование, жизненный цикл, импорт и пробный прогон
// (F04, F07, F10, UC-03, UC-11, UC-12, state-rule.puml).
import { validateRuleDefinition } from '../../../../../packages/rule-dsl/src/index.ts';
import type { RuleValidationError } from '../../../../../packages/rule-dsl/src/index.ts';
import { RuleEntity } from '../../domain/models.ts';
import type { MatchingEngine } from '../engine/matchingEngine.ts';
import type { WebhookEvent } from '../webhooks/receiveWebhook.ts';
import type { SourceRepository } from '../sources/sourceService.ts';
import type { TargetRepository } from '../targets/targetService.ts';

export interface RuleRepository {
  getRule(id: string): Promise<RuleEntity | null>;
  listRules(): Promise<RuleEntity[]>;
  saveRule(rule: RuleEntity): Promise<void>;
}

export type ImportReport = {
  created: number;
  updated: number;
  skipped: number;
  errors: { index: number; path: string; message: string }[];
};

export class RuleService {
  private readonly rules: RuleRepository;
  private readonly sources: SourceRepository;
  private readonly targets: TargetRepository;
  private readonly engine: MatchingEngine;

  constructor(
    rules: RuleRepository,
    sources: SourceRepository,
    targets: TargetRepository,
    engine: MatchingEngine,
  ) {
    this.rules = rules;
    this.sources = sources;
    this.targets = targets;
    this.engine = engine;
  }

  private async checkReferences(sourceId: string, targetNames: string[]): Promise<RuleValidationError[]> {
    const errs: RuleValidationError[] = [];
    const src = await this.sources.getSource(sourceId);
    if (!src) errs.push({ path: '$.source', message: `неизвестный источник: ${sourceId}` });
    for (let i = 0; i < targetNames.length; i++) {
      const t = await this.targets.getTargetByName(targetNames[i]);
      if (!t || !t.enabled) {
        errs.push({ path: `$.then[${i}].target`, message: `неизвестная цель: ${targetNames[i]}` });
      }
    }
    return errs;
  }

  async createRule(raw: unknown, authorId: string, now: number): Promise<{ ok: true; rule: RuleEntity } | { ok: false; errors: RuleValidationError[] }> {
    const v = validateRuleDefinition(raw);
    if (!v.ok) return v;
    const refErrs = await this.checkReferences(v.rule.source, v.rule.then.map((a) => a.target));
    if (refErrs.length > 0) return { ok: false, errors: refErrs };
    if (await this.rules.getRule(v.rule.id)) {
      return { ok: false, errors: [{ path: '$.id', message: 'правило с таким id уже существует' }] };
    }
    const entity = new RuleEntity(v.rule, authorId, now);
    await this.rules.saveRule(entity);
    return { ok: true, rule: entity };
  }

  async updateRule(id: string, raw: unknown, authorId: string, now: number): Promise<{ ok: true; rule: RuleEntity } | { ok: false; errors: RuleValidationError[] }> {
    const existing = await this.rules.getRule(id);
    if (!existing) return { ok: false, errors: [{ path: '$.id', message: 'правило не найдено' }] };
    const v = validateRuleDefinition(raw);
    if (!v.ok) return v;
    const refErrs = await this.checkReferences(v.rule.source, v.rule.then.map((a) => a.target));
    if (refErrs.length > 0) return { ok: false, errors: refErrs };
    existing.update(v.rule, authorId, now);
    await this.rules.saveRule(existing);
    return { ok: true, rule: existing };
  }

  async enableRule(id: string): Promise<RuleEntity> {
    const r = await this.rules.getRule(id);
    if (!r) throw new Error('RULE_NOT_FOUND');
    r.enable();
    await this.rules.saveRule(r);
    return r;
  }

  async disableRule(id: string): Promise<RuleEntity> {
    const r = await this.rules.getRule(id);
    if (!r) throw new Error('RULE_NOT_FOUND');
    r.disable();
    await this.rules.saveRule(r);
    return r;
  }

  async archiveRule(id: string): Promise<RuleEntity> {
    const r = await this.rules.getRule(id);
    if (!r) throw new Error('RULE_NOT_FOUND');
    r.archive();
    await this.rules.saveRule(r);
    return r;
  }

  async dryRun(id: string, event: WebhookEvent) {
    const r = await this.rules.getRule(id);
    if (!r) throw new Error('RULE_NOT_FOUND');
    return this.engine.dryRun(r, event);
  }

  /** Импорт массива правил из файла с отчётом (UC-11, F10, activity-import.puml). */
  async importRules(items: unknown[], mode: 'skip' | 'replace', authorId: string, now: number): Promise<ImportReport> {
    const report: ImportReport = { created: 0, updated: 0, skipped: 0, errors: [] };
    for (let idx = 0; idx < items.length; idx++) {
      const v = validateRuleDefinition(items[idx]);
      if (!v.ok) {
        report.errors.push({ index: idx, path: v.errors[0].path, message: v.errors[0].message });
        continue;
      }
      const refErrs = await this.checkReferences(v.rule.source, v.rule.then.map((a) => a.target));
      if (refErrs.length > 0) {
        report.errors.push({ index: idx, path: refErrs[0].path, message: refErrs[0].message });
        continue;
      }
      const existing = await this.rules.getRule(v.rule.id);
      if (existing) {
        if (mode === 'replace') {
          existing.update(v.rule, authorId, now);
          await this.rules.saveRule(existing);
          report.updated += 1;
        } else {
          report.skipped += 1;
        }
      } else {
        await this.rules.saveRule(new RuleEntity(v.rule, authorId, now));
        report.created += 1;
      }
    }
    return report;
  }

  listRules(): Promise<RuleEntity[]> {
    return this.rules.listRules();
  }
}
