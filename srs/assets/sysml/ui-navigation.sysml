package SvodkaUI {
    package Navigation {
        doc /* Модель переходов пользовательского интерфейса приложения «Сводка», версия 1.0.
               Описывает восемь переходов между экранами и внешним источником,
               методы HTTP и коды ответов из SRS §3.1.1 и REQ-INT-011.
               Идентификаторы — ASCII, текстовые значения — на русском. */

        private import ScalarValues::*;

        part def NavigationModel {
            doc /* Корневой элемент: полный набор переходов интерфейса. */
            attribute requirementIds : String = "REQ-INT-001";

            part mainToFeeds : MainToFeeds;
            part feedsToMain : FeedsToMain;
            part unknownToError : UnknownToError;
            part articleToSource : ArticleToSource;
            part refreshAction : RefreshAction;
            part addFeed : AddFeed;
            part deleteFeed : DeleteFeed;
            part toggleRead : ToggleRead;
        }

        part def MainToFeeds {
            doc /* Переход по ссылке «Ленты» в шапке главного экрана. */
            attribute sourcePath : String = "/";
            attribute targetPath : String = "/feeds";
            attribute trigger : String = "ссылка «Ленты» в шапке";
            attribute method : String = "GET";
            attribute httpStatus : String = "200";
            attribute requirementIds : String = "REQ-INT-001";
        }

        part def FeedsToMain {
            doc /* Возврат с экрана лент на главный экран. */
            attribute sourcePath : String = "/feeds";
            attribute targetPath : String = "/";
            attribute trigger : String = "ссылка «Сводка» в шапке";
            attribute method : String = "GET";
            attribute httpStatus : String = "200";
            attribute requirementIds : String = "REQ-INT-001";
        }

        part def UnknownToError {
            doc /* Неизвестный путь приводит на страницу ошибки с кодом 404. */
            attribute sourcePath : String = "любой неизвестный путь";
            attribute targetPath : String = "страница ошибки";
            attribute trigger : String = "запрос несуществующего пути";
            attribute method : String = "GET";
            attribute httpStatus : String = "404";
            attribute requirementIds : String = "REQ-INT-001";
        }

        part def ArticleToSource {
            doc /* Отметка статьи прочитанной и переход на первоисточник. */
            attribute sourcePath : String = "/articles/{id}/go";
            attribute targetPath : String = "внешний URL статьи";
            attribute trigger : String = "ссылка «Открыть источник»";
            attribute method : String = "GET";
            attribute httpStatus : String = "302";
            attribute requirementIds : String = "REQ-FUNC-004, REQ-SEC-005";
        }

        part def RefreshAction {
            doc /* Ручное обновление всех лент; повторный запуск отклоняется. */
            attribute sourcePath : String = "кнопка «Обновить»";
            attribute targetPath : String = "текущая страница";
            attribute trigger : String = "нажатие кнопки «Обновить»";
            attribute method : String = "POST";
            attribute httpStatus : String = "202 / 429";
            attribute requirementIds : String = "REQ-FUNC-007";
        }

        part def AddFeed {
            doc /* Добавление ленты из формы на экране лент. */
            attribute sourcePath : String = "/feeds";
            attribute targetPath : String = "/feeds";
            attribute trigger : String = "отправка формы добавления";
            attribute method : String = "POST";
            attribute httpStatus : String = "302 / 400 / 409";
            attribute requirementIds : String = "REQ-FUNC-001, REQ-FUNC-002";
        }

        part def DeleteFeed {
            doc /* Удаление ленты после подтверждения. */
            attribute sourcePath : String = "/feeds";
            attribute targetPath : String = "/feeds";
            attribute trigger : String = "подтверждённое удаление ленты";
            attribute method : String = "POST";
            attribute httpStatus : String = "302 / 404";
            attribute requirementIds : String = "REQ-FUNC-002";
        }

        part def ToggleRead {
            doc /* Ручное переключение отметки прочитанного с возвратом на ту же страницу. */
            attribute sourcePath : String = "/articles/{id}/read";
            attribute targetPath : String = "та же страница с параметрами page и filter";
            attribute trigger : String = "нажатие кнопки отметки";
            attribute method : String = "POST";
            attribute httpStatus : String = "302";
            attribute requirementIds : String = "REQ-FUNC-005, REQ-FUNC-013";
        }
    }
}
