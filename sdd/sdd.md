# Описание дизайна программного обеспечения

Для «Должок»

Версия 0.2

Подготовил(а) Козак М.М. — архитектор системы

БГУИР, кафедра ЭВМ, группа 450503

31.10.2026

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
| Козак М.М. | 31.10.2026 | Первая версия. Основана на SRS 0.2 (раунд 2 переписки) | 0.1 |
|      |      |                    |         |

---

## 1. Введение {#1-introduction}

Документ описывает архитектуру и проектные решения веб-приложения «Должок» на основе SRS версии 0.2 (`srs/srs.md`).

### 1.1 Назначение документа {#11-document-purpose}

SDD определяет, **КАК** будет устроена система, чтобы выполнить требования SRS. Документ предназначен для разработчиков (реализация, junior-разработчик), тестировщиков (тест-кейсы по компонентам) и Заказчика (обзор решений и сроков). Каждое значимое решение зафиксировано в ADR (`adr/`).

### 1.2 Область применения {#12-subject-scope}

Описание охватывает серверную часть (Java, Spring Boot), клиентскую часть (React, Vite), базу данных (PostgreSQL), отправку почты через внешний SMTP и окружение Docker. Нативные мобильные приложения, интеграции с банками и групповые траты с автоматическим разделением счёта в описание не входят.

### 1.3 Определения, акронимы и сокращения {#13-definitions-acronyms-and-abbreviations}

| Term | Definition |
|------|------------|
| ADR | Architectural Decision Record — запись архитектурного решения |
| API | Application Programming Interface — интерфейс взаимодействия клиента и сервера |
| Outbox | Таблица в БД, куда записываются письма в одной транзакции с данными, а затем отправляются фоновым процессом |
| SPA | Single Page Application — одностраничное веб-приложение |
| SRS | Software Requirements Specification — спецификация требований |

### 1.4 Ссылки {#14-references}

| Документ | Тип | Расположение |
|----------|-----|--------------|
| Спецификация требований к ПО «Должок», версия 0.2 | нормативный | `srs/srs.md` |
| Архитектурные решения ADR-0001…ADR-0005 | нормативный | `adr/` |
| План реализации по итерациям | справочный | `docs/plan/iterations.md` |
| IEEE 830-1998 — SRS | справочный | — |

### 1.5 Обзор документа {#15-document-overview}

Раздел 2 описывает задачи стейкхолдеров и выбранные точки зрения. Раздел 3 содержит проектные представления DES-001…DES-008 с трассировкой на требования SRS. Раздел 4 перечисляет решения (ADR). Раздел 5 — приложения: API и модель данных.

---

## 2. Обзор дизайна {#2-design-overview}

### 2.1 Задачи стейкхолдеров {#21-stakeholder-concerns}

| Стейкхолдер | Задача | Где решается |
|-------------|--------|--------------|
| Заказчик | Срок 12 недель, стоимость без скачков | Раздел 3 (DES-008), `docs/plan/iterations.md` |
| Пользователь | Точные суммы, быстрый ответ, понятный интерфейс | DES-003, DES-006, DES-007 |
| Разработчики | Понятная структура пакетов и модулей | DES-002 |
| Тестировщики | Проверяемые границы компонентов | DES-001, DES-005 |
| Администратор | Блокировка учётных записей | DES-003 |

### 2.2 Выбранные точки зрения {#22-selected-viewpoints}

#### 2.2.1 Контекст {#221-context}

Пользователь работает в браузере с SPA. SPA обращается к REST API серверной части. API читает и пишет в PostgreSQL и через SMTP отправляет письма. Внешние системы: SMTP-сервис. Больше внешних интеграций нет.

#### 2.2.2 Композиция {#222-composition}

Серверная часть состоит из модулей: `auth` (регистрация, вход, сессии), `friends` (приглашения и дружба), `debt` (долги, подтверждение, погашения), `balance` (расчёт баланса), `notification` (outbox и отправка писем), `admin` (блокировка), `common` (ошибки, валидация, конфигурация).

#### 2.2.3 Логическое представление {#223-logical}

Каждый модуль делится на три слоя: контроллер (REST), сервис (бизнес-логика, транзакции), репозиторий (доступ к данным). Контроллеры не обращаются к репозиториям напрямую (проверка ArchUnit, ADR-0001).

#### 2.2.4 Физическое представление {#224-physical}

