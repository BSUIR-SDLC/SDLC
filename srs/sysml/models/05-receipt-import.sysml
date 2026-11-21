package CheqReceiptImport {
    private import ScalarValues::Boolean;
    action def <ImportReceipt> 'Импорт и подтверждение покупки' {
        attribute 'сеть доступна' : Boolean;
        attribute 'ответ корректен' : Boolean;
        attribute 'пользователь подтвердил' : Boolean;
        first start;
        then action <photo> 'Сохранить фото в очереди';
        then action <ocr> 'Прочитать текст локально';
        then decide;
            if 'сеть доступна' then cloud;
            else wait;
        action <wait> 'Сохранить ожидание подключения';
        then done;
        action <cloud> 'Получить и проверить ответ Groq';
        then decide;
            if 'ответ корректен' then review;
            else error;
        action <error> 'Сохранить данные и показать ошибку';
        then done;
        action <review> 'Проверить товары, итог и расхождения';
        then decide;
            if 'пользователь подтвердил' then save;
            else draft;
        action <draft> 'Оставить черновик без учёта в расходах';
        then done;
        action <save> 'Сохранить покупку без дубля';
        then action <refresh> 'Обновить товары и расходы';
        then done;
    }
}
