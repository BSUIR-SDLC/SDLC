// Предметная модель RuleHook (SDD 004-information, UML class-domain.puml).
// Содержит иерархии наследования User -> Operator / Administrator и Target -> EmulatorTarget / NotifierTarget,
// а также агрегатные сущности Rule (с RuleVersion), WebhookEvent, RuleMatch и Delivery.
import type { ActionDefinition, ExplainEntry, RuleDefinition } from '../../../../packages/rule-dsl/src/index.ts';
import { PERMISSIONS } from '../modules/auth/authPolicy.ts';
import type { Role } from '../modules/auth/authPolicy.ts';
import { validateTarget, renderPath, joinUrl } from '../modules/targets/targetPolicy.ts';
import type { ValidationResult } from '../modules/targets/targetPolicy.ts';
import type { DeliveryState } from '../modules/dispatcher/deliveryMachine.ts';

export type RuleLifecycleState = 'disabled' | 'ready' | 'cooldown' | 'auto_disabled' | 'archived';
export type TargetKind = 'EMULATOR' | 'NOTIFIER';

/** Абстрактный пользователь консоли (обобщает Operator и Administrator). */
export abstract class User {
  protected readonly id: string;
  protected readonly login: string;
  protected readonly passwordHash: string;
  protected readonly role: Role;
  protected failedAttempts: number;
  protected lockedUntil: number | null;

  constructor(
    id: string,
    login: string,
    passwordHash: string,
    role: Role,
    failedAttempts = 0,
    lockedUntil: number | null = null,
  ) {
    this.id = id;
    this.login = login;
    this.passwordHash = passwordHash;
    this.role = role;
    this.failedAttempts = failedAttempts;
    this.lockedUntil = lockedUntil;
  }

  getId(): string { return this.id; }
  getLogin(): string { return this.login; }
  getRole(): Role { return this.role; }
  getPasswordHash(): string { return this.passwordHash; }
  getLoginState(): { failedAttempts: number; lockedUntil: number | null } {
    return { failedAttempts: this.failedAttempts, lockedUntil: this.lockedUntil };
  }

  isLocked(now: number): boolean {
    return this.lockedUntil !== null && now < this.lockedUntil;
  }

  can(permission: string): boolean {
    return this.getPermissions().includes(permission);
  }

  abstract getPermissions(): readonly string[];
}

export class Operator extends User {
  constructor(id: string, login: string, passwordHash: string, failedAttempts = 0, lockedUntil: number | null = null) {
    super(id, login, passwordHash, 'operator', failedAttempts, lockedUntil);
  }
  getPermissions(): readonly string[] {
    return PERMISSIONS.operator;
  }
}

export class Administrator extends User {
  constructor(id: string, login: string, passwordHash: string, failedAttempts = 0, lockedUntil: number | null = null) {
    super(id, login, passwordHash, 'admin', failedAttempts, lockedUntil);
  }
  getPermissions(): readonly string[] {
    return PERMISSIONS.admin;
  }
}

export type OutgoingRequest = {
  url: string;
  headers: Record<string, string>;
  body: Record<string, unknown>;
  timeoutMs: number;
};

/** Базовый класс цели доставки; наследники формируют тело запроса под протокол получателя. */
export abstract class Target {
  readonly id: string;
  readonly name: string;
  readonly kind: TargetKind;
  readonly baseUrl: string;
  readonly timeoutMs: number;
  enabled: boolean;

  constructor(id: string, name: string, kind: TargetKind, baseUrl: string, timeoutMs = 5000, enabled = true) {
    this.id = id;
    this.name = name;
    this.kind = kind;
    this.baseUrl = baseUrl;
    this.timeoutMs = timeoutMs;
    this.enabled = enabled;
  }

  validate(allowedHosts: readonly string[]): ValidationResult {
    return validateTarget({ name: this.name, baseUrl: this.baseUrl }, allowedHosts);
  }