Окружение Docker Compose: контейнер `web` (nginx, раздаёт статику React и проксирует `/api`), контейнер `api` (Spring Boot, JRE 21), контейнер `db` (PostgreSQL 16). SMTP — внешний сервис, адрес задаётся переменной окружения.

#### 2.2.5 Структура {#225-structure}

Ключевые сущности: `User`, `Friendship`, `Debt`, `Repayment`, `OutboxMessage`. Связи: пользователь — дружба (два пользователя), долг (кредитор и должник), погашения (многие к одному долгу).

#### 2.2.6 Зависимости {#226-dependency}

Модуль `debt` зависит от `friends` (проверка дружбы) и `notification` (постановка письма в outbox). Модуль `balance` читает `debt`, но не меняет его. Модуль `auth` не зависит от бизнес-модулей. Циклических зависимостей нет.

#### 2.2.7 Информация {#227-information}

Модель данных — в разделе 5 (приложение А). Деньги хранятся в `NUMERIC(14,2)` (ADR-0003). Пароли хранятся в виде bcrypt-хэша.

#### 2.2.8 Интерфейс {#228-interface}

REST API в формате JSON, все изменяющие запросы требуют CSRF-токен. Список endpoint'ов — в приложении Б. Ошибки возвращаются в едином формате `{code, message, field}`.

#### 2.2.9 Взаимодействие {#229-interaction}

Создание долга: клиент отправляет `POST /api/debts` → сервис проверяет дружбу и данные → в одной транзакции сохраняет долг и письмо в outbox → возвращает `201`. Фоновый процесс отправляет письмо. Подробный сценарий — DES-004.

#### 2.2.10 Алгоритм {#2210-algorithm}

Баланс пользователя по валюте `c`: сумма остатков активных долгов, где пользователь кредитор, минус сумма остатков активных долгов, где он должник. Учитываются только статусы `ACTIVE`. Остаток долга = сумма − сумма погашений. Округление — `HALF_UP` до двух знаков. Подробно — DES-006.

#### 2.2.11 Динамика состояний {#2211-state-dynamics}

Состояния долга: `PENDING_CONFIRMATION` → `ACTIVE` (вторая сторона подтвердила) или `REJECTED` (отклонила). `ACTIVE` → `CLOSED`, когда остаток равен 0. Редактирование и удаление разрешены только в `PENDING_CONFIRMATION` и только автору (релиз 2, F-09). Погашение разрешено только в `ACTIVE`.

#### 2.2.12 Параллелизм {#2212-concurrency}

Два одновременных погашения одного долга не должны превысить остаток. Для этого у долга есть поле `version` (оптимистичная блокировка JPA). Второй запрос получает конфликт `409` и повторяется клиентом.

#### 2.2.13 Паттерны {#2213-patterns}

Layered architecture, Repository, DTO для API, Transactional Outbox для почты, Optimistic Locking для погашений.

#### 2.2.14 Развёртывание {#2214-deployment}

Один экземпляр `api` и одна БД. Миграции схемы — Flyway. Конфигурация через переменные окружения (`SPRING_DATASOURCE_URL`, `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD`, `SESSION_SECRET`).

#### 2.2.15 Ресурсы {#2215-resources}

Для учебной нагрузки достаточно одной виртуальной машины: 2 vCPU, 2 ГБ RAM, 10 ГБ диска. Для нагрузочного теста REQ-PERF-002 — отдельная машина для генератора нагрузки.

---

## 3. Проектные представления {#3-design-views}

- **ID**: DES-001-контекст
- **Title**: Контекст системы и внешние интерфейсы
- **Viewpoint**: Контекст (2.2.1)
- **Representation**: Пользователь → браузер (SPA) → REST API → PostgreSQL; REST API → SMTP.
- **More Information**: Требования REQ-NOT-001, REQ-NOT-002, REQ-SEC-002, REQ-PERF-001. Решения ADR-0001, ADR-0005.

- **ID**: DES-002-композиция
- **Title**: Пакеты и модули серверной части
- **Viewpoint**: Композиция (2.2.2), Логическое (2.2.3)
- **Representation**: Пакеты `ru.dolzhok.auth`, `.friends`, `.debt`, `.balance`, `.notification`, `.admin`, `.common`; в каждом пакете подпакеты `web`, `service`, `persistence`.
- **More Information**: Требования REQ-AUTH-001…003, REQ-FR-001…003, REQ-DEBT-001…008, REQ-PAY-001…003, REQ-BAL-001…003, REQ-NOT-001…002, REQ-ADM-001. Решение ADR-0001.

