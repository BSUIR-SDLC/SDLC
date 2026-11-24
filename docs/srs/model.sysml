package FitScheduleModel {
    doc /* Модель системы FitSchedule: участники, данные, части системы,
          варианты использования и требования из SRS. */

    private import ScalarValues::*;

    // ---------- Перечисления ----------
    enum def BookingStatus {
        enum Pending;
        enum Confirmed;
        enum Cancelled;
        enum CancelledByClub;
    }

    enum def UserRole {
        enum Visitor;
        enum Trainer;
        enum Administrator;
    }

    // ---------- Данные ----------
    item def User {
        attribute id : String;
        attribute name : String;
        attribute email : String;
        attribute role : UserRole;
    }

    item def Training {
        attribute id : String;
        attribute title : String;
        attribute startsAt : String;
        attribute endsAt : String;
        attribute hall : String;
        attribute capacity : Integer;
        attribute freePlaces : Integer;
        attribute cancelDeadlineHours : Integer;
    }

    item def TrainerSlot {
        attribute id : String;
        attribute startsAt : String;
        attribute endsAt : String;
        attribute isAvailable : Boolean;
    }

    item def Booking {
        attribute id : String;
        attribute status : BookingStatus;
        attribute createdAt : String;
    }

    item def Activity {
        attribute date : String;
        attribute kind : String;
        attribute durationMin : Integer;
    }

    // ---------- Части системы ----------
    part def UserInterface;
    part def Database;

    part def ScheduleService {
        part trainings : Training[*];
        part trainerSlots : TrainerSlot[*];
    }

    part def BookingService {
        part bookings : Booking[*];
        attribute maxConcurrentRequests : Integer = 50;
    }

    part def ActivityService {
        doc /* Хранит записи завершённой активности посетителя. */
        part activities : Activity[*];
    }

    part def NotificationService {
        doc /* Формирует внутрисистемные уведомления об отмене занятия. */
    }

    part def FitScheduleApp {
        part ui : UserInterface;
        part schedule : ScheduleService;
        part booking : BookingService;
        part activity : ActivityService;
        part notifications : NotificationService;
        part storage : Database;

        connect ui to schedule;
        connect ui to booking;
        connect ui to activity;
        connect booking to storage;
        connect schedule to storage;
        connect booking to notifications;
    }

    part fitSchedule : FitScheduleApp;

    // ---------- Варианты использования ----------
    use case def ViewSchedule {
        subject app : FitScheduleApp;
        actor visitor : User;
    }

    use case def BookGroupTraining {
        subject app : FitScheduleApp;
        actor visitor : User;
        doc /* Запись возможна только при свободном месте и без пересечения времени. */
    }

    use case def BookTrainerSlot {
        subject app : FitScheduleApp;
        actor visitor : User;
        doc /* Подтверждённый слот становится недоступным для второго посетителя. */
    }

    use case def CancelBooking {
        subject app : FitScheduleApp;
        actor visitor : User;
        doc /* Свободная отмена возможна до срока, заданного администратором. */
    }

    use case def ManageSchedule {
        subject app : FitScheduleApp;
        actor administrator : User;
    }

    use case def ViewTrainerBookings {
        subject app : FitScheduleApp;
        actor trainer : User;
    }

    use case def TrackActivity {
        subject app : FitScheduleApp;
        actor visitor : User;
    }

    // ---------- Требования ----------
    requirement def FitScheduleRequirement {
        doc /* Базовый тип требований FitSchedule. */
    }

    requirement def CapacityLimit :> FitScheduleRequirement {
        attribute minFreePlaces : Integer = 0;
    }

    requirement def CancelDeadline :> FitScheduleRequirement {
        attribute deadlineHours : Integer;
    }

    requirement def BookingSpeed :> FitScheduleRequirement {
        attribute maxSeconds : Real = 2.0;
        attribute concurrentRequests : Integer = 50;
    }

    requirement <'REQ-FUNC-004'> viewSchedule : FitScheduleRequirement {
        doc /* Посетитель видит занятия за выбранную дату. */
    }

    requirement <'REQ-FUNC-007'> bookWhenAvailable : CapacityLimit {
        doc /* Запись на групповое занятие при наличии свободных мест. */
    }

    requirement <'REQ-FUNC-009'> noOverlap : FitScheduleRequirement {
        doc /* Записи одного посетителя не пересекаются по времени. */
    }

    requirement <'REQ-FUNC-011'> cancelBeforeDeadline : CancelDeadline {
        doc /* Свободная отмена возможна до срока, заданного администратором. */
    }

    requirement <'REQ-FUNC-016'> bookTrainerSlot : FitScheduleRequirement {
        doc /* Бронирование свободного слота персонального тренера. */
    }

    requirement <'REQ-PERF-002'> bookingSpeed : BookingSpeed {
        doc /* Запись завершается не более чем за 2 с при 50 одновременных запросах. */
    }

    requirement <'REQ-REL-001'> bookingIntegrity : FitScheduleRequirement {
        doc /* Одновременные запросы не создают двойную запись. */
    }

    // ---------- Удовлетворение требований ----------
    satisfy viewSchedule by fitSchedule.schedule;
    satisfy bookWhenAvailable by fitSchedule.booking;
    satisfy noOverlap by fitSchedule.booking;
    satisfy cancelBeforeDeadline by fitSchedule.booking;
    satisfy bookTrainerSlot by fitSchedule.booking;
    satisfy bookingSpeed by fitSchedule.booking;
    satisfy bookingIntegrity by fitSchedule.booking;
}
