/**
 * Управление пропусками (F08; UC-04; BR-02, BR-03, BR-05; SDD 017).
 * Операции соответствуют переходам диаграммы состояний uml/models/state-pass-lifecycle.puml:
 * выпуск (version = 1), продление, отзыв и перевыпуск (version + 1), удаление.
 * Статус «ожидает / активен / просрочен» вычисляется по времени и не хранится (lifecycleOf).
 */
import { normalizePassCode, type PassType } from '../../../../../packages/contracts/src/index.ts';

export type StoredStatus = 'ACTIVE' | 'REVOKED';
/** Статус жизненного цикла (глоссарий: PassStatus); DELETED — запись удалена и не читается. */
export type PassStatus = 'PENDING' | 'ACTIVE' | 'EXPIRED' | 'REVOKED';

export interface Pass {
  id: string;
  code: string;
  holderId: string;
  type: PassType;
  validFrom: number;
  validTo: number;
  status: StoredStatus;
  version: number;
  zoneIds: string[];
}

export interface IssuePassInput {
  holderId: string;
  type: PassType;
  validFrom: number;
  validTo: number;
  zoneIds: string[];
}

/** Порт хранилища пропусков; PostgreSQL-адаптер использует последовательности pass_code_p / pass_code_g. */
export interface PassRepository {
  nextNumber(type: PassType): Promise<number>;
  insert(pass: Pass): Promise<void>;
  findById(id: string): Promise<Pass | null>;
  findByCode(code: string): Promise<Pass | null>;
  update(pass: Pass): Promise<void>;
  delete(id: string): Promise<void>;
}

/** Порт подписи QR; адаптер — sign() пакета qr-token. */
export interface QrSigner {
  sign(payload: { passId: string; version: number }): string;
}

/** Порт генерации идентификаторов (crypto.randomUUID в рабочем окружении). */
export interface IdGenerator {
  newId(): string;
}

export const DAY_MS = 24 * 60 * 60 * 1000;
/** BR-03: гостевой пропуск — не дольше суток, пропуск сотрудника — не дольше года. */
export const MAX_DURATION_MS: Readonly<Record<PassType, number>> = {
  GUEST: DAY_MS,
  EMPLOYEE: 365 * DAY_MS,
};

export class PassRuleError extends Error {
  readonly status = 400;
  constructor(message: string) {
    super(message);
    this.name = 'PassRuleError';
  }
}

export class PassNotFoundError extends Error {
  readonly status = 404;
  constructor(id: string) {
    super(`pass not found: ${id}`);
    this.name = 'PassNotFoundError';
  }
}

/** Номер пропуска по BR-02: P-NNNNNN — сотрудник, G-NNNNNN — гость. */
export function formatPassCode(type: PassType, n: number): string {
  if (!Number.isInteger(n) || n < 1 || n > 999_999) throw new PassRuleError('pass number out of range');
  return `${type === 'EMPLOYEE' ? 'P' : 'G'}-${String(n).padStart(6, '0')}`;
}

/** Статус жизненного цикла на момент now. */
export function lifecycleOf(pass: Pick<Pass, 'status' | 'validFrom' | 'validTo'>, now: number): PassStatus {
  if (pass.status === 'REVOKED') return 'REVOKED';
  if (now < pass.validFrom) return 'PENDING';
  if (now > pass.validTo) return 'EXPIRED';
  return 'ACTIVE';
}

function assertPeriod(type: PassType, validFrom: number, validTo: number): void {
  if (!(validTo > validFrom)) throw new PassRuleError('validTo must be after validFrom');
  if (validTo - validFrom > MAX_DURATION_MS[type]) {
    throw new PassRuleError(type === 'GUEST' ? 'guest pass is valid for at most 24 h' : 'employee pass is valid for at most 1 year');
  }
}

export interface IssuedPass {
  pass: Pass;
  token: string;
}

export class PassService {
  private readonly repo: PassRepository;
  private readonly signer: QrSigner;
  private readonly ids: IdGenerator;

