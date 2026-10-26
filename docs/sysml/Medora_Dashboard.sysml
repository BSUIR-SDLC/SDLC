package Medora_Dashboard {
    part def DashboardPage {
        attribute title = "Medora – Сегодня";
        part header : Header;
        part schedulePanel : SchedulePanel;
        part medicineList : MedicineList;
        part notificationPanel : NotificationPanel;
        part stockWidget : StockWidget;
        part footer : Footer;
    }

    part def Header {
        attribute logo = "Medora";
        attribute search = "Поиск лекарств";
    }

    part def SchedulePanel {
        attribute today = "Приёмы на сегодня";
        attribute markTaken = "Отметить принятым";
        attribute markMissed = "Отметить пропуск";
    }

    part def MedicineList {
        attribute items = "Список лекарств пользователя";
    }

    part def NotificationPanel {
        attribute reminders = "Напоминания о приёме";
        attribute missed = "Уведомления о пропущенных дозах";
    }

    part def StockWidget {
        attribute remaining = "Остатки препаратов";
        attribute lowStock = "Предупреждение о низком остатке";
    }

    part def Footer {
        attribute info = "О приложении, Контакты, Дисклеймер";
    }
}
