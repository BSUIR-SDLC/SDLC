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
