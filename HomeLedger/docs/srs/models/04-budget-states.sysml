package HomeLedgerBudgetStates {
    // Состояния месячного лимита категории расходов
    private import ScalarValues::*;

    item def 'Расход';
    item def 'Новый месяц';
    item def 'Изменение лимита';

    state def <BudgetStates> 'Состояния лимита категории' {
        attribute usedPercent : Real;   // потрачено / лимит * 100

        entry; then normal;

        state <normal> 'В норме (< 80 %)';
        state <near> 'Почти исчерпан (80–100 %)';
        state <over> 'Превышен (> 100 %)';

        transition t1 first normal accept 'Расход' if usedPercent >= 80 and usedPercent <= 100 then near;
        transition t2 first normal accept 'Расход' if usedPercent > 100 then over;
        transition t3 first near accept 'Расход' if usedPercent > 100 then over;
        transition t4 first near accept 'Изменение лимита' if usedPercent < 80 then normal;
        transition t5 first over accept 'Изменение лимита' if usedPercent <= 100 then near;
        transition t6 first near accept 'Новый месяц' then normal;
        transition t7 first over accept 'Новый месяц' then normal;
    }
}
