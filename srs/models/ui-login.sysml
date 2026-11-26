// Окно входа в 3D-консоль. Требования: REQ-FUNC-026, REQ-SEC-003, REQ-SEC-013.
package UiLogin {
    private import UiLibrary::*;

    part loginScreen : Screen {
        attribute :>> width = 760;
        attribute :>> height = 600;
        attribute :>> caption = "3D Security Monitoring Center";

        part heading : Heading { attribute :>> posX = 80; attribute :>> posY = 34; attribute :>> width = 600; attribute :>> height = 40; attribute :>> caption = "Вход в консоль оператора"; }
        part loginField : TextField { attribute :>> posX = 80; attribute :>> posY = 110; attribute :>> width = 600; attribute :>> height = 48; attribute :>> caption = "Логин"; attribute :>> subcaption = "petrov"; }
        part passwordField : TextField { attribute :>> posX = 80; attribute :>> posY = 200; attribute :>> width = 600; attribute :>> height = 48; attribute :>> caption = "Пароль"; attribute :>> subcaption = "••••••••••"; }
        part totpField : TextField { attribute :>> posX = 80; attribute :>> posY = 290; attribute :>> width = 600; attribute :>> height = 48; attribute :>> caption = "Код второго фактора (если включён)"; attribute :>> subcaption = "123456"; }
        part lockMessage : Label { attribute :>> posX = 80; attribute :>> posY = 350; attribute :>> width = 600; attribute :>> height = 30; attribute :>> caption = "Учётная запись заблокирована до 10:30"; attribute :>> tone = "incident"; }
        part loginButton : PrimaryButton { attribute :>> posX = 80; attribute :>> posY = 396; attribute :>> width = 600; attribute :>> height = 56; attribute :>> caption = "Войти"; }
        part connectionState : Badge { attribute :>> posX = 80; attribute :>> posY = 474; attribute :>> width = 230; attribute :>> height = 34; attribute :>> caption = "Сервер доступен"; attribute :>> tone = "normal"; }
    }
}
