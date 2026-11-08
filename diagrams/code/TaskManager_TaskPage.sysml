package TaskManager_TaskPage {
    private import ScalarValues::*;
    part def TaskPage {
        attribute title : String = "Подготовить отчёт";
        part header : TaskHeader;
        part taskInfo : TaskInfo;
        part subtasks : SubtaskList;
        part recurrence : RecurrenceSettings;
        part actions : Actions;
    }
    part def TaskHeader {
        attribute 'title' : String = "Название задачи";
        attribute 'status' : String = "Не выполнена / Выполнена";
    }
    part def TaskInfo {
        attribute 'description' : String = "Описание задачи";
        attribute 'priority' : String = "Высокий";
        attribute 'deadline' : String = "25.10.2026 18:00";
        attribute 'category' : String = "Учёба";
    }

    part def SubtaskList {
        attribute 'items' : String = "Собрать данные; Оформить выводы";
        attribute 'progress' : String = "1 из 2; 50%";
        attribute 'action' : String = "Добавить подзадачу";
    }

    part def RecurrenceSettings {
        attribute 'rule' : String = "Каждую неделю";
        attribute 'nextDate' : String = "01.11.2026";
        attribute 'enabled' : String = "true / false";
    }

    part def Actions {
        attribute 'edit' : String = "Редактировать";
        attribute 'complete' : String = "Завершить";
        attribute 'deleteAction' : String = "Удалить";
    }

    part page : TaskPage;
}
