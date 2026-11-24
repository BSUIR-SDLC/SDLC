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
- `docs/decisions/` протоколы архитектурных решений ADR-0001 – ADR-0012 (MADR)
- `docs/glossary.md` глоссарий проекта, `docs/supplementary-specification.md` дополнительные спецификации (FURPS+, бизнес-правила)
- `uml/` модели UML в PlantUML (`uml/models`) и диаграммы (`uml/img`): динамическое поведение (ЛР 5, прецеденты [`uml/use-cases.md`](uml/use-cases.md)) и статическая структура (ЛР 6: `class-*`, `component-qrgate`, `deployment-qrgate`)
- `apps/`, `packages/` код итераций I1 – I2: `packages/qr-token` (подписанный QR), `packages/contracts` (общие типы API, номер пропуска), `apps/api` (политика входа и ролей, движок валидации `modules/validation`, управление пропусками `modules/passes`), `apps/scanner` (автомат состояний, карточка результата)
- `docs/plan/` бэклог с приоритетами, планы реализации v1 – v3, переписка с заказчиком
- `tools/` вспомогательные скрипты: `sysml_render.py` (модели SRS → PNG), `sdd_render.py` (модели SDD → PNG), `plan_render.py` (бэклог → планы и диаграммы Ганта)
- `src/` исходный код
- `docs/` документация

## Сборка и запуск

Сейчас (ЛР 6) в репозитории есть модели поведения и статической структуры на UML ([`uml/use-cases.md`](uml/use-cases.md), SDD 013–022), код итераций I1 – I2 с тестами (проектные диаграммы классов сверяются с кодом тестом, ADR-0011), требования ([`srs/srs-qrgate.md`](srs/srs-qrgate.md)),
архитектура ([`sdd/sdd-qrgate.md`](sdd/sdd-qrgate.md), [`docs/decisions`](docs/decisions))
и согласованный план реализации ([`docs/plan/plan-v3.md`](docs/plan/plan-v3.md)).
Тесты (Node.js 22.18+ / 24, без установки зависимостей):

```
npm test
npm run test:coverage
```

Перестроить изображения и планы (Python 3.10+):

```
pip install -r tools/requirements.txt
python tools/sysml_render.py
python tools/sdd_render.py
python tools/plan_render.py
python tools/uml_render.py      # UML: PLANTUML_JAR=plantuml.jar (Java) или сервер PlantUML
```
