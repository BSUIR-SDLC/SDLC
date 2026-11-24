# Описание дизайна программного обеспечения

Для **IoTPanel — веб-панели мониторинга и управления IoT-устройствами и правилами автоматизации**

Версия 0.3

Подготовил(а) Д.Г. Тишкевич

УО «Белорусский государственный университет информатики и радиоэлектроники», кафедра ЭВМ

2026-11-24

## Оглавление

<!-- TOC -->
* [1. Введение](#1-introduction)
  * [1.1 Назначение документа](#11-document-purpose)
  * [1.2 Область применения](#12-subject-scope)
  * [1.3 Определения, акронимы и сокращения](#13-definitions-acronyms-and-abbreviations)
  * [1.4 Ссылки](#14-references)
  * [1.5 Обзор документа](#15-document-overview)
* [2. Обзор дизайна](#2-design-overview)
  * [2.1 Задачи стейкхолдеров](#21-stakeholder-concerns)
  * [2.2 Выбранные точки зрения](#22-selected-viewpoints)
* [3. Проектные представления](#3-design-views)
* [4. Решения](#4-decisions)
* [5. Приложения](#5-appendixes)
<!-- TOC -->

## История изменений

| Name | Date | Reason For Changes | Version |
|------|------|--------------------|---------|
| Д.Г. Тишкевич | 2026-11-05 | Первоначальная разработка архитектуры SDD и бэклога (приоритеты 10–50) на основе SRS v0.2 | 0.1 |
| Д.Г. Тишкевич | 2026-11-09 | Корректировка приоритетов, добавление подсистемы оповещений (SYS-10, ADR-0005) и финального плана с Junior-разработчиком | 0.2 |
| Д.Г. Тишкевич | 2026-11-24 | Добавление поведенческих представлений UML 2.5 (`DV-08` – `DV-10`: варианты использования, активность, состояния, последовательность) по итогам ЛР № 5 | 0.3 |

---

## 1. Введение {#1-introduction}

### 1.1 Назначение документа {#11-document-purpose}

Настоящее описание дизайна программного обеспечения (Software Design Description, SDD) определяет системную архитектуру, компонентный состав, структуру данных, интерфейсы и динамическое поведение системы **IoTPanel**. Целевой аудиторией документа являются разработчики проекта, системный архитектор, тестировщики и представитель Заказчика. Документ переводит требования из спецификации `srs/srs-iotpanel.md` в предписывающую архитектуру, служащую руководством к реализации и верификации.

### 1.2 Область применения {#12-subject-scope}

Проектируемая система **IoTPanel (релиз 1.0)** представляет собой одностраничное веб-приложение (SPA) оператора мониторинга и инженера автоматизации, интегрированное с серверным движком правил (Rule Engine Backend) и эмулятором IoT-устройств (Device Emulator). Система обеспечивает:
1. Визуализацию живого потока телеметрии (`temperature`, `motion`) на графиках `Chart.js` с задержкой не более 2 с (**BG-1**);
2. Дистанционное переключение состояния устройств (`POST /command`) за время не более 1 с с автоматической блокировкой кнопки при офлайн-статусе (**BG-2**);
3. Безошибочное создание JSON-правил автоматизации через 4-шаговую визуальную форму «Выбрать устройство -> Выбрать метрику -> Условие -> Действие», их тестовый прогон (`Dry-Run`) и отправку экстренных уведомлений (**BG-3**).

### 1.3 Определения, акронимы и сокращения {#13-definitions-acronyms-and-abbreviations}

| Term | Definition |
|------|------------|
| ADR | Architectural Decision Record — протокол архитектурного решения (в формате MADR) |
| API | Application Programming Interface — программный интерфейс приложения (REST / WebSocket) |
| BG | Business Goal — бизнес-цель проекта из документа SRS |
| Dry-Run | Режим тестовой симуляции правила автоматизации без физического переключения реле устройства |
| Fail-Closed | Принцип безопасного отказа: при потере связи с устройством управление им принудительно блокируется |
| SDD | Software Design Description — описание проектирования ПО (IEEE 1016-2009 / ISO/IEC/IEEE 42010) |
| UML | Unified Modeling Language 2.5 — унифицированный язык моделирования структуры и поведения системы |

### 1.4 Ссылки {#14-references}

| Название документа | Автор / Владелец | Версия / Дата | Статус | Расположение |
|---|---|---|---|---|
| Спецификация требований к ПО (SRS) IoTPanel | Д.Г. Тишкевич | v0.3 (2026-11-09) | Нормативный | `srs/srs-iotpanel.md` |
| Глоссарий проекта и доп. спецификации | Д.Г. Тишкевич | v1.0 (2026-11-24) | Нормативный | `docs/glossary.md`, `docs/supplementary-specifications.md` |
| Диаграммы динамического поведения UML | Д.Г. Тишкевич | v1.0 (2026-11-24) | Нормативный | `uml/*.puml`, `uml/img/*.png` |
| Протоколы архитектурных решений ADR-0001 – ADR-0005 | Д.Г. Тишкевич | 2026-11-24 | Нормативный | `adr/0001..0005-*.md` |

### 1.5 Обзор документа {#15-document-overview}

Раздел 2 описывает задачи стейкхолдеров и выбранные архитектурные точки зрения (Viewpoints) согласно ISO/IEC/IEEE 42010. Раздел 3 содержит статические (`DV-01` – `DV-07`) и поведенческие (`DV-08` – `DV-10`) проектные представления. Раздел 4 резюмирует ключевые архитектурные решения `ADR-0001` – `ADR-0005`.

---

## 2. Обзор дизайна {#2-design-overview}

### 2.1 Задачи стейкхолдеров {#21-stakeholder-concerns}

| Стейкхолдер | Основные интересы и задачи (Concerns) | Адресующие Viewpoints и разделы |
|---|---|---|
| **Заказчик** | Соблюдение дедлайна (4 недели) и бюджета ($3 450), выполнение бизнес-целей BG-1 – BG-3. | Composition (`DV-01`), Приложения |
| **Оператор мониторинга** | Наглядность живых графиков (`< 2 с`), мгновенный отклик `/command` (`< 1 с`), защита Fail-Closed. | Interface (`DV-03`), State Dynamics (`DV-06`, `DV-09`), Interaction (`DV-10`) |
| **Инженер автоматизации** | Создание правил за 30 с через 4-шаговую форму без ручного ввода JSON, безопасный тест `Dry-Run`. | Information (`DV-02`), Algorithm (`DV-05`), Activity (`DV-08`) |
| **Команда разработки** | Чёткое разделение модулей, контракты API, диаграммы последовательности и переходов состояний. | Composition (`DV-01`), Sequence (`DV-10`), Deployment (`DV-07`) |

### 2.2 Выбранные точки зрения {#22-selected-viewpoints}

Для описания архитектуры `IoTPanel` из 15 точек зрения стандарта ISO/IEC/IEEE 42010 выбраны 8 основных ракурсов: **Context** (границы и акторы, `DV-08`), **Composition** (модульная структура, `DV-01`), **Information** (схема PostgreSQL 16 и JSONB, `DV-02`), **Interface** (контракты REST и WebSocket, `DV-03`), **Interaction** (сценарии взаимодействия и диаграмма последовательности UML, `DV-04`, `DV-10`), **Algorithm** (алгоритм вычисления правил и диаграмма активности, `DV-05`, `DV-08`), **State Dynamics** (автомат доступности устройства Fail-Closed, `DV-06`, `DV-09`) и **Deployment** (контейнеры Docker Compose, `DV-07`).

---

## 3. Проектные представления {#3-design-views}

### DV-01: Декомпозиция системы на подсистемы и модули
- **ID**: DV-01-Composition
- **Title**: Компонентная структура клиентской и серверной частей IoTPanel
- **Viewpoint**: Composition (Композиция)
- **Representation**:
  Система разделена на клиентское SPA-приложение `frontend/` (React 18, TypeScript, Chart.js, Tailwind CSS — модули `DashboardModule`, `RuleBuilderModule`, `RulesAndLogsModule`, `AlertBannerModule`) и серверный движок правил `backend/` (Node.js 20, Express, ws, Ajv — модули `TelemetryHub`, `CommandProxy`, `RuleEngineService`, `AlertDispatcher`), работающие с СУБД PostgreSQL 16 и эмулятором `Device Emulator`.
- **More Information**: Реализует `REQ-FUNC-001` – `REQ-FUNC-014`, `SYS-01` – `SYS-10`. Связано с `ADR-0001`, `ADR-0002`, `ADR-0005`.

### DV-02: Модель данных и схема хранения правил
- **ID**: DV-02-Information
- **Title**: Схема базы данных PostgreSQL 16 и JSON Schema правил
- **Viewpoint**: Information (Информация)
- **Representation**:
  Хранение данных организовано в трёх основных таблицах: `devices` (`device_id`, `name`, `metrics_supported`, `status`, `current_state`, `last_seen_at`), `automation_rules` (`rule_id`, `device_id`, `is_active`, `is_critical`, `rule_json JSONB`) и `command_logs` (`log_id`, `device_id`, `source`, `command_payload JSONB`, `http_status`, `executed_at`).
- **More Information**: Реализует `REQ-FUNC-007`, `REQ-FUNC-008`, `REQ-FUNC-010`, `REQ-FUNC-011`. Опирается на `ADR-0003`.

### DV-03: Спецификация интерфейсов REST API и WebSocket
- **ID**: DV-03-Interface
- **Title**: Контракты внешних и внутренних интерфейсов IoTPanel
- **Viewpoint**: Interface (Интерфейс)
- **Representation**:
  REST-эндпоинты (`GET /api/devices`, `POST /api/devices/:id/command`, `GET/POST /api/rules`, `PATCH /api/rules/:id/toggle`, `POST /api/rules/dry-run`, `GET /api/logs`) защищены заголовком `Authorization: Bearer <API_TOKEN>`. Потоковая доставка событий в браузер выполняется по каналу WebSocket (`wss://iotpanel.local/ws`) фреймами `TELEMETRY_UPDATE`, `DEVICE_STATUS` и `CRITICAL_ALERT`.
- **More Information**: Реализует `REQ-INT-001` – `REQ-INT-007`, `REQ-SEC-001`, `REQ-SEC-002`. Опирается на `ADR-0002`, `ADR-0005`.

### DV-04: Сценарий взаимодействия при обработке телеметрии
- **ID**: DV-04-Interaction
- **Title**: Прохождение пакета телеметрии и автоматическое срабатывание правила
- **Viewpoint**: Interaction (Взаимодействие)
- **Representation**:
  `Device Emulator` отправляет JSON-пакет на `POST /api/telemetry/ingest` -> `TelemetryHub` обновляет таймер `Heartbeat` и транслирует `TELEMETRY_UPDATE` по WebSocket на график `Chart.js` (`< 200 мс`) -> `RuleEngineService` проверяет активные правила и при превышении порога вызывает `CommandProxy` (`POST /command`) и `AlertDispatcher`.
- **More Information**: Реализует `REQ-PERF-001`, `REQ-FUNC-002`, `REQ-FUNC-009`.

### DV-05: Алгоритм вычисления правил и тестовой симуляции (Dry-Run)
- **ID**: DV-05-Algorithm
- **Title**: Детерминированный алгоритм проверки условий `RuleEvaluator`
- **Viewpoint**: Algorithm (Алгоритм)
- **Representation**:
  Для каждого входящего пакета телеметрии извлекаются активные правила по `device_id`, выполняется сравнение метрики по оператору (`>`, `<`, `==`, `!=`). При срабатывании в штатном режиме (`isDryRun = FALSE`) вызывается `CommandProxy.Send()`, а в режиме тестового прогона (`isDryRun = TRUE`) физическое переключение реле пропускается, но формируются запись `DRY-RUN` в журнале и уведомление в `AlertDispatcher`.
- **More Information**: Реализует `REQ-FUNC-008`, `REQ-FUNC-009`, `REQ-FUNC-014`. Опирается на `ADR-0003`, `ADR-0005`.

### DV-06: Табличная модель доступности устройства (Fail-Closed)
- **ID**: DV-06-StateDynamics
- **Title**: Правила переходов доступности карточки устройства и блокировки `/command`
- **Viewpoint**: State Dynamics (Динамика состояний)
- **Representation**:
  При получении пакетов телеметрии устройство находится в рабочем состоянии; при отсутствии пакетов более 5 с сервер переводит устройство в статус `OFFLINE`, а интерфейс принудительно блокирует тумблер переключения состояния (`disabled = true`) до восстановления связи.
- **More Information**: Реализует `REQ-REL-001`, `REQ-FUNC-005`. Опирается на `ADR-0004`.

### DV-07: Схема контейнерного развёртывания
- **ID**: DV-07-Deployment
- **Title**: Развёртывание сервисов IoTPanel в окружении Docker Compose
- **Viewpoint**: Deployment (Развёртывание)
- **Representation**:
  Единый файл `docker-compose.yml` запускает 4 контейнера в изолированной сети `iotnet`: `iotpanel-frontend` (Nginx + React), `iotpanel-backend` (Node.js 20), `iotpanel-db` (PostgreSQL 16) и `device-emulator`.
- **More Information**: Реализует `REQ-INST-001`, `REQ-INST-002`, `REQ-BUILD-001`.

### DV-08: Варианты использования и диаграмма активности UML
- **ID**: DV-08-UseCase-Activity
- **Title**: Поведенческая модель прецедентов и потоков управления (UML Use Case & Activity)
- **Viewpoint**: Context / Algorithm (Контекст и алгоритм поведения)
- **Representation**:
  1. **Диаграмма вариантов использования (`uml/usecase-iotpanel.puml`, `uml/img/uml_usecase_bw.png`):** отражает иерархию актёров с обобщением (*Оператор мониторинга* и *Инженер автоматизации* наследуют базового *Пользователя IoTPanel*), внешние системы (*Device Emulator*, *Telegram / Webhook*), обязательное включение `«include»` (*Авторизация по токену JWT*) и опциональное расширение `«extend»` (*Тестовый прогон правила Dry-Run*).
  2. **Диаграмма активности (`uml/activity-iotpanel.puml`, `uml/img/uml_activity_bw.png`):** детализирует ветвления при приёме телеметрии и заполнении 4-шаговой формы, а также асинхронные приёмники событий для открытия списка правил и обработки триггера `/command` в любой момент работы панели.
- **More Information**: Реализует `REQ-FUNC-002`, `REQ-FUNC-007`, `REQ-FUNC-010`, `REQ-FUNC-014`. Подробные потоки событий описаны в `docs/use-cases-flow.md`.

### DV-09: Диаграмма состояний устройства UML (State Machine)
- **ID**: DV-09-StateMachine
- **Title**: Конечный автомат состояний IoT-устройства в интерфейсе (UML State Machine)
- **Viewpoint**: State Dynamics (Динамика состояний)
- **Representation**:
  Диаграмма состояний (`uml/statemachine-device.puml`, `uml/img/uml_statemachine_bw.png`) формализует переходы устройства между тремя основными состояниями:
  - **`Idle (ONLINE_IDLE)`:** устройство в сети, ожидание команд или телеметрии;
  - **`Out of Service (OFFLINE_LOCKED)`:** переход по событию `heartbeat_lost (>5s)`, полная блокировка управления по стратегии Fail-Closed до прихода `heartbeat_ok`;
  - **`Active (COMMAND_ACTIVE)`:** переход по событию `postCommand(ON)`, возврат в `Idle` при отмене/таймауте (`cancel / timeout`) либо по завершении цикла работы (`done (OFF)`).
- **More Information**: Реализует `REQ-REL-001`, `REQ-FUNC-005`, `REQ-FUNC-006`. Детализировано в `adr/0004-fail-closed-offline-lock.md`.

### DV-10: Диаграмма последовательности исполнения команды UML (Sequence)
- **ID**: DV-10-Sequence
- **Title**: Временная диаграмма выполнения команды переключения состояния (UML Sequence)
- **Viewpoint**: Interaction (Взаимодействие во времени)
- **Representation**:
  Диаграмма последовательности (`uml/sequence-command.puml`, `uml/img/uml_sequence_bw.png`) описывает взаимодействие объектов `:Dashboard`, `«typescript» :CommandCtrl`, `«fetch» :ApiClient` и `«express» :RuleEngine`:
  1. Входной шлюз `toggleState()` инициирует проверку состояния `validateState()` в контроллере;
  2. Контроллер динамически создаёт экземпляр клиента запроса (`«create» :ApiClient`) и отправляет асинхронный запрос `«fetch» POST /command`;
  3. Сервер транслирует команду `«http» forward()`, возвращает статус (`200 OK` или ошибку) и завершает обработку (`destroy`);
  4. Временное ограничение `{10..200ms}` контролирует задержку отклика, а ссылка `ref Handle Errors (504 / Fail-Closed)` описывает сценарий отката тумблера и блокировки при сбое.
- **More Information**: Реализует `REQ-PERF-002`, `REQ-FUNC-005`, `REQ-FUNC-006`, `REQ-REL-001`. Детализировано в `adr/0002-websocket-telemetry.md` и `adr/0004-fail-closed-offline-lock.md`.

---

## 4. Решения {#4-decisions}

Полные протоколы архитектурных решений в шаблоне MADR размещены в каталоге `adr/`:
* **ADR-0001** (`adr/0001-spa-react-chartjs.md`): Выбор связки React 18 + TypeScript + Chart.js (HTML5 Canvas) для клиентской панели мониторинга.
* **ADR-0002** (`adr/0002-websocket-telemetry.md`): Использование протокола WebSocket для потоковой доставки телеметрии и сигналов тревоги (дополнено описанием корреляции событий и временных ограничений в рантайме).
* **ADR-0003** (`adr/0003-json-schema-rule-engine.md`): Сериализация и валидация правил автоматизации на основе JSON Schema (Ajv) и PostgreSQL JSONB.
* **ADR-0004** (`adr/0004-fail-closed-offline-lock.md`): Применение стратегии Fail-Closed при переходе устройства в статус OFFLINE (дополнено описанием связывания автомата состояний с блокировкой UI).
* **ADR-0005** (`adr/0005-webhook-alerting.md`): Асинхронная диспетчеризация экстренных оповещений (Webhook/Telegram) и режим тестового прогона правил (`Dry-Run`).

---

## 5. Приложения {#5-appendixes}

* **Приложение А:** Системные требования (`SYS-01` – `SYS-10`), приоритеты (10–50) и планы итераций приведены в `plans/plan.md`.
* **Приложение Б:** Глоссарий проекта, дополнительные спецификации и потоки событий прецедентов приведены в `docs/glossary.md`, `docs/supplementary-specifications.md` и `docs/use-cases-flow.md`.