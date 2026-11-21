/**
 * Mockups — прототипы экранов настольного приложения PillTrack.
 * Каждый экран — часть типа UiKit::Screen, внутри которой вложены элементы интерфейса.
 * PNG-изображения строятся из этой модели: srs/tools/Sysml2Png.
 */
package PillTrackMockups {

    /** Экран 1. Сегодня (REQ-FUNC-004, REQ-FUNC-007, REQ-FUNC-008, REQ-FUNC-012, REQ-FUNC-019, REQ-FUNC-021). */
    package TodayMockup {
        private import UiKit::*;

        part todayScreen : Screen {
            attribute :>> title = "PillTrack — сегодня";
            part tabs : TabBar {
                attribute :>> text = "PillTrack";
                attribute :>> items = ("Сегодня", "Препараты", "Статистика", "Настройки");
                attribute :>> active = "Сегодня";
                attribute :>> user = "Профиль: Я ▾";
            }
            part missed : Banner {
                attribute :>> text = "Пока компьютер был выключен, пропущено напоминаний: 1 (28.10, 21:00 — Аторвастатин 20 мг). Отметьте, был ли приём.";
                attribute :>> tone = Tone::warning;
            }
            part stats : Row {
                part done : StatCard {
                    attribute :>> label = "Приёмов сегодня";
                    attribute :>> text = "2 из 6";
                }
                part adherence : StatCard {
                    attribute :>> label = "Соблюдение за 7 дней";
                    attribute :>> text = "92 %";
                    attribute :>> tone = Tone::success;
                }
                part next : StatCard {
                    attribute :>> label = "Следующий приём";
                    attribute :>> text = "14:10 · Амоксициллин";
                }
                part lowStock : StatCard {
                    attribute :>> label = "Заканчивается";
                    attribute :>> text = "Аторвастатин · 4 дня";
                    attribute :>> tone = Tone::warning;
                }
            }
            part body : Row {
                part schedule : Panel {
                    attribute :>> text = "Расписание на 29.10.2026, четверг";
                    attribute :>> weight = 3;
                    part doses : Table {
                        attribute :>> columns = ("Время", "Препарат", "Доза", "Указание", "Статус", "Действия");
                        part r1 : TableRow { attribute :>> cells = ("08:00", "Метформин 500 мг", "½ таб.", "после еды", "✓ принято 08:04", "Исправить"); }
                        part r2 : TableRow { attribute :>> cells = ("08:00", "Амоксициллин 500 мг", "1 капс.", "после еды", "✓ принято 08:04", "Исправить"); }
                        part r4 : TableRow { attribute :>> cells = ("14:00", "Амоксициллин 500 мг", "1 капс.", "после еды", "отложено до 14:10", "Принято · Пропустить"); }
                        part r5 : TableRow { attribute :>> cells = ("20:00", "Метформин 500 мг", "½ таб.", "после еды", "ожидает", "Принято · Пропустить"); }
                        part r6 : TableRow { attribute :>> cells = ("20:00", "Амоксициллин 500 мг", "1 капс.", "после еды", "ожидает", "Принято · Пропустить"); }
                        part r7 : TableRow { attribute :>> cells = ("21:00", "Аторвастатин 20 мг", "1 таб.", "вечером", "ожидает", "Принято · Пропустить"); }
                    }
                    part actions : Row {
                        part prn : Button {
                            attribute :>> text = "+ Разовый приём";
                        }
                        part hint : Label {
                            attribute :>> text = "Разовый приём — для препаратов «по необходимости», например Ибупрофен";
                            attribute :>> style = TextStyle::muted;
                            attribute :>> weight = 3;
                        }
                    }
                }
                part stock : Panel {
                    attribute :>> text = "Запас лекарств";
                    attribute :>> weight = 2;
                    part stockTable : Table {
                        attribute :>> columns = ("Препарат", "Осталось", "Хватит до");
                        part s1 : TableRow { attribute :>> cells = ("Аторвастатин", "4 таб.", "01.11 ⚠"); }
                        part s2 : TableRow { attribute :>> cells = ("Амоксициллин", "9 капс.", "01.11 ⚠"); }
                        part s3 : TableRow { attribute :>> cells = ("Витамин D3", "18 капс.", "18.12"); }
                        part s4 : TableRow { attribute :>> cells = ("Метформин", "23 таб.", "21.11"); }
                    }
                    part refill : Button {
                        attribute :>> text = "Пополнить запас";
                    }
                }
            }
        }
    }

    /** Экран 2. Препараты и курсы (REQ-FUNC-001, REQ-FUNC-003, REQ-FUNC-010, REQ-FUNC-011, REQ-FUNC-012, REQ-FUNC-022). */
    package MedicinesMockup {
        private import UiKit::*;

        part medicinesScreen : Screen {
            attribute :>> title = "PillTrack — препараты";
            part tabs : TabBar {
                attribute :>> text = "PillTrack";
                attribute :>> items = ("Сегодня", "Препараты", "Статистика", "Настройки");
                attribute :>> active = "Препараты";
                attribute :>> user = "Профиль: Я ▾";
            }
            part toolbar : Row {
                part search : TextField {
                    attribute :>> text = "Поиск по названию";
                    attribute :>> weight = 3;
                }
                part filter : Select {
                    attribute :>> text = "Активные курсы";
                    attribute :>> weight = 2;
                }
                part refill : Button {
                    attribute :>> text = "Пополнить запас";
                }
                part add : Button {
                    attribute :>> text = "+ Добавить";
                    attribute :>> primary = true;
                }
            }
            part list : Table {
                attribute :>> columns = ("Препарат", "Доза", "Схема", "Время", "Курс", "Остаток", "Хватит до", "Действия");
                part m1 : TableRow { attribute :>> cells = ("Метформин 500 мг", "½ таб.", "ежедневно", "08:00, 20:00", "бессрочно", "23 таб.", "21.11.2026", "Изменить · Пауза · Завершить"); }
                part m2 : TableRow { attribute :>> cells = ("Амоксициллин 500 мг", "1 капс.", "ежедневно", "08, 14, 20 ч", "27.10–02.11", "9 капс.", "01.11.2026 ⚠", "Изменить · Пауза · Завершить"); }
                part m3 : TableRow { attribute :>> cells = ("Аторвастатин 20 мг", "1 таб.", "ежедневно", "21:00", "бессрочно", "4 таб.", "01.11.2026 ⚠", "Изменить · Пауза · Завершить"); }
                part m4 : TableRow { attribute :>> cells = ("Витамин D3 2000 МЕ", "1 капс.", "пн, ср, пт", "09:00", "пауза до 05.11", "18 капс.", "18.12.2026", "Изменить · Возобновить"); }
                part m5 : TableRow { attribute :>> cells = ("Ибупрофен 200 мг", "1 таб.", "по необх.", "—", "—", "9 таб.", "—", "Изменить · Пауза · Завершить"); }
            }
            part footer : Label {
                attribute :>> text = "Показано 5 из 5 · завершённых курсов: 2 · ⚠ — запас закончится раньше, чем через 5 дней";
                attribute :>> style = TextStyle::muted;
            }
        }
    }

    /** Экран 3. Форма курса приёма (REQ-FUNC-001, REQ-FUNC-002, REQ-FUNC-013). */
    package CourseFormMockup {
        private import UiKit::*;

        part courseFormScreen : Screen {
            attribute :>> title = "PillTrack — новый курс приёма";
            attribute :>> width = 1000;
            part form : Panel {
                attribute :>> text = "Новый курс приёма";
                part line1 : Row {
                    part name : TextField {
                        attribute :>> label = "Название препарата *";
                        attribute :>> text = "Амоксициллин";
                        attribute :>> weight = 2;
                    }
                    part form : Select {
                        attribute :>> label = "Форма выпуска";
                        attribute :>> text = "Капсула";
                    }
                    part strength : TextField {
                        attribute :>> label = "Дозировка";
                        attribute :>> text = "500 мг";
                    }
                }
                part line2 : Row {
                    part scheme : Select {
                        attribute :>> label = "Схема приёма *";
                        attribute :>> text = "Ежедневно";
                    }
                    part amount : NumberField {
                        attribute :>> label = "Количество на приём * (шаг ¼)";
                        attribute :>> text = "1";
                    }
                    part instruction : Select {
                        attribute :>> label = "Указание";
                        attribute :>> text = "После еды";
                    }
                }
                part line3 : Row {
                    part t1 : TimeField {
                        attribute :>> label = "Время приёма *";
                        attribute :>> text = "08:00";
                    }
                    part t2 : TimeField {
                        attribute :>> label = " ";
                        attribute :>> text = "14:00";
                    }
                    part t3 : TimeField {
                        attribute :>> label = " ";
                        attribute :>> text = "20:00";
                    }
                    part addTime : Link {
                        attribute :>> text = "+ добавить время";
                    }
                }
                part line4 : Row {
                    part start : DateField {
                        attribute :>> label = "Дата начала *";
                        attribute :>> text = "27.10.2026";
                    }
                    part duration : Select {
                        attribute :>> label = "Длительность";
                        attribute :>> text = "7 дней (до 02.11.2026)";
                    }
                    part stock : NumberField {
                        attribute :>> label = "В наличии, шт.";
                        attribute :>> text = "16";
                    }
                    part buyBefore : NumberField {
                        attribute :>> label = "Напомнить о покупке за, дн.";
                        attribute :>> text = "5";
                    }
                }
                part note : TextField {
                    attribute :>> label = "Примечание";
                    attribute :>> text = "Назначил терапевт 27.10, пить полный курс";
                }
                part warning : Banner {
                    attribute :>> text = "На курс нужно 21 капс., в наличии 16 — запас закончится 01.11.2026, раньше окончания курса";
                    attribute :>> tone = Tone::warning;
                }
                part buttons : Row {
                    part gap : Column {
                        attribute :>> weight = 3;
                    }
                    part cancel : Button {
                        attribute :>> text = "Отмена";
                    }
                    part save : Button {
                        attribute :>> text = "Сохранить";
                        attribute :>> primary = true;
                    }
                }
            }
        }
    }

    /** Экран 4. Напоминание о приёме (REQ-INT-002, REQ-FUNC-005, REQ-FUNC-006, REQ-FUNC-007, REQ-FUNC-008). */
    package ReminderMockup {
        private import UiKit::*;

        part reminderScreen : Screen {
            attribute :>> title = "PillTrack — напоминание";
            attribute :>> width = 560;
            part heading : Label {
                attribute :>> text = "Пора принять лекарство · 14:00";
                attribute :>> style = TextStyle::heading;
            }
            part dose : Panel {
                part what : Label {
                    attribute :>> text = "Амоксициллин 500 мг — 1 капсула";
                }
                part details : Label {
                    attribute :>> text = "После еды · профиль «Я» · курс до 02.11.2026";
                    attribute :>> style = TextStyle::muted;
                }
            }
            part buttons : Row {
                part taken : Button {
                    attribute :>> text = "Принято";
                    attribute :>> primary = true;
                }
                part snooze : Select {
                    attribute :>> text = "Отложить на 10 мин";
                    attribute :>> weight = 2;
                }
                part skip : Button {
                    attribute :>> text = "Пропустить";
                }
            }
            part autoSkip : Label {
                attribute :>> text = "Без отметки приём будет считаться пропущенным в 16:00";
                attribute :>> style = TextStyle::muted;
            }
        }
    }

    /** Экран 5. Статистика соблюдения курса (REQ-FUNC-014, REQ-FUNC-015, REQ-FUNC-020). */
    package StatisticsMockup {
        private import UiKit::*;

        part statisticsScreen : Screen {
            attribute :>> title = "PillTrack — статистика";
            part tabs : TabBar {
                attribute :>> text = "PillTrack";
                attribute :>> items = ("Сегодня", "Препараты", "Статистика", "Настройки");
                attribute :>> active = "Статистика";
                attribute :>> user = "Профиль: Я ▾";
            }
            part filters : Row {
                part period : Select {
                    attribute :>> label = "Период";
                    attribute :>> text = "30 дней (30.09–29.10.2026)";
                    attribute :>> weight = 2;
                }
                part medicine : Select {
                    attribute :>> label = "Препарат";
                    attribute :>> text = "Все препараты";
                    attribute :>> weight = 2;
                }
                part pdf : Button {
                    attribute :>> text = "Отчёт для врача (PDF)";
                    attribute :>> primary = true;
                    attribute :>> weight = 2;
                }
                part csv : Button {
                    attribute :>> text = "Экспорт CSV";
                }
            }
            part cards : Row {
                part adherence : StatCard {
                    attribute :>> label = "Соблюдение курса";
                    attribute :>> text = "93 %";
                    attribute :>> tone = Tone::success;
                }
                part taken : StatCard {
                    attribute :>> label = "Принято";
                    attribute :>> text = "102 из 110";
                }
                part late : StatCard {
                    attribute :>> label = "С опозданием > 30 мин";
                    attribute :>> text = "5";
                    attribute :>> tone = Tone::warning;
                }
                part missed : StatCard {
                    attribute :>> label = "Пропущено";
                    attribute :>> text = "8";
                    attribute :>> tone = Tone::danger;
                }
            }
            part charts : Row {
                part byDay : Panel {
                    attribute :>> text = "Соблюдение по дням, %";
                    attribute :>> weight = 3;
                    part chart : Chart {
                        attribute :>> kind = ChartKind::bar;
                        attribute :>> labels = ("16.10", "17.10", "18.10", "19.10", "20.10", "21.10", "22.10", "23.10", "24.10", "25.10", "26.10", "27.10", "28.10", "29.10");
                        attribute :>> values = (100, 100, 75, 100, 100, 100, 67, 100, 100, 75, 100, 100, 83, 100);
                    }
                }
                part byStatus : Panel {
                    attribute :>> text = "Отметки за период";
                    attribute :>> weight = 2;
                    part chart : Chart {
                        attribute :>> kind = ChartKind::pie;
                        attribute :>> labels = ("Вовремя", "С опозданием", "Пропущено");
                        attribute :>> values = (97, 5, 8);
                    }
                }
            }
            part byMedicine : Table {
                attribute :>> columns = ("Препарат", "Назначено", "Принято", "Пропущено", "Соблюдение");
                part a1 : TableRow { attribute :>> cells = ("Метформин 500 мг", "60", "57", "3", "95 %"); }
                part a2 : TableRow { attribute :>> cells = ("Аторвастатин 20 мг", "30", "26", "4", "87 %"); }
                part a3 : TableRow { attribute :>> cells = ("Витамин D3 2000 МЕ", "13", "12", "1", "92 %"); }
                part a4 : TableRow { attribute :>> cells = ("Амоксициллин 500 мг", "7", "7", "0", "100 %"); }
                part a5 : TableRow { attribute :>> cells = ("Ибупрофен 200 мг", "по необх.", "3", "—", "—"); }
            }
        }
    }

    /** Экран 6. Настройки (REQ-FUNC-016, REQ-FUNC-017, REQ-FUNC-018, REQ-SEC-002). */
    package SettingsMockup {
        private import UiKit::*;

        part settingsScreen : Screen {
            attribute :>> title = "PillTrack — настройки";
            part tabs : TabBar {
                attribute :>> text = "PillTrack";
                attribute :>> items = ("Сегодня", "Препараты", "Статистика", "Настройки");
                attribute :>> active = "Настройки";
                attribute :>> user = "Профиль: Я ▾";
            }
            part body : Row {
                part profiles : Panel {
                    attribute :>> text = "Профили";
                    part list : Table {
                        attribute :>> columns = ("Профиль", "Активных курсов", "Соблюдение, 30 дн.");
                        part p1 : TableRow { attribute :>> cells = ("Я (Руслан)", "5", "93 %"); }
                        part p2 : TableRow { attribute :>> cells = ("Мама", "3", "97 %"); }
                    }
                    part buttons : Row {
                        part add : Button {
                            attribute :>> text = "+ Добавить";
                        }
                        part rename : Button {
                            attribute :>> text = "Переименовать";
                        }
                        part remove : Button {
                            attribute :>> text = "Удалить";
                        }
                    }
                    part hint : Label {
                        attribute :>> text = "До 5 профилей; курсы и статистика ведутся отдельно для каждого";
                        attribute :>> style = TextStyle::muted;
                    }
                }
                part reminders : Panel {
                    attribute :>> text = "Напоминания";
                    part repeat : Row {
                        part every : Select {
                            attribute :>> label = "Повтор, если нет отметки";
                            attribute :>> text = "через 10 мин";
                        }
                        part times : Select {
                            attribute :>> label = "Повторов не более";
                            attribute :>> text = "3";
                        }
                    }
                    part limits : Row {
                        part missedAfter : Select {
                            attribute :>> label = "Считать пропущенным через";
                            attribute :>> text = "120 мин";
                        }
                        part buyBefore : Select {
                            attribute :>> label = "Напоминать о покупке за";
                            attribute :>> text = "5 дней";
                        }
                    }
                    part sound : Checkbox {
                        attribute :>> text = "Звуковой сигнал";
                        attribute :>> checked = true;
                    }
                    part autostart : Checkbox {
                        attribute :>> text = "Запускать вместе с Windows и сворачивать в область уведомлений";
                        attribute :>> checked = true;
                    }
                    part pin : Checkbox {
                        attribute :>> text = "Запрашивать PIN-код при открытии окна";
                    }
                }
            }
            part data : Panel {
                attribute :>> text = "Данные";
                part line : Row {
                    part info : Label {
                        attribute :>> text = "Резервная копия создаётся ежедневно, хранятся 7 последних · последняя: 29.10.2026 09:12";
                        attribute :>> style = TextStyle::muted;
                        attribute :>> weight = 4;
                    }
                    part backup : Button {
                        attribute :>> text = "Создать копию";
                    }
                    part restore : Button {
                        attribute :>> text = "Восстановить…";
                    }
                }
            }
        }
    }
}
