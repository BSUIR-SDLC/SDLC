/**
 * FlowerBox — архитектурная модель системного проектирования (SDD, ЛР №4).
 *
 * Язык: OMG SysML v2 (текстовая нотация, спецификация OMG Systems Modeling Language 2.0).
 * Продолжает модель бизнес-требований srs/flowerbox.sysml: уточняет системные требования
 * с приоритетами (10..50), модульную композицию клиента и сервера на C++17 / Qt 6,
 * логическую структуру классов, контракты HTTP/UDP/Telegram, информационную модель
 * атомарного хранилища, алгоритмы обработки и топологию развёртывания.
 */
package FlowerBoxDesign {
    private import ScalarValues::*;

    // =====================================================================
    // 1. Системные требования с приоритетами (10 — наивысший, 50 — минимальный)
    // =====================================================================
    package SystemRequirements {
        private import ScalarValues::*;

        requirement def SysRequirement {
            doc /* Системное требование с приоритетом 10..50 и ссылкой на SRS */
            attribute priority : Integer;
            attribute srsRef : String;
            attribute effortHours : Integer;
        }

        requirement <'SYS-01'> coreDomainLogic : SysRequirement {
            doc /* Pure C++17 domain core: pricing, packaging rules, mosaic layout, validation */
            attribute :>> priority = 10;
            attribute :>> srsRef = "REQ-FUNC-005, REQ-FUNC-007, REQ-FUNC-008, REQ-FUNC-017";
            attribute :>> effortHours = 24;
        }
        requirement <'SYS-02'> serverHttpAndStorage : SysRequirement {
            doc /* Embedded QTcpServer HTTP/1.1 API (:8080), UDP discovery (:45454), atomic JSON store */
            attribute :>> priority = 10;
            attribute :>> srsRef = "REQ-INT-005, REQ-SRV-002, REQ-REL-001";
            attribute :>> effortHours = 32;
        }
        requirement <'SYS-03'> authAndSecurity : SysRequirement {
            doc /* Password hashing, brute-force lockout (5 tries / 10 min), 30-day sessions, server pricing */
            attribute :>> priority = 10;
            attribute :>> srsRef = "REQ-FUNC-001, REQ-SEC-001, REQ-SEC-002, REQ-SRV-002";
            attribute :>> effortHours = 20;
        }
        requirement <'SYS-04'> catalogAndProductUi : SysRequirement {
            doc /* Home, Catalog (search/sort/filters), Product card (S/M/L, extras), Live Carousel */
            attribute :>> priority = 15;
            attribute :>> srsRef = "REQ-FUNC-002, REQ-FUNC-003, REQ-FUNC-004, REQ-INT-002";
            attribute :>> effortHours = 28;
        }
        requirement <'SYS-05'> bouquetBuilderUi : SysRequirement {
            doc /* 4-step bouquet builder with top-down dot mosaic, conditional arrangement, packaging */
            attribute :>> priority = 20;
            attribute :>> srsRef = "REQ-FUNC-005, REQ-FUNC-006, REQ-FUNC-007";
            attribute :>> effortHours = 36;
        }
        requirement <'SYS-06'> cartAndCheckout : SysRequirement {
            doc /* Cart totals, promo codes, checkout form with field validation and delivery slots */
            attribute :>> priority = 15;
            attribute :>> srsRef = "REQ-FUNC-008, REQ-FUNC-009, REQ-FUNC-017";
            attribute :>> effortHours = 24;
        }
        requirement <'SYS-07'> orderTrackingAndDates : SysRequirement {
            doc /* Order status polling (accepted->handed), important dates with reminders, favorites */
            attribute :>> priority = 25;
            attribute :>> srsRef = "REQ-FUNC-010, REQ-FUNC-011, REQ-FUNC-012";
            attribute :>> effortHours = 24;
        }
        requirement <'SYS-08'> floristPanel : SysRequirement {
            doc /* Desktop QML florist panel: catalog/flowers CRUD, photo background removal, order statuses */
            attribute :>> priority = 20;
            attribute :>> srsRef = "REQ-SRV-001";
            attribute :>> effortHours = 40;
        }
        requirement <'SYS-09'> telegramAndSupportChat : SysRequirement {
            doc /* Telegram Bot long-poll (login codes, status notifications), florist support chat, reviews */
            attribute :>> priority = 30;
            attribute :>> srsRef = "REQ-FUNC-001, REQ-FUNC-015, REQ-FUNC-016";
            attribute :>> effortHours = 28;
        }
        requirement <'SYS-10'> offlineCacheAndTests : SysRequirement {
            doc /* Offline cached catalog, local user data persistence, Qt Test suite (packaging/shop/network) */
            attribute :>> priority = 35;
            attribute :>> srsRef = "REQ-AVAIL-001, REQ-REL-001, REQ-PERF-001";
            attribute :>> effortHours = 20;
        }
    }

    // =====================================================================
    // 2. Композиция подсистем, порты и интерфейсы (Composition & Interface)
    // =====================================================================
    package Architecture {
        private import ScalarValues::*;

        // --- потоки данных и порты ---
        item def HttpPacket  { attribute method : String; attribute path : String; attribute jsonBody : String; }
        item def UdpBeacon   { attribute magic : String; attribute port : Integer; }
        item def TgUpdate    { attribute chatId : String; attribute text : String; }
        item def JsonSnapshot { attribute path : String; attribute checksum : String; }

        port def ShopApiPort {
            doc /* HTTP/1.1 REST JSON API на порту 8080 с Bearer-токеном */
            out item req : HttpPacket;
            in  item res : HttpPacket;
        }
        port def UdpDiscoveryPort {
            doc /* UDP broadcast автопоиска сервера в LAN на порту 45454 */
            out item probe : UdpBeacon;
            in  item reply : UdpBeacon;
        }
        port def TelegramPort {
            doc /* HTTPS long-polling к api.telegram.org */
            out item outgoing : TgUpdate;
            in  item incoming : TgUpdate;
        }
        port def StoragePort {
            doc /* Атомарная запись data.json.tmp -> rename -> data.json + .bak */
            inout item snapshot : JsonSnapshot;
        }
        port def QmlBindingPort {
            doc /* Qt Meta-Object System: Q_PROPERTY / Q_INVOKABLE / Signals */
            inout attribute binding : String;
        }

        interface def HttpRestLink {
            end client : ShopApiPort;
            end server : ~ShopApiPort;
        }
        interface def UdpLanLink {
            end client : UdpDiscoveryPort;
            end server : ~UdpDiscoveryPort;
        }
        interface def TelegramHttpsLink {
            end bot : TelegramPort;
            end api : ~TelegramPort;
        }

        // --- модули Android-клиента (FlowerBoxApp) ---
        part def CoreModule {
            doc /* Чистый C++17 без Qt UI: Pricing, Packaging, BouquetLayout, Validation, Catalog, Delivery */
        }
        part def ModelsModule {
            doc /* Qt-модели для QML: Shop, BouquetBuilder, CartModel, ProductListModel, FlowerListModel, Validator */
            port ui : QmlBindingPort;
        }
        part def NetModule {
            doc /* ApiClient: QNetworkAccessManager (HTTP) + QUdpSocket (автопоиск LAN) */
            port api : ShopApiPort;
            port udp : UdpDiscoveryPort;
        }
        part def QmlUiModule {
            doc /* Декларативный Qt Quick / QML: Nav, UserData, 21 страница, 14 компонентов */
            port models : ~QmlBindingPort;
        }

        part def FlowerBoxApp {
            doc /* Android-приложение покупателя (C++17, Qt 6.11 Quick, Android API 26+) */
            port api : ShopApiPort;
            port udp : UdpDiscoveryPort;

            part core   : CoreModule;
            part models : ModelsModule;
            part net    : NetModule;
            part qml    : QmlUiModule;

            connect models.ui to qml.models;
        }

        // --- модули сервера магазина (FlowerBoxServer) ---
        part def HttpServerModule {
            doc /* Встроенный HTTP/1.1 сервер на QTcpServer (src/server/HttpServer) */
            port api : ~ShopApiPort;
        }
        part def ShopServerEngine {
            doc /* Ядро сервера: маршрутизация API, пересчёт цен, сессии, rate-limit, UDP-ответчик */
            port udp : ~UdpDiscoveryPort;
            port storage : StoragePort;
            port ui : QmlBindingPort;
            attribute listenPort : Integer = 8080;
            attribute udpPort : Integer = 45454;
            attribute maxLoginTries : Integer = 5;
            attribute lockoutMinutes : Integer = 10;
            attribute sessionDays : Integer = 30;
        }
        part def TelegramBotModule {
            doc /* TelegramBot: getUpdates long-poll, выдача кодов входа и статусов заказа */
            port tg : TelegramPort;
        }
        part def FloristPanelUi {
            doc /* Десктопная QML-панель флориста (qml/server/Panel.qml) */
            port engine : ~QmlBindingPort;
        }
        part def AtomicFileStore {
            doc /* Локальное хранилище JSON + изображения букетов и спрайты цветов */
            port io : ~StoragePort;
        }

        part def ShopServerApp {
            doc /* FlowerBoxServer.exe (Windows, C++17, Qt 6 Quick) */
            port api : ~ShopApiPort;
            port udp : ~UdpDiscoveryPort;
            port tg  : TelegramPort;

            part http    : HttpServerModule;
            part engine  : ShopServerEngine;
            part bot     : TelegramBotModule;
            part panel   : FloristPanelUi;
            part store   : AtomicFileStore;

            connect engine.storage to store.io;
            connect engine.ui to panel.engine;
        }

        part def TelegramCloud {
            doc /* Внешний сервис Telegram Bot API (HTTPS) */
            port botApi : ~TelegramPort;
        }

        part def FlowerBoxSystem {
            part client   : FlowerBoxApp;
            part server   : ShopServerApp;
            part telegram : TelegramCloud;

            interface restLink : HttpRestLink connect client.api to server.api;
            interface lanLink  : UdpLanLink   connect client.udp to server.udp;
            interface tgLink   : TelegramHttpsLink connect server.tg to telegram.botApi;
        }
    }

    // =====================================================================
    // 3. Информационная модель (Information View)
    // =====================================================================
    package InformationModel {
        private import ScalarValues::*;

        item def UserRecord {
            attribute phone : String;
            attribute name : String;
            attribute passwordHash : String;
            attribute salt : String;
            attribute telegramChatId : String;
        }
        item def SessionRecord {
            attribute token : String;
            attribute phone : String;
            attribute expiresAt : Integer;
        }
        item def OrderRecord {
            attribute number : Integer;
            attribute clientPhone : String;
            attribute itemsJson : String;
            attribute promoCode : String;
            attribute serverTotal : Real;
            attribute status : Integer;
            attribute createdAt : String;
        }
        item def ProductRecord {
            attribute id : Integer;
            attribute title : String;
            attribute price : Integer;
            attribute oldPrice : Integer;
            attribute todayDelivery : Boolean;
            attribute hidden : Boolean;
            attribute photoPath : String;
        }
        item def FlowerRecord {
            attribute id : String;
            attribute name : String;
            attribute pricePerStem : Integer;
            attribute isGreen : Boolean;
            attribute enabled : Boolean;
            attribute dotColor : String;
        }
        item def ChatMessageRecord {
            attribute clientPhone : String;
            attribute fromFlorist : Boolean;
            attribute text : String;
            attribute timestamp : String;
        }
    }

    // =====================================================================
    // 4. Динамика, алгоритмы и ограничения (Interaction & Algorithm View)
    // =====================================================================
    package RuntimeBehavior {
        private import ScalarValues::*;

        constraint def EnoughPaperConstraint {
            doc /* Бумага: 1 лист на 5 стеблей, но не меньше 2 листов */
            in stems : Integer;
            in sheets : Integer;
            sheets >= 2 and sheets * 5 >= stems
        }

        calc def MinPaperSheets {
            in stems : Integer;
            return minSheets : Integer = if stems <= 10 ? 2 else (stems + 4) / 5;
        }

        constraint def RateLimitConstraint {
            doc /* Блокировка входа на 10 минут после 5 неудачных попыток */
            in failedAttempts : Integer;
            in allowed : Boolean;
            allowed == (failedAttempts < 5)
        }

        action def ValidateOrderInput;
        action def PostOrderHttp;
        action def RecalculateServerPrice { out priceMatches : Boolean; }
        action def RejectOutdatedPrice;
        action def PersistOrderAtomic;
        action def NotifyTelegramAndPanel;

        action def CheckoutWithServerPricing {
            doc /* Сценарий оформления заказа с серверной проверкой цены (ADR-0004, REQ-SRV-002) */
            attribute priceMatches : Boolean;

            first start;
            then action validate : ValidateOrderInput;
            then action sendHttp : PostOrderHttp;
            then action recalc   : RecalculateServerPrice;
            then decide checkPrice;
                if priceMatches then saveOrder;
                else reject;

            action reject : RejectOutdatedPrice;
            then done;

            action saveOrder : PersistOrderAtomic;
            then action notify : NotifyTelegramAndPanel;
            then done;
        }
    }

    // =====================================================================
    // 5. Физическое развёртывание и трассировка (Deployment & Traceability)
    // =====================================================================
    package Deployment {
        private import Architecture::*;
        private import SystemRequirements::*;

        part def AndroidDevice {
            doc /* Смартфон покупателя: Android 8.0+ (API 26+), ARM64, экран 5-7 дюймов */
            attribute os : String = "Android 8.0+";
            attribute arch : String = "arm64-v8a";
        }
        part def ShopPC {
            doc /* Рабочий ПК флориста в магазине: Windows 10/11 x64, локальная Wi-Fi сеть */
            attribute os : String = "Windows 10/11 x64";
            attribute tcpPort : Integer = 8080;
            attribute udpPort : Integer = 45454;
        }
        part def ExternalCloud {
            doc /* Облачная инфраструктура Telegram Bot API */
            attribute protocol : String = "HTTPS TLS 1.2+";
        }

        part deploymentTopology {
            part phone  : AndroidDevice;
            part pc     : ShopPC;
            part cloud  : ExternalCloud;
            part system : FlowerBoxSystem;

            allocate system.client   to phone;
            allocate system.server   to pc;
            allocate system.telegram to cloud;

            // трассировка системных требований на модули
            satisfy coreDomainLogic       by system.client.core;
            satisfy serverHttpAndStorage  by system.server.http;
            satisfy authAndSecurity       by system.server.engine;
            satisfy catalogAndProductUi   by system.client.qml;
            satisfy bouquetBuilderUi      by system.client.models;
            satisfy cartAndCheckout       by system.client.models;
            satisfy orderTrackingAndDates by system.client.net;
            satisfy floristPanel          by system.server.panel;
            satisfy telegramAndSupportChat by system.server.bot;
            satisfy offlineCacheAndTests  by system.server.store;
        }

        // верификация (автотесты Qt Test)
        verification def PackagingTestSuite {
            doc /* tests/tst_packaging.cpp: расчёт листов бумаги, выбор коробки и корзины */
            objective { verify coreDomainLogic; }
        }
        verification def ShopModelTestSuite {
            doc /* tests/tst_shop.cpp: фильтры каталога, промокоды, корзина, валидация */
            objective { verify cartAndCheckout; }
        }
        verification def NetworkSecurityTestSuite {
            doc /* tests/tst_network.cpp: 7 тестов HTTP API, пересчёт цены, блокировка входа */
            objective { verify authAndSecurity; }
        }
    }

    // =====================================================================
    // 6. Проектные представления SDD (ISO/IEC/IEEE 42010)
    // =====================================================================
    package DesignViews {
        private import Views::*;

        view compositionView {
            doc /* VIEW-01: Композиция подсистем, порты и интерфейсы (d1_composition.png) */
            expose Architecture::FlowerBoxSystem::**;
            render asInterconnectionDiagram;
        }
        view logicalView {
            doc /* VIEW-02: Логическая архитектура C++17 / Qt 6 классов (d2_logical.png) */
            expose Architecture::*;
            render asTreeDiagram;
        }
        view interfaceInfoView {
            doc /* VIEW-03: Контракты HTTP/UDP и информационная модель (d3_interface_info.png) */
            expose InformationModel::*;
            render asTreeDiagram;
        }
        view interactionAlgoView {
            doc /* VIEW-04: Алгоритмы и взаимодействие при оформлении заказа (d4_interaction_algo.png) */
            expose RuntimeBehavior::*;
            render asTreeDiagram;
        }
        view deploymentTraceView {
            doc /* VIEW-05: Развёртывание на узлах и трассировка требований (d5_deployment_trace.png) */
            expose Deployment::*;
            render asInterconnectionDiagram;
        }
    }
}
