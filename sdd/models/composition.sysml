// @diagram ibd "Композиция RuleHook"
package Composition {
  part emulator : Emulator {
    @External;
    doc /* Внешняя система. Шлёт вебхуки, принимает команды POST. */
  }
  part admin : AdminPanel {
    @Client;
    doc /* SPA оператора: React, TypeScript. Правила, журнал, недоставленные. */
  }
  part proxy : ReverseProxy {
    doc /* nginx: TLS 1.2+, лимит частоты, маршрутизация /hooks и /api. */
  }
  part server : RuleHookServer {
    @Primary;
    doc /* Node.js 20, Fastify. Модульный монолит: процессы api и worker из одного образа. */
    part hooks : WebhookReceiver { doc /* POST /hooks/{sourceId}: HMAC, идемпотентность, ответ 202. */ }
    part api : HttpApi { doc /* REST /api/v1, OpenAPI, ограничение частоты. */ }
    part auth : AuthModule { doc /* Вход, JWT 12 ч, bcrypt, роли, блокировка. */ }
    part endpoints : EndpointRegistry { doc /* Источники, цели, allow-list адресов, секреты. */ }
    part rules : RuleService { doc /* CRUD правил, схема, версии, импорт и экспорт. */ }
    part engine : MatchingEngine { @Core; doc /* Выбор правил, условия all / any / not, приоритеты. */ }
    part ruleDsl : RuleDslLib { @Core; doc /* Пакет rule-dsl: пути и операторы, без Fastify и БД. */ }
    part guard : LoopGuard { @Core; doc /* Счётчик X-Hop, cooldown, автоотключение правила. */ }
    part dispatcher : ActionDispatcher { @Core; doc /* Подстановки, POST, повторы, Idempotency-Key. */ }
    part worker : QueueWorker { doc /* Воркеры SKIP LOCKED, очистка по сроку хранения. */ }
    part journal : JournalService { doc /* Журнал, поиск, недоставленные, повтор. */ }
    part observability : Observability { doc /* JSON-логи pino, метрики /metrics, /health. */ }
  }
  part db : Database {
    @Store;
    doc /* PostgreSQL 16: правила, события, доставки, очередь, журнал. */
  }
  part notifier : NotificationSystem {
    @External;
    doc /* Внешняя система уведомлений: POST /notify. */
  }
  connect emulator to proxy { doc /* HTTPS: POST /hooks */ }
  connect admin to proxy { doc /* HTTPS: /api/v1 */ }
  connect proxy to hooks { doc /* HTTP :3000 */ }
  connect hooks to engine { doc /* evaluate() */ }
  connect engine to ruleDsl { doc /* match() */ }
  connect engine to guard { doc /* check() */ }
  connect api to auth { doc /* проверка роли */ }
  connect api to rules { doc /* CRUD */ }
  connect api to journal { doc /* запросы */ }
  connect worker to dispatcher { doc /* send() */ }
  connect dispatcher to endpoints { doc /* адрес цели */ }
  connect journal to db { doc /* SQL */ }
  connect dispatcher to emulator { @Back; doc /* POST: команды */ }
  connect dispatcher to notifier { doc /* POST: уведомления */ }
}
