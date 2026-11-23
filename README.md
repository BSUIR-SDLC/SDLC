# RuleHook – лабораторная работа №4 (вариант 9)

Движок правил: backend принимает вебхуки от эмулятора, проверяет их по сохранённым JSON-правилам и при совпадении отправляет POST-запрос обратно на эмулятор или в систему уведомлений.

- `srs/` – спецификация требований (SRS 0.3)
- `sdd/` – описание проектирования, модели SysML v2 (`sdd/models`), диаграммы (`sdd/img`)
- `docs/decisions/` – протоколы архитектурных решений ADR-0001 – 0008
- `docs/plan/` – бэклог, планы v1, v2, v3a, v3b, v3, диаграммы Ганта, переписка с Заказчиком
- `tools/` – скрипты построения диаграмм и планов

Команды (нужны Python 3, `pip install -r tools/requirements.txt` и Graphviz, `dot` в PATH):

    python tools/sdd_render.py          # диаграммы SDD из моделей SysML v2
    python tools/plan_render.py         # бэклог, планы и диаграммы Ганта из docs/plan/plan.json
    python tools/plan_render.py --check # сверка бэклога с требованиями SRS
## Лабораторная работа №5 – модели поведения UML

| Каталог | Содержимое |
|---|---|
| docs/glossary.md | Глоссарий (51 термин) |
| docs/supplementary-specification.md | Дополнительные спецификации FURPS+, бизнес-правила BR-01 – BR-12 |
| uml/use-cases.md | Актёры и спецификации 14 прецедентов |
| uml/models/*.puml | 7 моделей PlantUML |
| uml/img/*.png | Изображения диаграмм |
| docs/decisions/0009, 0010 | Новые ADR |
| packages/webhook-signature, apps/api | Код итерации I1 и тесты |

Запуск тестов (Node.js 24, без установки зависимостей):

    npm test
    npm run test:coverage

Построение диаграмм:

    PLANTUML_JAR=plantuml.jar python tools/uml_render.py
    python tools/uml_render.py --check
