package CheqReceiptStates {
    doc /* Жизненный цикл импортированного чека до и после подтверждения. */
    item def 'Фото сохранено';
    item def 'Текст прочитан';
    item def 'Сеть доступна';
    item def 'Корректный ответ';
    item def 'Сбой сервиса';
    item def 'Повтор анализа';
    item def 'Текст изменён';
    item def 'Сохранить';
    item def 'Удалить';
    state def <ReceiptState> 'Состояние импортированного чека' {
        entry; then imported;
        state <imported> 'Импортирован';
        state <ocr> 'Локальный OCR';
        state <waiting> 'Ожидает анализа';
        state <processing> 'Анализ Groq';
        state <ready> 'Проверка';
        state <error> 'Ошибка';
        state <saved> 'Сохранён';
        state <deleted> 'Удалён';
        transition first imported accept : 'Фото сохранено' then ocr;
        transition first ocr accept : 'Текст прочитан' then waiting;
        transition first waiting accept : 'Сеть доступна' then processing;
        transition first processing accept : 'Корректный ответ' then ready;
        transition first processing accept : 'Сбой сервиса' then error;
        transition first error accept : 'Повтор анализа' then waiting;
        transition first ready accept : 'Текст изменён' then waiting;
        transition first ready accept : 'Сохранить' then saved;
        transition first saved accept : 'Удалить' then deleted;
    }
}
