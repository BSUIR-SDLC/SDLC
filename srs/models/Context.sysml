/**
 * Контекст системы SubScope и карта переходов между экранами.
 * PNG-изображения строятся из этой модели: srs/tools/sysml2png.py.
 */
package SubScopeContext {

    part def Person;
    part def WebBrowser;
    part def WebApplication;
    part def Database;
    part def ExternalService;

    /** Контекстная диаграмма: система, её пользователи и внешние сервисы. */
    part systemContext {
        part user : Person {
            doc /* Пользователь */
        }
        part admin : Person {
            doc /* Администратор */
        }
        part browser : WebBrowser {
            doc /* Веб-браузер */
        }
        part subScope : WebApplication {
            doc /* SubScope (Spring Boot) */
        }
        part database : Database {
            doc /* PostgreSQL */
        }
        part nbrbApi : ExternalService {
            doc /* API курсов НБ РБ (api.nbrb.by) */
        }
        part mailServer : ExternalService {
            doc /* Почтовый сервер (SMTP) */
        }
        part telegram : ExternalService {
            doc /* Telegram Bot API (api.telegram.org) */
        }

        connection userUi connect user to browser {
            doc /* ведёт учёт подписок */
        }
        connection adminUi connect admin to browser {
            doc /* управляет категориями и пользователями */
        }
        connection web connect browser to subScope {
            doc /* HTTPS, HTML-страницы */
        }
        connection storage connect subScope to database {
            doc /* JDBC */
        }
        connection rates connect subScope to nbrbApi {
            doc /* HTTPS, JSON: официальные курсы валют */
        }
        connection mail connect subScope to mailServer {
            doc /* SMTP: напоминания */
        }
        connection inbox connect mailServer to user {
            doc /* письмо-напоминание */
        }
        connection bot connect subScope to telegram {
            doc /* HTTPS, JSON: сообщения бота */
        }
        connection chat connect telegram to user {
            doc /* сообщение-напоминание */
        }
    }

    item def SignedIn;
    item def SignedOut;
    item def OpenSubscriptions;
    item def OpenAnalytics;
    item def OpenSettings;
    item def OpenDashboard;
    item def AddOrEdit;
    item def SavedOrCancelled;

    /** Карта экранов: состояния — экраны, переходы — действия пользователя. */
    state def ScreenFlow {
        entry; then login;

        state login {
            doc /* Вход и регистрация */
        }
        state dashboard {
            doc /* Обзор */
        }
        state subscriptionList {
            doc /* Список подписок */
        }
        state subscriptionForm {
            doc /* Форма подписки */
        }
        state analytics {
            doc /* Аналитика */
        }
        state settings {
            doc /* Настройки */
        }

        transition signIn first login accept SignedIn then dashboard;
        transition toList first dashboard accept OpenSubscriptions then subscriptionList;
        transition toAnalytics first dashboard accept OpenAnalytics then analytics;
        transition toSettings first dashboard accept OpenSettings then settings;
        transition listToDashboard first subscriptionList accept OpenDashboard then dashboard;
        transition analyticsToDashboard first analytics accept OpenDashboard then dashboard;
        transition settingsToDashboard first settings accept OpenDashboard then dashboard;
        transition openForm first subscriptionList accept AddOrEdit then subscriptionForm;
        transition closeForm first subscriptionForm accept SavedOrCancelled then subscriptionList;
        transition analyticsToList first analytics accept OpenSubscriptions then subscriptionList;
        transition signOut first settings accept SignedOut then login;
    }
}
