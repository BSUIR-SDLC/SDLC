package QRGate_UI {
    doc /*
     * Прототипы графического интерфейса QRGate (мокапы).
     * Каждый элемент экрана - часть (part) с координатами x, y и размерами w, h в пикселях
     * относительно родителя. PNG-изображения строятся из этой модели скриптом tools/sysml_render.py.
     */

    private import ScalarValues::*;

    abstract part def Widget {
        attribute x : Integer;
        attribute y : Integer;
        attribute w : Integer;
        attribute h : Integer;
        attribute text : String;
    }
    part def PhoneScreen :> Widget { doc /* экран смартфона, мобильное веб-приложение */ }
    part def BrowserWindow :> Widget { doc /* окно браузера, панель администратора */ }
    part def AppBar :> Widget;
    part def Label :> Widget;
    part def MutedLabel :> Widget;
    part def ValueLabel :> Widget;
    part def TitleLabel :> Widget;
    part def TextBox :> Widget;
    part def ComboBox :> Widget;
    part def Button :> Widget;
    part def PrimaryButton :> Button;
    part def Toggle :> Widget {
        doc /* переключатель: варианты через "|", selected - номер выбранного */
        attribute selected : Integer;
    }
    part def CameraView :> Widget { doc /* поток с камеры с рамкой наведения на QR */ }
    part def StatusCard :> Widget {
        doc /* карточка результата; tone: "ok" | "deny" | "warn" */
        attribute tone : String;
    }
    part def KpiCard :> Widget { doc /* text = "подпись|значение" */ }
    part def NavMenu :> Widget {
        doc /* пункты меню через "|", selected - номер активного */
        attribute selected : Integer;
    }
    part def Banner :> Widget { attribute tone : String; }
    part def Table :> Widget {
        doc /* columns - заголовки через "|"; rows - строки через ";", ячейки через "|" */
        attribute columns : String;
        attribute rows : String;
    }
    part def LineChart :> Widget {
        doc /* points - "время=значение" через ";"; capacity и threshold - горизонтальные линии */
        attribute points : String;
        attribute capacity : Integer;
        attribute threshold : Integer;
    }

    // ===== Экран 1. Сканер (UC-02, UC-03) =====
    part scannerScreen : PhoneScreen {
        :>> x = 0; :>> y = 0; :>> w = 390; :>> h = 800;
        :>> text = "Сканер";

        part bar : AppBar { :>> x = 0; :>> y = 0; :>> w = 390; :>> h = 56; :>> text = "QRGate  |  Главный вход"; }
        part direction : Toggle {
            :>> x = 20; :>> y = 76; :>> w = 350; :>> h = 44;
            :>> text = "ВХОД|ВЫХОД"; :>> selected = 0;
        }
        part camera : CameraView { :>> x = 20; :>> y = 138; :>> w = 350; :>> h = 380; :>> text = "Наведите камеру на QR-код"; }
        part hint : MutedLabel { :>> x = 20; :>> y = 530; :>> w = 350; :>> h = 24; :>> text = "Распознавание автоматически, без нажатия кнопок"; }
        part btnManual : Button { :>> x = 20; :>> y = 572; :>> w = 350; :>> h = 48; :>> text = "Ввести код вручную"; }
        part btnTorch : Button { :>> x = 20; :>> y = 632; :>> w = 170; :>> h = 44; :>> text = "Фонарик"; }
        part btnCamera : Button { :>> x = 200; :>> y = 632; :>> w = 170; :>> h = 44; :>> text = "Сменить камеру"; }
        part occupancy : ValueLabel { :>> x = 20; :>> y = 700; :>> w = 350; :>> h = 30; :>> text = "Внутри: 312 из 400  (78 %)"; }
        part net : MutedLabel { :>> x = 20; :>> y = 740; :>> w = 350; :>> h = 24; :>> text = "Связь с сервером: онлайн  |  Контролёр: Петров А."; }
    }

    // ===== Экран 2. Результат: проход разрешён (UC-02) =====
    part resultAllowed : PhoneScreen {
        :>> x = 0; :>> y = 0; :>> w = 390; :>> h = 800;
        :>> text = "Результат - разрешено";

        part bar : AppBar { :>> x = 0; :>> y = 0; :>> w = 390; :>> h = 56; :>> text = "QRGate  |  Главный вход"; }
        part card : StatusCard {
            :>> x = 20; :>> y = 80; :>> w = 350; :>> h = 200;
            :>> text = "ПРОХОД РАЗРЕШЁН|Вход зарегистрирован в 09:41:07"; :>> tone = "ok";
        }
        part lblName : TitleLabel { :>> x = 20; :>> y = 306; :>> w = 350; :>> h = 34; :>> text = "Иванова Мария Сергеевна"; }
        part lblType : Label { :>> x = 20; :>> y = 350; :>> w = 350; :>> h = 28; :>> text = "Пропуск: сотрудник, № P-000482"; }
        part lblValid : Label { :>> x = 20; :>> y = 384; :>> w = 350; :>> h = 28; :>> text = "Действует до: 31.12.2026"; }
        part lblZone : Label { :>> x = 20; :>> y = 418; :>> w = 350; :>> h = 28; :>> text = "Зоны: корпус 1, корпус 2"; }
        part btnNext : PrimaryButton { :>> x = 20; :>> y = 640; :>> w = 350; :>> h = 56; :>> text = "Следующий (авто через 3 с)"; }
        part occupancy : ValueLabel { :>> x = 20; :>> y = 720; :>> w = 350; :>> h = 30; :>> text = "Внутри: 313 из 400  (78 %)"; }
    }

    // ===== Экран 3. Результат: отказ (UC-02) =====
    part resultDenied : PhoneScreen {
        :>> x = 0; :>> y = 0; :>> w = 390; :>> h = 800;
        :>> text = "Результат - отказ";

        part bar : AppBar { :>> x = 0; :>> y = 0; :>> w = 390; :>> h = 56; :>> text = "QRGate  |  Главный вход"; }
        part card : StatusCard {
            :>> x = 20; :>> y = 80; :>> w = 350; :>> h = 200;
            :>> text = "ОТКАЗ В ПРОХОДЕ|Пропуск уже использован для входа"; :>> tone = "deny";
        }
        part lblName : TitleLabel { :>> x = 20; :>> y = 306; :>> w = 350; :>> h = 34; :>> text = "Сидоров Олег Викторович"; }
        part lblReason : Label { :>> x = 20; :>> y = 350; :>> w = 350; :>> h = 28; :>> text = "Причина: повторный вход (anti-passback)"; }
        part lblLast : Label { :>> x = 20; :>> y = 384; :>> w = 350; :>> h = 28; :>> text = "Последний вход: 08:57, Главный вход"; }
        part lblCode : MutedLabel { :>> x = 20; :>> y = 418; :>> w = 350; :>> h = 28; :>> text = "Код ответа: DENY_ALREADY_INSIDE"; }
        part btnCall : Button { :>> x = 20; :>> y = 576; :>> w = 350; :>> h = 52; :>> text = "Вызвать администратора"; }
        part btnNext : PrimaryButton { :>> x = 20; :>> y = 640; :>> w = 350; :>> h = 56; :>> text = "Следующий"; }
        part occupancy : ValueLabel { :>> x = 20; :>> y = 720; :>> w = 350; :>> h = 30; :>> text = "Внутри: 313 из 400  (78 %)"; }
    }

    // ===== Экран 4. Панель администратора: live-заполняемость (UC-05, UC-06) =====
    part dashboard : BrowserWindow {
        :>> x = 0; :>> y = 0; :>> w = 1280; :>> h = 780;
        :>> text = "https://qrgate.example/admin/occupancy";

        part nav : NavMenu {
            :>> x = 0; :>> y = 0; :>> w = 210; :>> h = 780;
            :>> text = "Заполняемость|Журнал проходов|Пропуска|Точки прохода|Пользователи|Настройки"; :>> selected = 0;
        }
        part title : TitleLabel { :>> x = 234; :>> y = 18; :>> w = 600; :>> h = 34; :>> text = "Заполняемость: Корпус 1 (live)"; }
        part cbObject : ComboBox { :>> x = 900; :>> y = 18; :>> w = 200; :>> h = 34; :>> text = "Корпус 1"; }
        part cbPeriod : ComboBox { :>> x = 1110; :>> y = 18; :>> w = 150; :>> h = 34; :>> text = "Сегодня"; }

        part alert : Banner {
            :>> x = 234; :>> y = 64; :>> w = 1026; :>> h = 36; :>> tone = "warn";
            :>> text = "Внимание: заполняемость 78 %. Предупреждение будет выдано при 90 % (360 чел.)";
        }

        part kpiInside : KpiCard { :>> x = 234; :>> y = 114; :>> w = 196; :>> h = 84; :>> text = "Внутри сейчас|313"; }
        part kpiCapacity : KpiCard { :>> x = 442; :>> y = 114; :>> w = 196; :>> h = 84; :>> text = "Вместимость|400"; }
        part kpiPercent : KpiCard { :>> x = 650; :>> y = 114; :>> w = 196; :>> h = 84; :>> text = "Заполняемость|78 %"; }
        part kpiPasses : KpiCard { :>> x = 858; :>> y = 114; :>> w = 196; :>> h = 84; :>> text = "Проходов сегодня|1 146"; }
        part kpiDenied : KpiCard { :>> x = 1066; :>> y = 114; :>> w = 194; :>> h = 84; :>> text = "Отказов сегодня|23"; }

        part chart : LineChart {
            :>> x = 234; :>> y = 212; :>> w = 1026; :>> h = 300;
            :>> text = "Количество людей внутри (обновление в реальном времени)";
            :>> points = "07:00=4;07:30=18;08:00=64;08:30=171;09:00=248;09:30=297;10:00=318;10:30=331;11:00=322;11:30=309;12:00=268;12:30=241;13:00=287;13:30=313";
            :>> capacity = 400; :>> threshold = 360;
        }

        part events : Table {
            :>> x = 234; :>> y = 526; :>> w = 1026; :>> h = 200;
            :>> columns = "Время|Точка прохода|Направление|Пропуск|Владелец|Результат";
            :>> rows = "13:31:52|Главный вход|Вход|P-000482|Иванова М. С.|Разрешено;13:31:40|Главный вход|Вход|P-000517|Сидоров О. В.|Отказ: повторный вход;13:31:12|Вход со двора|Выход|G-104233|Гость: Ким Д.|Разрешено;13:30:58|Главный вход|Вход|P-000033|Ковалёв И. П.|Отказ: пропуск отозван;13:30:41|Главный вход|Вход|G-104230|Гость: Лис А.|Разрешено";
        }
    }
}
