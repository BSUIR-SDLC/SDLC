// @diagram stm "Состояния доставки действия"
package States {
  state def DeliveryStates {
    entry; then queued;
    state queued { doc /* Поставлено в очередь */ }
    state sending { doc /* Отправка POST (ожидание ответа ≤ 5 с) */ }
    state delivered { @Ok; doc /* Доставлено (ответ 2xx) */ }
    state retryWait { doc /* Пауза перед повтором: 2^n с */ }
    state rejected { @Error; doc /* Отклонено получателем (4xx) */ }
    state exhausted { @Error; doc /* Попытки исчерпаны (5 из 5) */ }
    state deadLetter { @Warn; doc /* В списке недоставленных */ }
    state skipped { @Warn; doc /* Пропущено защитой или паузой */ }
    state replayRequested { doc /* Повтор запрошен оператором */ }
    transition t01 first queued accept WorkerPicked then sending { doc /* воркер взял задачу */ }
    transition t02 first queued accept GuardTripped then skipped { doc /* петля или глобальная пауза */ }
    transition t03 first sending accept Http2xx then delivered { doc /* ответ 2xx */ }
    transition t04 first sending accept Retryable then retryWait { doc /* 5xx, 429, тайм-аут, сеть */ }
    transition t05 first sending accept Http4xx then rejected { doc /* 4xx кроме 408 и 429 */ }
    transition t06 first sending accept LastAttemptFailed then exhausted { doc /* 5-я попытка неудачна */ }
    transition t07 first retryWait accept BackoffElapsed then sending { doc /* пауза истекла */ }
    transition t08 first rejected accept Persist then deadLetter { doc /* сохранить причину */ }
    transition t09 first exhausted accept Persist then deadLetter { doc /* сохранить причину */ }
    transition t10 first deadLetter accept ReplayPressed then replayRequested { doc /* «Повторить» */ }
    transition t11 first replayRequested accept Requeued then queued { doc /* тот же Idempotency-Key */ }
  }
}
