package FitScheduleArchitecture {
    doc /* Модули модульного монолита FitSchedule 1.0, их порты и развёртывание.
          SDD: представления 002-modules и 009-deployment; ADR-0001, ADR-0002. */

    private import ScalarValues::*;

    // ---------- Порты (интерфейсы модулей) ----------
    port def ScheduleApi;
    port def BookingApi;
    port def SlotApi;
    port def WaitlistApi;
    port def ActivityApi;
    port def NotificationApi;
    port def IcalApi;
    port def JdbcPort;
    port def HttpsPort;

    // ---------- Модули ----------
    part def SpaClient {
        doc /* React SPA (Vite), статические файлы отдаются Spring Boot (ADR-0002). */
    }
    part def ApiModule {
        doc /* REST-контроллеры, DTO, OpenAPI 3.0 (/v3/api-docs), обработка ошибок. */
        port https : HttpsPort;
    }
    part def SecurityModule {
        doc /* Spring Security: сессия 7 суток, BCrypt(12), роли VISITOR/TRAINER/ADMIN. */
    }
    part def ScheduleModule {
        port api : ScheduleApi;
        doc /* Занятия, залы, вместимость, срок свободной отмены. */
    }
    part def BookingModule {
        port api : BookingApi;
        doc /* Запись и отмена; правила BookingPolicy без зависимостей от Spring. */
    }
    part def TrainerSlotModule {
        port api : SlotApi;
        doc /* Слоты тренеров и персональные записи. */
    }
    part def WaitlistModule {
        port api : WaitlistApi;
        doc /* Лист ожидания и продвижение очереди (ADR-0006, REQ-FUNC-023). */
    }
    part def ActivityModule {
        port api : ActivityApi;
    }
    part def NotificationModule {
        port api : NotificationApi;
        doc /* Внутрисистемные уведомления и напоминания за 2 ч; опрос 60 с (ADR-0005). */
    }
    part def IcalModule {
        port api : IcalApi;
    }
    part def OpsModule {
        doc /* Actuator, JSON-журнал без персональных данных, удаление аккаунта. */
    }
    part def PostgreSql {
        port jdbc : JdbcPort;
    }

    part def FitScheduleApp {
        part api : ApiModule;
        part security : SecurityModule;
        part schedule : ScheduleModule;
        part booking : BookingModule;
        part slots : TrainerSlotModule;
        part waitlist : WaitlistModule;
        part activity : ActivityModule;
        part notification : NotificationModule;
        part ical : IcalModule;
        part ops : OpsModule;

        // зависимость «использует» через порт
        connect api to schedule.api;
        connect api to booking.api;
        connect api to slots.api;
        connect api to waitlist.api;
        connect api to activity.api;
        connect api to notification.api;
        connect api to ical.api;
        connect booking to schedule.api;
        connect booking to waitlist.api;
        connect waitlist to notification.api;
        connect schedule to notification.api;
        connect slots to notification.api;
        connect ical to booking.api;
    }

    // ---------- Развёртывание ----------
    part def Browser;
    part def ReverseProxy { doc /* nginx 1.27, TLS 1.2+, порт 443. */ }
    part def AppContainer { doc /* eclipse-temurin:21-jre, fitschedule.jar. */ }
    part def DbContainer  { doc /* postgres:16, том pgdata. */ }
    part def BackupJob    { doc /* cron + pg_dump, 03:00, хранение 7 копий. */ }

    part deployment {
        part browser : Browser;
        part server {
            attribute vcpu : Integer = 2;
            attribute memoryMb : Integer = 2048;
            part proxy : ReverseProxy;
            part app : AppContainer;
            part db : DbContainer;
            part backup : BackupJob;
            connect proxy to app;
            connect app to db;
            connect backup to db;
        }
        connect browser to server.proxy;
    }

    part fitSchedule : FitScheduleApp;
    allocate fitSchedule to deployment.server.app;
}
