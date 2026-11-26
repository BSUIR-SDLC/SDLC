// Управление правилами обнаружения, роль администратора. Требования: REQ-FUNC-012, REQ-FUNC-029.
package UiRules {
    private import UiLibrary::*;

    part rulesScreen : Screen {
        attribute :>> width = 1300;
        attribute :>> height = 540;
        attribute :>> caption = "Правила обнаружения · admin · администратор";

        part addButton : PrimaryButton { attribute :>> posX = 24; attribute :>> posY = 20; attribute :>> width = 200; attribute :>> height = 48; attribute :>> caption = "Добавить"; }
        part editButton : Button { attribute :>> posX = 240; attribute :>> posY = 20; attribute :>> width = 200; attribute :>> height = 48; attribute :>> caption = "Изменить"; }
        part toggleButton : Button { attribute :>> posX = 456; attribute :>> posY = 20; attribute :>> width = 200; attribute :>> height = 48; attribute :>> caption = "Отключить"; }

        part rules : Table {
            attribute :>> posX = 24; attribute :>> posY = 88; attribute :>> width = 1252; attribute :>> height = 470; attribute :>> caption = "Правила";
            attribute :>> columns = "Название|Условие|Важность|Включено";
            attribute :>> columnWidths = "340|520|232|160";
            part row1 : TableRow { attribute :>> cells = "Перебор пароля|5 неудачных входов за 60 с|высокая|да"; }
            part row2 : TableRow { attribute :>> cells = "Неизвестная программа|запуск из временной папки|средняя|да"; }
            part row3 : TableRow { attribute :>> cells = "USB-накопитель|устройство не из белого списка|высокая|да"; }
            part row4 : TableRow { attribute :>> cells = "Изменение файла|хеш защищаемого файла изменён|высокая|да"; }
            part row5 : TableRow { attribute :>> cells = "Агент молчит|нет связи 90 с|средняя|да"; }
        }

        part saveNote : Label { attribute :>> posX = 24; attribute :>> posY = 430; attribute :>> width = 1252; attribute :>> height = 30; attribute :>> caption = "Изменения применяются без пересборки программы"; attribute :>> tone = "muted"; }
    }
}
