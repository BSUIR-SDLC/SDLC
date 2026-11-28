// Исполнитель действий и воркер очереди доставок (F06, UC-09, ADR-0006, BR-09, BR-10).
import type { DeliveryRecord, Target } from '../../domain/models.ts';
import { backoffMs, classify, step } from './deliveryMachine.ts';

export type HttpResponse = { status?: number; networkError?: boolean };

export interface HttpClient {
  post(url: string, headers: Record<string, string>, body: Record<string, unknown>, timeoutMs: number): Promise<HttpResponse>;
}

export interface DeliveryRepository {
  pickNextDue(now: number): Promise<DeliveryRecord | null>;
  getTargetByName(name: string): Promise<Target | null>;
  saveDelivery(delivery: DeliveryRecord): Promise<void>;
  isGloballyPaused(): Promise<boolean>;
}

/** Безопасная подстановка {{payload.x}} в строки тела действия без eval (REQ-SEC-004). */
export function renderBody(template: Record<string, unknown>, event: Record<string, unknown>): Record<string, unknown> {
  const renderValue = (val: unknown): unknown => {
    if (typeof val === 'string') {
      return val.replace(/\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}/g, (_m, path: string) => {
        let cur: any = event;
        for (const key of path.split('.')) cur = cur == null ? undefined : cur[key];
        return cur === undefined || cur === null || typeof cur === 'object' ? '' : String(cur);
      });
    }
    if (Array.isArray(val)) return val.map(renderValue);
    if (val && typeof val === 'object') {
      const out: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(val)) out[k] = renderValue(v);
      return out;
    }
    return val;
  };
  return renderValue(template) as Record<string, unknown>;
}

export class ActionDispatcher {
  private readonly repo: DeliveryRepository;
  private readonly httpClient: HttpClient;

  constructor(repo: DeliveryRepository, httpClient: HttpClient) {
    this.repo = repo;
    this.httpClient = httpClient;
  }

  async dispatch(delivery: DeliveryRecord, now: number): Promise<DeliveryRecord> {
    const target = await this.repo.getTargetByName(delivery.targetName);
    if (!target || !target.enabled) {
      const next = step(delivery.status, 'TARGET_DELETED', { retries: delivery.retries });
      delivery.status = next.state;
      await this.repo.saveDelivery(delivery);
      return delivery;
    }

    const startEvent = delivery.status === 'retryWait' ? 'BACKOFF_ELAPSED' : 'WORKER_PICKED';
    const picked = step(delivery.status, startEvent, { retries: delivery.retries });
    delivery.status = picked.state;

    const renderedBody = renderBody(delivery.action.body, delivery.eventSnapshot);
    const req = target.buildRequest(delivery.action.path, renderedBody, delivery.eventSnapshot, delivery.id, delivery.hop + 1);
    const resp = await this.httpClient.post(req.url, req.headers, req.body, req.timeoutMs);

    delivery.lastStatusCode = resp.status;
    const ev = classify(resp);
    const next = step(delivery.status, ev, { retries: delivery.retries });
    delivery.status = next.state;
    delivery.retries = next.ctx.retries;
    if (delivery.status === 'retryWait') {
      delivery.nextAttemptAt = now + backoffMs(delivery.retries);
    }
    await this.repo.saveDelivery(delivery);
    return delivery;
  }
}

export class DeliveryWorker {
  private readonly repo: DeliveryRepository;
  private readonly dispatcher: ActionDispatcher;

  constructor(repo: DeliveryRepository, dispatcher: ActionDispatcher) {
    this.repo = repo;
    this.dispatcher = dispatcher;
  }

  async tick(now: number): Promise<DeliveryRecord | null> {
    if (await this.repo.isGloballyPaused()) return null;
    const due = await this.repo.pickNextDue(now);
    if (!due) return null;
    return this.dispatcher.dispatch(due, now);
  }
}
