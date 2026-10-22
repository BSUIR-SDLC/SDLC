/**
 * Спецификация вариантов использования и акторов на языке SysML v2
 * Проект: HabitROI (Калькулятор стоимости вредных привычек в перспективе)
 * Автор: Студент группы 450503 Игнатюк А. А.
 */
package HabitROIUseCases {

    part def User;
    part def ExternalCurrencyAPI;
    part def ExternalAssetAPI;

    use case def AddHabit {
        subject system : HabitROISystem;
        actor user : User;
        doc /* Пользователь вводит название привычки, периодичность и сумму трат */
    }

    use case def CalculateProjections {
        subject system : HabitROISystem;
        actor user : User;
        doc /* Система выполняет расчет прямого ущерба и инвестиционного дохода со сложным процентом */
    }

    use case def VisualizeAlternativeAssets {
        subject system : HabitROISystem;
        actor user : User;
        doc /* Система отображает наглядные карточки: гаджеты, поездки, дивидендные акции */
    }

    use case def ExportSocialCard {
        subject system : HabitROISystem;
        actor user : User;
        doc /* Экспорт вирусной инфографики для мотивации или шеринга в Telegram/VK */
    }

    use case def SyncRates {
        subject system : HabitROISystem;
        actor api : ExternalCurrencyAPI;
        doc /* Синхронизация актуальных курсов валют через НБРБ / ЦБ РФ */
    }

    part def HabitROISystem {
        // включенные варианты использования
    }
}
