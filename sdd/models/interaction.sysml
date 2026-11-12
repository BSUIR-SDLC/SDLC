// @diagram sd "Обработка вебхука и доставка действия (UC-02)"
package Interaction {
  occurrence def HandleWebhook {
    part emulator : Emulator;
    part proxy : ReverseProxy;
    part hooks : WebhookReceiver;
    part engine : MatchingEngine { @Core; }
    part guard : LoopGuard { @Core; }
    part db : Database;
    part dispatcher : ActionDispatcher { @Core; }
    part target : Target;
    message m01 from emulator to proxy { doc /* POST /hooks/emu-1 {событие}; X-Event-Id, X-Signature, X-Hop */ }
    message m02 from proxy to hooks { doc /* proxy_pass, лимит частоты на источник */ }
    message m03 from hooks to hooks { doc /* размер ≤ 1 МиБ, проверка HMAC-SHA256 */ }
    message m04 from hooks to db { doc /* BEGIN; INSERT event ON CONFLICT DO NOTHING */ }
    message m05 from db to hooks { @Reply; doc /* вставлено или дубликат (тогда 200 и выход) */ }
    message m06 from hooks to engine { doc /* evaluate(event, активные правила источника) */ }
    message m07 from engine to engine { doc /* условия по приоритету, all / any / not */ }
    message m08 from engine to guard { doc /* check(rule, hop) для каждого совпадения */ }
    message m09 from guard to engine { @Reply; doc /* allow или skip(причина) */ }
    message m10 from engine to hooks { @Reply; doc /* список совпадений */ }
    message m11 from hooks to db { doc /* INSERT rule_match, delivery(QUEUED); COMMIT */ }
    message m12 from hooks to proxy { @Reply; doc /* 202 Accepted {eventId} */ }
    message m13 from proxy to emulator { @Reply; doc /* 202 Accepted */ }
    message m14 from dispatcher to db { doc /* асинхронно: SELECT delivery FOR UPDATE SKIP LOCKED */ }
    message m15 from dispatcher to target { doc /* POST /api/devices/d1/command, Idempotency-Key, тайм-аут 5 с */ }
    message m16 from target to dispatcher { @Reply; doc /* 200 OK */ }
    message m17 from dispatcher to db { doc /* UPDATE delivery SET status = DELIVERED */ }
  }
}
