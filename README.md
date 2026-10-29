# QRGate — контроль доступа по QR-пропускам

**Автор:** Гамза Григорий Александрович, группа 439401
**Дисциплина:** Жизненный цикл разработки программного обеспечения
**Учебное заведение:** БГУИР

## Описание проекта

QRGate — веб-система контроля доступа на объект. Контролёр сканирует QR-пропуск
камерой смартфона в мобильном веб-приложении, сервер проверяет пропуск
(подпись, срок действия, статус, anti-passback) и возвращает решение, а
администратор видит live-график заполняемости объекта.

Технологии: TypeScript, React (PWA), Node.js + Express, WebSocket, PostgreSQL, Chart.js.

## Структура репозитория

- `srs/` требования к ПО: шаблоны и спецификация [`srs/srs-qrgate.md`](srs/srs-qrgate.md)
- `srs/models/` модели SysML v2 (контекст, варианты использования, требования, макеты GUI)
- `srs/img/` изображения, построенные из моделей
- `sdd/` описание дизайна [`sdd/sdd-qrgate.md`](sdd/sdd-qrgate.md), модели SysML v2 архитектуры (`sdd/models`) и диаграммы (`sdd/img`)
- `docs/decisions/` протоколы архитектурных решений ADR-0001 – ADR-0008 (MADR)
- `docs/plan/` бэклог с приоритетами, планы реализации v1 – v3, переписка с заказчиком
- `tools/` вспомогательные скрипты: `sysml_render.py` (модели SRS → PNG), `sdd_render.py` (модели SDD → PNG), `plan_render.py` (бэклог → планы и диаграммы Ганта)
- `src/` исходный код
- `docs/` документация

## Сборка и запуск

Сейчас (ЛР 4) в репозитории есть требования ([`srs/srs-qrgate.md`](srs/srs-qrgate.md)),
архитектура ([`sdd/sdd-qrgate.md`](sdd/sdd-qrgate.md), [`docs/decisions`](docs/decisions))
и согласованный план реализации ([`docs/plan/plan-v3.md`](docs/plan/plan-v3.md)).
Код приложения появится в следующих лабораторных работах.

Перестроить изображения и планы (Python 3.10+):

```
pip install -r tools/requirements.txt
python tools/sysml_render.py
python tools/sdd_render.py
python tools/plan_render.py
```
