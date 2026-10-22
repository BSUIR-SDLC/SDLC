/**
 * Спецификация структуры GUI и мокапов интерфейса на языке SysML v2
 * Проект: HabitROI (Калькулятор стоимости вредных привычек в перспективе)
 * Автор: Студент группы 450503 Игнатюк А. А.
 */
package HabitROIGUIMockup {

    // Обобщенные элементы UI
    part def UIElement;
    part def Container :> UIElement;
    part def Control :> UIElement;

    part def Button :> Control {
        attribute label : String;
        attribute icon : String;
    }

    part def TextInput :> Control {
        attribute placeholder : String;
        attribute textValue : String;
    }

    part def ComboBox :> Control {
        attribute options : String[*];
        attribute selectedOption : String;
    }

    part def Slider :> Control {
        attribute minValue : Real;
        attribute maxValue : Real;
        attribute currentValue : Real;
    }

    part def ChartArea :> UIElement {
        attribute chartType : String; // "LineChart", "BarChart"
        attribute title : String;
    }

    part def VisualGoalCard :> Container {
        attribute targetName : String;
        attribute targetCost : Real;
        attribute timeToAchieve : String;
        attribute imageIllustration : String;
        attribute progressPercentage : Real;
    }

    // Главное окно приложения
    part def MainWindow :> Container {
        part headerBar : HeaderBar;
        part leftPanel : HabitManagementPanel;
        part centerPanel : CalculationAndChartsPanel;
        part rightPanel : VisualAlternativesShowcasePanel;
        part statusBar : StatusBar;
    }

    part def HeaderBar :> Container {
        part appTitle : UIElement;
        part currencySelector : ComboBox;
        part themeToggle : Button;
    }

    part def HabitManagementPanel :> Container {
        doc /* Левая панель: управление списком привычек */
        part inputTitle : TextInput;
        part inputCost : TextInput;
        part cmbFrequency : ComboBox; // "В день", "В неделю", "В месяц"
        part btnAddHabit : Button;
        part habitListView : Container;
        part totalExpenseBadge : UIElement;
    }

    part def CalculationAndChartsPanel :> Container {
        doc /* Центральная панель: временные горизонты, сложный процент, график */
        part horizonButtons : Button[4]; // 1 год, 3 года, 5 лет, 10 лет
        part interestRateSlider : Slider; // Доходность от 0% до 25% (сложный процент)
        part growthComparisonChart : ChartArea; // График: "Траты" vs "Инвестиции с процентом"
        part summaryMetricsRow : Container;
    }

    part def VisualAlternativesShowcasePanel :> Container {
        doc /* Правая панель: визуальные эквиваленты (изюминка проекта) */
        part cardGadget : VisualGoalCard;     // "Новый iPhone 16 Pro Max"
        part cardTravel : VisualGoalCard;     // "2 недели отдыха на Бали"
        part cardInvestment : VisualGoalCard; // "Пакет акций Apple + дивиденды"
        part cardAuto : VisualGoalCard;       // "Новый автомобиль среднего класса"
        part btnExportVisualCard : Button;    // Кнопка сохранения красивой картинки
    }

    part def StatusBar :> Container {
        attribute statusMessage : String;
        attribute lastSyncTime : String;
    }
}
