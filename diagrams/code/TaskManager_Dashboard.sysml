package TaskManager_Dashboard {
    private import ScalarValues::*;
    part def DashboardPage {
        attribute title : String = "Task Manager — Список дел";
        part header : Header;
        part filterPanel : FilterPanel;
        part taskList : TaskList;
        part categoryPanel : CategoryPanel;
        part quickAdd : QuickAddTask;
    }
    part def Header {
        attribute 'logo' : String = "Task Manager";
        attribute 'user' : String = "Профиль пользователя";
        attribute 'action' : String = "Выйти";
    }
    part def FilterPanel {
        attribute 'status' : String = "Все / Активные / Выполненные";
        attribute 'priority' : String = "Низкий ... Критический";
        attribute 'deadline' : String = "Сегодня / Просроченные";
    }

    part def TaskList {
        attribute 'items' : String = "Список задач";
        attribute 'sort' : String = "Дедлайн / Приоритет";
        attribute 'state' : String = "Пусто / Загрузка / Ошибка";
    }

    part def CategoryPanel {
        attribute 'categories' : String = "Учёба, Работа, Личное";
        attribute 'action' : String = "Добавить категорию";
    }

    part def QuickAddTask {
        attribute 'title' : String = "Название задачи";
        attribute 'deadline' : String = "Дедлайн";
        attribute 'priority' : String = "Приоритет";
        attribute 'save' : String = "Создать";
    }

    part page : DashboardPage;
}
