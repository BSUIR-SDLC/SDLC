package TaskFlowUI {
    part def User
    part def Task
    part def KanbanBoard
    part def TaskCard
    part def SearchFilterBar

    part taskFlowUI : KanbanBoard {
        part todoColumn : KanbanBoard
        part inProgressColumn : KanbanBoard
        part doneColumn : KanbanBoard
        part toolbar : SearchFilterBar

        part todoTask : TaskCard
        part workTask : TaskCard
        part doneTask : TaskCard
    }

    item taskData : Task {
        attribute title : String;
        attribute description : String;
        attribute priority : String;
        attribute status : String;
        attribute dueDate : String;
    }

    connection userToBoard {
        item user : User;
        item board : KanbanBoard;
    }

    // Graphical prototype intent:
    // toolbar: application title, search, filters, "+ New task"
    // columns: "To do", "In progress", "Done"
    // cards: title, priority, due date, action controls
}
