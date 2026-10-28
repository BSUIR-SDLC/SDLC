package IoTPanelUseCases {
    actor Operator;
    actor AutomationEngineer;
    use case <'UC-01'> viewDevices { doc /* Просмотреть список устройств и их статус */ }
    use case <'UC-02'> watchLiveCharts { doc /* Наблюдать live-графики метрик (Chart.js) */ }
    use case <'UC-03'> toggleState { doc /* Переключить состояние устройства (/command) */ }
    use case <'UC-04'> createRule { doc /* Создать правило: Устройство -> Метрика -> Условие -> Действие */ }
    use case <'UC-05'> manageRules { doc /* Активировать, изменить или удалить правило */ }
    use case <'UC-06'> viewRuleLogs { doc /* Просмотреть журнал срабатываний правил */ }
    use case <'UC-07'> configureChart { doc /* Настроить интервал опроса и пороги графиков */ }
}
