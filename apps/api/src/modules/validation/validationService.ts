/**
 * Сервис валидации пропуска (F04, F07; UC-10, UC-02, UC-03; SDD 006, 008, 010, 018).
 * Не зависит от HTTP и PostgreSQL: зависимости передаются через интерфейсы-порты (ADR-0012).
 * Порядок работы — диаграмма последовательности uml/models/sequence-validate-pass.puml:
 *   подпись (без БД) → транзакция { точка, блокировка счётчика, пропуск, присутствие, цепочка,
 *   запись события, изменение присутствия и счётчика } → публикация только после COMMIT.
 */
import {
  decisionOf, normalizePassCode,
  type Direction, type PassSummary, type Reason, type ValidationResponse,
} from '../../../../../packages/contracts/src/index.ts';
import { CheckChain, type CheckpointInfo, type PassRecord } from './checks.ts';

/** Полезная нагрузка QR-токена (совпадает с TokenPayload пакета qr-token). */
export interface TokenPayload {
  passId: string;
  version: number;
}

/** Порт проверки подписи; адаптер — пакет qr-token (verify с секретом из окружения). */
export interface TokenVerifier {
  verify(token: string): TokenPayload | null;
}

/** Порт времени — позволяет тестировать сроки действия без ожидания. */
export interface Clock {
  now(): number;
}

/** Запись журнала access_event (BR-11). */
export interface AccessEventRecord {
  ts: number;
  checkpointId: string;
  passId: string | null;
  controllerId: string;
  direction: Direction;
  decision: 'ALLOW' | 'DENY';
  reason: Reason;
  manual: boolean;
  latencyMs: number;
}

/**
 * Операции внутри одной транзакции БД (Unit of Work, SDD 011).
 * PostgreSQL-адаптер выполняет их в BEGIN … COMMIT; lockCounter — SELECT … FOR UPDATE (ADR-0004).
 */
export interface ValidationTx {
  findCheckpoint(checkpointId: string): Promise<CheckpointInfo | null>;
  lockCounter(siteId: string): Promise<number>;
  findPassById(passId: string): Promise<PassRecord | null>;
  findPassByCode(code: string): Promise<PassRecord | null>;
  isInside(passId: string, siteId: string): Promise<boolean>;
  insertEvent(event: AccessEventRecord): Promise<void>;
  setInside(passId: string, siteId: string, inside: boolean, at: number): Promise<void>;
  addToCounter(siteId: string, delta: 1 | -1): Promise<number>;
}

/** Порт хранилища: выполняет работу атомарно; при исключении — откат. */
export interface ValidationRepository {
  transaction<T>(work: (tx: ValidationTx) => Promise<T>): Promise<T>;
}

/** Событие для панели администратора (сообщения WebSocket `occupancy` и `event`, REQ-INT-006). */
export interface OccupancyEvent {
  siteId: string;
  occupancy: number;
  capacity: number;
  event: AccessEventRecord;
}

/** Порт публикации; адаптер — OccupancyService → RealtimeGateway (ADR-0005). */
export interface OccupancyPublisher {
  publish(event: OccupancyEvent): void;
}

export class CheckpointNotFoundError extends Error {
  readonly status = 404;
  constructor(checkpointId: string) {
    super(`checkpoint not found: ${checkpointId}`);
    this.name = 'CheckpointNotFoundError';
  }
}

export class InvalidPassCodeError extends Error {
  readonly status = 400;
  constructor() {
    super('pass code must match P-NNNNNN or G-NNNNNN');
    this.name = 'InvalidPassCodeError';
  }
}

export interface ValidationServiceDeps {
  repo: ValidationRepository;
  tokens: TokenVerifier;
  publisher: OccupancyPublisher;
  clock: Clock;
  chain?: CheckChain;
}

export interface ValidationCommand {
  checkpointId: string;
  direction: Direction;
  controllerId: string;
}

type PassLookup =
  | { by: 'id'; passId: string; version: number }
  | { by: 'code'; code: string };

export class ValidationService {
  private readonly repo: ValidationRepository;
  private readonly tokens: TokenVerifier;
  private readonly publisher: OccupancyPublisher;
  private readonly clock: Clock;
  private readonly chain: CheckChain;

