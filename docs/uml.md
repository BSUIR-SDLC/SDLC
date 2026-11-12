# UML-модели динамического поведения EasyTicket

Версия 0.1. Подготовил: Питковский В.В. Дата: 12.11.2026. Диаграммы описаны текстом (Mermaid) и отображаются на GitHub; растровые копии лежат в `uml/*.png`, исходники — в `uml/src/*.mmd`.

Диаграммы строятся последовательно: **вариант использования** (`docs/use-cases.md`) задаёт сценарий → **диаграмма активности** описывает его шаги и ветвления → **диаграммы состояний** показывают жизненный цикл объектов, которые меняются по ходу сценария → **диаграммы последовательности** показывают, какие компоненты и в каком порядке обмениваются сообщениями. Связь с требованиями — в разделе «Трассировка».

## 1. Диаграмма активности: покупка билета

Сценарий UC-03 → UC-04 → UC-05. Ромбы — ветвления, пунктирная стрелка — параллельная фоновая отправка письма. Реализует REQ-FUNC-004…008, REQ-REL-001.

```mermaid
flowchart TD
    start((" ")) --> a1["Выбрать мероприятие в афише"]
    a1 --> a2["Открыть схему зала"]
    a2 --> a3["Выбрать свободное место"]
    a3 --> d1{"Место свободно?"}
    d1 -- "нет" --> a4["Показать сообщение:<br/>место занято"]
    a4 --> a3
    d1 -- "да" --> a5["Создать бронь на 10 минут,<br/>запустить таймер"]
    a5 --> d2{"Добавить ещё место?<br/>(не более 10)"}
    d2 -- "да" --> a3
    d2 -- "нет" --> a6["Ввести email"]
    a6 --> d3{"Email корректен?"}
    d3 -- "нет" --> a6
    d3 -- "да" --> a7["Подтвердить оплату<br/>(эмуляция)"]
    a7 --> d4{"Бронь ещё<br/>действует?"}
    d4 -- "нет" --> a8["Освободить места,<br/>показать сообщение об истечении брони"]
    a8 --> fin1(((" ")))
    d4 -- "да" --> a9["Создать заказ,<br/>места становятся «Продано»"]
    a9 --> a10["Сформировать подписанный QR-код<br/>для каждого билета"]
    a10 --> a11["Записать письмо в outbox"]
    a11 --> a12["Показать страницу подтверждения<br/>с QR-кодом"]
    a12 --> fin2(((" ")))
    a11 -. "в фоне" .-> b1["Отправить письмо в SMTP"]
    b1 --> d5{"Отправка<br/>успешна?"}
    d5 -- "да" --> b2["Пометить письмо отправленным"]
    d5 -- "нет, попыток < 3" --> b3["Ждать 1 минуту"]
    b3 --> b1
    d5 -- "нет, попыток = 3" --> b4["Пометить письмо failed;<br/>билет доступен по номеру заказа"]
    b2 --> fin3(((" ")))
    b4 --> fin3
```

## 2. Диаграмма состояний: место

Жизненный цикл места на мероприятии. Реализует REQ-FUNC-003, 005, 006, 014, 015.

```mermaid
stateDiagram-v2
    direction LR
    [*] --> Free
    Free --> Reserved : AddToCart [место свободно] / запуск таймера 10 мин
    Reserved --> Free : ReservationTimeout
    Reserved --> Free : RemoveFromCart
    Reserved --> Free : AdminCancel
    Reserved --> Sold : PaymentConfirmed [бронь действует]
    Sold --> Free : Refund [не позднее чем за 24 ч до начала]
    state "Free (Свободно)" as Free
    state "Reserved (Забронировано)" as Reserved
    state "Sold (Продано)" as Sold
```

## 3. Диаграмма состояний: билет

Жизненный цикл билета. Реализует REQ-FUNC-007, 010, 015.

