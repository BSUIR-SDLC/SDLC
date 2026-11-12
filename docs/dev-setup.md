# Запуск и разработка EasyTicket (итерация 1)

Реализовано по плану (`sdd/plan.md`, итерация 1): каркас приложения (БД, Docker Compose, CI), каталог мероприятий (REQ-FUNC-001), страница мероприятия (REQ-FUNC-002), вход сотрудников (REQ-FUNC-011).

## Структура

```
src/easyticket/
  config.py      настройки из переменных окружения
  db.py          доступ к БД (SQLite для тестов, PostgreSQL в Docker)
  schema.sql     схема БД (SDD DV-004)
  catalog.py     афиша и карточка мероприятия
  auth.py        вход сотрудников: scrypt, токены HMAC, блокировка после 5 неудач на 15 минут
  web.py         HTML-страницы (Jinja2, автоэкранирование)
  main.py        FastAPI-приложение и REST API
  seed.py        демонстрационные данные
tests/           модульные тесты (unittest)
```

## Тесты

```bash
pip install jinja2
PYTHONPATH=src python -m unittest discover -s tests -t . -v
```

Тесты используют SQLite в памяти, FastAPI для них не нужен.

## Запуск в Docker

```bash
export SECRET_KEY="длинная-случайная-строка"
export ADMIN_PASSWORD="пароль-администратора-не-короче-8-символов"
docker compose up --build
```

- сайт: http://localhost:8000 (афиша), Swagger UI: http://localhost:8000/docs;
- просмотр писем mock SMTP (MailHog): http://localhost:8025.

## REST API (версия 1)

| Метод | Путь | Назначение |
|-------|------|------------|
| GET | `/api/events` | афиша: `date_from`, `date_to`, `genre`, `price_min`, `price_max`, `page`, `page_size` |
| GET | `/api/events/{id}` | карточка мероприятия |
| POST | `/api/admin/login` | вход сотрудника: `{"login": "...", "password": "..."}` → токен и роль |
| GET | `/api/admin/me` | проверка токена (заголовок `Authorization: Bearer ...`) |
| GET | `/healthz` | проверка работоспособности |
