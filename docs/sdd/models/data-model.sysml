package FitScheduleData {
    doc /* Модель данных FitSchedule 1.0: каждое item def соответствует таблице PostgreSQL 16.
          SDD: представление 003-data-model; ADR-0003, ADR-0004, ADR-0006. */

    private import ScalarValues::*;

    enum def UserRole { enum VISITOR; enum TRAINER; enum ADMIN; }
    enum def BookingStatus { enum CONFIRMED; enum CANCELLED; enum CANCELLED_BY_CLUB; enum ATTENDED; }
    enum def TrainingStatus { enum SCHEDULED; enum CANCELLED; }
    enum def WaitlistStatus { enum WAITING; enum PROMOTED; enum LEFT; enum EXPIRED; }
    enum def NotificationKind { enum TRAINING_CANCELLED; enum TRAINING_CHANGED; enum REMINDER; enum WAITLIST_PROMOTED; }

    item def AppUser {
        attribute id : Integer;            // PK
        attribute email : String;          // UNIQUE
        attribute passwordHash : String;   // BCrypt, cost 12
        attribute name : String;
        attribute role : UserRole;
        attribute deletedAt : String;      // обезличивание через 30 суток (REQ-COMP-003)
    }

    item def Hall {
        attribute id : Integer;
        attribute name : String;
    }

    item def Training {
        attribute id : Integer;
        attribute title : String;
        attribute kind : String;
        ref hall : Hall;
        ref trainer : AppUser;
        attribute startsAt : String;       // timestamptz
        attribute endsAt : String;         // CHECK endsAt > startsAt
        attribute capacity : Integer;      // CHECK capacity > 0
        attribute freePlaces : Integer;    // CHECK 0 <= freePlaces <= capacity
        attribute cancelDeadlineHours : Integer;
        attribute status : TrainingStatus;
        attribute version : Integer;
    }

    item def Booking {
        attribute id : Integer;
        ref visitor : AppUser;
        ref training : Training;           // либо training, либо slot
        ref slot : TrainerSlot;
        attribute status : BookingStatus;
        attribute startsAt : String;       // копия для проверки пересечений
        attribute endsAt : String;
        attribute createdAt : String;
        attribute viaWaitlist : Boolean;
        // UNIQUE (visitor, training) WHERE status = CONFIRMED
    }

    item def TrainerSlot {
        attribute id : Integer;
        ref trainer : AppUser;
        attribute startsAt : String;
        attribute endsAt : String;
        ref bookedBy : AppUser;            // UNIQUE, NULL — слот свободен
    }

    item def WaitlistEntry {
        doc /* Добавлено во втором раунде согласования (REQ-FUNC-023). */
        attribute id : Integer;
        ref training : Training;
        ref visitor : AppUser;
        attribute position : Integer;      // UNIQUE (training, position)
        attribute status : WaitlistStatus;
        attribute createdAt : String;
        // UNIQUE (training, visitor) WHERE status = WAITING
    }

    item def Activity {
        attribute id : Integer;
        ref visitor : AppUser;
        attribute date : String;
        attribute kind : String;
        attribute durationMin : Integer;   // CHECK 1..600
    }

    item def Notification {
        attribute id : Integer;
        ref recipient : AppUser;
        attribute kind : NotificationKind;
        attribute text : String;
        ref booking : Booking;             // UNIQUE (booking, kind) для REMINDER
        attribute createdAt : String;
        attribute readAt : String;
    }
}
