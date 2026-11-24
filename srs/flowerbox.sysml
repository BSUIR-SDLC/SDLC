/**
 * FlowerBox — модель бизнес-требований, вариантов использования, структуры системы,
 * поведения и графического интерфейса.
 *
 * Язык: OMG SysML v2 (текстовая нотация, спецификация OMG Systems Modeling Language 2.0).
 * Модель построена на парах «определение — использование» (def / usage), пакетах с импортом,
 * требованиях с субъектом и ограничениями, портах и интерфейсах, действиях, состояниях,
 * проверочных случаях и представлениях (view) — этих конструкций в SysML v1 нет.
 */
package FlowerBox {
    private import ScalarValues::*;

    // =====================================================================
    // 1. Предметная область: то, чем обмениваются части системы
    // =====================================================================
    package Domain {
        private import ScalarValues::*;

        enum def PackKind { enum paper; enum basket; enum box; }
        enum def OrderStatus { enum accepted; enum assembled; enum delivering; enum handed; }
        enum def Arrangement { enum mix; enum center; enum sides; enum rows; }

        item def Flower {
            doc /* Цветок или зелень, которые флорист выставил в конструктор */
            attribute name : String;
            attribute pricePerStem : Integer;   // BYN
            attribute isGreen : Boolean;
            attribute dotColor : String;        // цвет точки в мозаике «вид сверху»
        }

        item def StemGroup {
            doc /* Сколько стеблей одного вида в букете */
            ref item flower : Flower;
            attribute count : Integer;
        }

        item def Bouquet {
            doc /* Букет: готовый из каталога или собранный покупателем */
            item stems : StemGroup[1..*];
            attribute pack : PackKind;
            attribute sheets : Integer;          // листов бумаги, если pack == paper
            attribute arrangement : Arrangement;
            attribute price : Integer;           // BYN
        }

        item def Order {
            item bouquets : Bouquet[1..*];
            attribute recipient : String;
            attribute address : String;
            attribute slot : String;             // интервал доставки
            attribute total : Real;              // BYN с копейками
            attribute status : OrderStatus;
        }

        item def ImportantDate {
            attribute who : String;
            attribute day : Integer;
            attribute month : Integer;
            attribute remindDaysBefore : Integer;
        }

        // события, по которым меняется состояние заказа и экраны
        attribute def BouquetAssembled;
        attribute def CourierLeft;
        attribute def BouquetHanded;
        attribute def TabSelected { attribute index : Integer; }
        attribute def ProductOpened;
        attribute def BackPressed;
        attribute def OrderConfirmed;
    }

    // =====================================================================
    // 2. Заинтересованные стороны
    // =====================================================================
    package Stakeholders {
        part def Buyer     { doc /* Покупатель: выбирает или собирает букет и оформляет заказ */ }
        part def Recipient { doc /* Получатель букета */ }
        part def ShopOwner { doc /* Владелец магазина — заказчик разработки */ }
        part def Florist   { doc /* Флорист: ведёт каталог, собирает букеты, отвечает в чате */ }
        part def Courier   { doc /* Курьер: доставляет заказ */ }
    }

    // =====================================================================
    // 3. Структура системы: приложение, сервер магазина, внешний сервис
    // =====================================================================
    package Structure {
        private import Domain::*;
        private import ScalarValues::*;

        // --- интерфейсы между частями ---
        item def ApiRequest  { attribute path : String; attribute token : String; }
        item def ApiResponse { attribute status : Integer; }

        port def ShopApiPort {
            doc /* HTTP API магазина: каталог, конструктор, вход, заказы, чат, отзывы */
            out item request : ApiRequest;
            in item response : ApiResponse;
        }
        port def TelegramPort {
            doc /* Telegram Bot API: код входа и статусы заказа покупателю */
            out attribute message : String;
        }
        port def TouchPort {
            doc /* Сенсорный экран: нажатия и жесты покупателя */
            in attribute gesture : String;
        }

        interface def ShopLink {
            doc /* Приложение обращается к серверу магазина */
            end client : ShopApiPort;
            end server : ~ShopApiPort;
        }

        // --- вычисления и правила, общие для приложения и сервера ---
        constraint def EnoughPaper {
            doc /* Один лист бумаги на пять стеблей, но не меньше двух листов */
            in stems : Integer;
            in sheets : Integer;
            sheets >= 2 and sheets * 5 >= stems
        }

        calc def CartTotal {
            doc /* Сумма заказа: скидка по промокоду, доставка бесплатна от 100 BYN до скидки */
            in goods : Integer;
            in promoPercent : Integer;
            return total : Real = goods - goods * promoPercent / 100
                                  + (if goods > 0 and goods < 100 ? 10 else 0);
        }

        // --- экраны и элементы интерфейса ---
        part def Widget { attribute caption : String; }
        part def Button :> Widget;
        part def TextField :> Widget { attribute errorText : String; }
        part def CardList :> Widget { attribute columns : Integer; }
        part def Stepper :> Widget { attribute minimum : Integer; attribute maximum : Integer; }

        part def Screen {
            doc /* Экран приложения */
            attribute title : String;
            part widgets : Widget[0..*];
        }

        part def BottomCarousel {
            doc /* Живая карусель вкладок: видно три, остальные листаются жестом */
            attribute totalTabs : Integer = 5;
            attribute visibleTabs : Integer = 3;
        }

        part def BouquetBuilder {
            doc /* Конструктор «Собери сам»: цветы, расположение, упаковка, цвет */
            attribute stems : Integer;
            attribute kinds : Integer;
            attribute sheets : Integer;
            attribute total : Integer;
            assert constraint paperRule : EnoughPaper {
                in stems = BouquetBuilder::stems;
                in sheets = BouquetBuilder::sheets;
            }
        }

        part def FlowerBoxApp {
            doc /* Android-приложение покупателя (C++17, Qt 6 Quick) */
            port touch : TouchPort;
            port api : ShopApiPort;

            part nav : BottomCarousel;
            part builderLogic : BouquetBuilder;

            // пять вкладок карусели
            part home : Screen {
                part search : TextField;
                part reminder : Widget;      // ближайшая важная дата
                part banners : Widget;
                part hits : CardList;
            }
            part catalog : Screen {
                part search : TextField;
                part categories : Widget;
                part sortButton : Button;
                part filterButton : Button;
                part grid : CardList { :>> columns = 2; }
            }
            part builder : Screen {
                part mosaic : Widget;        // букет сверху: стебель — точка своего цвета
                part flowers : CardList;
                part count : Stepper { :>> minimum = 0; :>> maximum = 51; }
                part nextButton : Button;
            }
            part cart : Screen {
                part items : CardList;
                part promo : TextField;
                part applyPromo : Button;
                part totals : Widget;        // букеты, скидка, доставка, итого
                part orderButton : Button;
            }
            part profile : Screen {
                part purchases : Widget;     // «Мои покупки»
                part sections : Widget;      // Избранное · Даты · Заказы
                part favorites : CardList;
                part dates : CardList;
                part orders : CardList;
                part menu : CardList;        // адреса, оплата, уведомления, поддержка, политика, удаление
            }
            // экраны поверх вкладок
            part login : Screen {
                part mode : Widget;          // Вход · Регистрация
                part phone : TextField { :>> errorText = "В номере не хватает цифр"; }
                part password : TextField;
                part signIn : Button;
                part telegramLink : Button;
            }
            part product : Screen {
                part photo : Widget;
                part sizes : Widget;         // S · M · L с ценой
                part composition : Widget;
                part extras : CardList;      // открытка, ваза
                part quantity : Stepper { :>> minimum = 1; :>> maximum = 20; }
                part addButton : Button;
            }
            part checkout : Screen {
                part recipient : TextField;
                part recipientPhone : TextField;
                part address : TextField { :>> errorText = "Укажите номер дома"; }
                part askRecipient : Widget;  // «уточнить адрес у получателя»
                part slot : Widget;
                part card : TextField;       // текст открытки
                part payment : Widget;
                part confirm : Button;
            }
            part tracking : Screen {
                part steps : CardList;       // принят — собран — в пути — вручён
                part bouquet : Widget;
                part chatButton : Button;
            }
            part support : Screen;
        }

        part def ShopServer {
            doc /* Сервер магазина и панель флориста (C++17, Qt 6): каталог, заказы, чат, отзывы */
            port api : ~ShopApiPort;
            port telegram : TelegramPort;
            part floristPanel : Screen[1];
            attribute sessionDays : Integer = 30;
            attribute loginTries : Integer = 5;
        }

        part def TelegramService { port bot : ~TelegramPort; }

        part def FlowerBoxSystem {
            doc /* Система целиком: приложение и сервер в одной сети */
            part app : FlowerBoxApp;
            part server : ShopServer;
            part telegram : TelegramService;

            interface shopLink : ShopLink connect app.api to server.api;
            connect server.telegram to telegram.bot;
        }
    }

    // =====================================================================
    // 4. Требования
    // =====================================================================
    package Requirements {
        private import Domain::*;
        private import Structure::*;
        private import Stakeholders::*;
        private import ScalarValues::*;

        // --- бизнес-цели: требования верхнего уровня с измеримым критерием ---
        requirement def BusinessGoal {
            doc /* Цель владельца магазина с измеримым критерием успеха */
            subject shop : ShopOwner;
            attribute measured : Real;
            attribute target : Real;
        }

        requirement <'BG-1'> mobileOrders : BusinessGoal {
            doc /* Не менее 60 % заказов оформляется через приложение через 6 месяцев после запуска */
            attribute :>> target = 0.60;
            require constraint { measured >= target }
        }
        requirement <'BG-2'> higherCheck : BusinessGoal {
            doc /* Средний чек в приложении на 15 % выше, чем при заказе по телефону */
            attribute :>> target = 1.15;
            require constraint { measured >= target }
        }
        requirement <'BG-3'> repeatOrders : BusinessGoal {
            doc /* Не менее 30 % пользователей с важными датами заказывают по напоминанию */
            attribute :>> target = 0.30;
            require constraint { measured >= target }
        }
        requirement <'BG-4'> fewerCalls : BusinessGoal {
            doc /* Не более 10 % заказов требуют звонка оператора */
            attribute :>> target = 0.10;
            require constraint { measured <= target }
        }

        // --- функциональные требования ---
        requirement def FunctionalRequirement {
            subject app : FlowerBoxApp;
        }

        requirement <'REQ-FUNC-001'> signIn : FunctionalRequirement {
            doc /* Регистрация и вход по номеру телефона и паролю; вход по коду из Telegram,
                 * когда у магазина подключён бот. Каталог и конструктор доступны без входа. */
        }
        requirement <'REQ-FUNC-003'> catalogFilters : FunctionalRequirement {
            doc /* Каталог: категории, поиск, отдельная сортировка, фильтры по цене и «доставке сегодня» */
        }
        requirement <'REQ-FUNC-004'> productCard : FunctionalRequirement {
            doc /* Карточка букета: настоящее фото, размер S/M/L с пересчётом цены, состав, дополнения */
        }
        requirement <'REQ-FUNC-005'> builderFlowers : FunctionalRequirement {
            doc /* Конструктор: виды цветов и количество каждого (кнопками и вводом числа),
                 * букет показан сверху мозаикой точек */
            require constraint { app.builderLogic.stems >= 1 }
        }
        requirement <'REQ-FUNC-006'> builderArrangement : FunctionalRequirement {
            doc /* Шаг «расположение» показывается только при двух и более видах цветов */
        }
        requirement <'REQ-FUNC-007'> builderPackaging : FunctionalRequirement {
            doc /* Бумага: один лист на пять стеблей, не меньше двух; коробка — только размеры,
                 * в которые букет помещается */
            require constraint paper : EnoughPaper {
                in stems = app.builderLogic.stems;
                in sheets = app.builderLogic.sheets;
            }
        }
        requirement <'REQ-FUNC-008'> cartTotals : FunctionalRequirement {
            doc /* Корзина: количество, промокод, бесплатная доставка от 100 BYN */
        }
        requirement <'REQ-FUNC-009'> checkoutOrder : FunctionalRequirement {
            doc /* Оформление: получатель и его телефон, адрес или «уточнить у получателя»,
                 * интервал доставки, открытка, способ оплаты */
        }
        requirement <'REQ-FUNC-010'> orderTracking : FunctionalRequirement {
            doc /* Статусы «принят — собран — в пути — вручён» приходят с сервера магазина */
        }
        requirement <'REQ-FUNC-011'> dateReminders : FunctionalRequirement {
            doc /* Важные даты близких и напоминание с подбором букета */
        }
        requirement <'REQ-FUNC-017'> inputValidation : FunctionalRequirement {
            doc /* Каждое поле ввода проверяется; под неверным полем выводится причина ошибки */
        }

        // --- требования к серверу магазина ---
        requirement def ServerRequirement {
            subject server : ShopServer;
        }
        requirement <'REQ-SRV-001'> floristCatalog : ServerRequirement {
            doc /* Флорист в панели добавляет цветы и букеты с фото, меняет цены, снимает с продажи */
        }
        requirement <'REQ-SRV-002'> serverPricing : ServerRequirement {
            doc /* Сумму заказа считает сервер; заказ с другой суммой не принимается */
        }
        requirement <'REQ-SEC-001'> loginProtection : ServerRequirement {
            doc /* Пароль хранится хешем; после 5 неверных паролей вход закрыт на 10 минут;
                 * вход действует 30 дней */
            require constraint { server.loginTries <= 5 and server.sessionDays <= 30 }
        }

        // --- нефункциональные требования ---
        requirement <'REQ-INT-002'> liveCarousel {
            doc /* Нижняя карусель из 5 вкладок: видно 3, остальные листаются жестом */
            subject nav : BottomCarousel;
            require constraint { nav.totalTabs == 5 and nav.visibleTabs == 3 }
        }
        requirement <'REQ-PERF-001'> startupTime {
            doc /* Приложение запускается не более чем за 3 секунды */
            subject app : FlowerBoxApp;
            attribute startupSeconds : Real;
            require constraint { startupSeconds <= 3.0 }
        }

        // --- от целей к функциям: какая функция ради какой цели ---
        requirement goalsToFunctions {
            doc /* Прослеживаемость «бизнес-цель → функциональные требования» */
            require mobileOrders;
            require higherCheck;
            require repeatOrders;
            require fewerCalls;
        }
        dependency from catalogFilters, checkoutOrder, signIn to mobileOrders;
        dependency from builderFlowers, builderPackaging, productCard to higherCheck;
        dependency from dateReminders to repeatOrders;
        dependency from orderTracking, inputValidation to fewerCalls;
    }

    // =====================================================================
    // 5. Варианты использования
    // =====================================================================
    package UseCases {
        private import Stakeholders::*;
        private import Structure::*;
        private import Domain::*;

        use case def BrowseCatalog {
            subject app : FlowerBoxApp;
            actor buyer : Buyer;
            objective { doc /* Покупатель находит подходящий букет */ }
        }

        use case def BuildBouquet {
            subject app : FlowerBoxApp;
            actor buyer : Buyer;
            objective { doc /* Покупатель собирает свой букет и видит его цену */ }
        }

        use case def SignIn {
            subject app : FlowerBoxApp;
            actor buyer : Buyer;
            actor shop : ShopServer;
        }

        use case def PlaceOrder {
            subject app : FlowerBoxApp;
            actor buyer : Buyer;
            actor shop : ShopServer;
            objective { doc /* Заказ принят магазином по цене, которую видел покупатель */ }
            include use case signIn : SignIn;
        }

        use case def TrackOrder {
            subject app : FlowerBoxApp;
            actor buyer : Buyer;
            actor shop : ShopServer;
        }

        use case def GetReminder {
            subject app : FlowerBoxApp;
            actor buyer : Buyer;
            include use case browse : BrowseCatalog;
        }

        use case def ManageShop {
            subject server : ShopServer;
            actor florist : Florist;
            objective { doc /* Флорист ведёт каталог, цены и заказы без программиста */ }
        }

        // использования: сценарии конкретной системы
        use case browseCatalog : BrowseCatalog;
        use case buildBouquet : BuildBouquet;
        use case placeOrder : PlaceOrder;
        use case trackOrder : TrackOrder;
        use case getReminder : GetReminder;
        use case manageShop : ManageShop;
    }

    // =====================================================================
    // 6. Поведение
    // =====================================================================
    package Behavior {
        private import Domain::*;
        private import ScalarValues::*;

        action def ChooseFlowers { out stems : Integer; out kinds : Integer; }
        action def ArrangeFlowers;
        action def ChoosePack { in stems : Integer; }
        action def ChooseColor;
        action def AddToCart { out bouquet : Bouquet; }

        action def BuildBouquetFlow {
            doc /* Шаги конструктора; расположение — только при двух и более видах цветов */
            attribute kinds : Integer;

            first start;
            then action chooseFlowers : ChooseFlowers;
            then decide severalKinds;
                if kinds >= 2 then arrange;
                else choosePack;

            action arrange : ArrangeFlowers;
            then choosePack;

            action choosePack : ChoosePack;
            then action chooseColor : ChooseColor;
            then action addToCart : AddToCart;
            then done;
        }

        state def OrderLifecycle {
            doc /* Жизненный цикл заказа: статус меняет флорист в панели сервера */
            entry; then accepted;

            state accepted;
            state assembled;
            state delivering;
            state handed;

            transition accepted_to_assembled
                first accepted accept BouquetAssembled then assembled;
            transition assembled_to_delivering
                first assembled accept CourierLeft then delivering;
            transition delivering_to_handed
                first delivering accept BouquetHanded then handed;
        }

        state def Navigation {
            doc /* Переходы между экранами приложения */
            entry; then tabs;

            state tabs {
                doc /* Пять вкладок карусели; выбор вкладки не покидает состояние */
            }
            state productCard;
            state checkout;
            state tracking;

            transition first tabs accept ProductOpened then productCard;
            transition first productCard accept BackPressed then tabs;
            transition first tabs accept OrderConfirmed then checkout;
            transition first checkout accept OrderConfirmed then tracking;
            transition first checkout accept BackPressed then tabs;
            transition first tracking accept BackPressed then tabs;
        }
    }

    // =====================================================================
    // 7. Кто выполняет требования и как они проверяются
    // =====================================================================
    package Realization {
        private import Structure::*;
        private import Requirements::*;
        private import UseCases::*;
        private import Behavior::*;

        part flowerBox : FlowerBoxSystem {
            // экраны и части, выполняющие требования
            satisfy signIn by app.login;
            satisfy catalogFilters by app.catalog;
            satisfy productCard by app.product;
            satisfy builderFlowers by app.builder;
            satisfy builderArrangement by app.builder;
            satisfy builderPackaging by app.builderLogic;
            satisfy cartTotals by app.cart;
            satisfy checkoutOrder by app.checkout;
            satisfy orderTracking by app.tracking;
            satisfy dateReminders by app.profile;
            satisfy inputValidation by app.checkout;
            satisfy liveCarousel by app.nav;
            satisfy floristCatalog by server.floristPanel;
            satisfy serverPricing by server;
            satisfy loginProtection by server;

            // поведение, которое исполняют части
            perform action buildFlow : BuildBouquetFlow;
            exhibit state navigation : Navigation;
        }

        // --- проверка: автоматические тесты проекта ---
        verification def PackagingRulesTest {
            doc /* tests/tst_packaging: минимум листов бумаги и размеры коробки */
            subject builder : BouquetBuilder;
            objective { verify builderPackaging; }
        }
        verification def ServerPricingTest {
            doc /* tests/tst_network: заказ с устаревшей ценой сервер отклоняет */
            subject server : ShopServer;
            objective { verify serverPricing; }
        }
        verification def LoginProtectionTest {
            doc /* tests/tst_network: пять неверных паролей закрывают вход */
            subject server : ShopServer;
            objective { verify loginProtection; }
        }
    }

    // =====================================================================
    // 8. Представления: какие диаграммы строятся из модели и для кого
    // =====================================================================
    package ModelViews {
        private import Views::*;
        private import Stakeholders::*;

        concern clearScope {
            doc /* Заказчик хочет видеть, какие цели и функции входят в продукт */
            stakeholder owner : ShopOwner;
        }
        viewpoint ownerViewpoint {
            frame clearScope;
        }

        view requirementsView {
            doc /* Рисунки 3.2 и 3.3 отчёта: цели, требования и отношения satisfy */
            satisfy ownerViewpoint;
            expose Requirements::*;
            expose Realization::*;
            render asTreeDiagram;
        }
        view useCaseView {
            doc /* Рисунок 3.1 отчёта: варианты использования */
            expose UseCases::*;
            render asTreeDiagram;
        }
        view structureView {
            doc /* Рисунок 3.4 отчёта: части системы, порты и связи */
            expose Structure::FlowerBoxSystem::**;
            render asInterconnectionDiagram;
        }
        view behaviorView {
            doc /* Рисунок 3.5 отчёта: шаги конструктора и состояния заказа */
            expose Behavior::*;
            render asTreeDiagram;
        }
    }
}
