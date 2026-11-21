/**
 * Контекст системы PillTrack и карта переходов между окнами.
 * PNG-изображения строятся из этой модели: srs/tools/Sysml2Png.
 */
package PillTrackContext {
    part def Person;
    part def DesktopApplication;
    part def Database;
    part def OperatingSystem;
    part def FileStorage;

    /** Контекстная диаграмма: система, её пользователи и внешнее окружение. */
    part systemContext {
        part caregiver : Person {
            doc /* Опекун */
        }
        part patient : Person {
            doc /* Пациент */
        }
        part pillTrack : DesktopApplication {
            doc /* PillTrack (C++17, Qt 6) */
        }
        part database : Database {
            doc /* SQLite (локальный файл) */
        }
        part files : FileStorage {
            doc /* Файлы: PDF, CSV, резервные копии */
        }
        part windows : OperatingSystem {
            doc /* Windows: уведомления, автозапуск */
        }
        part doctor : Person {
            doc /* Врач */
        }

        connection patientUi connect patient to pillTrack {
            doc /* ведёт курсы, отмечает приём */
        }
        connection caregiverUi connect caregiver to pillTrack {
            doc /* ведёт профили близких */
        }
        connection storage connect pillTrack to database {
            doc /* Qt SQL */
        }
        connection notify connect pillTrack to windows {
            doc /* уведомления, значок в трее */
        }
        connection export connect pillTrack to files {
            doc /* отчёт, экспорт, копии */
        }
        connection report connect files to doctor {
            doc /* отчёт о соблюдении курса */
        }
        connection alert connect windows to patient {
            doc /* напоминание о приёме */
        }
    }

    item def AppStarted;
    item def OpenWindow;
    item def Minimize;
    item def DoseDue;
    item def DoseMarked;
    item def OpenToday;
    item def OpenMedicines;
    item def OpenStatistics;
    item def OpenSettings;
    item def AddOrEdit;
    item def SavedOrCancelled;

    /** Карта окон: состояния — окна, переходы — события и действия пользователя. */
    state def ScreenFlow {
        entry; then tray;

        state tray {
            doc /* Область уведомлений */
        }
        state today {
            doc /* Сегодня */
        }
        state reminder {
            doc /* Напоминание */
        }
        state medicines {
            doc /* Препараты */
        }
        state courseForm {
            doc /* Форма курса */
        }
        state statistics {
            doc /* Статистика */
        }
        state settings {
            doc /* Настройки */
        }

        transition open first tray accept OpenWindow then today;
        transition hide first today accept Minimize then tray;
        transition due first tray accept DoseDue then reminder;
        transition marked first reminder accept DoseMarked then tray;
        transition reminderToToday first reminder accept OpenWindow then today;
        transition toMedicines first today accept OpenMedicines then medicines;
        transition toStatistics first today accept OpenStatistics then statistics;
        transition toSettings first today accept OpenSettings then settings;
        transition medicinesToToday first medicines accept OpenToday then today;
        transition statisticsToToday first statistics accept OpenToday then today;
        transition settingsToToday first settings accept OpenToday then today;
        transition openForm first medicines accept AddOrEdit then courseForm;
        transition closeForm first courseForm accept SavedOrCancelled then medicines;
    }
}