```mermaid
stateDiagram-v2
    direction LR
    [*] --> Issued : PaymentConfirmed / создать QR
    Issued --> Used : ScanValid [подпись верна, не использован]
    Issued --> Refunded : Refund [не позднее чем за 24 ч до начала]
    Issued --> Issued : ScanInvalid / отказ «Недействителен»
    Used --> Used : Scan / отказ «Уже использован»
    Refunded --> Refunded : Scan / отказ «Возвращён»
    state "Issued (Выдан)" as Issued
    state "Used (Использован)" as Used
    state "Refunded (Возвращён)" as Refunded
```

## 4. Диаграмма последовательности: покупка билета

Взаимодействие компонентов при UC-03, UC-04, UC-05; фрагмент `alt` показывает путь истёкшей брони. Реализует REQ-FUNC-005…008.

```mermaid
sequenceDiagram
    autonumber
    actor B as Покупатель
    participant UI as WebUI
    participant API as RestApi
    participant R as ReservationService
    participant O as OrderService
    participant Q as QrService
    participant W as OutboxWorker
    participant S as MailServer (mock SMTP)
    B->>UI: выбрать места
    UI->>API: POST /api/reservations
    activate API
    API->>R: reserve(event, seats)
    activate R
    R-->>API: reservation_id, expires_at (+10 мин)
    deactivate R
    API-->>UI: 201 Created
    deactivate API
    B->>UI: ввести email, нажать «Оплатить»
    UI->>API: POST /api/orders, POST /api/orders/{id}/pay
    activate API
    API->>O: createOrder(reservation, email)
    activate O
    alt бронь истекла
        O-->>API: ошибка
        API-->>UI: 409 Conflict
    else бронь действует
        O->>R: confirm(seats) → «Продано»
        O->>Q: generate(ticket)
        activate Q
        Q-->>O: PNG + подпись HMAC
        deactivate Q
        O->>W: поставить письмо в outbox
        O-->>API: order_id, tickets
        deactivate O
        API-->>UI: 200 OK
        deactivate API
        UI-->>B: страница подтверждения с QR
        W-)S: SMTP DATA (не позднее 60 с)
        S--)W: 250 OK
    end
```

## 5. Диаграмма последовательности: проверка билета

Взаимодействие при UC-08; атомарное условное обновление исключает повторный проход. Реализует REQ-FUNC-010, REQ-SEC-006.

```mermaid
sequenceDiagram
    autonumber
    actor C as Контролёр
    participant UI as WebUI (смартфон)
    participant API as RestApi
    participant O as OrderService
    participant DB as PostgreSQL
    C->>UI: сканировать QR-код
    UI->>API: POST /api/tickets/verify
    activate API
    API->>O: verify(qr_payload)
    activate O
    O->>O: проверить подпись HMAC
    alt подпись неверна
        O-->>API: invalid
        API-->>UI: «Недействителен»
    else подпись верна
        O->>DB: UPDATE tickets SET used_at = now() WHERE id = ? AND used_at IS NULL
        DB-->>O: затронуто строк: 0 или 1
        alt 1 строка
            O-->>API: valid
            API-->>UI: «Действителен»
        else 0 строк
            O-->>API: already used / refunded
            API-->>UI: «Уже использован» / «Возвращён»
        end
    end
    deactivate O
    deactivate API
    UI-->>C: результат проверки
```

## 6. Трассировка

| Диаграмма | Прецеденты | Требования | Представление SDD |
|-----------|-----------|------------|-------------------|
| Активность: покупка | UC-03, UC-04, UC-05 | REQ-FUNC-004…008 | DV-014 |
| Состояния: место | UC-03, UC-04, UC-07, UC-12, UC-13 | REQ-FUNC-003, 005, 006, 014, 015 | DV-015 |
| Состояния: билет | UC-05, UC-07, UC-08 | REQ-FUNC-007, 010, 015 | DV-015 |
| Последовательность: покупка | UC-03, UC-04, UC-05 | REQ-FUNC-005…008 | DV-016 |
| Последовательность: проверка | UC-08 | REQ-FUNC-010 | DV-016 |