- **ID**: DES-003-безопасность
- **Title**: Аутентификация, сессии и разграничение доступа
- **Viewpoint**: Структура (2.2.5), Взаимодействие (2.2.9)
- **Representation**: Spring Security: фильтр сессии, cookie `HttpOnly; Secure; SameSite=Strict`; bcrypt с cost 12; счётчик неудачных попыток в `users.failed_attempts` и `users.locked_until`; проверка владельца в сервисе долгов (`debt.creditor_id = me OR debt.debtor_id = me`); блокировка администратором (`users.blocked`).
- **More Information**: Требования REQ-AUTH-001…003, REQ-SEC-001…005, REQ-ADM-001. Решение ADR-0004.

- **ID**: DES-004-уведомления
- **Title**: Отправка писем через outbox
- **Viewpoint**: Взаимодействие (2.2.9), Физическое (2.2.4)
- **Representation**: При создании долга, погашении и закрытии сервис записывает письмо в `outbox_messages` в той же транзакции. Планировщик каждые 30 секунд отправляет письма со статусом `NEW` или `RETRY`; после 5 неудачных попыток — статус `FAILED`, событие в журнал.
- **More Information**: Требования REQ-NOT-001, REQ-NOT-002, REQ-NOT-001, REQ-NOT-002. Решение ADR-0005.

- **ID**: DES-005-данные
- **Title**: Модель данных и оптимистичные блокировки
- **Viewpoint**: Информация (2.2.7), Параллелизм (2.2.12)
- **Representation**: Таблицы из приложения А. Поле `debts.version` для оптимистичной блокировки. Суммы — `NUMERIC(14,2)`, валюта — `CHAR(3)` с ограничением `IN ('BYN','USD','EUR','RUB')`.
- **More Information**: Требования REQ-DEBT-002, REQ-DEBT-003, REQ-PAY-002, REQ-QUAL-007. Решение ADR-0003.

- **ID**: DES-006-баланс
- **Title**: Расчёт баланса по валютам
- **Viewpoint**: Алгоритм (2.2.10)
- **Representation**: Запрос агрегирует остатки `ACTIVE`-долгов по ролям пользователя и валюте. Сумма округляется до двух знаков `HALF_UP`. Результат кешируется на время запроса, но не между запросами (для простоты и актуальности).
- **More Information**: Требования REQ-BAL-001, REQ-BAL-002 (баланс), REQ-PERF-001 (загрузка главной ≤ 2 с). Решение ADR-0003.

- **ID**: DES-007-интерфейс
- **Title**: Клиентская часть и экраны
- **Viewpoint**: Интерфейс (2.2.8), Физическое (2.2.4)
- **Representation**: SPA на React + Vite. Экраны: главная (`srs/sysml/dashboard.sysml`), добавление долга (`srs/sysml/add_debt.sysml`), вход и регистрация. Сборка через `vite build`; статика раздаётся nginx.
- **More Information**: Требования REQ-UI-001…005, REQ-SEC-002, REQ-QUAL-004. Решение ADR-0002.

- **ID**: DES-008-процесс
- **Title**: Итерационная реализация и контроль сроков
- **Viewpoint**: Развёртывание (2.2.14), Ресурсы (2.2.15)
- **Representation**: 6 итераций по 2 недели; распределение функций, оценки и стоимость — в `docs/plan/priorities-and-estimates.md` и `docs/plan/iterations.md`. Junior-разработчик работает с итерации 1 по итерацию 4.
- **More Information**: Ограничения 2.3 SRS; План реализации.

---

## 4. Решения {#4-decisions}

| ID | Название | Статус | Файл |
|----|----------|--------|------|
| ADR-0001 | Серверный фреймворк — Spring Boot 3 | принято | `adr/ADR-0001-server-framework.md` |
| ADR-0002 | Клиентская часть — React SPA на Vite | принято | `adr/ADR-0002-client-build-tool.md` |
| ADR-0003 | Хранение денежных сумм — NUMERIC(14,2) и BigDecimal | принято | `adr/ADR-0003-money-storage.md` |
| ADR-0004 | Аутентификация — серверные сессии с cookie | принято | `adr/ADR-0004-authentication.md` |
| ADR-0005 | Отправка почты — outbox в PostgreSQL | принято | `adr/ADR-0005-mail-delivery.md` |

---

## 5. Приложения {#5-appendixes}

### Приложение А. Модель данных (фрагмент DDL)

