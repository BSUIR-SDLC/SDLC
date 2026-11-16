/**
 * Мокапы экранов веб-приложения SubScope (трекер подписок).
 * Каждый экран — отдельный пакет с одной частью типа UiKit::Screen.
 * PNG-изображения строятся из этой модели: srs/tools/sysml2png.py.
 */
package SubScopeMockups {

    /** Экран 1. Вход и регистрация (REQ-FUNC-001, REQ-FUNC-002, REQ-FUNC-021). */
    package LoginMockup {
        private import UiKit::*;

        part loginScreen : Screen {
            attribute :>> title = "SubScope — вход";
            attribute :>> url = "https://subscope.local/login";

            part header : NavBar {
                attribute :>> text = "SubScope";
            }
            part body : Row {
                part leftGap : Column;
                part forms : Row {
                    attribute :>> weight = 4;
                    part loginForm : Panel {
                        attribute :>> text = "Вход";
                        part email : TextField {
                            attribute :>> label = "E-mail";
                            attribute :>> text = "student@example.com";
                        }
                        part password : PasswordField {
                            attribute :>> label = "Пароль";
                            attribute :>> text = "••••••••••";
                        }
                        part remember : Checkbox {
                            attribute :>> text = "Запомнить меня";
                        }
                        part forgot : Link {
                            attribute :>> text = "Забыли пароль?";
                        }
                        part submit : Button {
                            attribute :>> text = "Войти";
                            attribute :>> primary = true;
                        }
                        part error : Label {
                            attribute :>> text = "Ошибка: неверный e-mail или пароль";
                            attribute :>> style = TextStyle::muted;
                        }
                    }
                    part registerForm : Panel {
                        attribute :>> text = "Регистрация";
                        part email : TextField {
                            attribute :>> label = "E-mail";
                        }
                        part password : PasswordField {
                            attribute :>> label = "Пароль (не менее 8 символов)";
                        }
                        part passwordRepeat : PasswordField {
                            attribute :>> label = "Повтор пароля";
                        }
                        part baseCurrency : Select {
                            attribute :>> label = "Базовая валюта";
                            attribute :>> text = "BYN";
                        }
                        part submit : Button {
                            attribute :>> text = "Создать аккаунт";
                        }
                    }
                }
                part rightGap : Column;
            }
        }
    }

    /** Экран 2. Обзор (REQ-FUNC-009, REQ-FUNC-010, REQ-FUNC-013, REQ-FUNC-015, REQ-FUNC-022). */
    package DashboardMockup {
        private import UiKit::*;

        part dashboardScreen : Screen {
            attribute :>> title = "SubScope — обзор";
            attribute :>> url = "https://subscope.local/dashboard";

            part header : NavBar {
                attribute :>> text = "SubScope";
                attribute :>> items = ("Обзор", "Подписки", "Аналитика", "Настройки");
                attribute :>> active = "Обзор";
                attribute :>> user = "student@example.com · Выйти";
            }
            part stats : Row {
                part perMonth : StatCard {
                    attribute :>> label = "В месяц";
                    attribute :>> text = "87,40 BYN";
                }
                part perYear : StatCard {
                    attribute :>> label = "В год";
                    attribute :>> text = "1 048,80 BYN";
                }
                part activeCount : StatCard {
                    attribute :>> label = "Активных подписок";
                    attribute :>> text = "6";
                }
                part unused : StatCard {
                    attribute :>> label = "Кандидаты на отмену";
                    attribute :>> text = "2 · 19,90 BYN";
                }
                part limit : StatCard {
                    attribute :>> label = "Лимит 100,00 BYN в месяц";
                    attribute :>> text = "87 % занято";
                }
            }
            part content : Row {
                part upcoming : Panel {
                    attribute :>> text = "Ближайшие списания (30 дней)";
                    attribute :>> weight = 3;
                    part charges : Table {
                        attribute :>> columns = ("Дата", "Сервис", "Сумма", "В базовой валюте", "Статус");
                        part r1 : TableRow {
                            attribute :>> cells = ("04.10.2026", "Яндекс Плюс", "12,90 BYN", "12,90 BYN", "через 2 дня");
                        }
                        part r2 : TableRow {
                            attribute :>> cells = ("09.10.2026", "Spotify (1/4)", "5,99 USD", "4,40 BYN", "через 7 дней");
                        }
                        part r3 : TableRow {
                            attribute :>> cells = ("15.10.2026", "JetBrains (пробный)", "0,00 USD", "—", "пробный период до 15.10");
                        }
                        part r4 : TableRow {
                            attribute :>> cells = ("21.10.2026", "Хостинг", "4,00 EUR", "13,72 BYN", "через 19 дней");
                        }
                    }
                    part usageHint : Label {
                        attribute :>> text = "Курсы НБ РБ на 02.10.2026. Отметьте, пользовались ли подпиской в этом месяце.";
                        attribute :>> style = TextStyle::muted;
                    }
                }
                part categories : Panel {
                    attribute :>> text = "Расходы по категориям";
                    attribute :>> weight = 2;
                    part pie : Chart {
                        attribute :>> kind = ChartKind::pie;
                        attribute :>> text = "Доля категорий в месячных расходах";
                    }
                }
            }
        }
    }

    /** Экран 3. Список подписок (REQ-FUNC-004 … REQ-FUNC-008, REQ-FUNC-012). */
    package SubscriptionListMockup {
        private import UiKit::*;

        part subscriptionListScreen : Screen {
            attribute :>> title = "SubScope — подписки";
            attribute :>> url = "https://subscope.local/subscriptions";

            part header : NavBar {
                attribute :>> text = "SubScope";
                attribute :>> items = ("Обзор", "Подписки", "Аналитика", "Настройки");
                attribute :>> active = "Подписки";
                attribute :>> user = "student@example.com · Выйти";
            }
            part toolbar : Row {
                part search : TextField {
                    attribute :>> text = "Поиск по названию";
                    attribute :>> weight = 3;
                }
                part category : Select {
                    attribute :>> text = "Все категории";
                    attribute :>> weight = 2;
                }
                part status : Select {
                    attribute :>> text = "Активные";
                    attribute :>> weight = 2;
                }
                part add : Button {
                    attribute :>> text = "+ Добавить";
                    attribute :>> primary = true;
                    attribute :>> weight = 2;
                }
            }
            part list : Table {
                attribute :>> columns = ("Сервис", "Категория", "Цена", "Период", "Следующее списание", "Использована", "Действия");
                part r1 : TableRow {
                    attribute :>> cells = ("Яндекс Плюс", "Развлечения", "12,90 BYN", "месяц", "04.10.2026", "[x] да", "Изменить · Пауза · Удалить");
                }
                part r2 : TableRow {
                    attribute :>> cells = ("Spotify", "Музыка", "5,99 USD", "месяц", "09.10.2026", "[x] да", "Изменить · Пауза · Удалить");
                }
                part r3 : TableRow {
                    attribute :>> cells = ("JetBrains", "Работа", "пробный", "год", "15.10.2026", "[ ] нет", "Изменить · Пауза · Удалить");
                }
                part r4 : TableRow {
                    attribute :>> cells = ("Хостинг", "Работа", "4,00 EUR", "месяц", "21.10.2026", "[x] да", "Изменить · Пауза · Удалить");
                }
                part r5 : TableRow {
                    attribute :>> cells = ("Онлайн-кинотеатр", "Развлечения", "9,90 BYN", "месяц", "28.10.2026", "[ ] нет", "Изменить · Пауза · Удалить");
                }
            }
            part footer : Label {
                attribute :>> text = "Показано 5 из 6 · Итого в месяц: 87,40 BYN · Пустой список: «Подписок пока нет — добавьте первую»";
                attribute :>> style = TextStyle::muted;
            }
        }
    }

    /** Экран 4. Форма подписки (REQ-FUNC-004, REQ-FUNC-005, REQ-FUNC-011, REQ-FUNC-019, REQ-FUNC-020). */
    package SubscriptionFormMockup {
        private import UiKit::*;

        part subscriptionFormScreen : Screen {
            attribute :>> title = "SubScope — новая подписка";
            attribute :>> url = "https://subscope.local/subscriptions/new";

            part header : NavBar {
                attribute :>> text = "SubScope";
                attribute :>> items = ("Обзор", "Подписки", "Аналитика", "Настройки");
                attribute :>> active = "Подписки";
                attribute :>> user = "student@example.com · Выйти";
            }
            part form : Panel {
                attribute :>> text = "Новая подписка";
                part line1 : Row {
                    part name : TextField {
                        attribute :>> label = "Название сервиса * (подсказки из каталога)";
                        attribute :>> text = "Spotify";
                        attribute :>> weight = 2;
                    }
                    part category : Select {
                        attribute :>> label = "Категория";
                        attribute :>> text = "Музыка";
                    }
                }
                part line2 : Row {
                    part price : TextField {
                        attribute :>> label = "Цена *";
                        attribute :>> text = "5,99";
                    }
                    part currency : Select {
                        attribute :>> label = "Валюта *";
                        attribute :>> text = "USD";
                    }
                    part period : Select {
                        attribute :>> label = "Период списания *";
                        attribute :>> text = "Каждый месяц";
                    }
                    part participants : Select {
                        attribute :>> label = "Участников тарифа";
                        attribute :>> text = "4 (моя доля 1/4)";
                    }
                }
                part line3 : Row {
                    part nextCharge : DateField {
                        attribute :>> label = "Дата следующего списания *";
                        attribute :>> text = "09.10.2026";
                    }
                    part trialEnd : DateField {
                        attribute :>> label = "Окончание пробного периода";
                        attribute :>> text = "дд.мм.гггг";
                    }
                    part remindDays : Select {
                        attribute :>> label = "Напомнить за";
                        attribute :>> text = "3 дня";
                    }
                }
                part note : TextField {
                    attribute :>> label = "Заметка (способ оплаты, тариф)";
                    attribute :>> text = "Семейный тариф, карта *1234";
                }
                part preview : Label {
                    attribute :>> text = "Ваша доля ≈ 4,40 BYN в месяц из 17,61 BYN по курсу НБ РБ на 02.10.2026 (1 USD = 2,9400 BYN)";
                    attribute :>> style = TextStyle::muted;
                }
                part buttons : Row {
                    part gap : Column {
                        attribute :>> weight = 4;
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

    /** Экран 5. Аналитика (REQ-FUNC-013, REQ-FUNC-014, REQ-FUNC-015). */
    package AnalyticsMockup {
        private import UiKit::*;

        part analyticsScreen : Screen {
            attribute :>> title = "SubScope — аналитика";
            attribute :>> url = "https://subscope.local/analytics";

            part header : NavBar {
                attribute :>> text = "SubScope";
                attribute :>> items = ("Обзор", "Подписки", "Аналитика", "Настройки");
                attribute :>> active = "Аналитика";
                attribute :>> user = "student@example.com · Выйти";
            }
            part filters : Row {
                part period : Select {
                    attribute :>> label = "Период";
                    attribute :>> text = "Последние 12 месяцев";
                }
                part category : Select {
                    attribute :>> label = "Категория";
                    attribute :>> text = "Все категории";
                }
                part gap : Column {
                    attribute :>> weight = 2;
                }
            }
            part charts : Row {
                part trend : Panel {
                    attribute :>> text = "Расходы по месяцам, BYN";
                    attribute :>> weight = 3;
                    part bars : Chart {
                        attribute :>> kind = ChartKind::bar;
                        attribute :>> text = "Сумма списаний за месяц в базовой валюте";
                    }
                }
                part rate : Panel {
                    attribute :>> text = "Влияние курса: Spotify, 5,99 USD";
                    attribute :>> weight = 2;
                    part line : Chart {
                        attribute :>> kind = ChartKind::line;
                        attribute :>> text = "Стоимость подписки в BYN по курсу НБ РБ";
                    }
                }
            }
            part candidates : Panel {
                attribute :>> text = "Кандидаты на отмену";
                part unusedTable : Table {
                    attribute :>> columns = ("Сервис", "Не использовалась", "Цена в месяц", "Экономия за год", "Действие");
                    part r1 : TableRow {
                        attribute :>> cells = ("Онлайн-кинотеатр", "3 месяца", "9,90 BYN", "118,80 BYN", "Отметить отменённой");
                    }
                    part r2 : TableRow {
                        attribute :>> cells = ("JetBrains (пробный)", "2 месяца", "10,00 BYN", "120,00 BYN", "Отметить отменённой");
                    }
                }
            }
        }
    }

    /** Экран 6. Настройки (REQ-FUNC-003, REQ-FUNC-011, REQ-FUNC-015, REQ-FUNC-022, REQ-FUNC-023). */
    package SettingsMockup {
        private import UiKit::*;

        part settingsScreen : Screen {
            attribute :>> title = "SubScope — настройки";
            attribute :>> url = "https://subscope.local/settings";

            part header : NavBar {
                attribute :>> text = "SubScope";
                attribute :>> items = ("Обзор", "Подписки", "Аналитика", "Настройки");
                attribute :>> active = "Настройки";
                attribute :>> user = "student@example.com · Выйти";
            }
            part columns : Row {
                part profile : Panel {
                    attribute :>> text = "Профиль";
                    part email : TextField {
                        attribute :>> label = "E-mail";
                        attribute :>> text = "student@example.com";
                    }
                    part baseCurrency : Select {
                        attribute :>> label = "Базовая валюта";
                        attribute :>> text = "BYN — белорусский рубль";
                    }
                    part newPassword : PasswordField {
                        attribute :>> label = "Новый пароль";
                    }
                    part save : Button {
                        attribute :>> text = "Сохранить профиль";
                        attribute :>> primary = true;
                    }
                }
                part notifications : Panel {
                    attribute :>> text = "Напоминания";
                    part channel : Select {
                        attribute :>> label = "Канал напоминаний";
                        attribute :>> text = "Telegram (@student_by)";
                    }
                    part telegramLink : Link {
                        attribute :>> text = "Отвязать Telegram";
                    }
                    part defaultDays : Select {
                        attribute :>> label = "Напоминать о списании за";
                        attribute :>> text = "3 дня";
                    }
                    part trialOn : Checkbox {
                        attribute :>> text = "Напоминать о конце пробного периода";
                        attribute :>> checked = true;
                    }
                    part usageOn : Checkbox {
                        attribute :>> text = "Спрашивать об использовании подписок";
                        attribute :>> checked = true;
                    }
                    part unusedThreshold : Select {
                        attribute :>> label = "Кандидат на отмену после";
                        attribute :>> text = "2 месяцев без использования";
                    }
                    part save : Button {
                        attribute :>> text = "Сохранить напоминания";
                    }
                }
                part data : Panel {
                    attribute :>> text = "Лимит и данные";
                    part monthlyLimit : TextField {
                        attribute :>> label = "Месячный лимит, BYN (пусто — без лимита)";
                        attribute :>> text = "100,00";
                    }
                    part saveLimit : Button {
                        attribute :>> text = "Сохранить лимит";
                    }
                    part hint : Label {
                        attribute :>> text = "Удаление аккаунта необратимо.";
                        attribute :>> style = TextStyle::muted;
                    }
                    part delete : Button {
                        attribute :>> text = "Удалить аккаунт";
                    }
                }
            }
        }
    }
}
