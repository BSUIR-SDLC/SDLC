package QRGate_ValidateSequence {
    doc /* Взаимодействие при проверке пропуска (UC-02, SDD представление 006).
     * Бюджет времени: обработка на сервере ≤ 500 мс p95 (REQ-PERF-001), от скана до решения ≤ 1,5 с (REQ-PERF-002). */

    part def Controller;
    part def ScannerApp;
    part def ReverseProxy;
    part def HttpApi;
    part def ValidationService;
    part def Database;
    part def RealtimeGateway;
    part def AdminPanel;

    item def Action;
    item def Request;
    item def Call;
    item def Query;
    item def Rows;
    item def Decision;
    item def Response;
    item def Push;

    occurrence def ValidatePass {
        part controller : Controller;
        part scanner : ScannerApp;
        part proxy : ReverseProxy;
        part api : HttpApi;
        part validation : ValidationService;
        part db : Database;
        part realtime : RealtimeGateway;
        part admin : AdminPanel;

        message m01 of Action from controller to scanner { doc /* наводит камеру на QR */ }
        message m02 of Action from scanner to scanner { doc /* ZXing распознал токен, повтор за 3 с игнорируется */ }
        message m03 of Request from scanner to proxy { doc /* POST /api/v1/validate {token, checkpointId, direction} */ }
        message m04 of Request from proxy to api { doc /* proxy_pass, HTTP :3000 */ }
        message m05 of Call from api to api { doc /* сессия, роль, точка контролёра, лимит 10 запросов/с */ }
        message m06 of Call from api to validation { doc /* validate(token, checkpoint, direction, controller) */ }
        message m07 of Call from validation to validation { doc /* qr-token.verify(): подпись HMAC-SHA256 */ }
        message m08 of Query from validation to db { doc /* BEGIN; SELECT пропуск, зоны, присутствие; SELECT счётчик FOR UPDATE */ }
        message m09 of Rows from db to validation { doc /* строки пропуска и счётчика */ }
        message m10 of Call from validation to validation { doc /* статус, срок, зона, anti-passback, вместимость */ }
        message m11 of Query from validation to db { doc /* INSERT событие; UPDATE присутствие, счётчик; COMMIT */ }
        message m12 of Decision from validation to api { doc /* {decision, reason, pass, occupancy} */ }
        message m13 of Response from api to proxy { doc /* 200 OK, JSON */ }
        message m14 of Response from proxy to scanner { doc /* 200 OK, JSON */ }
        message m15 of Action from scanner to controller { doc /* карточка решения, звук, вибрация */ }
        message m16 of Push from validation to realtime { doc /* publish(occupancy, event) после COMMIT */ }
        message m17 of Push from realtime to admin { doc /* WSS {type: "occupancy"}, {type: "event"} */ }
    }
}
