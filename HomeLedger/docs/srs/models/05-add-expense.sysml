package HomeLedgerAddExpense {
    // Сценарий «Внести расход» с проверками и контролем лимита
    private import ScalarValues::*;

    action def <AddExpense> 'Внести расход' {
        attribute valid : Boolean;      // сумма > 0, категория и кошелёк существуют, дата не в будущем
        attribute enough : Boolean;     // сумма не больше остатка в кошельке
        attribute confirmed : Boolean;  // пользователь подтвердил расход сверх остатка

        action <amount> 'Ввести сумму';
        action <category> 'Выбрать категорию (по умолчанию — последняя)';
        action <wallet> 'Выбрать кошелёк (по умолчанию — последний)';
        action <date> 'Ввести дату (по умолчанию — сегодня) и комментарий';
        action <validate> 'Проверить данные';
        action <error> 'Показать причину ошибки';
        action <funds> 'Предупредить: в кошельке недостаточно средств';
        action <save> 'Сохранить операцию в файл';
        action <limit> 'Показать состояние лимита категории';

        first start;
        then amount;
        then category;
        then wallet;
        then date;
        then validate;
        then decide;
            if not valid then error;
            if valid and not enough then funds;
            else save;
        first error then amount;
        first funds then decide;
            if confirmed then save;
            else done;
        first save then limit;
        first limit then done;
    }
}
