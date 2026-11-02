package SportSpotRequirements {
    doc /* Спецификация требований к сервису бронирования спортивных площадок SportSpot.
           Версия 0.2 (после рецензирования Заказчиком Бышкало В.П.). */

    import ScalarValues::*;

    // =========================================================================
    // 1. АКТОРЫ И СИСТЕМА
    // =========================================================================
    part def Customer;
    part def VenueManager;
    part def Administrator;
    part def PaymentGateway;
    part def MailServer;

    part def SportSpot {
        part authModule;
        part catalogModule;
        part bookingEngine;
        part paymentService;
        part subscriptionService;
        part reviewService;
    }

    // =========================================================================
    // 2. БАЗОВЫЕ ТИПЫ ТРЕБОВАНИЙ
    // =========================================================================
    requirement def FunctionalRequirement {
        attribute priority : String;   // MoSCoW: Must | Should | Could
        subject system : SportSpot;
    }

    requirement def QualityRequirement {
        attribute metric : String;
        attribute targetValue : String;
        subject system : SportSpot;
    }

    // =========================================================================
    // 3. ФУНКЦИОНАЛЬНЫЕ ТРЕБОВАНИЯ
    // =========================================================================
    requirement sportSpotSpec {
        doc /* Корневой пакет: функциональные требования к веб-сервису SportSpot. */

        requirement accessAndRoles {
            requirement <'REQ-FUNC-001'> func001 : FunctionalRequirement {
                doc /* Регистрация и аутентификация пользователей по email и паролю. */
                attribute :>> priority = "Must";
            }
            requirement <'REQ-FUNC-002'> func002 : FunctionalRequirement {
                doc /* Ролевая модель: Гость, Клиент, Менеджер площадки, Администратор. */
                attribute :>> priority = "Must";
            }
        }

        requirement catalogGroup {
            requirement <'REQ-FUNC-003'> func003 : FunctionalRequirement {
                doc /* Каталог спортивных комплексов с адресами, контактами и фото. */
                attribute :>> priority = "Must";
            }
            requirement <'REQ-FUNC-004'> func004 : FunctionalRequirement {
                doc /* Фильтрация и поиск по видам спорта, покрытиям, району и дате. */
                attribute :>> priority = "Must";
            }
            requirement <'REQ-FUNC-008'> func008 : FunctionalRequirement {
                doc /* Детальная карточка площадки с тарифами и правилами посещения. */
                attribute :>> priority = "Must";
            }
            requirement <'REQ-FUNC-018'> func018 : FunctionalRequirement {
                doc /* Просмотр отзывов и галереи спортивного объекта. */
                attribute :>> priority = "Should";
            }
        }

        requirement bookingGroup {
            requirement <'REQ-FUNC-005'> func005 : FunctionalRequirement {
                doc /* Интерактивная сетка тайм-слотов (по 60 мин) с ценами. */
                attribute :>> priority = "Must";
            }
            requirement <'REQ-FUNC-006'> func006 : FunctionalRequirement {
                doc /* Контроль коллизий и защита от овербукинга слотов. */
                attribute :>> priority = "Must";
            }
            requirement <'REQ-FUNC-007'> func007 : FunctionalRequirement {
                doc /* Оформление бронирования выбранного слота пользователем. */
                attribute :>> priority = "Must";
            }
            requirement <'REQ-FUNC-010'> func010 : FunctionalRequirement {
                doc /* Отмена и перенос бронирования (бесплатно за 12 часов до начала). */
                attribute :>> priority = "Should";
            }
            requirement <'REQ-FUNC-019'> func019 : FunctionalRequirement {
                doc /* Аренда спортивного инвентаря на игру (добавлено по замечанию PR #1). */
                attribute :>> priority = "Should";
            }
            requirement <'REQ-FUNC-020'> func020 : FunctionalRequirement {
                doc /* Регулярные периодические бронирования слотов (добавлено по замечанию PR #1). */
                attribute :>> priority = "Could";
            }
        }

        requirement paymentGroup {
            requirement <'REQ-FUNC-011'> func011 : FunctionalRequirement {
                doc /* Онлайн-оплата картой через симуляцию платежного эквайринга. */
                attribute :>> priority = "Must";
            }
            requirement <'REQ-FUNC-012'> func012 : FunctionalRequirement {
                doc /* Пакетные абонементы на фиксированное число часов со скидкой. */
                attribute :>> priority = "Should";
            }
            requirement <'REQ-FUNC-013'> func013 : FunctionalRequirement {
                doc /* Автоматическое списание часов с абонемента при бронировании. */
                attribute :>> priority = "Should";
            }
            requirement <'REQ-FUNC-014'> func014 : FunctionalRequirement {
                doc /* Формирование электронного чека и подтверждения брони. */
                attribute :>> priority = "Could";
            }
        }

        requirement feedbackGroup {
            requirement <'REQ-FUNC-015'> func015 : FunctionalRequirement {
                doc /* Оценка (1-5 звезд) и отзыв только для подтвержденных броней. */
                attribute :>> priority = "Should";
            }
            requirement <'REQ-FUNC-016'> func016 : FunctionalRequirement {
                doc /* Расчет среднего рейтинга площадки по покрытию и сервису. */
                attribute :>> priority = "Should";
            }
            requirement <'REQ-FUNC-017'> func017 : FunctionalRequirement {
                doc /* Модерация отзывов администратором сервиса. */
                attribute :>> priority = "Should";
            }
            requirement <'REQ-FUNC-009'> func009 : FunctionalRequirement {
                doc /* Управление расписанием и блокировка слотов на техобслуживание. */
                attribute :>> priority = "Must";
            }
        }
    }

    // =========================================================================
    // 4. НЕФУНКЦИОНАЛЬНЫЕ ТРЕБОВАНИЯ
    // =========================================================================
    requirement qualitySpec {
        doc /* Нефункциональные требования (качество, производительность, безопасность). */

        requirement <'REQ-PERF-001'> perf001 : QualityRequirement {
            doc /* Время отклика веб-страниц: 95 % запросов не более 1,5 с. */
            attribute :>> metric = "ResponseTime95";
            attribute :>> targetValue = "<= 1500 ms";
        }

        requirement <'REQ-PERF-002'> perf002 : QualityRequirement {
            doc /* Время атомарной блокировки слота при оформлении брони. */
            attribute :>> metric = "SlotLockDuration";
            attribute :>> targetValue = "<= 500 ms";
        }

        requirement <'REQ-SEC-001'> sec001 : QualityRequirement {
            doc /* Хранение паролей в хэшированном виде (BCrypt с фактором работы >= 10). */
            attribute :>> metric = "PasswordHashingAlgorithm";
            attribute :>> targetValue = "BCrypt (strength 10+)";
        }

        requirement <'REQ-SEC-002'> sec002 : QualityRequirement {
            doc /* Изоляция ролей и защита от типовых веб-угроз (CSRF, XSS, SQLi). */
            attribute :>> metric = "SecurityCompliance";
            attribute :>> targetValue = "Spring Security standard filter chain";
        }

        requirement <'REQ-REL-002'> rel002 : QualityRequirement {
            doc /* Атомарность транзакций бронирования и баланса (уровень изоляции Repeatable Read). */
            attribute :>> metric = "TransactionAtomicity";
            attribute :>> targetValue = "100% ACID compliance";
        }

        requirement <'REQ-AVAIL-001'> avail001 : QualityRequirement {
            doc /* Доступность сервиса за календарный месяц не менее 99,5 %. */
            attribute :>> metric = "MonthlyUptime";
            attribute :>> targetValue = ">= 99.5 %";
        }

        requirement <'REQ-MAINT-001'> maint001 : QualityRequirement {
            doc /* Покрытие автоматическими тестами модуля бронирования и абонементов. */
            attribute :>> metric = "LineCodeCoverage";
            attribute :>> targetValue = ">= 85 %";
        }

        requirement <'REQ-COST-001'> cost001 : QualityRequirement {
            doc /* Месячная стоимость хостинга серверных компонентов не более 15 USD. */
            attribute :>> metric = "MonthlyCloudCost";
            attribute :>> targetValue = "<= 15 USD";
        }
    }
}