  constructor(deps: { repo: PassRepository; signer: QrSigner; ids: IdGenerator }) {
    this.repo = deps.repo;
    this.signer = deps.signer;
    this.ids = deps.ids;
  }

  /** Выпуск: новый номер, version = 1, QR-токен. */
  async issue(input: IssuePassInput): Promise<IssuedPass> {
    assertPeriod(input.type, input.validFrom, input.validTo);
    if (input.zoneIds.length === 0) throw new PassRuleError('pass must grant at least one zone');
    const code = formatPassCode(input.type, await this.repo.nextNumber(input.type));
    const pass: Pass = {
      id: this.ids.newId(),
      code,
      holderId: input.holderId,
      type: input.type,
      validFrom: input.validFrom,
      validTo: input.validTo,
      status: 'ACTIVE',
      version: 1,
      zoneIds: [...new Set(input.zoneIds)],
    };
    await this.repo.insert(pass);
    return { pass, token: this.tokenOf(pass) };
  }

  /** Продление срока (BR-03 применяется к новому сроку); версия не меняется — QR остаётся прежним. */
  async extend(id: string, validTo: number): Promise<Pass> {
    const pass = await this.get(id);
    if (pass.status === 'REVOKED') throw new PassRuleError('revoked pass cannot be extended');
    assertPeriod(pass.type, pass.validFrom, validTo);
    const updated = { ...pass, validTo };
    await this.repo.update(updated);
    return updated;
  }

  /** Отзыв (BR-05): статус REVOKED и version + 1 — все выданные QR недействительны. */
  async revoke(id: string): Promise<Pass> {
    const pass = await this.get(id);
    if (pass.status === 'REVOKED') return pass;
    const updated: Pass = { ...pass, status: 'REVOKED', version: pass.version + 1 };
    await this.repo.update(updated);
    return updated;
  }

  /** Перевыпуск (BR-05): version + 1, пропуск снова активен, новый QR; номер сохраняется. */
  async reissue(id: string): Promise<IssuedPass> {
    const pass = await this.get(id);
    const updated: Pass = { ...pass, status: 'ACTIVE', version: pass.version + 1 };
    await this.repo.update(updated);
    return { pass: updated, token: this.tokenOf(updated) };
  }

  /** Поиск по номеру, введённому вручную (F07). */
  async findByCode(input: string): Promise<Pass | null> {
    const code = normalizePassCode(input);
    return code ? this.repo.findByCode(code) : null;
  }

  /** Удаление по запросу владельца (BR-09). */
  async remove(id: string): Promise<void> {
    await this.get(id);
    await this.repo.delete(id);
  }

  tokenOf(pass: Pass): string {
    return this.signer.sign({ passId: pass.id, version: pass.version });
  }

  private async get(id: string): Promise<Pass> {
    const pass = await this.repo.findById(id);
    if (!pass) throw new PassNotFoundError(id);
    return pass;
  }
}

/** Адаптер в памяти для порта PassRepository (тесты, локальный запуск). */
export class InMemoryPassRepository implements PassRepository {
  private readonly passes = new Map<string, Pass>();
  private readonly counters: Record<PassType, number> = { EMPLOYEE: 0, GUEST: 0 };

  async nextNumber(type: PassType): Promise<number> {
    this.counters[type] += 1;
    return this.counters[type];
  }

  async insert(pass: Pass): Promise<void> {
    if ([...this.passes.values()].some((p) => p.code === pass.code)) throw new PassRuleError('duplicate pass code');
    this.passes.set(pass.id, { ...pass });
  }

  async findById(id: string): Promise<Pass | null> {
    const p = this.passes.get(id);
    return p ? { ...p } : null;
  }

  async findByCode(code: string): Promise<Pass | null> {
    for (const p of this.passes.values()) if (p.code === code) return { ...p };
    return null;
  }

  async update(pass: Pass): Promise<void> {
    if (!this.passes.has(pass.id)) throw new PassNotFoundError(pass.id);
    this.passes.set(pass.id, { ...pass });
  }

  async delete(id: string): Promise<void> {
    this.passes.delete(id);
  }
}
