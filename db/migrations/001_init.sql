-- Начальная миграция схемы БД PostgreSQL 16 (F01, SDD 004-information, data.sysml)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  login TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('ADMIN', 'OPERATOR', 'VIEWER')),
  failed_attempts INTEGER NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ
);

CREATE TABLE sources (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  secret_ref TEXT NOT NULL,
  prev_secret_ref TEXT,
  secret_rotated_at TIMESTAMPTZ,
  allowed_types TEXT[] NOT NULL DEFAULT ARRAY['*'],
  rate_limit_rps INTEGER NOT NULL DEFAULT 50,
  enabled BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE targets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  kind TEXT NOT NULL CHECK (kind IN ('EMULATOR', 'NOTIFIER')),
  base_url TEXT NOT NULL,
  auth_ref TEXT,
  timeout_ms INTEGER NOT NULL DEFAULT 5000,
  enabled BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE rules (
  id TEXT PRIMARY KEY,
  source_id TEXT NOT NULL REFERENCES sources(id),
  event_type TEXT NOT NULL,
  priority INTEGER NOT NULL DEFAULT 100,
  enabled BOOLEAN NOT NULL DEFAULT FALSE,
  version INTEGER NOT NULL DEFAULT 1,
  definition JSONB NOT NULL,
  cooldown_s INTEGER NOT NULL DEFAULT 0,
  disabled_reason TEXT
);

CREATE TABLE rule_versions (
  rule_id TEXT NOT NULL REFERENCES rules(id),
  version INTEGER NOT NULL,
  definition JSONB NOT NULL,
  author_id UUID NOT NULL REFERENCES users(id),
  ts TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (rule_id, version)
);

CREATE TABLE events (
  id BIGSERIAL PRIMARY KEY,
  source_id TEXT NOT NULL REFERENCES sources(id),
  external_id TEXT NOT NULL,
  type TEXT NOT NULL,
  payload JSONB NOT NULL,
  hop INTEGER NOT NULL DEFAULT 0,
  received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (source_id, external_id)
);

CREATE TABLE rule_matches (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES events(id),
  rule_id TEXT NOT NULL REFERENCES rules(id),
  rule_version INTEGER NOT NULL,
  explain JSONB NOT NULL
);

CREATE TABLE deliveries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id BIGINT NOT NULL REFERENCES rule_matches(id),
  target_id UUID NOT NULL REFERENCES targets(id),
  status TEXT NOT NULL CHECK (status IN (
    'QUEUED', 'SENDING', 'RETRY_WAIT', 'PAUSED',
    'DELIVERED', 'SKIPPED', 'FAILED', 'CANCELLED', 'PURGED'
  )),
  attempts INTEGER NOT NULL DEFAULT 0,
  next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  response_code INTEGER,
  request_body JSONB NOT NULL
);

CREATE INDEX idx_deliveries_due
  ON deliveries (next_attempt_at)
  WHERE status IN ('QUEUED', 'RETRY_WAIT');

CREATE TABLE replays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES users(id),
  filter JSONB NOT NULL,
  count INTEGER NOT NULL,
  ts TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE dead_letters (
  delivery_id UUID PRIMARY KEY REFERENCES deliveries(id),
  reason TEXT NOT NULL,
  failed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  replay_id UUID REFERENCES replays(id)
);

CREATE TABLE loop_trips (
  id BIGSERIAL PRIMARY KEY,
  rule_id TEXT NOT NULL REFERENCES rules(id),
  kind TEXT NOT NULL CHECK (kind IN ('HOP', 'COOLDOWN', 'BREAKER')),
  ts TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE system_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
