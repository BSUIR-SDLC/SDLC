package FitScheduleBookingFlow {
    doc /* Последовательность записи на занятие и отмены записи с продвижением листа ожидания.
          SDD: представления 005-booking-flow и 006-booking-algorithm; ADR-0004, ADR-0006. */

    private import FitScheduleArchitecture::*;

    item def BookRequest;
    item def BookResult;
    item def CancelRequest;
    item def LockTraining;
    item def Promote;
    item def NotificationCreated;

    occurrence def BookingFlow {
        part client : SpaClient;
        part api : ApiModule;
        part booking : BookingModule;
        part waitlist : WaitlistModule;
        part notification : NotificationModule;
        part db : PostgreSql;

        // --- запись ---
        message book of BookRequest from client to api;
        message placeBooking of BookRequest from api to booking;
        message lock of LockTraining from booking to db;       // SELECT ... FOR UPDATE
        message result of BookResult from booking to api;
        message reply of BookResult from api to client;

        first book then placeBooking;
        first placeBooking then lock;
        first lock then result;
        first result then reply;

        // --- отмена с продвижением очереди (одна транзакция) ---
        message cancel of CancelRequest from client to api;
        message cancelBooking of CancelRequest from api to booking;
        message lockAgain of LockTraining from booking to db;
        message promoteFirst of Promote from booking to waitlist;
        message notifyPromoted of NotificationCreated from waitlist to notification;

        first reply then cancel;
        first cancel then cancelBooking;
        first cancelBooking then lockAgain;
        first lockAgain then promoteFirst;
        first promoteFirst then notifyPromoted;
    }
}
