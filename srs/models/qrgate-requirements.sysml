package QRGate_Requirements {
    doc /* Ключевые требования QRGate. Полные формулировки и критерии приёмки - в srs/srs-qrgate.md. */

    private import QRGate_Context::*;

    requirement def BusinessGoal;
    requirement def FunctionalRequirement;
    requirement def QualityRequirement;

    // Бизнес-цели заказчика
    requirement <'BG-1'> fastCheck : BusinessGoal {
        doc /* Проверка пропуска на входе не дольше 3 с */
    }
    requirement <'BG-2'> noFraud : BusinessGoal {
        doc /* Исключить проход по поддельным и чужим пропускам */
    }
    requirement <'BG-3'> occupancy : BusinessGoal {
        doc /* Знать заполняемость объекта в реальном времени */
    }

    // Функциональные требования
    requirement <'REQ-FUNC-002'> cameraScan : FunctionalRequirement {
        doc /* Считывание QR камерой смартфона в браузере */
    }
    requirement <'REQ-FUNC-004'> validation : FunctionalRequirement {
        doc /* Серверная валидация пропуска и ответ-решение */
    }
    requirement <'REQ-FUNC-005'> signedQr : FunctionalRequirement {
        doc /* QR содержит подписанный токен (HMAC-SHA256) */
    }
    requirement <'REQ-FUNC-006'> antiPassback : FunctionalRequirement {
        doc /* Запрет повторного входа без выхода (anti-passback) */
    }
    requirement <'REQ-FUNC-009'> liveChart : FunctionalRequirement {
        doc /* Live-график заполняемости с обновлением по WebSocket */
    }
    requirement <'REQ-FUNC-010'> capacityAlert : FunctionalRequirement {
        doc /* Предупреждение при заполнении от 90 % вместимости */
    }

    // Требования к качеству
    requirement <'REQ-PERF-001'> validationLatency : QualityRequirement {
        doc /* Ответ на валидацию не более 500 мс (95-й процентиль) */
    }
    requirement <'REQ-SEC-002'> httpsOnly : QualityRequirement {
        doc /* Только HTTPS, доступ к API по токену сессии */
    }

    // Связи "цель - требование" (выводимость)
    #derivation connection { end #original ::> fastCheck; end #derive ::> cameraScan; }
    #derivation connection { end #original ::> fastCheck; end #derive ::> validationLatency; }
    #derivation connection { end #original ::> noFraud; end #derive ::> validation; }
    #derivation connection { end #original ::> noFraud; end #derive ::> signedQr; }
    #derivation connection { end #original ::> noFraud; end #derive ::> antiPassback; }
    #derivation connection { end #original ::> occupancy; end #derive ::> liveChart; }
    #derivation connection { end #original ::> occupancy; end #derive ::> capacityAlert; }

    // Удовлетворение требований системой (satisfy ссылается на использование части)
    part qrgateSystem : QRGate;

    satisfy cameraScan by qrgateSystem;
    satisfy validation by qrgateSystem;
    satisfy signedQr by qrgateSystem;
    satisfy antiPassback by qrgateSystem;
    satisfy liveChart by qrgateSystem;
    satisfy capacityAlert by qrgateSystem;
    satisfy validationLatency by qrgateSystem;
    satisfy httpsOnly by qrgateSystem;
}
