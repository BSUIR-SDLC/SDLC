// Маршрутизатор HTTP API RuleHook (SDD 005-interface, F01, F02, F03, F04, F08, F14).
import type { IncomingMessage, ServerResponse } from 'node:http';
import type { AuthService } from '../modules/auth/authService.ts';
import type { RuleService } from '../modules/rules/ruleService.ts';
import type { SourceService } from '../modules/sources/sourceService.ts';
import type { TargetService } from '../modules/targets/targetService.ts';
import type { WebhookController } from '../modules/webhooks/webhookController.ts';
import { MAX_BODY_BYTES } from '../modules/webhooks/receiveWebhook.ts';
import type { InMemoryStore } from '../infrastructure/inMemoryStore.ts';

export type AppContainer = {
  store: InMemoryStore;
  auth: AuthService;
  sources: SourceService;
  targets: TargetService;
  rules: RuleService;
  webhooks: WebhookController;
  now: () => number;
};

const MAX_API_BODY = MAX_BODY_BYTES * 5; // 5 МиБ для импорта правил (UC-11)

function sendJson(res: ServerResponse, status: number, payload: unknown): void {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(payload));
}

async function readBody(req: IncomingMessage, limit: number): Promise<Buffer> {
  const chunks: Buffer[] = [];
  let total = 0;
  for await (const chunk of req) {
    const buf = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buf.length;
    if (total <= limit + 1) chunks.push(buf);
  }
  return Buffer.concat(chunks);
}

function bearerToken(req: IncomingMessage): string | undefined {
  const h = req.headers.authorization;
  return typeof h === 'string' && h.startsWith('Bearer ') ? h.slice(7).trim() : undefined;
}

function parseJson(raw: Buffer): unknown | null {
  try {
    return JSON.parse(raw.toString('utf8'));
  } catch {
    return null;
  }
}

export class AppRouter {
  private readonly app: AppContainer;

  constructor(app: AppContainer) {
    this.app = app;
  }

  private authorize(req: IncomingMessage, res: ServerResponse, permission: string) {
    const resAuth = this.app.auth.authorize(bearerToken(req), permission, this.app.now());
    if (!resAuth.ok) {
      sendJson(res, resAuth.status, { code: resAuth.code });
      return null;
    }
    return resAuth.claims;
  }

