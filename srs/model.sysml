package EventOrganizerSystem {
    private import ScalarValues::*;

    requirement def BR1_EventManagement {
        attribute id : String = "BR_1";
        attribute text : String = "CRUD-операции событий";
    }

    requirement def BR2_TicketCategories {
        attribute id : String = "BR_2";
        attribute text : String = "Категории VIP и Стандарт";
    }

    requirement def BR4_SalesAggregation {
        attribute id : String = "BR_4";
        attribute text : String = "Сводная таблица и выручка";
    }

    requirement reqBR1 : BR1_EventManagement;
    requirement reqBR2 : BR2_TicketCategories;
    requirement reqBR4 : BR4_SalesAggregation;

    enum def TicketTypeEnum {
        STANDARD;
        VIP;
    }

    part def TicketCategory {
        attribute categoryType : TicketTypeEnum;
        attribute quota : Integer;
        attribute soldCount : Integer;
        attribute price : Real;
        attribute revenue : Real;
    }

    part def Event {
        attribute id : String;
        attribute title : String;
        attribute eventDate : String;
        attribute maxCapacity : Integer;
        attribute totalRevenue : Real;

        part tickets : TicketCategory[2];
    }

    part def GUIScreen;
    part def InputField;
    part def Button;
    part def KPIWidget;
    part def Table;

    part def OrganizerDashboardView :> GUIScreen {
        part searchBar : InputField;
        part btnCreateEvent : Button;
        part kpiTotalRevenue : KPIWidget;
        part salesSummaryTable : Table;
    }

    part def EventEditorModalView :> GUIScreen {
        part inputTitle : InputField;
        part vipQuotaInput : InputField;
        part stdPriceInput : InputField;
        part btnSave : Button;
    }

    part dashboardView : OrganizerDashboardView;
    part editorModalView : EventEditorModalView;

    satisfy reqBR1 by dashboardView;
    satisfy reqBR4 by dashboardView;
    satisfy reqBR2 by editorModalView;
}
