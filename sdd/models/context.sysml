// @diagram ibd "Контекст RuleHook"
package Context {
  part emulator : Emulator {
    @External;
    doc /* Эмулятор: источник событий (датчики, устройства). Отправляет вебхуки и принимает команды POST. */
  }
  part rulehook : RuleHookSystem {
    @Primary;
    doc /* Движок правил: принимает вебхуки, сверяет их с JSON-правилами, выполняет POST-действия. */
  }
  part notifier : NotificationSystem {
    @External;
    doc /* Система уведомлений: принимает POST /notify и доставляет сообщения людям. */
  }
  part admin : Administrator {
    @Actor;
    doc /* Администратор: источники, цели, пользователи, настройки, пауза. */
  }
  part operator : Operator {
    @Actor;
    doc /* Оператор: пишет и проверяет правила, разбирает журнал, повторяет недоставленные. */
  }
  part viewer : Viewer {
    @Actor;
    doc /* Наблюдатель: только чтение правил и журнала. */
  }
  connect emulator to rulehook { doc /* вебхук: POST /hooks/{sourceId}, подпись HMAC-SHA256 */ }
  connect rulehook to emulator { @Back; doc /* действие: POST-команда эмулятору */ }
  connect rulehook to notifier { doc /* действие: POST-уведомление */ }
  connect admin to rulehook { doc /* веб-консоль и REST API */ }
  connect operator to rulehook { doc /* веб-консоль и REST API */ }
  connect viewer to rulehook { doc /* веб-консоль, только чтение */ }
}
