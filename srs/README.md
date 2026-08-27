
# SRS Templates / Шаблоны SRS

> **Разработан на кафедре ЭВМ, БГУИР в учебных целях.**

Software Requirements Specification (SRS) — документ, определяющий **ЧТО** должна делать система.

## 📑 Выбор шаблона

| Шаблон | Когда использовать |
|--------|-------------------|
| `srs-template.md` | Основной шаблон для большинства проектов. Содержит подробные подсказки. |
| `srs-template-en.md` | Основной шаблон для большинства проектов на английском языке. |
| `req-template.md` | Для модульной структуры, когда каждое требование — отдельный файл. |
| `req-template-en.md` | Для модульной структуры, когда каждое требование — отдельный файл. На английском языке |

## 🎯 Соответствие стандартам

Шаблоны соответствуют:
- **ISO/IEC/IEEE 29148:2018** — Systems and software engineering — Life cycle processes — Requirements engineering
- **IEEE 830-1998** — Recommended Practice for Software Requirements Specifications (историческая основа)

## 📋 Рекомендуемые разделы

1. **Введение (Introduction)** — контекст, область применения, глоссарий
2. **Обзор продукта (Product Overview)** — перспективы продукта, функции, пользователи, ограничения, допущения
3. **Требования (Requirements)** — функциональные и нефункциональные требования
   - Внешние интерфейсы (External Interfaces): UI, Hardware, Software
   - Функциональные (Functional)
   - Качество обслуживания (Quality of Service): Performance, Security, Reliability, Availability, Observability
   - Соответствие стандартам (Compliance)
   - Проектирование и реализация (Design and Implementation)
   - ИИ/МО (AI/ML) — для систем с машинным обучением
4. **Верификация (Verification)** — матрица верификации требований
5. **Приложения (Appendixes)** — вспомогательные материалы

## 🏷 Идентификаторы требований

Используйте формат: `REQ-[AREA]-[NNN]-[VER]`, где 
- `AREA` — категория:
- `FUNC` — Functional
- `INT` — Interface
- `PERF` — Performance
- `SEC` — Security
- `REL` — Reliability
- `AVAIL` — Availability
- `OBS` — Observability
- `COMP` — Compliance
- `ML` — AI/ML
- и т. д.

Пример: `REQ-SEC-001` — первое требование по безопасности.

## 🔗 Связь с SDD и ADR

Каждый элемент дизайна в SDD (раздел 3) должен ссылаться на реализованное требование SRS. Каждое значимое решение (ADR) должно указывать, какие требования оно адресует.