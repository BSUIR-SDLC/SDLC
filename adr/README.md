# ADR Templates / Шаблоны ADR

Architecture Decision Record (ADR) — запись значимого архитектурного или проектного решения с обоснованием.

> **Разработан на кафедре ЭВМ, БГУИР в учебных целях.**

## 📑 Что такое MADR?

**MADR** (Markdown Architectural Decision Records) — легковесный Markdown-шаблон для документирования решений. Решения, которые **имеют значение** (matter).

> *«An Architectural Decision (AD) is a justified software design choice that addresses a functional or non-functional requirement of architectural significance.»*

## 📑 Выбор шаблона

| Шаблон | Когда использовать |
|--------|-------------------|
| `adr-template.md` | Полный шаблон с подсказками |
| `adr-template-en.md` | Полный шаблон с подсказками на английском языке |

## 📂 Именование файлов

Формат: `NNNN-title-with-dashes.md`

- `NNNN` — порядковый номер (0001–9999)
- `title-with-dashes` — суть решения в нижнем регистре через дефис

Примеры:
- `0001-use-postgresql-as-primary-db.md`
- `0002-choose-react-for-frontend.md`
- `0003-adopt-microservices-architecture.md`

## 📂 Структура каталога решений

```
docs/decisions/
├── 0001-use-postgresql-as-primary-db.md
├── 0002-choose-react-for-frontend.md
└── 0003-adopt-microservices-architecture.md
```

Для крупных проектов возможна категоризация:

```
docs/decisions/
├── backend/
│   └── 0001-use-quarkus.md
└── frontend/
    └── 0001-use-vuejs.md
```

## 🎯 Обязательные разделы ADR

1. **Context and Problem Statement** — контекст и постановка проблемы
2. **Considered Options** — рассмотренные альтернативы
3. **Decision Outcome** — выбранное решение с кратким обоснованием

## 🎯 Опциональные разделы

- **Decision Drivers** — драйверы решения
- **Consequences** — последствия (Good / Bad / Neutral)
- **Confirmation** — как будет проверяться соблюдение решения
- **Pros and Cons of the Options** — детальный разбор альтернатив
- **More Information** — ссылки, бенчмарки, связанные ADR

## 🔄 Жизненный цикл ADR

Статусы решения (в метаданных):
- `proposed` — предложено, обсуждается
- `accepted` — принято
- `rejected` — отклонено
- `deprecated` — устарело
- `superseded by ADR-NNNN` — заменено другим решением

## 🔗 Связь с SRS и SDD

В рамках данного процесса каждый ADR должен указывать:
- Какие требования SRS он адресует (через ID `REQ-XXX`)
- Какие элементы дизайна SDD затронуты (через ID в разделе 3 SDD)
