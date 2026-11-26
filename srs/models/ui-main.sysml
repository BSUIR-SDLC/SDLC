// Главный экран консоли, уровень «этаж», роль оператора.
// Требования: REQ-FUNC-018 ... REQ-FUNC-025, REQ-REL-002.
package UiMain {
    private import UiLibrary::*;

    part mainScreen : Screen {
        attribute :>> width = 1600;
        attribute :>> height = 900;
        attribute :>> caption = "3D Security Monitoring Center";

        part topBar : Panel {
            attribute :>> posX = 0; attribute :>> posY = 0; attribute :>> width = 1600; attribute :>> height = 50;
            part breadcrumb : Heading { attribute :>> posX = 16; attribute :>> posY = 10; attribute :>> width = 700; attribute :>> height = 30; attribute :>> caption = "Объект «Северный» › Здание 1 › Этаж 2"; }
            part userLabel : Label { attribute :>> posX = 1010; attribute :>> posY = 10; attribute :>> width = 190; attribute :>> height = 30; attribute :>> caption = "petrov · оператор"; }
            part linkBadge : Badge { attribute :>> posX = 1215; attribute :>> posY = 8; attribute :>> width = 230; attribute :>> height = 34; attribute :>> caption = "Связь с сервером"; attribute :>> tone = "normal"; }
            part clockLabel : Label { attribute :>> posX = 1480; attribute :>> posY = 10; attribute :>> width = 100; attribute :>> height = 30; attribute :>> caption = "10:15:31"; }
        }

        part scene : Panel {
            attribute :>> posX = 16; attribute :>> posY = 62; attribute :>> width = 1120; attribute :>> height = 640; attribute :>> caption = "3D-сцена показана условным планом: этаж 2 (колесо мыши – приблизить, Esc – назад)";

            part room211 : Room {
                attribute :>> posX = 24; attribute :>> posY = 56; attribute :>> width = 340; attribute :>> height = 230; attribute :>> caption = "211"; attribute :>> tone = "restricted";
                part ws211 : Host { attribute :>> posX = 150; attribute :>> posY = 100; attribute :>> caption = "WS-211"; attribute :>> tone = "normal"; }
            }
            part room212 : Room {
                attribute :>> posX = 374; attribute :>> posY = 56; attribute :>> width = 340; attribute :>> height = 230; attribute :>> caption = "212"; attribute :>> tone = "restricted";
                part ws212 : Host { attribute :>> posX = 150; attribute :>> posY = 100; attribute :>> caption = "WS-212"; attribute :>> tone = "normal"; }
            }
            part room213 : Room {
                attribute :>> posX = 724; attribute :>> posY = 56; attribute :>> width = 372; attribute :>> height = 230; attribute :>> caption = "213"; attribute :>> tone = "service";
                part ws2131 : Host { attribute :>> posX = 60; attribute :>> posY = 100; attribute :>> caption = "WS-213-1"; attribute :>> tone = "warning"; }
                part ws2132 : Host { attribute :>> posX = 170; attribute :>> posY = 100; attribute :>> caption = "WS-213-2"; attribute :>> tone = "normal"; }
                part ws2133 : Host { attribute :>> posX = 280; attribute :>> posY = 100; attribute :>> caption = "WS-213-3"; attribute :>> tone = "normal"; }
            }
            part corridor : Label { attribute :>> posX = 24; attribute :>> posY = 296; attribute :>> width = 1072; attribute :>> height = 30; attribute :>> caption = "Коридор"; attribute :>> tone = "muted"; }
            part room214 : Room {
                attribute :>> posX = 24; attribute :>> posY = 336; attribute :>> width = 340; attribute :>> height = 230; attribute :>> caption = "214"; attribute :>> tone = "alarm";
                part ws214 : Host { attribute :>> posX = 90; attribute :>> posY = 100; attribute :>> caption = "WS-214"; attribute :>> tone = "incident"; }
                part ws2142 : Host { attribute :>> posX = 230; attribute :>> posY = 100; attribute :>> caption = "WS-214-2"; attribute :>> tone = "normal"; }
            }
            part room215 : Room {
                attribute :>> posX = 374; attribute :>> posY = 336; attribute :>> width = 340; attribute :>> height = 230; attribute :>> caption = "215"; attribute :>> tone = "restricted";
                part srv01 : Host { attribute :>> posX = 90; attribute :>> posY = 100; attribute :>> caption = "SRV-01"; attribute :>> tone = "normal"; }
                part srv02 : Host { attribute :>> posX = 230; attribute :>> posY = 100; attribute :>> caption = "SRV-02"; attribute :>> tone = "normal"; }
            }
            part room216 : Room {
                attribute :>> posX = 724; attribute :>> posY = 336; attribute :>> width = 372; attribute :>> height = 230; attribute :>> caption = "216"; attribute :>> tone = "service";
                part ws216 : Host { attribute :>> posX = 170; attribute :>> posY = 100; attribute :>> caption = "WS-216"; attribute :>> tone = "silent"; }
            }
            part legend : Label { attribute :>> posX = 24; attribute :>> posY = 584; attribute :>> width = 1072; attribute :>> height = 30; attribute :>> caption = "Зелёный – норма, жёлтый – предупреждение, красный – инцидент, серый – агент молчит; штриховка – режимная зона"; attribute :>> tone = "muted"; }
        }

        part incidents : Panel {
            attribute :>> posX = 1150; attribute :>> posY = 62; attribute :>> width = 434; attribute :>> height = 300; attribute :>> caption = "Открытые инциденты · 3";
            part incident301 : ListRow { attribute :>> posX = 14; attribute :>> posY = 50; attribute :>> width = 406; attribute :>> height = 74; attribute :>> caption = "Возможный перебор пароля"; attribute :>> subcaption = "WS-214 · 10:15:02 · новый"; attribute :>> tone = "incident"; }
            part incident300 : ListRow { attribute :>> posX = 14; attribute :>> posY = 132; attribute :>> width = 406; attribute :>> height = 74; attribute :>> caption = "Агент молчит"; attribute :>> subcaption = "WS-216 · 10:11:20 · новый"; attribute :>> tone = "silent"; }
            part incident298 : ListRow { attribute :>> posX = 14; attribute :>> posY = 214; attribute :>> width = 406; attribute :>> height = 74; attribute :>> caption = "Запуск PowerShell из Word"; attribute :>> subcaption = "WS-213-1 · 03:02:11 · в работе"; attribute :>> tone = "warning"; }
        }

        part hostCard : Panel {
            attribute :>> posX = 1150; attribute :>> posY = 374; attribute :>> width = 434; attribute :>> height = 328; attribute :>> caption = "Карточка хоста WS-214";
            part stateBadge : Badge { attribute :>> posX = 310; attribute :>> posY = 10; attribute :>> width = 110; attribute :>> height = 30; attribute :>> caption = "инцидент"; attribute :>> tone = "incident"; }
            part ipLabel : Label { attribute :>> posX = 14; attribute :>> posY = 50; attribute :>> width = 400; attribute :>> height = 26; attribute :>> caption = "IP: 10.0.2.14 · Windows 11 23H2"; }
            part userLabel2 : Label { attribute :>> posX = 14; attribute :>> posY = 78; attribute :>> width = 400; attribute :>> height = 26; attribute :>> caption = "Пользователь: petrov_a · комната 214"; }
            part eventsHeading : Label { attribute :>> posX = 14; attribute :>> posY = 112; attribute :>> width = 400; attribute :>> height = 26; attribute :>> caption = "Последние события"; attribute :>> tone = "muted"; }
            part event1 : Mono { attribute :>> posX = 14; attribute :>> posY = 140; attribute :>> width = 406; attribute :>> height = 24; attribute :>> caption = "10:14:37 неудачный вход admin"; }
            part event2 : Mono { attribute :>> posX = 14; attribute :>> posY = 164; attribute :>> width = 406; attribute :>> height = 24; attribute :>> caption = "10:14:29 неудачный вход admin"; }
            part event3 : Mono { attribute :>> posX = 14; attribute :>> posY = 188; attribute :>> width = 406; attribute :>> height = 24; attribute :>> caption = "10:14:22 неудачный вход admin"; }
            part takeButton : PrimaryButton { attribute :>> posX = 14; attribute :>> posY = 226; attribute :>> width = 200; attribute :>> height = 40; attribute :>> caption = "Взять в работу"; }
            part resolveButton : Button { attribute :>> posX = 222; attribute :>> posY = 226; attribute :>> width = 198; attribute :>> height = 40; attribute :>> caption = "Решён"; }
            part falseButton : Button { attribute :>> posX = 14; attribute :>> posY = 274; attribute :>> width = 200; attribute :>> height = 40; attribute :>> caption = "Ложное"; }
            part commentButton : Button { attribute :>> posX = 222; attribute :>> posY = 274; attribute :>> width = 198; attribute :>> height = 40; attribute :>> caption = "Комментарий"; }
        }

        part timeline : Panel {
            attribute :>> posX = 16; attribute :>> posY = 714; attribute :>> width = 1568; attribute :>> height = 130; attribute :>> caption = "Таймлайн: последний час";
            part slider : Slider { attribute :>> posX = 20; attribute :>> posY = 60; attribute :>> width = 1290; attribute :>> height = 50; attribute :>> subcaption = "09:15|10:15"; attribute :>> marks = "0.02:warning|0.93:silent|0.995:incident"; }
            part playButton : Button { attribute :>> posX = 1350; attribute :>> posY = 56; attribute :>> width = 196; attribute :>> height = 44; attribute :>> caption = "Воспроизвести"; }
        }
    }
}
