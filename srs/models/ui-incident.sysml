// Карточка инцидента, роль оператора. Требования: REQ-FUNC-013, REQ-FUNC-022, REQ-FUNC-023.
package UiIncident {
    private import UiLibrary::*;

    part incidentScreen : Screen {
        attribute :>> width = 1200;
        attribute :>> height = 800;
        attribute :>> caption = "Инцидент № 301";

        part title : Heading { attribute :>> posX = 24; attribute :>> posY = 18; attribute :>> width = 700; attribute :>> height = 36; attribute :>> caption = "Возможный перебор пароля"; }
        part severityBadge : Badge { attribute :>> posX = 830; attribute :>> posY = 20; attribute :>> width = 160; attribute :>> height = 34; attribute :>> caption = "высокая"; attribute :>> tone = "incident"; }
        part statusBadge : Badge { attribute :>> posX = 1006; attribute :>> posY = 20; attribute :>> width = 170; attribute :>> height = 34; attribute :>> caption = "в работе"; attribute :>> tone = "warning"; }

        part facts : Panel {
            attribute :>> posX = 24; attribute :>> posY = 70; attribute :>> width = 1152; attribute :>> height = 126; attribute :>> caption = "Сведения";
            part hostLabel : Label { attribute :>> posX = 14; attribute :>> posY = 46; attribute :>> width = 540; attribute :>> height = 28; attribute :>> caption = "Хост: WS-214, комната 214, этаж 2"; }
            part timeLabel : Label { attribute :>> posX = 14; attribute :>> posY = 78; attribute :>> width = 540; attribute :>> height = 28; attribute :>> caption = "Создан: 10:15:02, исполнитель: petrov"; }
            part ruleLabel : Label { attribute :>> posX = 570; attribute :>> posY = 46; attribute :>> width = 570; attribute :>> height = 28; attribute :>> caption = "Правило: 5 неудачных входов за 60 с"; }
            part sourceLabel : Label { attribute :>> posX = 570; attribute :>> posY = 78; attribute :>> width = 570; attribute :>> height = 28; attribute :>> caption = "Источник: 10.0.2.99, учётная запись admin"; }
        }

        part evidence : Table {
            attribute :>> posX = 24; attribute :>> posY = 210; attribute :>> width = 1152; attribute :>> height = 260; attribute :>> caption = "События, вызвавшие инцидент";
            attribute :>> columns = "Время|Тип события|Учётная запись|Источник";
            attribute :>> columnWidths = "180|420|272|280";
            part row1 : TableRow { attribute :>> cells = "10:14:22|Неудачный вход (4625)|admin|10.0.2.99"; }
            part row2 : TableRow { attribute :>> cells = "10:14:29|Неудачный вход (4625)|admin|10.0.2.99"; }
            part row3 : TableRow { attribute :>> cells = "10:14:37|Неудачный вход (4625)|admin|10.0.2.99"; }
            part row4 : TableRow { attribute :>> cells = "…|ещё 3 события|…|…"; }
        }

        part comments : Panel {
            attribute :>> posX = 24; attribute :>> posY = 484; attribute :>> width = 1152; attribute :>> height = 176; attribute :>> caption = "Комментарии";
            part oldComment : Label { attribute :>> posX = 14; attribute :>> posY = 46; attribute :>> width = 1120; attribute :>> height = 28; attribute :>> caption = "10:17 petrov: Позвонил пользователю, вход выполнял не он"; }
            part commentField : TextField { attribute :>> posX = 14; attribute :>> posY = 96; attribute :>> width = 930; attribute :>> height = 48; attribute :>> subcaption = "Новый комментарий"; }
            part addButton : Button { attribute :>> posX = 958; attribute :>> posY = 96; attribute :>> width = 180; attribute :>> height = 48; attribute :>> caption = "Добавить"; }
        }

        part flyButton : Button { attribute :>> posX = 24; attribute :>> posY = 680; attribute :>> width = 260; attribute :>> height = 52; attribute :>> caption = "Показать на сцене"; }
        part resolveButton : PrimaryButton { attribute :>> posX = 700; attribute :>> posY = 680; attribute :>> width = 230; attribute :>> height = 52; attribute :>> caption = "Решён"; }
        part falseButton : Button { attribute :>> posX = 946; attribute :>> posY = 680; attribute :>> width = 230; attribute :>> height = 52; attribute :>> caption = "Ложное"; }
    }
}
