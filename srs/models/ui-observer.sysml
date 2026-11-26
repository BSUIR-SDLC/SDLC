// Карточка хоста для наблюдателя: кнопок действий нет. Требование: REQ-FUNC-025.
package UiObserver {
    private import UiLibrary::*;

    part observerScreen : Screen {
        attribute :>> width = 900;
        attribute :>> height = 600;
        attribute :>> caption = "Карточка хоста · sidorov · наблюдатель";

        part title : Heading { attribute :>> posX = 24; attribute :>> posY = 18; attribute :>> width = 500; attribute :>> height = 36; attribute :>> caption = "WS-214"; }
        part stateBadge : Badge { attribute :>> posX = 720; attribute :>> posY = 20; attribute :>> width = 156; attribute :>> height = 34; attribute :>> caption = "инцидент"; attribute :>> tone = "incident"; }

        part facts : Panel {
            attribute :>> posX = 24; attribute :>> posY = 70; attribute :>> width = 852; attribute :>> height = 170; attribute :>> caption = "Сведения";
            part ipLabel : Label { attribute :>> posX = 14; attribute :>> posY = 46; attribute :>> width = 800; attribute :>> height = 28; attribute :>> caption = "IP: 10.0.2.14 · Windows 11 23H2"; }
            part userLabel : Label { attribute :>> posX = 14; attribute :>> posY = 80; attribute :>> width = 800; attribute :>> height = 28; attribute :>> caption = "Пользователь: petrov_a"; }
            part roomLabel : Label { attribute :>> posX = 14; attribute :>> posY = 114; attribute :>> width = 800; attribute :>> height = 28; attribute :>> caption = "Комната 214, обычная зона"; }
        }

        part openIncidents : Panel {
            attribute :>> posX = 24; attribute :>> posY = 254; attribute :>> width = 852; attribute :>> height = 150; attribute :>> caption = "Открытые инциденты";
            part incident301 : ListRow { attribute :>> posX = 14; attribute :>> posY = 50; attribute :>> width = 824; attribute :>> height = 74; attribute :>> caption = "Возможный перебор пароля"; attribute :>> subcaption = "10:15:02 · новый"; attribute :>> tone = "incident"; }
        }

        part roleNote : Label { attribute :>> posX = 24; attribute :>> posY = 424; attribute :>> width = 852; attribute :>> height = 30; attribute :>> caption = "Кнопок смены статуса и комментариев для этой роли нет"; attribute :>> tone = "muted"; }
        part closeButton : Button { attribute :>> posX = 696; attribute :>> posY = 476; attribute :>> width = 180; attribute :>> height = 48; attribute :>> caption = "Закрыть"; }
    }
}
