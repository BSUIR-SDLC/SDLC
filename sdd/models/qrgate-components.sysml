package QRGate_Components {
    doc /* Композиция и структура QRGate: клиентские приложения, обратный прокси,
     * модульный монолит API-сервера и хранилища (SDD, представления 002 и 003). */

    part def ScannerApp {
        doc /* PWA контролёра: React, TypeScript, ZXing. Камера, выбор точки, карточка решения. */
    }
    part def AdminPanel {
        doc /* SPA администратора: React, Chart.js. Пропуска, live-график, журнал, настройки. */
    }
    part def ReverseProxy {
        doc /* nginx: TLS 1.2+, HSTS, статика клиентов, маршрутизация /api и /ws. */
    }
    part def ApiServer {
        doc /* Node.js 20, Express, ws. Один процесс, модули с явными интерфейсами. */
    }
    part def HttpApi { doc /* Маршруты REST /api/v1, OpenAPI, ограничение частоты. */ }
    part def AuthModule { doc /* Вход, сессии 12 ч, bcrypt, роли, блокировка. */ }
    part def RealtimeGateway { doc /* WebSocket /ws/occupancy, подписка на объект. */ }
    part def ValidationService { doc /* 7 проверок пропуска в одной транзакции БД. */ }
    part def PassService { doc /* Выпуск, продление, отзыв, перевыпуск, импорт CSV. */ }
    part def OccupancyService { doc /* Счётчик, порог, кто внутри, эвакуация. */ }
    part def QrTokenLib { doc /* Пакет qr-token: подпись и проверка HMAC-SHA256. */ }
    part def SiteService { doc /* Объекты, зоны, точки прохода, контролёры. */ }
    part def AccessLogService { doc /* Журнал событий: фильтры, выгрузка CSV. */ }
    part def PhotoService { doc /* Фото владельцев: загрузка, сжатие, выдача. */ }
    part def Scheduler { doc /* Сброс в 04:00, удаление данных старше 12 мес. */ }
    part def Observability { doc /* JSON-логи pino, метрики Prometheus /metrics. */ }
    part def Database {
        doc /* PostgreSQL 16: пропуска, объекты, присутствие, счётчики, журнал. */
    }
    part def PhotoStorage {
        doc /* Том Docker photos: JPEG 480×480, имя — UUID. */
    }

    part qrgateComponents {
        attribute w = 1900; attribute h = 1180;
        attribute title = "Композиция QRGate";

        part scanner : ScannerApp { attribute x = 40; attribute y = 150; attribute w = 300; attribute h = 190; attribute color = "client"; }
        part admin : AdminPanel { attribute x = 40; attribute y = 820; attribute w = 300; attribute h = 190; attribute color = "client"; }
        part proxy : ReverseProxy { attribute x = 420; attribute y = 480; attribute w = 280; attribute h = 200; }

        part server : ApiServer {
            attribute x = 790; attribute y = 80; attribute w = 760; attribute h = 1050; attribute color = "system";
            part api : HttpApi { attribute x = 20; attribute y = 120; attribute w = 210; attribute h = 175; }
            part auth : AuthModule { attribute x = 275; attribute y = 120; attribute w = 210; attribute h = 175; }
            part realtime : RealtimeGateway { attribute x = 530; attribute y = 345; attribute w = 210; attribute h = 175; }
            part validation : ValidationService { attribute x = 20; attribute y = 345; attribute w = 210; attribute h = 175; attribute color = "core"; }
            part passes : PassService { attribute x = 275; attribute y = 570; attribute w = 210; attribute h = 175; }
            part occupancy : OccupancyService { attribute x = 275; attribute y = 345; attribute w = 210; attribute h = 175; }
            part qrToken : QrTokenLib { attribute x = 20; attribute y = 570; attribute w = 210; attribute h = 175; attribute color = "core"; }
            part sites : SiteService { attribute x = 530; attribute y = 120; attribute w = 210; attribute h = 175; }
            part accessLog : AccessLogService { attribute x = 530; attribute y = 570; attribute w = 210; attribute h = 175; }
            part photos : PhotoService { attribute x = 20; attribute y = 795; attribute w = 210; attribute h = 175; }
            part scheduler : Scheduler { attribute x = 275; attribute y = 795; attribute w = 210; attribute h = 175; }
            part observability : Observability { attribute x = 530; attribute y = 795; attribute w = 210; attribute h = 175; }

            connection apiValidation connect api to validation { doc /* validate() */ }
            connection apiAuth connect api to auth;
            connection validationToken connect validation to qrToken { doc /* verify() */ }
            connection validationOccupancy connect validation to occupancy;
            connection passesToken connect passes to qrToken;
            connection occupancyRealtime connect occupancy to realtime;
        }

        part db : Database { attribute x = 1650; attribute y = 330; attribute w = 230; attribute h = 200; attribute color = "store"; }
        part storage : PhotoStorage { attribute x = 1650; attribute y = 800; attribute w = 230; attribute h = 170; attribute color = "store"; }

        connection scanLink connect scanner to proxy { doc /* HTTPS: /api/v1/validate */ }
        connection adminLink connect admin to proxy { doc /* HTTPS + WSS */ }
        connection proxyApi connect proxy to server { doc /* HTTP :3000 /api, /ws */ }
        connection serverDb connect server to db { doc /* SQL */ }
        connection serverStorage connect server to storage { doc /* файлы */ }
    }
}
