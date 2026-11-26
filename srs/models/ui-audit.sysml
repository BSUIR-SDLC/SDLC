// Журнал действий операторов, роль аудитора. Требования: REQ-FUNC-028, REQ-SEC-005.
package UiAudit {
    private import UiLibrary::*;

    part auditScreen : Screen {
        attribute :>> width = 1300;
        attribute :>> height = 560;
        attribute :>> caption = "Журнал действий · kozlova · аудитор";

        part fromField : TextField { attribute :>> posX = 24; attribute :>> posY = 46; attribute :>> width = 280; attribute :>> height = 48; attribute :>> caption = "С"; attribute :>> subcaption = "20.11.2026 00:00"; }
        part toField : TextField { attribute :>> posX = 324; attribute :>> posY = 46; attribute :>> width = 280; attribute :>> height = 48; attribute :>> caption = "По"; attribute :>> subcaption = "20.11.2026 23:59"; }
        part showButton : PrimaryButton { attribute :>> posX = 624; attribute :>> posY = 46; attribute :>> width = 180; attribute :>> height = 48; attribute :>> caption = "Показать"; }

        part records : Table {
            attribute :>> posX = 24; attribute :>> posY = 116; attribute :>> width = 1252; attribute :>> height = 440; attribute :>> caption = "Записи журнала";
            attribute :>> columns = "Время|Пользователь|Действие|Объект|Подробности";
            attribute :>> columnWidths = "150|170|330|200|402";
            part row1 : TableRow { attribute :>> cells = "08:02:14|petrov|Вход в систему|–|Успешно"; }
            part row2 : TableRow { attribute :>> cells = "10:16:40|petrov|Смена статуса|Инцидент 301|Новый → в работе"; }
            part row3 : TableRow { attribute :>> cells = "10:17:05|petrov|Комментарий|Инцидент 301|Позвонил пользователю"; }
            part row4 : TableRow { attribute :>> cells = "10:29:51|petrov|Смена статуса|Инцидент 301|В работе → решён"; }
            part row5 : TableRow { attribute :>> cells = "11:03:22|ivanova|Смена статуса|Инцидент 298|В работе → ложное"; }
        }

        part roleNote : Label { attribute :>> posX = 24; attribute :>> posY = 460; attribute :>> width = 1252; attribute :>> height = 30; attribute :>> caption = "Записи только читаются: изменить или удалить их из консоли нельзя"; attribute :>> tone = "muted"; }
    }
}
