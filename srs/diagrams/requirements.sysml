package WineVaultRequirements {
    private import ScalarValues::*;

    doc /*
     * Спецификация требований к системе 'WineVault'
     * Стандарт ISO/IEC/IEEE 29148:2018
     */

    requirement <'REQ-SYS-001'> WineVaultSystem {
        doc /* Система каталогизации домашних вин, контроля выдержки и гастрономического подбора. */
    }

    requirement <'REQ-FUNC-001'> WineCatalogManagement {
        doc /* Учет винной коллекции: сорт винограда, год сбора, крепость, объем, дата закладки. */
    }

    requirement <'REQ-FUNC-002'> CellarTopologyTracking {
        doc /* Точный учет расположения бутылки в погребе: сектор, стеллаж, полка, номер ячейки. */
    }

    requirement <'REQ-FUNC-003'> AgingLifecycleCalculation {
        doc /* Автоматический расчет фаз выдержки ('созревает', 'на пике', 'риск передержки'). */
    }

    requirement <'REQ-FUNC-004'> AgingCalendarNotifications {
        doc /* Визуализация календаря выдержки и предиктивные уведомления о созревании. */
    }

    requirement <'REQ-FUNC-005'> ReadyToDrinkFilter {
        doc /* Быстрая фильтрация вин, находящихся на пике формы, в один клик. */
    }

    requirement <'REQ-FUNC-006'> VirtualSommelierPairing {
        doc /* Интеллектуальный подбор вина из имеющихся запасов под блюдо или мероприятие. */
    }

    requirement <'REQ-FUNC-007'> TastingNotesJournal {
        doc /* Ведение дегустационных заметок, выставление персональных оценок и истории открытий. */
    }

    requirement <'REQ-FUNC-008'> CsvReportExport {
        doc /* Экспорт реестра коллекции и графиков выдержки в формат CSV/Excel. */
    }

    requirement <'REQ-NFR-PERF-001'> ColdStartTime {
        doc /* Время холодного старта приложения не должно превышать 1.5 секунды. */
    }

    requirement <'REQ-NFR-REL-001'> AtomicJsonPersistence {
        doc /* Сохранение состояния в JSON с обеспечением целостности и отказоустойчивости (Air-gap). */
    }

    // Трассировка связей декомпозиции
    connection c1 : Subrequirement from WineVaultSystem to WineCatalogManagement;
    connection c2 : Subrequirement from WineVaultSystem to CellarTopologyTracking;
    connection c3 : Subrequirement from WineVaultSystem to AgingLifecycleCalculation;
    connection c4 : Subrequirement from WineVaultSystem to AgingCalendarNotifications;
    connection c5 : Subrequirement from WineVaultSystem to ReadyToDrinkFilter;
    connection c6 : Subrequirement from WineVaultSystem to VirtualSommelierPairing;
    connection c7 : Subrequirement from WineVaultSystem to TastingNotesJournal;
    connection c8 : Subrequirement from WineVaultSystem to CsvReportExport;
    connection c9 : Subrequirement from WineVaultSystem to ColdStartTime;
    connection c10 : Subrequirement from WineVaultSystem to AtomicJsonPersistence;
}
