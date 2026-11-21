package CheqGuiLib {
    private import ScalarValues::String;
    part def 'Экран';
    part def 'Диалог' :> 'Экран';
    part def 'Поле ввода';
    part def 'Текст';
    part def 'Дата';
    part def 'Панель' { attribute 'действия' : String[*]; }
    part def 'Список';
    part def 'Группа';
    part def 'Индикатор';
    part def 'Таблица' { attribute 'столбцы' : String[*]; }
    part def 'Выбор' { attribute 'варианты' : String[*]; }
    connection def 'Фильтр' { end part 'источник'; end part 'получатель'; }
    connection def 'Выбранная запись' { end part 'источник'; end part 'получатель'; }
    connection def 'Результат проверки' { end part 'источник'; end part 'получатель'; }
}
package CheqGui {
    private import CheqGuiLib::*;
    part <purchases> 'Покупки' : 'Экран' {
        part <search> 'Поиск по магазину, товару, дате' : 'Поле ввода';
        part <queue> 'Ожидающие и готовые к проверке чеки' : 'Список';
        part <list> 'Подтверждённые покупки' : 'Таблица' {
            attribute redefines 'столбцы' = ("магазин", "дата", "сумма", "валюта");
        }
        part <buttons> 'Добавить чек' : 'Панель' {
            attribute redefines 'действия' = ("Камера", "Фото", "Вручную");
        }
        connection : 'Фильтр' connect search to list;
        connect list to buttons;
    }
    part <editor> 'Редактор чека' : 'Экран' {
        part <fields> 'Реквизиты покупки' : 'Группа' {
            part <shop> 'Магазин' : 'Поле ввода';
            part <date> 'Дата покупки' : 'Дата';
            part <currency> 'Валюта' : 'Выбор' {
                attribute redefines 'варианты' = ("BYN", "RUB", "EUR", "USD", "KZT", "PLN");
            }
            connect shop to date;
            connect date to currency;
        }
        part <text> 'Исходный текст чека' : 'Поле ввода';
        part <items> 'Позиции' : 'Таблица' {
            attribute redefines 'столбцы' = ("товар", "количество", "цена", "сумма", "категория");
        }
        part <total> 'Итог чека' : 'Поле ввода';
        part <card> 'Карта или Без карты' : 'Выбор';
        part <status> 'Результат анализа и расхождения' : 'Индикатор';
        part <buttons> 'Действия редактора' : 'Панель' {
            attribute redefines 'действия' = ("Распознать повторно", "Сохранить", "Назад");
        }
        connect fields to text;
        connect text to items;
        connect items to total;
        connect total to card;
        connection : 'Результат проверки' connect status to buttons;
    }
    part <products> 'Товары' : 'Экран' {
        part <search> 'Поиск товара' : 'Поле ввода';
        part <sort> 'Сортировка' : 'Выбор' {
            attribute redefines 'варианты' = ("по дате", "по имени", "по цене");
        }
        part <displayMode> 'Представление' : 'Выбор' {
            attribute redefines 'варианты' = ("Карточки", "Список");
        }
        part <list> 'Товары и категории' : 'Список';
        part <buttons> 'Действия с выбранным' : 'Панель' {
            attribute redefines 'действия' = ("История цен", "Категория", "Поделиться");
        }
        connection : 'Фильтр' connect search to list;
        connect sort to displayMode;
        connect displayMode to list;
        connection : 'Выбранная запись' connect list to buttons;
    }
    part <history> 'История цен товара' : 'Диалог' {
        part <title> 'Название товара' : 'Текст';
        part <prices> 'Покупки товара' : 'Таблица' {
            attribute redefines 'столбцы' = ("дата", "магазин", "цена единицы", "валюта");
        }
        part <buttons> 'Действия' : 'Панель' {
            attribute redefines 'действия' = ("Поделиться", "Закрыть");
        }
        connect title to prices;
        connect prices to buttons;
    }
    part <expenses> 'Расходы' : 'Экран' {
        part <month> 'Выбранный месяц' : 'Дата';
        part <summary> 'Итог и признак неполных курсов' : 'Индикатор';
        part <budget> 'Лимит, остаток или превышение' : 'Индикатор';
        part <categories> 'Расходы по категориям' : 'Список';
        part <cards> 'По картам и Без карты' : 'Список';
        connect month to summary;
        connect summary to budget;
        connect budget to categories;
        connect categories to cards;
    }
    part <settings> 'Настройки' : 'Экран' {
        part <theme> 'Тема' : 'Выбор' {
            attribute redefines 'варианты' = ("Как в системе", "Светлая", "Тёмная");
        }
        part <currency> 'Общая валюта' : 'Выбор';
        part <budget> 'Бюджет' : 'Группа' {
            part <month> 'Месяц лимита' : 'Дата';
            part <amount> 'Сумма лимита, 0 без лимита' : 'Поле ввода';
            part <save> 'Сохранить бюджет' : 'Панель';
            connect month to amount;
            connect amount to save;
        }
        part <cards> 'Управление банковскими картами' : 'Список';
        connect theme to currency;
        connect currency to budget;
        connect budget to cards;
    }
    part <card> 'Добавить или изменить карту' : 'Диалог' {
        part <name> 'Название карты' : 'Поле ввода';
        part <digits> 'Последние четыре цифры' : 'Поле ввода';
        part <buttons> 'Действия' : 'Панель' {
            attribute redefines 'действия' = ("Сохранить", "Отмена");
        }
        connect name to digits;
        connect digits to buttons;
    }
}
package CheqNavigation {
    part <nav> 'Карта экранов Cheq' {
        part <tabs> 'Нижняя навигация';
        part <purchases> 'Покупки';
        part <editor> 'Редактор чека';
        part <products> 'Товары';
        part <history> 'История цен';
        part <expenses> 'Расходы';
        part <settings> 'Настройки';
        part <card> 'Банковские карты';
        connect purchases to editor;
        connect tabs to purchases;
        connect tabs to products;
        connect tabs to expenses;
        connect tabs to settings;
        connect products to history;
        connect settings to card;
        connect editor to card;
    }
}
