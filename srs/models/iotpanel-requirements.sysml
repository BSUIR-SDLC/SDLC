package IoTPanelRequirements {
    requirement <'BG-1'> liveMonitoring : BusinessGoal {
        doc /* Мониторинг метрик (temperature, motion) на графиках с задержкой не более 2 с */
    }
    requirement <'BG-2'> fastStateSwitch : BusinessGoal {
        doc /* Дистанционное переключение состояния устройства в 1 клик не дольше 1 с */
    }
    requirement <'BG-3'> errorFreeRules : BusinessGoal {
        doc /* Создание правил без ручного ввода JSON и ошибок за время до 30 с */
    }
    requirement <'REQ-FUNC-002'> chartJsView : FunctionalRequirement {
        doc /* Отрисовка live-графиков метрик на базе Chart.js */
    }
    requirement <'REQ-FUNC-005'> stateButtons : FunctionalRequirement {
        doc /* Кнопки переключения состояния с отправкой /command */
    }
    requirement <'REQ-FUNC-007'> ruleForm4Step : FunctionalRequirement {
        doc /* Форма: Устройство -> Метрика -> Условие -> Действие */
    }
    #derivation connection { end #original ::> errorFreeRules; end #derive ::> ruleForm4Step; }
    part iotPanelSystem : IoTPanel;
    satisfy ruleForm4Step by iotPanelSystem;
}
