package AnimalAidArchitecture {

    part def AnimalAidSystem {
        part userInterface : UserInterface;
        part accessControl : AccessControl;
        part organizationModeration : OrganizationModeration;
        part requestManagement : RequestManagement;
        part requestCatalog : RequestCatalog;
        part volunteerCoordination : VolunteerCoordination;
        part notifications : NotificationService;
        part dataRepository : DataRepository;

        connect userInterface to accessControl;
        connect userInterface to organizationModeration;
        connect userInterface to requestManagement;
        connect userInterface to requestCatalog;
        connect userInterface to volunteerCoordination;
        connect organizationModeration to requestManagement;
        connect requestManagement to requestCatalog;
        connect requestManagement to volunteerCoordination;
        connect accessControl to dataRepository;
        connect organizationModeration to dataRepository;
        connect requestManagement to dataRepository;
        connect requestCatalog to dataRepository;
        connect volunteerCoordination to dataRepository;
        connect notifications to dataRepository;
        connect volunteerCoordination to notifications;
    }

    part def UserInterface {
        doc /* Веб-экраны для посетителя, волонтёра, представителя приюта и администратора. */
    }

    part def AccessControl {
        doc /* Регистрация, вход, профиль и проверка прав пользователя. */
    }

    part def OrganizationModeration {
        doc /* Проверка организаций и модерация заявок перед публикацией. */
    }

    part def RequestManagement {
        doc /* Создание, редактирование и управление состояниями заявок. */
    }

    part def RequestCatalog {
        doc /* Публичный каталог, поиск и фильтры по заявкам. */
    }

    part def VolunteerCoordination {
        doc /* Запись на свободное место, отказ от записи и отчёт о выполнении. */
    }

    part def NotificationService {
        doc /* Уведомления в приложении и условная отправка копии через SMTP. */
    }

    part def DataRepository {
        doc /* Хранение пользователей, организаций, заявок, записей и истории изменений. */
    }

    part def SmtpGateway {
        doc /* Необязательная внешняя служба электронной почты. */
    }

    part def AnimalAidContext {
        part system : AnimalAidSystem;
        part smtpGateway : SmtpGateway;

        connect system.notifications to smtpGateway;
    }

    part context : AnimalAidContext;
}
