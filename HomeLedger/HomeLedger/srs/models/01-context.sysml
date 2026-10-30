package HomeLedgerContext {
    doc /* Системный контекст ПО «HomeLedger — Домашняя бухгалтерия» */

    part def 'Программное средство';
    part def 'Пользователь';
    part def 'Хранилище';
    part def 'Внешняя программа';

    part <context> 'Контекст HomeLedger' {
        part <owner> 'Владелец бюджета' : 'Пользователь';
        part <family> 'Член семьи' : 'Пользователь';

        part <sys> 'ПО HomeLedger (консоль, Windows / Linux)' : 'Программное средство';

        part <data> 'Файлы данных CSV (каталог data)' : 'Хранилище';
        part <bak> 'Резервные копии (data/backup)' : 'Хранилище';
        part <rep> 'Отчёт за месяц CSV' : 'Хранилище';
        part <xls> 'Табличный редактор (Excel / Calc)' : 'Внешняя программа';

        connection 'доходы, расходы, лимиты, отчёты' connect owner to sys;
        connection 'свои расходы, просмотр' connect family to sys;
        connection 'чтение / запись' connect sys to data;
        connection 'копия при запуске' connect sys to bak;
        connection 'экспорт' connect sys to rep;
        connection 'просмотр, печать' connect rep to xls;
    }
}
