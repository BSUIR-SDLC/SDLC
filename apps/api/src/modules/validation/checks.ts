/**
 * Цепочка проверок пропуска (F04, BR-01, REQ-FUNC-004; SDD 008, 011 — паттерн «Цепочка обязанностей»).
 * Каждая проверка — отдельный класс, реализующий интерфейс PassCheck; CheckChain вызывает их по порядку
 * и возвращает код первой нарушенной. Проверка подписи выполняется раньше, без БД (ValidationService).
 * Классы и связи — диаграмма классов uml/models/class-validation.puml (сверяется тестом, ADR-0011).
 */
import type { Direction, PassType, Reason } from '../../../../../packages/contracts/src/index.ts';

/** Правила объекта, влияющие на решение (поля site модели данных SDD 004). */
export interface SiteRules {
  id: string;
  capacity: number;
  antipassbackStrict: boolean;
  capacityLock: boolean;
}

/** Точка прохода с зоной и объектом. */
export interface CheckpointInfo {
  id: string;
  zoneId: string;
  site: SiteRules;
}

/** Пропуск в том виде, в котором его читает валидация. */
export interface PassRecord {
  id: string;
  code: string;
  holderName: string;
  photoId: string | null;
  type: PassType;
  validFrom: number; // мс epoch
  validTo: number;
  status: 'ACTIVE' | 'REVOKED';
  version: number;
  zoneIds: readonly string[];
}

/** Всё, что нужно проверкам; собирается ValidationService внутри транзакции. */
export interface ValidationContext {
  pass: PassRecord | null;
  /** Версия из QR-токена; null — ручной ввод номера (F07), версия не проверяется. */
  presentedVersion: number | null;
  checkpoint: CheckpointInfo;
  direction: Direction;
  /** Пропуск сейчас внутри объекта (presence.inside). */
  inside: boolean;
  /** Значение счётчика объекта под блокировкой FOR UPDATE (ADR-0004). */
  occupancy: number;
  now: number;
}

/** Одна проверка цепочки: код отказа или null, если проверка пройдена. */
export interface PassCheck {
  readonly name: string;
  check(ctx: ValidationContext): Reason | null;
}

export class PassExistsCheck implements PassCheck {
  readonly name = 'существование';
  check(ctx: ValidationContext): Reason | null {
    return ctx.pass ? null : 'DENY_NOT_FOUND';
  }
}

/** Отзыв и версия (BR-05): QR прежней версии получает DENY_REVOKED. */
export class RevocationCheck implements PassCheck {
  readonly name = 'отзыв и версия';
  check(ctx: ValidationContext): Reason | null {
    const pass = ctx.pass;
    if (!pass) return null;
    if (pass.status === 'REVOKED') return 'DENY_REVOKED';
    if (ctx.presentedVersion !== null && ctx.presentedVersion !== pass.version) return 'DENY_REVOKED';
    return null;
  }
}

/** Срок действия: valid_from ≤ now ≤ valid_to. */
export class ValidityPeriodCheck implements PassCheck {
  readonly name = 'срок';
  check(ctx: ValidationContext): Reason | null {
    const pass = ctx.pass;
    if (!pass) return null;
    return ctx.now >= pass.validFrom && ctx.now <= pass.validTo ? null : 'DENY_EXPIRED';
  }
}

/** Зона точки прохода должна входить в зоны пропуска. */
export class ZoneCheck implements PassCheck {
  readonly name = 'зона';
  check(ctx: ValidationContext): Reason | null {
    const pass = ctx.pass;
    if (!pass) return null;
    return pass.zoneIds.includes(ctx.checkpoint.zoneId) ? null : 'DENY_ZONE';
  }
}

/** Anti-passback (BR-04): при строгом режиме нельзя войти дважды и выйти, не войдя. */
export class AntiPassbackCheck implements PassCheck {
  readonly name = 'anti-passback';
  check(ctx: ValidationContext): Reason | null {
    if (!ctx.pass || !ctx.checkpoint.site.antipassbackStrict) return null;
    if (ctx.direction === 'IN' && ctx.inside) return 'DENY_ALREADY_INSIDE';
    if (ctx.direction === 'OUT' && !ctx.inside) return 'DENY_NOT_INSIDE';
    return null;
  }
}

/** Вместимость (REQ-FUNC-010, BR-04): при блокировке вход запрещён на 100 %, выход разрешён всегда. */
export class CapacityCheck implements PassCheck {
  readonly name = 'вместимость';
  check(ctx: ValidationContext): Reason | null {
    const site = ctx.checkpoint.site;
    if (!ctx.pass || ctx.direction !== 'IN' || !site.capacityLock) return null;
    return ctx.occupancy >= site.capacity ? 'DENY_CAPACITY' : null;
  }
}

/** Упорядоченная цепочка проверок; порядок задан BR-01. */
export class CheckChain {
  private readonly checks: readonly PassCheck[];

  constructor(checks: readonly PassCheck[]) {
    this.checks = checks;
  }

  /** Стандартный порядок BR-01 (после подписи): существование → отзыв → срок → зона → anti-passback → вместимость. */
  static standard(): CheckChain {
    return new CheckChain([
      new PassExistsCheck(),
      new RevocationCheck(),
      new ValidityPeriodCheck(),
      new ZoneCheck(),
      new AntiPassbackCheck(),
      new CapacityCheck(),
    ]);
  }

  /** Код первой нарушенной проверки или OK. */
  evaluate(ctx: ValidationContext): Reason {
    for (const c of this.checks) {
      const reason = c.check(ctx);
      if (reason) return reason;
    }
    return 'OK';
  }

  names(): string[] {
    return this.checks.map((c) => c.name);
  }
}
