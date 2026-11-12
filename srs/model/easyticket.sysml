package EasyTicketModel {
    doc /* EasyTicket: система бронирования билетов, версия 0.1. Трассируется на srs/srs.md */

    import ScalarValues::*;

    /* ---------- 1. Перечисления и данные ---------- */
    enum def SeatStatus   { enum free; enum reserved; enum sold; }
    enum def EventStatus  { enum draft; enum active; enum ended; }
    enum def VerifyResult { enum valid; enum invalid; enum alreadyUsed; }

    item def Seat {
        attribute row      : String;
        attribute number   : Integer;
        attribute category : String;
        attribute price    : Real;            // BYN
        attribute status   : SeatStatus;
    }

    item def Event {
        attribute title    : String;
        attribute genre    : String;
        attribute dateTime : String;
        attribute venue    : String;
        attribute status   : EventStatus;
    }

    item def Reservation {
        attribute id              : String;
        attribute expiresAt       : String;
        attribute lifetimeMinutes : Integer = 10;
        attribute maxSeats        : Integer = 10;
        ref item seats : Seat[1..10];
    }

    item def Order {
        attribute orderId : String;           // ORD-ГГГГ-NNNNNN
        attribute email   : String;
        ref item seats : Seat[1..10];
    }

    item def Ticket {
        attribute ticketId : String;
        attribute qrPayload : String;         // order_id, ticket_id, event_id, seat, signature
        attribute used : Boolean = false;
    }

    /* ---------- 2. Структура системы ---------- */
    part def Buyer;
    part def Administrator;
    part def Controller;

    part def WebUI;
    part def RestApi;
    part def CatalogService;
    part def ReservationService;
    part def OrderService;
    part def QrService;
    part def MailService;
    part def AdminService;

    part def PostgreSQL;
    part def QrLibrary;                       // библиотека qrcode
    part def MockSmtp;                        // mock SMTP, порт 1025

    part def EasyTicketSystem {
        part webUI        : WebUI;
        part api          : RestApi;
        part catalog      : CatalogService;
        part reservations : ReservationService;
        part orders       : OrderService;
        part qr           : QrService;
        part mail         : MailService;
        part admin        : AdminService;

        connect webUI to api;
        connect api to catalog;
        connect api to reservations;
        connect api to orders;
        connect api to admin;
        connect orders to qr;
        connect orders to mail;
    }

    part def EasyTicketContext {
        part buyer      : Buyer;
        part administrator : Administrator;
        part controller : Controller;
        part easyTicket : EasyTicketSystem;
        part db         : PostgreSQL;
        part qrlib      : QrLibrary;
        part smtp       : MockSmtp;

        connect buyer to easyTicket.webUI;
        connect administrator to easyTicket.webUI;
        connect controller to easyTicket.webUI;
        connect easyTicket.catalog to db;
        connect easyTicket.reservations to db;
        connect easyTicket.orders to db;
        connect easyTicket.admin to db;
        connect easyTicket.qr to qrlib;
        connect easyTicket.mail to smtp;
    }

    /* ---------- 3. Варианты использования ---------- */
    use case def BrowseCatalog     { subject system : EasyTicketSystem; actor buyer : Buyer; }
    use case def SelectAndReserve  { subject system : EasyTicketSystem; actor buyer : Buyer; }
    use case def PlaceOrder        { subject system : EasyTicketSystem; actor buyer : Buyer; }
    use case def ReceiveTicket     { subject system : EasyTicketSystem; actor buyer : Buyer; }
    use case def FindMyTickets     { subject system : EasyTicketSystem; actor buyer : Buyer; }
    use case def VerifyTicket      { subject system : EasyTicketSystem; actor controller : Controller; }
    use case def SignIn            { subject system : EasyTicketSystem; actor staff : Administrator; }
    use case def ManageEvents      { subject system : EasyTicketSystem; actor admin : Administrator; }
    use case def ViewStatistics    { subject system : EasyTicketSystem; actor admin : Administrator; }
    use case def CancelReservation { subject system : EasyTicketSystem; actor admin : Administrator; }

    /* ---------- 4. Требования ---------- */
    requirement def <'REQ-FUNC-001'> CatalogRequirement {
        doc /* Каталог предстоящих мероприятий с фильтрами по дате, жанру и цене */
    }
    requirement def <'REQ-FUNC-003'> SeatMapRequirement {
        doc /* Схема зала со статусами: свободно, забронировано, продано */
    }
    requirement def <'REQ-FUNC-005'> ReservationRequirement {
        doc /* Место переводится в «Забронировано» на 10 минут, выбор другими покупателями блокируется */
        attribute lifetime : Integer = 10;
    }
    requirement def <'REQ-FUNC-006'> OrderRequirement {
        doc /* Заказ оформляется по действующей брони, email и эмуляции оплаты */
    }
    requirement def <'REQ-FUNC-007'> QrRequirement {
        doc /* Уникальный QR-код с подписью HMAC для каждого оплаченного билета */
    }
    requirement def <'REQ-FUNC-008'> MailRequirement {
        doc /* Билет отправляется на email не позднее 60 секунд после оплаты */
        attribute maxDelaySeconds : Integer = 60;
    }
    requirement def <'REQ-FUNC-010'> VerifyRequirement {
        doc /* Проверка подлинности и однократности билета на входе */
    }
    requirement def <'REQ-FUNC-012'> EventManagementRequirement {
        doc /* Создание, изменение и удаление мероприятий; удаление запрещено при проданных билетах */
    }
    requirement def <'REQ-SEC-002'> QrSignatureRequirement {
        doc /* Подпись HMAC-SHA256, секретный ключ хранится вне репозитория */
    }

    part def EasyTicketRequirements {
        part system : EasyTicketSystem;

        requirement catalogReq   : CatalogRequirement;
        requirement seatMapReq   : SeatMapRequirement;
        requirement reserveReq   : ReservationRequirement;
        requirement orderReq     : OrderRequirement;
        requirement qrReq        : QrRequirement;
        requirement signatureReq : QrSignatureRequirement;
        requirement mailReq      : MailRequirement;
        requirement verifyReq    : VerifyRequirement;
        requirement eventsReq    : EventManagementRequirement;

        satisfy catalogReq   by system.catalog;
        satisfy seatMapReq   by system.reservations;
        satisfy reserveReq   by system.reservations;
        satisfy orderReq     by system.orders;
        satisfy qrReq        by system.qr;
        satisfy signatureReq by system.qr;
        satisfy mailReq      by system.mail;
        satisfy verifyReq    by system.orders;
        satisfy eventsReq    by system.admin;
    }

    /* ---------- 5. Поведение: жизненный цикл места и билета ---------- */
    item def AddToCart;
    item def RemoveFromCart;
    item def AdminCancel;
    item def ReservationTimeout;      // истекло 10 минут
    item def PaymentConfirmed;
    item def ScanValid;

    state def SeatLifecycle {
        entry; then free;

        state free;
        state reserved;
        state sold;

        transition addToCart
            first free
            accept AddToCart
            then reserved;

        transition reservationExpired
            first reserved
            accept ReservationTimeout
            then free;

        transition removedFromCart
            first reserved
            accept RemoveFromCart
            then free;

        transition adminCancel
            first reserved
            accept AdminCancel
            then free;

        transition paymentConfirmed
            first reserved
            accept PaymentConfirmed
            then sold;
    }

    state def TicketLifecycle {
        entry; then issued;

        state issued;
        state used;

        transition scanned
            first issued
            accept ScanValid
            then used;
    }

    /* ---------- 6. Сценарий покупки ---------- */
    action def PurchaseScenario {
        action selectSeats;
        action reserve;
        action placeOrder;
        action pay;
        action generateQr;
        action sendEmail;
        action showConfirmation;

        first start;
        then selectSeats;
        then reserve;
        then placeOrder;
        then pay;
        then generateQr;
        then sendEmail;
        then showConfirmation;
        then done;
    }

    /* ---------- 7. Пользовательский интерфейс ---------- */
    part def FilterPanel {
        attribute dateFrom : String;
        attribute dateTo   : String;
        attribute genre    : String;
        attribute priceMin : Real;
        attribute priceMax : Real;
    }
    part def EventCard {
        attribute genre    : String;
        attribute title    : String;
        attribute date     : String;
        attribute venue    : String;
        attribute minPrice : Real;
        action book;
    }
    part def Pagination;

    part def HomePage {
        part filters    : FilterPanel;
        part cards      : EventCard[*];
        part pagination : Pagination;
        attribute sortBy : String = "date";
    }

    part def SeatMap {
        item seats : Seat[*];
        attribute legend : String = "Свободно | Забронировано | Продано";
    }
    part def CartPanel {
        attribute subtotal : Real;
        attribute total    : Real;
        action checkout;
    }
    part def ReservationTimer {
        attribute secondsLeft : Integer;
    }

    part def EventPage {
        part seatMap : SeatMap;
        part cart    : CartPanel;
        part timer   : ReservationTimer;
        attribute title : String;
        action selectSeat;
        action removeSeat;
    }

    part def ConfirmationPage {
        attribute orderId : String;
        attribute email   : String;
        attribute qrImage : String;
        action downloadPdf;                   // приоритет «Низкий», релиз 0.2
    }

    part def MyTicketsPage {
        attribute orderId : String;
        attribute email   : String;
        action find;
    }

    part def VerifyPage {
        attribute scanResult : VerifyResult;
        action scan;
    }

    part def AdminLoginPage {
        attribute login    : String;
        attribute password : String;
        action signIn;
    }

    part def AdminPanel {
        attribute totalEvents     : Integer;
        attribute activeEvents    : Integer;
        attribute totalRevenueByn : Real;
        attribute ticketsSold     : Integer;
        action createEvent;
        action editEvent;
        action deleteEvent;
        action cancelReservation;
    }

    part def UiNavigation {
        part home      : HomePage;
        part event     : EventPage;
        part confirm   : ConfirmationPage;
        part myTickets : MyTicketsPage;
        part login     : AdminLoginPage;
        part admin     : AdminPanel;
        part verify    : VerifyPage;

        connect home to event;
        connect event to confirm;
        connect home to myTickets;
        connect myTickets to confirm;
        connect login to admin;
        connect login to verify;
    }
}
