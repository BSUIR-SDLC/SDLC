package Dolzhok_Dashboard {

    part def DashboardPage {
        attribute title = "Должок — Мои долги";
        part header : Header;
        part userProfile : UserProfile;
        part balanceSummary : BalanceSummary;
        part addDebtBtn : AddDebtButton;
        part debtLists : DebtLists;
        part friendsPanel : FriendsPanel;
        part footer : Footer;
    }

    part def Header {
        attribute logo = "Должок";
    }

    part def UserProfile {
        attribute name = "Имя пользователя";
        attribute email = "Электронная почта";
        attribute logoutLink = "Выйти";
    }

    part def BalanceSummary {
        attribute owedToMe = "Мне должны";
        attribute iOwe = "Я должен";
        attribute netBalance = "Итоговый баланс";
    }

    part def AddDebtButton {
        attribute label = "Добавить долг";
    }

    part def DebtLists {
        part activeDebts : ActiveDebts;
        part closedDebts : ClosedDebts;
    }

    part def ActiveDebts {
        attribute items = "Активные долги: друг, сумма, срок возврата, статус";
    }

    part def ClosedDebts {
        attribute items = "История: погашенные долги";
    }

    part def FriendsPanel {
        attribute title = "Друзья";
        attribute items = "Список друзей и баланс с каждым";
        attribute addFriendBtn = "Добавить друга";
    }

    part def Footer {
        attribute info = "О сервисе, Контакты";
    }
}
