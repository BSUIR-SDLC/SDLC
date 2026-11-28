// Композиция приложения и HTTP-сервер на node:http (F01, ADR-0001).
import { createServer } from 'node:http';
import type { Server } from 'node:http';
import { InMemoryStore } from './infrastructure/inMemoryStore.ts';
import { AuthService, ScryptPasswordHasher, TokenService } from './modules/auth/authService.ts';
import { ActionDispatcher, DeliveryWorker } from './modules/dispatcher/actionDispatcher.ts';
import type { HttpClient } from './modules/dispatcher/actionDispatcher.ts';
import { MatchingEngine } from './modules/engine/matchingEngine.ts';
import { LoopGuard } from './modules/guard/loopGuard.ts';
import { RuleService } from './modules/rules/ruleService.ts';
import { SourceService } from './modules/sources/sourceService.ts';
import { TargetService } from './modules/targets/targetService.ts';
import { WebhookController } from './modules/webhooks/webhookController.ts';
import { AppRouter } from './http/router.ts';

export type ServerOptions = {
  jwtSecret?: string;
  allowedHosts?: readonly string[];
  httpClient?: HttpClient;
  now?: () => number;
};

export function createRuleHookApp(opts: ServerOptions = {}) {
  const now = opts.now ?? (() => Date.now());
  const store = new InMemoryStore();
  const hasher = new ScryptPasswordHasher();
  const tokens = new TokenService(opts.jwtSecret ?? 'dev-session-secret-change-me');
  const auth = new AuthService(store, hasher, tokens);
  const sources = new SourceService(store);
  const targets = new TargetService(store, opts.allowedHosts ?? ['emulator.local', 'notifier.local']);
  const guard = new LoopGuard();
  const engine = new MatchingEngine(guard);
  const rules = new RuleService(store, store, store, engine);
  const webhooks = new WebhookController(store.createWebhookDeps(engine, now));
  const httpClient: HttpClient = opts.httpClient ?? {
    async post() { return { status: 204 }; },
  };
  const dispatcher = new ActionDispatcher(store, httpClient);
  const worker = new DeliveryWorker(store, dispatcher);

  const router = new AppRouter({ store, auth, sources, targets, rules, webhooks, now });
  const server: Server = createServer((req, res) => {
    void router.handle(req, res);
  });

  return { server, store, hasher, auth, sources, targets, rules, guard, engine, dispatcher, worker };
}
