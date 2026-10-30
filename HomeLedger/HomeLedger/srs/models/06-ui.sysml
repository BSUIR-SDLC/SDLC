package ConsoleLib {
    // Типы элементов текстового (консольного) интерфейса
    part def 'Экран';
    part def 'Заголовок';
    part def 'Сводка';
    part def 'Меню';
    part def 'Поле ввода';
    part def 'Список выбора';
    part def 'Таблица';
    part def 'Диаграмма';
    part def 'Список сообщений';
    part def 'Строка команд';
}

package UiMockups {
    private import ConsoleLib::*;
    private import ScalarValues::*;

    part <main> 'Главный экран' : 'Экран' {
        part <title> 'Заголовок с датой' : 'Заголовок';
        part <summary> 'Баланс и итоги месяца' : 'Сводка' {
            attribute строки : String[*] = ("Баланс (по кошелькам)", "Доходы · расходы · остаток месяца");
        }
        part <alerts> 'Предупреждения о лимитах' : 'Список сообщений';
        part <menu> 'Главное меню' : 'Меню' {
            attribute пункты : String[*] = ("1 Добавить расход", "2 Добавить доход", "3 Перевод",
                "4 Журнал", "5 Статистика", "6 Бюджеты", "7 Советы", "8 Кошельки и категории",
                "9 Экспорт", "0 Выход");
        }
        connect title to summary;
        connect summary to alerts;
        connect alerts to menu;
    }

    part <add> 'Экран «Новый расход / доход»' : 'Экран' {
        part <sum> 'Сумма, BYN' : 'Поле ввода';
        part <cat> 'Категория' : 'Список выбора' {
            attribute 'по умолчанию' : String = "последняя выбранная";
        }
        part <wal> 'Кошелёк' : 'Список выбора' {
            attribute 'по умолчанию' : String = "последний выбранный";
        }
        part <dt> 'Дата' : 'Поле ввода' {
            attribute 'по умолчанию' : String = "сегодня";
        }
        part <cmt> 'Комментарий' : 'Поле ввода';
        part <res> 'Результат и состояние лимита' : 'Список сообщений';
        connect sum to cat;     // порядок ввода
        connect cat to wal;
        connect wal to dt;
        connect dt to cmt;
        connect cmt to res;
    }

    part <journal> 'Экран «Журнал операций»' : 'Экран' {
        part <ops> 'Операции за месяц' : 'Таблица' {
            attribute столбцы : String[*] = ("№", "Дата", "Тип", "Категория", "Кошелёк", "Сумма", "Комментарий");
        }
        part <tot> 'Итоги: операций, доходы, расходы' : 'Сводка';
        part <cmd> 'Команды' : 'Строка команд' {
            attribute команды : String[*] = ("< >  месяц", "к  фильтр по категории", "и N  изменить", "у N  удалить", "0  назад");
        }
        connect ops to tot;
        connect tot to cmd;
    }

    part <stats> 'Экран «Статистика»' : 'Экран' {
        part <head> 'Доходы, расходы, остаток месяца' : 'Сводка';
        part <bycat> 'Расходы и доходы по категориям' : 'Диаграмма' {
            attribute столбцы : String[*] = ("Категория", "Сумма", "Доля, %", "Полоса");
        }
        part <rule> 'Структура 50/30/20' : 'Диаграмма';
        part <dyn> 'Динамика за 6 месяцев' : 'Диаграмма';
        part <cmd> 'Команды' : 'Строка команд';
        connect head to bycat;
        connect bycat to rule;
        connect rule to dyn;
        connect dyn to cmd;
    }

    part <budgets> 'Экран «Бюджеты»' : 'Экран' {
        part <tbl> 'Лимиты месяца' : 'Таблица' {
            attribute столбцы : String[*] = ("Категория", "Лимит", "Потрачено", "Осталось", "Использовано, %");
        }
        part <cmd> 'Команды' : 'Строка команд' {
            attribute команды : String[*] = ("1  установить лимит", "2  снять лимит", "0  назад");
        }
        connect tbl to cmd;
    }

    part <advice> 'Экран «Советы»' : 'Экран' {
        part <list> 'Советы с отметками [+] [i] [!]' : 'Список сообщений' {
            attribute правила : String[*] = ("50/30/20", "прогноз на месяц", "дневной лимит",
                "топ-3 категории", "рост к прошлому месяцу", "лимиты");
        }
    }

    part <transfer> 'Экран «Перевод между кошельками»' : 'Экран' {
        part <sum> 'Сумма, BYN' : 'Поле ввода';
        part <src> 'Откуда' : 'Список выбора';
        part <dst> 'Куда' : 'Список выбора';
        part <cmt> 'Комментарий' : 'Поле ввода';
        connect sum to src;
        connect src to dst;
        connect dst to cmt;
    }

    part <wallets> 'Экран «Кошельки и категории»' : 'Экран' {
        part <wl> 'Кошельки и остатки' : 'Таблица';
        part <cl> 'Категории по группам 50/30/20' : 'Список сообщений';
        part <cmd> 'Команды' : 'Строка команд' {
            attribute команды : String[*] = ("1  добавить кошелёк", "2  категорию расходов", "3  категорию доходов", "0  назад");
        }
        connect wl to cl;
        connect cl to cmd;
    }

    part <export> 'Экран «Экспорт отчёта»' : 'Экран' {
        part <month> 'Месяц (ММ.ГГГГ)' : 'Поле ввода';
        part <res> 'Путь к файлу отчёта' : 'Список сообщений';
        connect month to res;
    }

    part <map> 'Карта экранов' {
        ref part m = main;
        ref part a = add;
        ref part j = journal;
        ref part s = stats;
        ref part b = budgets;
        ref part v = advice;
        ref part t = transfer;
        ref part w = wallets;
        ref part e = export;
        connect m to a;   // пункты 1, 2
        connect m to t;   // 3
        connect m to j;   // 4
        connect m to s;   // 5
        connect m to b;   // 6
        connect m to v;   // 7
        connect m to w;   // 8
        connect m to e;   // 9
        connect j to a;   // изменение операции (и N) использует те же поля ввода
    }
}
