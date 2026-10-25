package Medora_Medicine {
    part def MedicinePage {
        attribute title = "Аспирин / 100 мг";
        part header : Header;
        part medicineInfo : MedicineInfo;
        part scheduleEditor : ScheduleEditor;
        part stockTracker : StockTracker;
        part intakeHistory : IntakeHistory;
        part actions : Actions;
        part footer : Footer;
    }

    part def Header {
        attribute logo = "Medora";
        attribute back = "Назад к расписанию";
    }

    part def MedicineInfo {
        attribute name = "Название препарата";
        attribute dosage = "Дозировка и форма";
        attribute notes = "Заметки пользователя";
    }

    part def ScheduleEditor {
        attribute times = "Время приёма";
        attribute days = "Дни недели / периодичность";
        attribute course = "Длительность курса";
    }

    part def StockTracker {
        attribute quantity = "Текущий остаток";
        attribute threshold = "Порог предупреждения";
        attribute refill = "Пополнить остаток";
    }

    part def IntakeHistory {
        attribute records = "История приёма препарата";
        attribute filter = "Фильтр по периоду и статусу";
    }

    part def Actions {
        attribute takeNow = "Отметить приём сейчас";
        attribute skip = "Пропустить дозу";
        attribute edit = "Редактировать лекарство";
    }

    part def Footer {
        attribute info = "О приложении, Контакты, Дисклеймер";
    }
}
