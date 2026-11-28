// Сервис реестра целей доставки с защитой от SSRF (F08, UC-06, REQ-INT-003).
import { randomUUID } from 'node:crypto';
import { EmulatorTarget, NotifierTarget } from '../../domain/models.ts';
import type { Target, TargetKind } from '../../domain/models.ts';
import { validateTarget } from './targetPolicy.ts';
import type { ValidationResult } from './targetPolicy.ts';

export interface TargetRepository {
  getTargetByName(name: string): Promise<Target | null>;
  listTargets(): Promise<Target[]>;
  saveTarget(target: Target): Promise<void>;
  cancelActiveDeliveriesForTarget(targetName: string): Promise<number>;
}

/** Проверяет, является ли hostname приватным/служебным IP-адресом (защита от SSRF). */
export function isPrivateOrReservedHost(hostname: string): boolean {
  const h = hostname.toLowerCase().replace(/^\[|\]$/g, '');
  if (h === 'localhost' || h === '::1' || h.startsWith('fe80:') || h.startsWith('fc') || h.startsWith('fd')) {
    return true;
  }
  const m = h.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (!m) return false;
  const [a, b] = [Number(m[1]), Number(m[2])];
  return a === 10 || a === 127 || a === 0 || (a === 169 && b === 254) ||
    (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168);
}

export class TargetService {
  private readonly repo: TargetRepository;
  private readonly allowedHosts: readonly string[];

  constructor(repo: TargetRepository, allowedHosts: readonly string[]) {
    this.repo = repo;
    this.allowedHosts = allowedHosts;
  }

  validateInput(name: string, baseUrl: string): ValidationResult {
    const baseCheck = validateTarget({ name, baseUrl }, this.allowedHosts);
    if (!baseCheck.ok) return baseCheck;
    const hostname = new URL(baseUrl).hostname;
    if (isPrivateOrReservedHost(hostname)) return { ok: false, error: 'SSRF_PRIVATE_HOST' };
    return { ok: true };
  }

  async createTarget(input: { name: string; kind: TargetKind; baseUrl: string; timeoutMs?: number }): Promise<Target> {
    const v = this.validateInput(input.name, input.baseUrl);
    if (!v.ok) throw new Error(v.error);
    const id = randomUUID();
    const target = input.kind === 'EMULATOR'
      ? new EmulatorTarget(id, input.name, input.baseUrl, input.timeoutMs ?? 5000, true)
      : new NotifierTarget(id, input.name, input.baseUrl, input.timeoutMs ?? 5000, true);
    await this.repo.saveTarget(target);
    return target;
  }

  async deleteTarget(name: string): Promise<{ cancelledDeliveries: number }> {
    const target = await this.repo.getTargetByName(name);
    if (!target) throw new Error('TARGET_NOT_FOUND');
    target.enabled = false;
    await this.repo.saveTarget(target);
    const cancelledDeliveries = await this.repo.cancelActiveDeliveriesForTarget(name);
    return { cancelledDeliveries };
  }

  listTargets(): Promise<Target[]> {
    return this.repo.listTargets();
  }
}
