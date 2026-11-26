// Контекстная диаграмма: система, её пользователи и внешние элементы.
package SystemContext {
    private import UiLibrary::*;

    part contextDiagram : Screen {
        attribute :>> width = 1500;
        attribute :>> height = 820;
        attribute :>> caption = "Контекст системы 3D Security Monitoring Center";

        part administrator : Actor { attribute :>> posX = 135; attribute :>> posY = 40; attribute :>> caption = "Администратор"; }
        part operator : Actor { attribute :>> posX = 135; attribute :>> posY = 220; attribute :>> caption = "Оператор безопасности"; }
        part observer : Actor { attribute :>> posX = 135; attribute :>> posY = 400; attribute :>> caption = "Наблюдатель"; }
        part auditor : Actor { attribute :>> posX = 135; attribute :>> posY = 580; attribute :>> caption = "Аудитор"; }

        part smc : Block {
            attribute :>> posX = 330; attribute :>> posY = 30; attribute :>> width = 800; attribute :>> height = 700; attribute :>> caption = "3D Security Monitoring Center";
            part console : Block { attribute :>> posX = 40; attribute :>> posY = 220; attribute :>> width = 200; attribute :>> height = 130; attribute :>> caption = "3D-консоль"; }
            part server : Block { attribute :>> posX = 310; attribute :>> posY = 220; attribute :>> width = 200; attribute :>> height = 130; attribute :>> caption = "Сервер"; }
            part agent : Block { attribute :>> posX = 570; attribute :>> posY = 220; attribute :>> width = 200; attribute :>> height = 130; attribute :>> caption = "Агент"; }
            part database : Block { attribute :>> posX = 310; attribute :>> posY = 490; attribute :>> width = 200; attribute :>> height = 130; attribute :>> caption = "База данных"; }
        }

        part hosts : Block { attribute :>> posX = 1260; attribute :>> posY = 250; attribute :>> width = 220; attribute :>> height = 130; attribute :>> caption = "Хосты Windows"; attribute :>> tone = "external"; }
        part authority : Block { attribute :>> posX = 1260; attribute :>> posY = 540; attribute :>> width = 220; attribute :>> height = 130; attribute :>> caption = "Внутренний УЦ"; attribute :>> tone = "external"; }

        connection adminLink : Link connect administrator to smc.console;
        connection operatorLink : Link connect operator to smc.console;
        connection observerLink : Link connect observer to smc.console;
        connection auditorLink : Link connect auditor to smc.console;
        connection consoleLink : Link connect smc.console to smc.server { attribute :>> caption = "TLS 1.3"; }
        connection agentLink : Link connect smc.agent to smc.server { attribute :>> caption = "mTLS"; }
        connection storageLink : Link connect smc.server to smc.database { attribute :>> caption = "запросы"; }
        connection hostLink : Link connect hosts to smc.agent { attribute :>> caption = "события"; }
        connection certificateLink : Link connect authority to smc.agent { attribute :>> caption = "сертификаты"; }
    }
}
