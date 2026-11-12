-- Схема БД итерации 1 (SDD DV-004). {ID} заменяется на тип первичного ключа диалекта.
CREATE TABLE IF NOT EXISTS halls (
    id {ID},
    name TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS seats (
    id {ID},
    hall_id INTEGER NOT NULL REFERENCES halls(id),
    row_label TEXT NOT NULL,
    number INTEGER NOT NULL,
    category TEXT NOT NULL,
    UNIQUE (hall_id, row_label, number)
);
CREATE TABLE IF NOT EXISTS events (
    id {ID},
    hall_id INTEGER NOT NULL REFERENCES halls(id),
    title TEXT NOT NULL,
    genre TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    venue TEXT NOT NULL,
    starts_at TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('draft', 'active', 'ended'))
);
CREATE INDEX IF NOT EXISTS idx_events_starts_at ON events (starts_at);
CREATE INDEX IF NOT EXISTS idx_events_genre ON events (genre);
CREATE TABLE IF NOT EXISTS event_prices (
    event_id INTEGER NOT NULL REFERENCES events(id),
    category TEXT NOT NULL,
    price_byn NUMERIC NOT NULL,
    PRIMARY KEY (event_id, category)
);
CREATE TABLE IF NOT EXISTS staff_users (
    id {ID},
    login TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'controller')),
    failed_attempts INTEGER NOT NULL DEFAULT 0,
    locked_until TEXT
);