  buildRequest(
    pathTemplate: string,
    renderedBody: Record<string, unknown>,
    event: Record<string, unknown>,
    deliveryId: string,
    nextHop: number,
  ): OutgoingRequest {
    const path = renderPath(pathTemplate, event);
    return {
      url: joinUrl(this.baseUrl, path),
      headers: {
        'content-type': 'application/json',
        'idempotency-key': deliveryId,
        'x-hop': String(nextHop),
      },
      body: this.formatBody(renderedBody),
      timeoutMs: this.timeoutMs,
    };
  }

  protected abstract formatBody(renderedBody: Record<string, unknown>): Record<string, unknown>;
}

export class EmulatorTarget extends Target {
  constructor(id: string, name: string, baseUrl: string, timeoutMs = 5000, enabled = true) {
    super(id, name, 'EMULATOR', baseUrl, timeoutMs, enabled);
  }
  protected formatBody(renderedBody: Record<string, unknown>): Record<string, unknown> {
    return { ...renderedBody, source: 'rulehook' };
  }
}

export class NotifierTarget extends Target {
  constructor(id: string, name: string, baseUrl: string, timeoutMs = 5000, enabled = true) {
    super(id, name, 'NOTIFIER', baseUrl, timeoutMs, enabled);
  }
  protected formatBody(renderedBody: Record<string, unknown>): Record<string, unknown> {
    return { channel: 'default', ...renderedBody };
  }
}

export type RuleVersion = {
  readonly ruleId: string;
  readonly version: number;
  readonly definition: RuleDefinition;
  readonly authorId: string;
  readonly createdAt: number;
};

/** Правило обработки событий; владеет историей версий (композиция Rule *-- RuleVersion). */
export class RuleEntity {
  readonly id: string;
  readonly sourceId: string;
  eventType: string;
  priority: number;
  version: number;
  state: RuleLifecycleState;
  definition: RuleDefinition;
  cooldownSec: number;
  cooldownUntil: number;
  disabledReason: string | null;
  readonly versions: RuleVersion[];

  constructor(definition: RuleDefinition, authorId: string, now: number) {
    this.id = definition.id;
    this.sourceId = definition.source;
    this.eventType = definition.eventType;
    this.priority = definition.priority;
    this.version = 1;
    this.state = 'disabled'; // новые и импортированные правила создаются выключенными (UC-03, UC-11)
    this.definition = definition;
    this.cooldownSec = definition.cooldownSec ?? 0;
    this.cooldownUntil = 0;
    this.disabledReason = null;
    this.versions = [{ ruleId: this.id, version: 1, definition, authorId, createdAt: now }];
  }

  isEnabled(): boolean {
    return this.state === 'ready' || this.state === 'cooldown';
  }

  update(definition: RuleDefinition, authorId: string, now: number): number {
    if (this.state === 'archived') throw new Error('RULE_ARCHIVED');
    this.version += 1;
    this.eventType = definition.eventType;
    this.priority = definition.priority;
    this.cooldownSec = definition.cooldownSec ?? 0;
    this.definition = definition;
    this.versions.push({ ruleId: this.id, version: this.version, definition, authorId, createdAt: now });
    return this.version;
  }

  enable(): void {
    if (this.state === 'archived') throw new Error('RULE_ARCHIVED');
    this.state = 'ready';
    this.disabledReason = null;
    this.cooldownUntil = 0;
  }

  disable(reason: string | null = null): void {
    if (this.state === 'archived') throw new Error('RULE_ARCHIVED');
    this.state = 'disabled';
    this.disabledReason = reason;
  }

  autoDisable(reason: string): void {
    this.state = 'auto_disabled';
    this.disabledReason = reason;
  }

  archive(): void {
    if (this.isEnabled()) throw new Error('DISABLE_BEFORE_ARCHIVE');
    this.state = 'archived';
  }
}

export type RuleMatchRecord = {
  readonly id: string;
  readonly eventId: string;
  readonly ruleId: string;
  readonly ruleVersion: number;
  readonly explain: ExplainEntry[];
};

export type DeliveryRecord = {
  id: string;
  matchId: string;
  eventId: string;
  ruleId: string;
  targetName: string;
  action: ActionDefinition;
  eventSnapshot: Record<string, unknown>;
  hop: number;
  status: DeliveryState;
  retries: number;
  nextAttemptAt: number;
  skipReason?: string;
  lastStatusCode?: number;
};
