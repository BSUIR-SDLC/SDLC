package VolunteerAidUI {

    private import ScalarValues::*;

    part def VolunteerAidWebApp {
        part requestCatalog : RequestCatalogScreen;
        part requestDetails : RequestDetailsScreen;
        part createRequest : CreateRequestScreen;
    }

    part def RequestCatalogScreen {
        attribute pageTitle : String;
        attribute searchField : String;
        attribute cityFilter : String;
        attribute helpTypeFilter : String;
        attribute urgencyFilter : String;
        part firstRequestCard : HelpRequestCard;
        part secondRequestCard : HelpRequestCard;
    }

    part def HelpRequestCard {
        attribute animalName : String;
        attribute helpTitle : String;
        attribute organizationAndArea : String;
        attribute deadline : String;
        attribute availablePlaces : Integer;
        attribute publicStatus : String;
    }

    part def RequestDetailsScreen {
        attribute requestTitle : String;
        attribute animalDescription : String;
        attribute generalArea : String;
        attribute deadline : String;
        attribute privateAddressNotice : String;
        attribute remainingPlaces : Integer;
        action claimHelp : ClaimHelp;
    }

    part def CreateRequestScreen {
        attribute animalType : String;
        attribute requestTitle : String;
        attribute helpCategory : String;
        attribute description : String;
        attribute generalArea : String;
        attribute deadline : String;
        attribute numberOfPlaces : Integer;
        action saveDraft : SaveDraft;
        action submitForModeration : SubmitForModeration;
    }

    action def ClaimHelp {
        in attribute requestId : String;
        in attribute volunteerId : String;
        out attribute bookingStatus : String;
    }

    action def SaveDraft;

    action def SubmitForModeration;

    requirement def <'REQ-INT-001'> ResponsiveRussianInterface {
        doc /* Русскоязычный интерфейс поддерживает каталог, детали заявки и форму её создания на мобильной и настольной ширине окна. */
        subject ui : VolunteerAidWebApp;
    }

    requirement def <'REQ-INT-002'> PrivateContactAfterBooking {
        doc /* Точный адрес и контакт координатора показываются волонтёру после записи на заявку и координатору; публичный каталог показывает только общий район. */
        subject details : RequestDetailsScreen;
    }

    requirement def <'REQ-FUNC-009'> ClaimAvailablePlace {
        doc /* Записавшийся волонтёр занимает одно свободное место; система не подтверждает запись сверх числа доступных мест. */
        subject claim : ClaimHelp;
    }

    requirement def <'REQ-FUNC-006'> SubmitHelpRequest {
        doc /* Подтверждённый представитель приюта задаёт заголовок, категорию, описание, общий район, срок и число мест, затем отправляет заявку на модерацию. */
        subject form : CreateRequestScreen;
    }
}
