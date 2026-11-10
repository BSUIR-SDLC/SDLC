package QRGate_Context {
    doc /* Контекст системы QRGate: участники и внешние системы, с которыми она взаимодействует. */

    part def Visitor {
        doc /* Посетитель объекта, предъявляющий QR-пропуск (на экране телефона или распечатанный). */
    }
    part def Controller {
        doc /* Контролёр на входе: сканирует QR смартфоном через мобильное веб-приложение. */
    }
    part def Administrator {
        doc /* Администратор объекта: выпускает и отзывает пропуска, следит за заполняемостью. */
    }
    part def QRGate {
        doc /* Система QRGate: мобильный веб-сканер, панель администратора и сервер валидации. */
    }
    part def Database {
        doc /* СУБД PostgreSQL: пропуска, точки прохода, журнал событий. */
    }
    part def MailService {
        doc /* Внешний SMTP-сервис для отправки QR-пропусков посетителям по e-mail. */
    }

    part qrgateContext {
        part visitor : Visitor;
        part controller : Controller;
        part admin : Administrator;
        part qrgate : QRGate;
        part db : Database;
        part mail : MailService;

        connection showLink connect visitor to controller {
            doc /* предъявляет QR-пропуск */
        }
        connection scanLink connect controller to qrgate {
            doc /* HTTPS: скан QR, запрос валидации, ответ */
        }
        connection adminLink connect admin to qrgate {
            doc /* HTTPS + WebSocket: пропуска, live-график */
        }
        connection dbLink connect qrgate to db {
            doc /* SQL: пропуска, события проходов */
        }
        connection mailLink connect qrgate to mail {
            doc /* SMTP: письмо с QR-пропуском */
        }
    }
}
