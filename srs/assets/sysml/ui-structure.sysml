package SvodkaUI {
    doc /* Структурная модель пользовательского интерфейса приложения «Сводка», версия 1.0.
           Охватывает экраны и элементы из SRS §3.1.1: главный экран, экран управления лентами,
           страницу ошибки, состояния пустоты, ошибки и работы из кэша.
           Идентификаторы — ASCII, текстовые значения — на русском.
           Трассируемость к требованиям задаётся атрибутом requirementIds. */

    private import ScalarValues::*;

    part def Application {
        doc /* Корневой элемент модели: одно приложение и три экрана. */
        attribute name : String = "Сводка";
        attribute version : String = "1.0";
        attribute requirementIds : String = "REQ-INT-001";

        part mainScreen : MainScreen;
        part feedsScreen : FeedsScreen;
        part errorScreen : ErrorScreen;
        part localisation : Localisation;
        part accessibility : Accessibility;
    }

    part def MainScreen {
        doc /* Главный экран: объединённый список статей, фильтр, пагинация, баннеры состояний. */
        attribute path : String = "/";
        attribute queryParameters : String = "page, filter";
        attribute requirementIds : String = "REQ-INT-001, REQ-INT-002, REQ-INT-004, REQ-INT-005, REQ-INT-006";

        part header : Header;
        part filterBar : FilterBar;
        part articleList : ArticleList;
        part pagination : Pagination;
        part banners : Banners;
    }

    part def Header {
        doc /* Шапка: название приложения, время последнего успешного обновления, кнопка обновления. */
        attribute title : String = "Сводка";
        attribute lastUpdateFormat : String = "ГГГГ-ММ-ДД ЧЧ:ММ";
        part refreshButton : Button;
    }

    part def Button {
        doc /* Кнопка или ссылка, инициирующая действие. */
        attribute label : String;
        attribute actionName : String;
        attribute method : String = "POST";
        attribute targetPath : String;
    }

    part def FilterBar {
        doc /* Переключатель «Все» / «Непрочитанные» со счётчиками. */
        attribute selectedFilter : String = "all";
        attribute allowedValues : String = "all | unread";
        part allTab : FilterTab;
        part unreadTab : FilterTab;
    }

    part def FilterTab {
        doc /* Вкладка фильтра с необязательным счётчиком статей. */
        attribute label : String;
        attribute filterValue : String;
        attribute showsCount : Boolean = true;
    }

    part def ArticleList {
        doc /* Список статей всех лент, по 50 записей на страницу. */
        attribute pageSize : Integer = 50;
        part row : ArticleRow [0..*];
    }

    part def ArticleRow {
        doc /* Строка списка: заголовок, источник, дата, фрагмент, признак непрочитанного, ссылка. */
        attribute title : String;
        attribute sourceName : String;
        attribute publishedAt : String;
        attribute snippetMaxChars : Integer = 300;
        attribute unread : Boolean;
        part unreadBadge : UnreadBadge;
        part sourceLink : ExternalLink;
    }

    part def UnreadBadge {
        doc /* Текстовый бейдж непрочитанной статьи, различимый без наведения. */
        attribute label : String = "непрочитано";
        attribute visibleWhen : String = "unread = true";
    }

    part def ExternalLink {
        doc /* Ссылка на первоисточник, открывается в новой вкладке. */
        attribute label : String = "Открыть источник";
        attribute target : String = "_blank";
        attribute rel : String = "noopener noreferrer";
    }

    part def Pagination {
        doc /* Постраничный вывод: номер страницы, общее число страниц, переходы. */
        attribute pageSize : Integer = 50;
        attribute showsTotalPages : Boolean = true;
        attribute pageParameter : String = "page";
        part previous : Button;
        part next : Button;
    }

    part def Banners {
        doc /* Состояния, отображаемые над списком статей. */
        part emptyState : EmptyState;
        part allFeedsError : ErrorBanner;
        part cacheBanner : CacheBanner;
    }

    part def EmptyState {
        doc /* Состояние «ленты не добавлены». */
        attribute text : String = "Ленты не добавлены";
        attribute linkPath : String = "/feeds";
        attribute visibleWhen : String = "feedCount = 0";
    }

    part def ErrorBanner {
        doc /* Предупреждение о неудачном обновлении всех лент. */
        attribute text : String = "Обновление не удалось";
        attribute showsLastSuccessTime : Boolean = true;
        attribute visibleWhen : String = "allFeedsFailed = true";
    }

    part def CacheBanner {
        doc /* Баннер работы из кэша с датой и временем сохранённых данных. */
        attribute text : String = "Данные от <дата и время>";
        attribute visibleWhen : String = "servedFromCache = true";
    }

    part def FeedsScreen {
        doc /* Экран управления лентами: таблица лент, форма добавления, удаление с подтверждением. */
        attribute path : String = "/feeds";
        attribute requirementIds : String = "REQ-INT-003, REQ-INT-006";

        part feedTable : FeedTable;
        part addFeedForm : AddFeedForm;
        part deleteAction : DeleteAction;
    }

    part def FeedTable {
        doc /* Таблица лент с состоянием последней загрузки. */
        part row : FeedRow [0..5];
    }

    part def FeedRow {
        doc /* Строка таблицы лент. */
        attribute url : String;
        attribute title : String;
        attribute lastFetchAt : String;
        attribute articleCount : Integer;
        attribute status : String;
        attribute statusValues : String = "success | error | never";
        attribute errorText : String;
    }

    part def AddFeedForm {
        doc /* Форма добавления ленты с проверкой URL и кодами ответа. */
        attribute fieldName : String = "url";
        attribute maxLength : Integer = 2048;
        attribute successStatus : Integer = 302;
        attribute invalidStatus : Integer = 400;
        attribute limitStatus : Integer = 409;
        part submit : Button;
    }

    part def DeleteAction {
        doc /* Удаление ленты вместе со статьями, с подтверждением. */
        attribute method : String = "POST";
        attribute path : String = "/feeds/{id}/delete";
        attribute requiresConfirmation : Boolean = true;
        attribute successStatus : Integer = 302;
        attribute missingStatus : Integer = 404;
    }

    part def ErrorScreen {
        doc /* Страница ошибки для неизвестного пути. */
        attribute status : Integer = 404;
        attribute text : String = "Страница не найдена";
        attribute linkPath : String = "/";
        attribute requirementIds : String = "REQ-INT-001";
    }

    part def Localisation {
        doc /* Язык интерфейса и кодировка. */
        attribute uiLanguage : String = "ru";
        attribute charset : String = "UTF-8";
        attribute requirementIds : String = "REQ-INT-005";
    }

    part def Accessibility {
        doc /* Требования доступности, применимые к экранам. */
        attribute minContrastRatio : Real = 4.5;
        attribute keyboardReachable : Boolean = true;
        attribute visibleFocus : Boolean = true;
        attribute visibleFocusWidthPx : Integer = 2;
        attribute iconAlternativeText : Boolean = true;
        attribute requirementIds : String = "REQ-INT-006";
    }
}