```sql
CREATE TABLE users (
  id              BIGSERIAL PRIMARY KEY,
  email           VARCHAR(254) NOT NULL UNIQUE,
  name            VARCHAR(100) NOT NULL,
  password_hash   VARCHAR(100) NOT NULL,
  blocked         BOOLEAN NOT NULL DEFAULT FALSE,
  failed_attempts INT NOT NULL DEFAULT 0,
  locked_until    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE friendships (
  id          BIGSERIAL PRIMARY KEY,
  user_a      BIGINT NOT NULL REFERENCES users(id),
  user_b      BIGINT NOT NULL REFERENCES users(id),
  status      VARCHAR(16) NOT NULL CHECK (status IN ('PENDING','ACCEPTED','REJECTED')),
  created_by  BIGINT NOT NULL REFERENCES users(id),
  UNIQUE (user_a, user_b)
);

CREATE TABLE debts (
  id            BIGSERIAL PRIMARY KEY,
  creditor_id   BIGINT NOT NULL REFERENCES users(id),
  debtor_id     BIGINT NOT NULL REFERENCES users(id),
  amount        NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  remaining     NUMERIC(14,2) NOT NULL CHECK (remaining >= 0),
  currency      CHAR(3) NOT NULL CHECK (currency IN ('BYN','USD','EUR','RUB')),
  debt_date     DATE NOT NULL,
  due_date      DATE,
  comment       VARCHAR(500),
  status        VARCHAR(24) NOT NULL CHECK (status IN ('PENDING_CONFIRMATION','ACTIVE','REJECTED','CLOSED')),
  version       BIGINT NOT NULL DEFAULT 0,
  created_by    BIGINT NOT NULL REFERENCES users(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (creditor_id <> debtor_id),
  CHECK (due_date IS NULL OR due_date >= debt_date)
);

CREATE TABLE repayments (
  id           BIGSERIAL PRIMARY KEY,
  debt_id      BIGINT NOT NULL REFERENCES debts(id),
  amount       NUMERIC(14,2) NOT NULL CHECK (amount > 0),
  paid_on      DATE NOT NULL,
  recorded_by  BIGINT NOT NULL REFERENCES users(id)
);

CREATE TABLE outbox_messages (
  id              BIGSERIAL PRIMARY KEY,
  recipient       VARCHAR(254) NOT NULL,
  subject         VARCHAR(200) NOT NULL,
  body            TEXT NOT NULL,
  status          VARCHAR(12) NOT NULL CHECK (status IN ('NEW','RETRY','SENT','FAILED')),
  attempts        INT NOT NULL DEFAULT 0,
  next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### Приложение Б. Список endpoint'ов REST API (фрагмент)

| Метод и путь | Назначение | Требования |
|--------------|------------|------------|
| POST /api/auth/register | Регистрация | REQ-AUTH-001 |
| POST /api/auth/login | Вход | REQ-AUTH-003, REQ-SEC-005 |
| POST /api/auth/logout | Выход | REQ-AUTH-003 |
| GET /api/me | Текущий пользователь | REQ-AUTH-003 |
| POST /api/friends/invitations | Приглашение в друзья | REQ-FR-001, REQ-FR-002 |
| POST /api/friends/invitations/{id}/accept | Принять приглашение | REQ-FR-001, REQ-FR-002 |
| GET /api/friends | Список друзей с балансом | REQ-FR-001, REQ-FR-002, REQ-BAL-001, REQ-BAL-002 |
| POST /api/debts | Создать долг | REQ-DEBT-001 |
| POST /api/debts/{id}/confirm | Подтвердить долг | REQ-DEBT-005 |
| POST /api/debts/{id}/reject | Отклонить долг | REQ-DEBT-005 |
| POST /api/debts/{id}/repayments | Зафиксировать погашение | REQ-PAY-001 |
| GET /api/debts?status=ACTIVE | Список активных долгов | REQ-DEBT-001 |
| GET /api/debts/history | История долгов | REQ-PAY-003, REQ-BAL-003 |
| GET /api/balance | Баланс по валютам | REQ-BAL-001, REQ-BAL-002 |
| POST /api/admin/users/{id}/block | Блокировка пользователя | REQ-ADM-001 |

### Приложение В. Модели интерфейса (SysMLv2)

- `srs/sysml/dashboard.sysml` — главная страница;
- `srs/sysml/add_debt.sysml` — добавление долга;
- `srs/images/dashboard.png`, `srs/images/add-debt.png` — рисунки моделей.
