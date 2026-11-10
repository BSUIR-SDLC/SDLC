// ============================================================================
// Прототип графического интерфейса на языке SysML v2 (Structural Architecture)
// Проект: Трекер здорового распорядка дня и полезных привычек (HabitFlow C++)
// Автор: Петкун Роман Юрьевич, группа 450503
// ============================================================================

package HabitTrackerGUIPrototype {
    private import ScalarValues::*;

    // Базовые типы элементов графического интерфейса
    part def UIComponent;
    part def Button :> UIComponent;
    part def CheckBox :> UIComponent;
    part def ProgressBar :> UIComponent;
    part def NumberInput :> UIComponent;
    part def DateSelector :> UIComponent;
    part def CalendarGrid :> UIComponent;

    // Главное окно приложения (Desktop Application Window)
    part def MainWindow :> UIComponent {
        part topBar : NavigationBar;
        part trackerTab : TrackerView;
        part statsTab : StatisticsView;
        part settingsDialog : SettingsModal;
    }

    // Верхняя панель навигации
    part def NavigationBar :> UIComponent {
        part tabTrackerBtn : Button;
        part tabStatsBtn : Button;
        part tabSettingsBtn : Button;
        part currentDateSelector : DateSelector;
        part quickSaveBtn : Button;
    }

    // Представление ежедневного трекера (вкладка 1)
    part def TrackerView :> UIComponent {
        part sleepCard : SleepHabitPanel;
        part nutritionCard : NutritionHabitPanel;
        part waterCard : WaterTrackerPanel;
        part activityCard : WalkAndActivityPanel;
        part breaksCard : ScreenBreaksPanel;
        part summaryDisciplineCard : DisciplineSummaryPanel;
    }

    // Карточка 1: Контроль сна
    part def SleepHabitPanel :> UIComponent {
        part sleepDurationBox : CheckBox;
        part bedTimeBox : CheckBox;
        part qualityRating : NumberInput;
    }

    // Карточка 2: Регулярность питания
    part def NutritionHabitPanel :> UIComponent {
        part breakfastBox : CheckBox;
        part lunchBox : CheckBox;
        part dinnerBox : CheckBox;
        part noJunkFoodBox : CheckBox;
    }

    // Карточка 3: Водный баланс
    part def WaterTrackerPanel :> UIComponent {
        part waterProgressBar : ProgressBar;
        part add250Btn : Button;
        part add500Btn : Button;
        part sub250Btn : Button;
        part resetBtn : Button;
    }

    // Карточка 4: Прогулка
    part def WalkAndActivityPanel :> UIComponent {
        part minutesInput : NumberInput;
        part targetStatusLabel : UIComponent;
    }

    // Карточка 5: Перерывы от экрана
    part def ScreenBreaksPanel :> UIComponent {
        part breakCounter : NumberInput;
        part breakSlots : UIComponent[6];
    }

    // Карточка 6: Сводный процент и стрик
    part def DisciplineSummaryPanel :> UIComponent {
        part dailyScoreGauge : ProgressBar;
        part streakFireBadge : UIComponent;
        part motivationalQuote : UIComponent;
    }

    // Представление аналитики и календаря (вкладка 2)
    part def StatisticsView :> UIComponent {
        part monthPicker : DateSelector;
        part calendarView : CalendarGrid;
        part categoryTrends : ProgressBar[5];
        part averageMonthlyScore : UIComponent;
        part longestStreakBadge : UIComponent;
        part exportCsvBtn : Button;
    }

    // Модальное окно настроек (диалог 3)
    part def SettingsModal :> UIComponent {
        part targetSleepInput : NumberInput;
        part targetWaterInput : NumberInput;
        part targetWalkInput : NumberInput;
        part screenIntervalInput : NumberInput;
        part streakThresholdInput : NumberInput;
        part dbFilePathSelector : UIComponent;
        part applyBtn : Button;
        part cancelBtn : Button;
    }
}
