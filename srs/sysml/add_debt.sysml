package Dolzhok_AddDebt {

    part def AddDebtPage {
        attribute title = "Новый долг";
        part header : Header;
        part directionSwitch : DirectionSwitch;
        part friendSelector : FriendSelector;
        part amountBlock : AmountBlock;
        part descriptionField : DescriptionField;
        part datesBlock : DatesBlock;
        part saveBtn : SaveButton;
        part cancelBtn : CancelButton;
    }

    part def Header {
        attribute logo = "Должок";
    }

    part def DirectionSwitch {
        attribute optionLent = "Я одолжил(а)";
        attribute optionBorrowed = "Я занял(а)";
    }

    part def FriendSelector {
        attribute label = "Друг";
        attribute hint = "Выберите из списка или введите имя";
    }

    part def AmountBlock {
        attribute amount = "Сумма";
        attribute currency = "Валюта (BYN, USD, EUR, RUB)";
    }

    part def DescriptionField {
        attribute label = "Комментарий";
        attribute hint = "На что одолжили (необязательно)";
    }

    part def DatesBlock {
        attribute debtDate = "Дата долга";
        attribute dueDate = "Срок возврата (необязательно)";
    }

    part def SaveButton {
        attribute label = "Сохранить";
    }

    part def CancelButton {
        attribute label = "Отмена";
    }
}
