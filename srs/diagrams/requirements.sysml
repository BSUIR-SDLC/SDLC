/**
 * Спецификация системных и функциональных требований на языке SysML v2
 * Проект: HabitROI (Калькулятор стоимости вредных привычек в перспективе)
 * Стандарт: ISO/IEC/IEEE 29148:2018 / OMG SysML v2
 * Автор: Студент группы 450503 Игнатюк А. А.
 */
package HabitROIRequirements {
    private import ScalarValues::*;

    // Базовое определение требования
    requirement def HabitSystemRequirement {
        attribute id : String;
        attribute title : String;
        attribute statement : String;
        attribute rationale : String;
        attribute verificationMethod : String;
    }

    // 1. Бизнес-требование
    requirement def BusinessGoalRequirement :> HabitSystemRequirement {
        attribute targetAudience : String;
        attribute businessROI : String;
    }

    requirement habitROI_BG : BusinessGoalRequirement {
        doc /* Бизнес-цель: Мотивация пользователя к отказу от вредных привычек через наглядную финансовую альтернативу */
        id = "REQ-BIZ-001";
        title = "Мотивация через осознание финансовых альтернатив";
        statement = "Система должна трансформировать абстрактные периодические траты на вредные привычки в осязаемые материальные и инвестиционные цели.";
        rationale = "Пользователи недооценивают масштаб мелких ежедневных трат (эффект латте). Наглядное сопоставление с крупными покупками и инвестициями кардинально повышает мотивацию к отказу от привычки.";
        verificationMethod = "Demonstration";
        targetAudience = "Люди, желающие избавиться от пагубных привычек (курение, фастфуд, кофе на вынос, импульсивные подписки) и сформировать капитал";
        businessROI = "Повышение конверсии пользователей в долгосрочное удержание за счет психологического импакта визуализации.";
    }

    // 2. Функциональные требования
    requirement habitInput_req : HabitSystemRequirement {
        id = "REQ-FUNC-001";
        title = "Ввод и каталогизация вредных привычек";
        statement = "Система должна обеспечивать ввод названия привычки, категории (курение, напитки, фастфуд, подписки, азарт/игры), стоимости одной порции/единицы и периодичности списания (день, неделя, месяц).";
        rationale = "Необходимость точного задания параметров регулярных расходов для корректного прогнозирования.";
        verificationMethod = "Test";
    }

    requirement projectionCalc_req : HabitSystemRequirement {
        id = "REQ-FUNC-002";
        title = "Многопериодный расчет накопленного ущерба и экономии";
        statement = "Система должна рассчитывать суммарные финансовые потери за временные горизонты: 1 месяц, 6 месяцев, 1 год, 3 года, 5 лет, 10 лет, 20 лет.";
        rationale = "Позволяет пользователю увидеть кумулятивный эффект трат на коротких и длинных дистанциях.";
        verificationMethod = "Test";
    }

    requirement compoundInterest_req : HabitSystemRequirement {
        id = "REQ-FUNC-003";
        title = "Моделирование сложного процента (инвестиционный ROI)";
        statement = "Система должна рассчитывать капитал, который был бы сформирован при инвестировании сэкономленных сумм с ежемесячной капитализацией по настраиваемой процентной ставке (по умолчанию 12% годовых).";
        rationale = "Демонстрация работы сложного процента усиливает эмоциональный эффект упущенной выгоды (Opportunity Cost).";
        verificationMethod = "Test";
    }

    requirement visualAlternatives_req : HabitSystemRequirement {
        id = "REQ-FUNC-004";
        title = "Визуализация материальных альтернатив (эквиваленты покупок)";
        statement = "Система должна динамически сопоставлять сэкономленную сумму с каталогом материальных и жизненных целей (новый iPhone, поездка на Бали, автомобиль, акции Apple с дивидендами) и формировать графическую карточку с изображением и прогресс-баром достижения цели.";
        rationale = "Ключевая особенность продукта — визуальный шок-контент, заменяющий скучные сухие цифры привлекательными образами.";
        verificationMethod = "Demonstration";
    }

    requirement currencySupport_req : HabitSystemRequirement {
        id = "REQ-FUNC-005";
        title = "Мультивалютность и интеграция с внешними курсами";
        statement = "Система должна поддерживать основные валюты (BYN, RUB, USD, EUR) с возможностью автоматического обновления курсов через API центробанков (ЦБ РФ / НБРБ).";
        rationale = "Обеспечение релевантности расчетов для целевой аудитории Беларуси и СНГ.";
        verificationMethod = "Test";
    }

    requirement shareCard_req : HabitSystemRequirement {
        id = "REQ-FUNC-006";
        title = "Экспорт и генерация вирусных карточек для соцсетей";
        statement = "Система должна позволять экспортировать сгенерированную карточку сравнения в формате PNG/JPEG для отправки в мессенджеры и социальные сети.";
        rationale = "Создание органического вирального охвата приложения.";
        verificationMethod = "Test";
    }

    // 3. Нефункциональные требования (QoS)
    requirement perfLatency_req : HabitSystemRequirement {
        id = "REQ-PERF-001";
        title = "Мгновенный пересчет в реальном времени";
        statement = "Время полного пересчета финансовой модели и обновления графических эквивалентов при изменении любого входного параметра не должно превышать 50 миллисекунд.";
        rationale = "Обеспечение плавного интерактивного пользовательского опыта (UX) без задержек.";
        verificationMethod = "Test";
    }

    requirement secStorage_req : HabitSystemRequirement {
        id = "REQ-SEC-001";
        title = "Локальная конфиденциальность данных";
        statement = "Все пользовательские данные о привычках и расходах должны храниться локально на устройстве пользователя в зашифрованном виде (SQLite с SQLCipher или защищенный JSON) без обязательной передачи на внешний сервер.";
        rationale = "Защита приватности личной жизни пользователя и чувствительных финансовых сведений.";
        verificationMethod = "Inspection";
    }

    // Трассируемость и связи требований
    dependency from projectionCalc_req to habitInput_req;
    dependency from compoundInterest_req to projectionCalc_req;
    dependency from visualAlternatives_req to projectionCalc_req;
    dependency from visualAlternatives_req to compoundInterest_req;
}
