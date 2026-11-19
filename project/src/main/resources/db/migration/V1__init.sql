-- SubScope: начальная схема базы данных (SDD 0.4, 004-information; ADR-0003).
-- Денежные суммы — numeric(12,2), курсы — numeric(14,4); даты — по часовому поясу Europe/Minsk.

CREATE TABLE app_user (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email             varchar(254) NOT NULL UNIQUE,
    password_hash     varchar(60)  NOT NULL,
    role              varchar(10)  NOT NULL DEFAULT 'USER'   CHECK (role IN ('USER', 'ADMIN')),
    status            varchar(10)  NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'BLOCKED')),
    base_currency     char(3)      NOT NULL DEFAULT 'BYN'    CHECK (base_currency IN ('BYN', 'USD', 'EUR')),
    unused_threshold  smallint     NOT NULL DEFAULT 2        CHECK (unused_threshold IN (1, 2, 3)),
    reminder_days     smallint     NOT NULL DEFAULT 3        CHECK (reminder_days IN (1, 3, 7)),
    remind_charges    boolean      NOT NULL DEFAULT true,
    remind_trials     boolean      NOT NULL DEFAULT true,
    channel           varchar(10)  NOT NULL DEFAULT 'EMAIL'  CHECK (channel IN ('EMAIL', 'TELEGRAM')),
    telegram_chat_id  bigint       UNIQUE,
    monthly_limit     numeric(12,2) CHECK (monthly_limit >= 0),
    failed_logins     smallint     NOT NULL DEFAULT 0,
    locked_until      timestamptz,
    consent_at        timestamptz  NOT NULL,
    created_at        timestamptz  NOT NULL DEFAULT now(),
    CHECK (channel = 'EMAIL' OR telegram_chat_id IS NOT NULL)
);

CREATE TABLE one_time_token (
    token_hash  varchar(64) PRIMARY KEY,
    user_id     bigint      NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    purpose     varchar(20) NOT NULL CHECK (purpose IN ('PASSWORD_RESET', 'TELEGRAM_LINK')),
    expires_at  timestamptz NOT NULL,
    used_at     timestamptz
);

CREATE TABLE category (
    id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  varchar(50) NOT NULL UNIQUE
);

CREATE TABLE catalog_service (
    id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         varchar(100) NOT NULL UNIQUE,
    category_id  bigint       NOT NULL REFERENCES category (id)
);

CREATE TABLE subscription (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id           bigint        NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    name              varchar(100)  NOT NULL CHECK (length(name) >= 1),
    category_id       bigint        REFERENCES category (id) ON DELETE SET NULL,
    price             numeric(12,2) NOT NULL CHECK (price >= 0),
    currency          char(3)       NOT NULL,
    period            varchar(10)   NOT NULL CHECK (period IN ('WEEK', 'MONTH', 'QUARTER', 'YEAR')),
    next_charge_date  date          NOT NULL,
    charge_day        smallint      NOT NULL CHECK (charge_day BETWEEN 1 AND 31),
    trial_end_date    date,
    participants      smallint      NOT NULL DEFAULT 1 CHECK (participants BETWEEN 1 AND 10),
    reminder_days     smallint      CHECK (reminder_days IN (1, 3, 7)),
    status            varchar(10)   NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'PAUSED', 'CANCELLED')),
    note              varchar(500),
    created_at        timestamptz   NOT NULL DEFAULT now(),
    CHECK (trial_end_date IS NULL OR trial_end_date <= next_charge_date)
);
CREATE INDEX subscription_user_idx ON subscription (user_id);
CREATE INDEX subscription_due_idx ON subscription (next_charge_date) WHERE status = 'ACTIVE';

-- Прошедшие списания для аналитики (SDD 0.4; UC-12, UC-22)
CREATE TABLE charge (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    subscription_id  bigint        NOT NULL REFERENCES subscription (id) ON DELETE CASCADE,
    charge_date      date          NOT NULL,
    amount           numeric(12,2) NOT NULL CHECK (amount >= 0),
    currency         char(3)       NOT NULL,
    category_id      bigint        REFERENCES category (id) ON DELETE SET NULL,
    UNIQUE (subscription_id, charge_date)
);
CREATE INDEX charge_date_idx ON charge (charge_date);

CREATE TABLE usage_mark (
    subscription_id  bigint      NOT NULL REFERENCES subscription (id) ON DELETE CASCADE,
    month            date        NOT NULL CHECK (extract(day FROM month) = 1),
    used             boolean     NOT NULL,
    marked_at        timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (subscription_id, month)
);

-- Журнал уведомлений: запись до отправки, уникальный ключ исключает дубли (ADR-0005, sm-3-notification)
CREATE TABLE notification_log (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id          bigint      NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    subscription_id  bigint      REFERENCES subscription (id) ON DELETE CASCADE,
    kind             varchar(10) NOT NULL CHECK (kind IN ('CHARGE', 'TRIAL_END', 'LIMIT')),
    due_date         date        NOT NULL,
    channel          varchar(10) NOT NULL CHECK (channel IN ('EMAIL', 'TELEGRAM')),
    status           varchar(12) NOT NULL DEFAULT 'PENDING'
                     CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'UNDELIVERED')),
    attempts         smallint    NOT NULL DEFAULT 0 CHECK (attempts BETWEEN 0 AND 3),
    created_at       timestamptz NOT NULL DEFAULT now(),
    updated_at       timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT notification_once UNIQUE NULLS NOT DISTINCT (user_id, subscription_id, kind, due_date, channel)
);
CREATE INDEX notification_retry_idx ON notification_log (updated_at) WHERE status = 'FAILED';

-- Курсы НБ РБ (ADR-0004): стоимость единицы валюты = official_rate / scale
CREATE TABLE exchange_rate (
    currency       char(3)       NOT NULL,
    rate_date      date          NOT NULL,
    scale          integer       NOT NULL CHECK (scale > 0),
    official_rate  numeric(14,4) NOT NULL CHECK (official_rate > 0),
    loaded_at      timestamptz   NOT NULL DEFAULT now(),
    PRIMARY KEY (currency, rate_date)
);