  constructor(deps: ValidationServiceDeps) {
    this.repo = deps.repo;
    this.tokens = deps.tokens;
    this.publisher = deps.publisher;
    this.clock = deps.clock;
    this.chain = deps.chain ?? CheckChain.standard();
  }

  /** Проверка по QR-токену (UC-02 → UC-10). */
  async validate(cmd: ValidationCommand & { token: string }): Promise<ValidationResponse> {
    const started = this.clock.now();
    const payload = this.tokens.verify(cmd.token);
    if (!payload) return this.denyBadSignature(cmd, started);
    return this.run(cmd, { by: 'id', passId: payload.passId, version: payload.version }, false, started);
  }

  /** Проверка по номеру, введённому вручную (UC-03, F07): та же цепочка без проверки версии. */
  async validateManual(cmd: ValidationCommand & { code: string }): Promise<ValidationResponse> {
    const started = this.clock.now();
    const code = normalizePassCode(cmd.code);
    if (!code) throw new InvalidPassCodeError();
    return this.run(cmd, { by: 'code', code }, true, started);
  }

  /** Неверная подпись: решение без чтения пропуска, но событие журналируется (BR-11). */
  private async denyBadSignature(cmd: ValidationCommand, started: number): Promise<ValidationResponse> {
    await this.repo.transaction(async (tx) => {
      const cp = await tx.findCheckpoint(cmd.checkpointId);
      if (!cp) throw new CheckpointNotFoundError(cmd.checkpointId);
      await tx.insertEvent(this.event(cmd, null, 'DENY_BAD_SIGNATURE', false, started));
    });
    return { decision: 'DENY', reason: 'DENY_BAD_SIGNATURE', pass: null, occupancy: null, capacity: null };
  }

  private async run(
    cmd: ValidationCommand, lookup: PassLookup, manual: boolean, started: number,
  ): Promise<ValidationResponse> {
    const outcome = await this.repo.transaction(async (tx) => {
      const checkpoint = await tx.findCheckpoint(cmd.checkpointId);
      if (!checkpoint) throw new CheckpointNotFoundError(cmd.checkpointId);
      const site = checkpoint.site;
      let occupancy = await tx.lockCounter(site.id);
      const pass = lookup.by === 'id' ? await tx.findPassById(lookup.passId) : await tx.findPassByCode(lookup.code);
      const inside = pass ? await tx.isInside(pass.id, site.id) : false;
      const now = this.clock.now();
      const reason = this.chain.evaluate({
        pass,
        presentedVersion: lookup.by === 'id' ? lookup.version : null,
        checkpoint,
        direction: cmd.direction,
        inside,
        occupancy,
        now,
      });
      const event = this.event(cmd, pass?.id ?? null, reason, manual, started);
      await tx.insertEvent(event);
      if (reason === 'OK' && pass) {
        const enter = cmd.direction === 'IN';
        // при нестрогом anti-passback повторный вход/выход не меняет счётчик
        if (enter !== inside) {
          await tx.setInside(pass.id, site.id, enter, now);
          occupancy = await tx.addToCounter(site.id, enter ? 1 : -1);
        }
      }
      return { reason, pass, occupancy, site, event };
    });
    // публикация только после COMMIT: при откате исключение не дойдёт до этой строки (SDD 010)
    this.publisher.publish({
      siteId: outcome.site.id,
      occupancy: outcome.occupancy,
      capacity: outcome.site.capacity,
      event: outcome.event,
    });
    return {
      decision: decisionOf(outcome.reason),
      reason: outcome.reason,
      pass: outcome.pass ? summary(outcome.pass) : null,
      occupancy: outcome.occupancy,
      capacity: outcome.site.capacity,
    };
  }

  private event(
    cmd: ValidationCommand, passId: string | null, reason: Reason, manual: boolean, started: number,
  ): AccessEventRecord {
    const ts = this.clock.now();
    return {
      ts,
      checkpointId: cmd.checkpointId,
      passId,
      controllerId: cmd.controllerId,
      direction: cmd.direction,
      decision: decisionOf(reason),
      reason,
      manual,
      latencyMs: Math.max(0, ts - started),
    };
  }
}

function summary(pass: PassRecord): PassSummary {
  return {
    code: pass.code,
    holderName: pass.holderName,
    type: pass.type,
    validTo: pass.validTo,
    photoId: pass.photoId,
  };
}
