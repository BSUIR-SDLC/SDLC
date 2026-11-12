// @diagram ibd "Развёртывание RuleHook"
package Deployment {
  part github : GitHubActions { @Client; doc /* CI/CD: сборка, линтер, тесты, образ в GHCR, деплой по SSH. */ }
  part registry : Ghcr { @Client; doc /* Реестр образов GitHub Container Registry. */ }
  part browser : AdminBrowser { @Actor; doc /* Браузер оператора: веб-консоль. */ }
  part emulator : Emulator { @External; doc /* Эмулятор: вебхуки и команды POST. */ }
  part notifier : NotificationSystem { @External; doc /* Система уведомлений: POST /notify. */ }
  part vps : VpsHost {
    @Primary;
    doc /* Один VPS: Ubuntu 22.04, 2 vCPU, 4 ГБ RAM, 40 ГБ SSD. Docker Compose. */
    part proxy : NginxContainer { doc /* nginx: TLS (Let's Encrypt), :443, лимиты. */ }
    part app : AppContainer { @Core; doc /* Процесс api: Fastify, :3000. */ }
    part worker : WorkerContainer { @Core; doc /* Процесс worker: очередь доставки, очистка. */ }
    part db : PostgresContainer { @Store; doc /* PostgreSQL 16, том pgdata. */ }
    part backup : BackupJob { doc /* pg_dump ежесуточно, хранение 14 копий. */ }
  }
  connect github to registry { doc /* push образа */ }
  connect github to vps { doc /* SSH: docker compose pull && up -d */ }
  connect emulator to proxy { doc /* HTTPS: вебхуки */ }
  connect browser to proxy { doc /* HTTPS: веб-консоль и API */ }
  connect proxy to app { doc /* HTTP :3000 */ }
  connect app to db { doc /* SQL :5432 */ }
  connect worker to db { doc /* SQL :5432 */ }
  connect backup to db { doc /* pg_dump */ }
  connect worker to emulator { @Back; doc /* HTTPS POST */ }
  connect worker to notifier { doc /* HTTPS POST */ }
}
