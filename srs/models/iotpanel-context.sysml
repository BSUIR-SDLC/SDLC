package IoTPanelContext {
    part def Operator;
    part def AutomationEngineer;
    part def IoTPanel;
    part def DeviceEmulator;
    part def RuleEngine;

    part operator : Operator {
        doc /* Оператор мониторинга: отслеживает графики метрик и переключает состояние устройств. */
    }
    part engineer : AutomationEngineer {
        doc /* Инженер автоматизации: настраивает правила через форму «Устройство -> Метрика -> Условие -> Действие». */
    }
    part iotpanel : IoTPanel {
        doc /* Веб-панель управления IoTPanel: графики Chart.js, переключатели состояния и конструктор правил. */
    }
    part emulator : DeviceEmulator {
        doc /* Эмулятор IoT-устройств: генерирует JSON (device_id, temperature, motion) и слушает /command. */
    }
    part ruleEngine : RuleEngine {
        doc /* Backend движка правил: проверяет вебхуки против JSON-правил и вызывает /command. */
    }

    connection operatorToPanel connect operator to iotpanel;
    connection engineerToPanel connect engineer to iotpanel;
    connection panelToEmulator connect iotpanel to emulator;
    connection panelToRuleEngine connect iotpanel to ruleEngine;
}