  async handle(req: IncomingMessage, res: ServerResponse): Promise<void> {
    const method = req.method ?? 'GET';
    const url = new URL(req.url ?? '/', 'http://localhost');
    const path = url.pathname;

    if (method === 'GET' && path === '/health') {
      return sendJson(res, 200, { status: 'ok' });
    }

    if (method === 'POST' && path.startsWith('/hooks/')) {
      const sourceId = decodeURIComponent(path.slice('/hooks/'.length));
      const raw = await readBody(req, MAX_BODY_BYTES);
      const headers: Record<string, string | undefined> = {};
      for (const [k, v] of Object.entries(req.headers)) {
        headers[k.toLowerCase()] = Array.isArray(v) ? v[0] : v;
      }
      const reply = await this.app.webhooks.ingest(sourceId, raw, headers);
      return sendJson(res, reply.status, reply.body);
    }

    const raw = await readBody(req, MAX_API_BODY);
    if (method === 'POST' && path === '/api/v1/auth/login') {
      const body = parseJson(raw) as { login?: string; password?: string } | null;
      if (!body || typeof body.login !== 'string' || typeof body.password !== 'string') {
        return sendJson(res, 400, { code: 'INVALID_BODY' });
      }
      const result = await this.app.auth.login(body.login, body.password, this.app.now());
      return sendJson(res, result.status, result);
    }

    if (path === '/api/v1/sources') {
      if (method === 'GET') {
        if (!this.authorize(req, res, 'sources:manage')) return;
        const list = (await this.app.sources.listSources()).map(({ secret: _s, previousSecret: _p, ...rest }) => rest);
        return sendJson(res, 200, { items: list });
      }
      if (method === 'POST') {
        if (!this.authorize(req, res, 'sources:manage')) return;
        const body = parseJson(raw) as any;
        if (!body?.id || !body?.name) return sendJson(res, 422, { code: 'INVALID_SOURCE' });
        try {
          const created = await this.app.sources.createSource(body);
          return sendJson(res, 201, { id: created.source.id, name: created.source.name, secret: created.plainSecret });
        } catch (err: any) {
          return sendJson(res, 422, { code: err.message });
        }
      }
    }

    if (method === 'POST' && /^\/api\/v1\/sources\/[^/]+\/rotate-secret$/.test(path)) {
      if (!this.authorize(req, res, 'sources:manage')) return;
      const id = decodeURIComponent(path.split('/')[4]);
      try {
        return sendJson(res, 200, await this.app.sources.rotateSecret(id, this.app.now()));
      } catch (err: any) {
        return sendJson(res, 404, { code: err.message });
      }
    }

    if (path === '/api/v1/targets') {
      if (method === 'GET') {
        if (!this.authorize(req, res, 'targets:manage')) return;
        return sendJson(res, 200, { items: await this.app.targets.listTargets() });
      }
      if (method === 'POST') {
        if (!this.authorize(req, res, 'targets:manage')) return;
        const body = parseJson(raw) as any;
        if (!body?.name || !body?.baseUrl || !body?.kind) return sendJson(res, 422, { code: 'INVALID_TARGET' });
        try {
          return sendJson(res, 201, await this.app.targets.createTarget(body));
        } catch (err: any) {
          return sendJson(res, 422, { code: err.message });
        }
      }
    }

    if (method === 'DELETE' && path.startsWith('/api/v1/targets/')) {
      if (!this.authorize(req, res, 'targets:manage')) return;
      const name = decodeURIComponent(path.slice('/api/v1/targets/'.length));
      try {
        return sendJson(res, 200, await this.app.targets.deleteTarget(name));
      } catch (err: any) {
        return sendJson(res, 404, { code: err.message });
      }
    }

    if (path === '/api/v1/rules') {
      if (method === 'GET') {
        if (!this.authorize(req, res, 'rules:read')) return;
        return sendJson(res, 200, { items: await this.app.rules.listRules() });
      }
      if (method === 'POST') {
        const claims = this.authorize(req, res, 'rules:write');
        if (!claims) return;
        const body = parseJson(raw);
        if (!body) return sendJson(res, 400, { code: 'INVALID_JSON' });
        const result = await this.app.rules.createRule(body, claims.sub, this.app.now());
        return sendJson(res, result.ok ? 201 : 422, result);
      }
    }

    if (method === 'POST' && path === '/api/v1/rules/import') {
      const claims = this.authorize(req, res, 'rules:import');
      if (!claims) return;
      const body = parseJson(raw) as { mode?: 'skip' | 'replace'; rules?: unknown[] } | null;
      if (!body || !Array.isArray(body.rules)) return sendJson(res, 422, { code: 'INVALID_IMPORT' });
      const report = await this.app.rules.importRules(body.rules, body.mode ?? 'skip', claims.sub, this.app.now());
      return sendJson(res, 200, report);
    }

    if (method === 'POST' && /^\/api\/v1\/rules\/[^/]+\/(enable|disable)$/.test(path)) {
      if (!this.authorize(req, res, 'rules:write')) return;
      const parts = path.split('/');
      const id = decodeURIComponent(parts[4]);
      const action = parts[5];
      try {
        const rule = action === 'enable'
          ? await this.app.rules.enableRule(id)
          : await this.app.rules.disableRule(id);
        return sendJson(res, 200, rule);
      } catch (err: any) {
        return sendJson(res, 404, { code: err.message });
      }
    }

    if (method === 'GET' && path === '/api/v1/journal') {
      if (!this.authorize(req, res, 'journal:read')) return;
      return sendJson(res, 200, this.app.store.getJournal());
    }

    if (method === 'POST' && (path === '/api/v1/system/pause' || path === '/api/v1/system/resume')) {
      if (!this.authorize(req, res, 'system:pause')) return;
      const paused = path.endsWith('/pause');
      const changed = await this.app.store.setGlobalPause(paused);
      return sendJson(res, 200, { paused, changed });
    }

    return sendJson(res, 404, { code: 'NOT_FOUND' });
  }
}
