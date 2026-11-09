# Описание дизайна программного обеспечения (SDD)

Для проекта «EventPass — приложение посетителя»

Версия 1.0

Подготовил(а): Овсяник Алексей, студент группы 439401

Белорусский государственный университет информатики и радиоэлектроники (БГУИР)

Факультет компьютерных систем и сетей, кафедра ЭВМ

2026 г.

---

## Оглавление

* [1. Введение](#1-introduction)
  * [1.1 Назначение документа](#11-document-purpose)
  * [1.2 Область применения](#12-subject-scope)
  * [1.3 Определения, акронимы и сокращения](#13-definitions-acronyms-and-abbreviations)
  * [1.4 Ссылки](#14-references)
  * [1.5 Обзор документа](#15-document-overview)
* [2. Обзор дизайна](#2-design-overview)
  * [2.1 Задачи стейкхолдеров](#21-stakeholder-concerns)
  * [2.2 Выбранные точки зрения](#22-selected-viewpoints)
    * [2.2.1 Контекст](#221-context)
    * [2.2.2 Композиция](#222-composition)
    * [2.2.3 Логическое представление](#223-logical)
    * [2.2.4 Физическое представление](#224-physical)
    * [2.2.5 Структура](#225-structure)
    * [2.2.6 Зависимости](#226-dependency)
    * [2.2.7 Информация](#227-information)
    * [2.2.8 Интерфейс](#228-interface)
    * [2.2.9 Взаимодействие](#229-interaction)
    * [2.2.10 Алгоритм](#2210-algorithm)
    * [2.2.11 Динамика состояний](#2211-state-dynamics)
    * [2.2.12 Параллелизм](#2212-concurrency)
    * [2.2.13 Паттерны](#2213-patterns)
    * [2.2.14 Развёртывание](#2214-deployment)
    * [2.2.15 Ресурсы](#2215-resources)
* [3. Проектные представления и приоритеты функций](#3-design-views)
  * [3.1 Ранжирование приоритетов функционала (Prioritization 10-50)](#31-prioritization)
  * [3.2 Детализированные проектные представления](#32-detailed-views)
* [4. Решения](#4-decisions)
* [5. Приложения](#5-appendixes)

---

## История изменений

| Name | Date | Reason For Changes | Version |
|---|---|---|---|
| Овсяник А. Н. | 2026-11-09 | Создание документа системного проектирования SDD для лаб. № 4 | 1.0 |

---

## 1. Введение {#1-introduction}

### 1.1 Назначение документа {#11-document-purpose}

Настоящее описание дизайна программного обеспечения (Software Design Description, SDD) определяет внутреннюю архитектуру, модульную структуру, контракты интерфейсов и информационные модели клиентского веб-приложения «EventPass — приложение посетителя». Документ служит практическим руководством для разработчиков фронтенда, инженеров интеграции бэкенда, тестировщиков и архитектора при реализации решений, зафиксированных в спецификации требований к ПО (SRS).

### 1.2 Область применения {#12-subject-scope}

Проектируемый модуль «EventPass — приложение посетителя» охватывает клиентскую логику витрины мероприятий, многокритериальной фильтрации, временного удержания мест в корзине, фиксации оформления заказов, отрисовки динамического оптического QR-кода и просмотра истории покупок.
* **Входит в дизайн:** компонентная модель React, клиентское состояние корзины и таймера резервирования (15 мин), REST API клиент для работы с сервисом билетов, алгоритм клиентской генерации/валидации QR-кода, адаптивная верстка (Mobile-first).
* **Не входит в дизайн:** реализация алгоритмов расчета наполняемости турникетов (сервис № 4), модуль организатора (сервис № 1), физический эквайринг банковских карт.

### 1.3 Определения, акронимы и сокращения {#13-definitions-acronyms-and-abbreviations}

| Term | Definition |
|---|---|
| API | Application Programming Interface — программный интерфейс интеграции систем |
| ECC | Error Correction Code — уровень коррекции ошибок матричного кода Reed-Solomon |
| JWT | JSON Web Token — формат защищенных сессионных маркеров авторизации |
| Mock SMTP | Локальный отладочный почтовый сервер (Mailpit / MailHog) для перехвата писем без выхода в интернет |
| QR | Quick Response — двумерный матричный оптический код |
| RWD | Responsive Web Design — методология адаптивной отзывчивой веб-верстки |
| SDD | Software Design Description — документ описания архитектуры и дизайна ПО |
| SRS | Software Requirements Specification — спецификация требований к ПО |
| WBS | Work Breakdown Structure — иерархическая структура декомпозиции работ |

### 1.4 Ссылки {#14-references}

* **ISO/IEC/IEEE 42010:2011**, «Systems and software engineering — Architecture description» — **нормативная**.
* **IEEE Std 1016-2009**, «IEEE Standard for Information Technology — Systems Design — Software Design Descriptions» — **нормативная**.
* **Спецификация требований к ПО**: `srs/srs.md` (проект EventPass, репозиторий SDLC) — **нормативная**.
* **Протоколы архитектурных решений**: `adr/` (ADR-001...ADR-003) — **нормативная**.
* **Модель системных требований**: `model.sysml` — **справочная**.
* **Графические прототипы интерфейса**: `srs/img/` (`catalog.png`, `cart.png`, `ticket_qr.png`, `history.png`) — **справочная**.

### 1.5 Обзор документа {#15-document-overview}

Раздел 2 определяет архитектурные точки зрения (Viewpoints) согласно стандарту IEEE 1016-2009, охватывая статические, динамические и эксплуатационные аспекты. Раздел 3 содержит формализованный перечень системных компонентов с ранжированием приоритетов от 10 (Highest) до 50 (Lowest). В Разделе 4 приведены ссылки на архитектурные решения ADR.

---

## 2. Обзор дизайна {#2-design-overview}

### 2.1 Задачи стейкхолдеров {#21-stakeholder-concerns}

* **Посетитель (End User):** скорость отклика каталога, читаемость QR-кода при слабом освещении или с экрана смартфона, гарантия сохранения брони на время оформления.
* **Разработчик (Frontend / Backend Engineer):** строгая типизация (TypeScript), модульность компонентов, предсказуемые контракты REST API, воспроизводимость сборки.
* **Архитектор / PM:** соблюдение сроков поставки итераций, минимизация стоимости инфраструктуры, отсутствие деградации при пиковых продажах.
* **Служба контроля доступа:** гарантированная считываемость QR-кода валидатором за время < 500 мс.

### 2.2 Выбранные точки зрения {#22-selected-viewpoints}

#### 2.2.1 Контекст {#221-context}
Система «EventPass Client» функционирует в изолированной песочнице веб-браузера пользователя. Клиент инициирует HTTPS-соединения к `Ticket Service API` (сервис билетов № 2) и `Auth Service`. Внешний мобильный сканер турникетов (сервис № 4) оптически считывает экран посетителя без прямого сетевого контакта между клиентскими устройствами.

#### 2.2.2 Композиция {#222-composition}
Клиентское приложение декомпозировано на функциональные модули:
* `AuthModule`: управление состоянием сессии, форма входа/регистрации, перехватчик токенов JWT.
* `CatalogModule`: каталог мероприятий, карточки событий, строка поиска и фасетные фильтры.
* `CartModule`: хранилище выбранных билетов, локальный обратный таймер синхронизации с сервером.
* `CheckoutModule`: форма ввода данных покупателя, эмулятор платежного шлюза.
* `TicketRendererModule`: генератор и отрисовщик QR-кода на базе векторного/растрового холста (`qrcode.react`).
* `HistoryModule`: отображение архивных и активных заказов.
* `ApiClientLayer`: изолированный HTTP-транспорт на базе `fetch`/`axios` с обработкой повторных попыток.

#### 2.2.3 Логическое представление {#223-logical}
Интерфейсы основных доменных сущностей клиентской части:
```typescript
interface EventItem {
  id: string;
  title: string;
  description: string;
  city: string;
  venue: string;
  date: string;
  standardPrice: number;
  vipPrice: number;
  availableStandard: number;
  availableVip: number;
}

interface CartItem {
  eventId: string;
  eventTitle: string;
  ticketType: 'VIP' | 'Standard';
  price: number;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  reservationExpiresAt: number | null; // UNIX timestamp (ms)
  totalAmount: number;
}

interface TicketRecord {
  ticketId: string;
  orderId: string;
  eventTitle: string;
  venue: string;
  date: string;
  ticketType: 'VIP' | 'Standard';
  qrPayload: string;
  status: 'VALID' | 'USED' | 'REFUNDED';
}
```

#### 2.2.4 Физическое представление {#224-physical}
Развертывание клиентской части осуществляется на статическом веб-сервере Nginx (или CDN) в виде предсобранного бандла (HTML, CSS, JS chunks). Связь с сервером билетов осуществляется по защищенному каналу через порт 443 (HTTPS).

#### 2.2.5 Структура {#225-structure}
Архитектура фронтенда построена по принципу слоев (Feature-Driven / Layered Architecture):
1. **Shared/UI:** базовые компоненты (кнопки, модальные окна, таймер, скелетоны).
2. **Features:** изолированные бизнес-блоки (`filter-events`, `reserve-seat`, `render-qr`).
3. **Entities:** состояние доменных моделей (`event`, `cart`, `ticket`).
4. **App Layer:** маршрутизация (React Router), провайдеры контекста и корневой контейнер.

#### 2.2.6 Зависимости {#226-dependency}
* React 18+ / React DOM
* TypeScript 5+
* Lucide-React (иконки интерфейса)
* qrcode / qrcode.react (генерация QR-матрицы в браузере)
* Tailwind CSS (утилитарная верстка)

#### 2.2.7 Информация {#227-information}
Клиент не использует постоянную базу данных. Для сохранения промежуточного состояния (сессия пользователя, кэш каталога) используется `localStorage` (с флагами маскирования данных) и оперативная память сессионного хранилища React State.

#### 2.2.8 Интерфейс {#228-interface}
* `GET /api/v1/events` $\rightarrow$ `HTTP 200 OK: EventItem[]`
* `POST /api/v1/cart/reserve` $\rightarrow$ `Req: { items: { eventId, type, count }[] }` $\rightarrow$ `Resp: { reservationId, expiresAt }`
* `POST /api/v1/orders/checkout` $\rightarrow$ `Req: { reservationId, paymentToken }` $\rightarrow$ `Resp: { orderId, tickets: TicketRecord[] }`
* `GET /api/v1/orders/my` $\rightarrow$ `HTTP 200 OK: OrderHistoryItem[]`

#### 2.2.9 Взаимодействие {#229-interaction}
*Поток оформления билета:*
1. Пользователь выбирает билеты в Каталоге $\rightarrow$ передача действия в `CartModule`.
2. `CartModule` отправляет сетевой запрос `POST /api/v1/cart/reserve`.
3. Сервер бронирует квоту в БД на 15 минут, возвращает `expiresAt`.
4. Клиент запускает таймер обратного отсчета в шапке сайта.
5. Пользователь нажимает «Оформить» $\rightarrow$ эмуляция оплаты $\rightarrow$ `POST /api/v1/orders/checkout`.
6. Сервер фиксирует заказ, инициирует отправку копии билета в Mock SMTP и возвращает билеты с токеном QR.
7. Клиент переключается на экран билета, рендерит QR-код на `<canvas>`.

#### 2.2.10 Алгоритм {#2210-algorithm}
*Алгоритм визуализации QR-кода билета:*
1. Получить строку полезной нагрузки `qrPayload` из структуры билета (содержит формат: `EVTPASS:v1:<ticket_id>:<hmac_signature>`).
2. Задать параметры рендерера: размер матрицы 256×256 px, уровень коррекции ошибок `ECC Level M` (восстановление до 15% повреждений), цвет фона `#FFFFFF`, цвет модулей `#000000`, отступ (quiet zone) — 4 модуля.
3. Отрисовать матрицу на элементе HTML5 Canvas.
4. Проверить контрастность результирующего элемента перед снятием экрана загрузки.

#### 2.2.11 Динамика состояний {#2211-state-dynamics}
*Конечный автомат состояния корзины:*
`[EMPTY]` $\xrightarrow{\text{добавление места}}$ `[RESERVING]` $\xrightarrow{\text{ответ API: OK}}$ `[ACTIVE_HOLD]` (таймер 15:00) $\xrightarrow{\text{таймаут истек}}$ `[EXPIRED]` $\rightarrow$ `[EMPTY]`.  
Из `[ACTIVE_HOLD]` $\xrightarrow{\text{клик «Оплатить»}}$ `[PROCESSING]` $\xrightarrow{\text{успех}}$ `[ORDER_COMPLETED]`.

#### 2.2.12 Параллелизм {#2212-concurrency}
Браузерная среда JavaScript исполняется в однопоточном цикле событий (Event Loop). Все сетевые обращения к API билетов и таймер обратного отсчета изолированы в асинхронных функциях (`async/await`, `setInterval`) и не блокируют рендеринг пользовательского интерфейса (60 fps).

#### 2.2.13 Паттерны {#2213-patterns}
* **Container/Presentational Pattern:** разделение логики работы с состоянием и глупых компонентов верстки.
* **Repository/Service Layer:** изоляция работы с REST API от компонентов React.
* **Observer:** подписка компонентов интерфейса на изменения единого хранилища состояния (React Context / хуки).

#### 2.2.14 Развёртывание {#2214-deployment}
Бандл фронтенда упаковывается в легковесный Docker-контейнер `alpine-nginx` и разворачивается на виртуальном хосте. Статические ресурсы кэшируются HTTP-заголовками `Cache-Control: max-age=31536000, immutable` для бандлов с хэшами.

#### 2.2.15 Ресурсы {#2215-resources}
* Память: потребление вкладки браузера не должно превышать 75 МБ.
* Трафик: первоначальный размер загружаемого сжатого бандла (Gzip/Brotli) не более 200 КБ.

---

## 3. Проектные представления и приоритеты функций {#3-design-views}

### 3.1 Ранжирование приоритетов функционала (Prioritization 10-50) {#31-prioritization}

В соответствии с заданием лабораторной работы № 4 функциональные возможности ранжированы по шкале от **10 (наивысший приоритет / Critical Core)** до **50 (минимальный приоритет / Low Optional)**. Ранжирование выполнено на английском языке:

| Function ID | Feature Name | Priority (10-50) | Priority Class | Description |
|---|---|---|---|---|
| **FEAT-01** | QR-Code Generation & Display | **10** | Highest / Critical Core | Immediate client-side rendering of high-contrast QR token for turnstile optical check. |
| **FEAT-02** | Cart Reservation & 15-min Hold | **15** | Highest / Critical Core | Seat locking mechanism with countdown timer and conflict prevention via Ticket API. |
| **FEAT-03** | Event Catalog Display & Pagination | **20** | High / Core Feature | Display of event grid with real-time seat availability quotas (VIP and Standard). |
| **FEAT-04** | Search & Multi-criteria Filtering | **25** | High / Core Feature | Filtering events by city, dates, genre, price range, and ticket class without full reload. |
| **FEAT-05** | Order Checkout & Payment Mock | **30** | Medium / Essential | Simulating payment gateway confirmation, issuing ticket tokens, triggering Mock SMTP. |
| **FEAT-06** | User Authentication & Session JWT | **35** | Medium / Important | Registration, login, and secure JWT storage (guest browsing remains unrestricted). |
| **FEAT-07** | Order History & Ticket Archive | **40** | Low-Medium / Supporting | Viewing list of purchased tickets with statuses (Valid, Used, Refunded) and quick QR access. |
| **FEAT-08** | Offline PDF Ticket Download | **45** | Low / Nice-to-Have | Exporting ticket receipt with raster QR to PDF file for disconnected access. |
| **FEAT-09** | Promo Code Discount Engine | **50** | Lowest / Optional | Applying coupon codes in cart for dynamic price reduction during campaigns. |

### 3.2 Детализированные проектные представления {#32-detailed-views}

#### VIEW-001: Модуль QR-билета (FEAT-01, Приоритет 10)
* **ID:** VIEW-001-QR-RENDER
* **Title:** Клиентский компонент отрисовки электронного билета
* **Viewpoint:** Интерфейс / Алгоритм (2.2.8, 2.2.10)
* **Representation:** Компонент `TicketQrCard` принимает структурированный токен билета, валидирует контрольную сумму и рендерит холст 256×256 px.
* **More Information:** Связан с требованием `REQ-FUNC-007` (SRS), макетом `srs/img/ticket_qr.png` и решением ADR-002.

#### VIEW-002: Модуль корзины и бронирования (FEAT-02, Приоритет 15)
* **ID:** VIEW-002-CART-TIMER
* **Title:** Контроллер сессионного резервирования мест
* **Viewpoint:** Динамика состояний / Взаимодействие (2.2.9, 2.2.11)
* **Representation:** Хук `useCartReservation` отслеживает локальное время и время сервера `expiresAt`. По истечении 900 секунд инициирует очистку состояния корзины и блокирует переход к шагу оплаты.
* **More Information:** Связан с требованием `REQ-FUNC-005` (SRS), макетом `srs/img/cart.png` и решением ADR-003.

#### VIEW-003: Каталог и фасетная фильтрация (FEAT-03/FEAT-04, Приоритеты 20, 25)
* **ID:** VIEW-003-CATALOG-FILTER
* **Title:** Витрина мероприятий с динамической выборкой
* **Viewpoint:** Композиция / Логическое представление (2.2.2, 2.2.3)
* **Representation:** Контейнер `EventsCatalogView` с дочерними компонентами `FilterSidebar`, `SearchBar`, `EventCardGrid`. Состояние фильтрации синхронизируется с URL Query Params для возможности сохранения ссылок на выборку.
* **More Information:** Связан с требованиями `REQ-FUNC-002`, `REQ-FUNC-003` (SRS) и макетом `srs/img/catalog.png`.

---

## 4. Решения {#4-decisions}

В ходе проектирования были приняты ключевые архитектурные решения, формализованные в виде ADR:
* **ADR-001:** Выбор архитектурного стека React + TypeScript для адаптивного веб-клиента.
* **ADR-002:** Клиентская генерация QR-кода на базе легковесной библиотеки против серверного рендеринга растровых картинок.
* **ADR-003:** Механизм двухстороннего контроля 15-минутного таймаута резервирования мест в корзине.

---

## 5. Приложения {#5-appendixes}

### Приложение 1. Трассировка требований SRS на проектные компоненты SDD

| SRS Requirement ID | SDD Component / View | Feature ID | Priority |
|---|---|---|---|
| REQ-FUNC-001 | AuthModule | FEAT-06 | 35 |
| REQ-FUNC-002 | CatalogModule (`EventCardGrid`) | FEAT-03 | 20 |
| REQ-FUNC-003 | CatalogModule (`FilterSidebar`) | FEAT-04 | 25 |
| REQ-FUNC-004 | CatalogModule (`EventDetailsModal`) | FEAT-03 | 20 |
| REQ-FUNC-005 | CartModule (`useCartReservation`) | FEAT-02 | 15 |
| REQ-FUNC-006 | CheckoutModule (`CheckoutView`) | FEAT-05 | 30 |
| REQ-FUNC-007 | TicketRendererModule (`TicketQrCard`) | FEAT-01 | 10 |
| REQ-FUNC-008 | HistoryModule (`OrderHistoryList`) | FEAT-07 | 40 |
| REQ-FUNC-009 | ExportModule (`PdfDownloader`) | FEAT-08 | 45 |
| REQ-FUNC-010 | CartModule (`PromoCodeInput`) | FEAT-09 | 50 |