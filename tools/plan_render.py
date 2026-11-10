"""Расчёт итерационных планов QRGate по бэклогу docs/plan/plan.json.

Для каждой версии плана (v1, v2, v3a, v3) скрипт раскладывает функции по
исполнителям с учётом приоритетов и зависимостей, вычисляет даты, загрузку
итераций и стоимость, после чего формирует:
  * docs/plan/backlog.md        — бэклог с декомпозицией на задачи;
  * docs/plan/plan-<версия>.md   — план по итерациям;
  * docs/plan/img/plan-<версия>.png — диаграмма Ганта.

Использование:
    python tools/plan_render.py
"""
from __future__ import annotations

import copy
import datetime as dt
import json
import math
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
PLAN_DIR = ROOT / "docs" / "plan"
IMG = PLAN_DIR / "img"

PRIORITY_NAME = {10: "Critical", 20: "High", 30: "Medium", 40: "Low", 50: "Optional"}
PRIORITY_COLOR = {10: "#b91c1c", 20: "#ea580c", 30: "#2563eb", 40: "#0d9488", 50: "#6b7280"}
LANE_NAME = {"middle": "Middle", "junior": "Junior"}


# --------------------------------------------------------------------------- #
# Календарь: рабочие дни с понедельника по пятницу
# --------------------------------------------------------------------------- #
def workdays(start: dt.date, count: int) -> list[dt.date]:
    days, d = [], start
    while len(days) < count:
        if d.weekday() < 5:
            days.append(d)
        d += dt.timedelta(days=1)
    return days


def fmt(d: dt.date) -> str:
    return d.strftime("%d.%m.%Y")


# --------------------------------------------------------------------------- #
# Модель версии плана
# --------------------------------------------------------------------------- #
def features_for(data: dict, name: str) -> dict:
    """Функции с учётом переопределений версии и её базовой версии."""
    ver = data["versions"][name]
    feats = copy.deepcopy(data["features"])
    chain = []
    while ver:
        chain.append(ver)
        ver = data["versions"].get(ver.get("base", ""))
    for v in reversed(chain):
        for fid, ov in v["overrides"].items():
            feats[fid].update(ov)
    for f in feats.values():
        f["hours"] = sum(h for _, h in f["tasks"])
    return feats


def lane_capacity(data: dict, ver: dict) -> dict:
    """Производительные часы в день для каждого исполнителя по итерациям."""
    team, n = data["team"], data["iterations"]
    jun = team["junior"]
    has_junior = bool(ver["junior"])
    cap = {"middle": [], "junior": []}
    for it in range(1, n + 1):
        mid = team["middle"]["productive_hours_per_day"]
        if has_junior and it >= jun["join_iteration"]:
            mid -= jun["mentoring_hours_per_iteration"] / data["iteration_days"]
        cap["middle"].append(mid)
        if has_junior and it >= jun["join_iteration"]:
            cap["junior"].append(jun["paid_hours_per_day"] * jun["productivity_by_iteration"][str(it)])
        else:
            cap["junior"].append(0.0)
    return cap


def schedule(data: dict, name: str) -> dict:
    ver = data["versions"][name]
    feats = features_for(data, name)
    per_it = data["iteration_days"]
    cap = lane_capacity(data, ver)
    total_days = per_it * data["iterations"]

    def day_cap(lane, day):
        it = min(day // per_it, data["iterations"] - 1)
        return cap[lane][it]

    lanes = {"middle": 0.0, "junior": 0.0}  # позиция в днях (дробная часть — доля дня)
    end_pos, rows = {}, []
    queues = {lane: list(ver[lane]) for lane in ("middle", "junior")}
    # раскладываем функции по очереди, чтобы зависимости между исполнителями успели посчитаться
    while queues["middle"] or queues["junior"]:
        progressed = False
        for lane in ("middle", "junior"):
            if not queues[lane]:
                continue
            fid = queues[lane][0]
            if any(dep not in end_pos for dep in feats[fid]["depends"] if dep in ver["middle"] + ver["junior"]):
                continue
            queues[lane].pop(0)
            progressed = True
            f = feats[fid]
            start = max([lanes[lane]] + [end_pos[d] for d in f["depends"] if d in end_pos])
            pos, left = start, float(f["hours"])
            by_it: dict[int, float] = {}
            while left > 1e-9:
                day = int(pos)
                c = day_cap(lane, day)
                if c <= 0:
                    pos = day + 1
                    start = max(start, pos)
                    continue
                free = (day + 1 - pos) * c
                use = min(free, left)
                by_it[day // per_it + 1] = by_it.get(day // per_it + 1, 0) + use
                left -= use
                pos += use / c
            lanes[lane] = pos
            end_pos[fid] = pos
            rows.append({"id": fid, "lane": lane, "start": start, "end": pos, "by_it": by_it, **f})
        if not progressed:
            raise RuntimeError(f"{name}: циклические или пропущенные зависимости в {queues}")

    days = workdays(dt.date.fromisoformat(data["start"]), total_days + 40)
    deadline_day = days.index(dt.date.fromisoformat(data["deadline"])) + 1
    for r in rows:
        r["start_date"] = days[int(r["start"])]
        r["end_date"] = days[max(int(math.ceil(r["end"] - 1e-9)) - 1, 0)]
        r["late"] = r["end"] > deadline_day + 1e-9

    # стоимость: middle — оплачиваемые рабочие дни до окончания своих задач,
    # junior — полные итерации с момента подключения до конца проекта
    team = data["team"]
    mid_days = math.ceil(max(r["end"] for r in rows if r["lane"] == "middle") - 1e-9)
    cost = {"middle_hours": mid_days * team["middle"]["paid_hours_per_day"]}
    cost["middle_usd"] = cost["middle_hours"] * team["middle"]["rate_usd"]
    cost["junior_hours"] = 0
    if ver["junior"]:
        last_it = max(math.ceil(mid_days / per_it), max(math.ceil(r["end"] / per_it) for r in rows))
        its = last_it - team["junior"]["join_iteration"] + 1
        cost["junior_hours"] = its * per_it * team["junior"]["paid_hours_per_day"]
    cost["junior_usd"] = cost["junior_hours"] * team["junior"]["rate_usd"]
    cost["total_usd"] = cost["middle_usd"] + cost["junior_usd"]

    capacity4 = sum(sum(cap[l][:4]) * per_it for l in cap)
    return {
        "name": name, "title": ver["title"], "rows": rows, "feats": feats, "days": days,
        "deadline_day": deadline_day, "cap": cap, "cost": cost, "capacity4": capacity4,
        "hours": sum(r["hours"] for r in rows), "deferred": ver["deferred"], "has_junior": bool(ver["junior"]),
        "finish_date": max(r["end_date"] for r in rows),
    }


# --------------------------------------------------------------------------- #
# Вывод: Markdown и диаграмма Ганта
# --------------------------------------------------------------------------- #
def iteration_bounds(data: dict, days: list[dt.date]) -> list[tuple[int, dt.date, dt.date]]:
    n = data["iteration_days"]
    return [(i + 1, days[i * n], days[i * n + n - 1]) for i in range(data["iterations"])]


def write_backlog(data: dict, plans: dict) -> Path:
    feats = data["features"]
    lines = [
        "# Бэклог QRGate", "",
        "Сформирован скриптом `tools/plan_render.py` из [`plan.json`](plan.json). Приоритет: 10 — наивысший, 50 — минимальный.",
        "Оценки — производительные часы middle-разработчика; столбцы v1–v3 показывают приоритет функции в каждой версии плана",
        "(«—» — функция не входит в план версии, «R3» — перенесена в релиз 3).", "",
        "| Priority | Name |", "|---------:|------|",
    ]
    lines += [f"| {p} | {n} |" for p, n in PRIORITY_NAME.items()]
    lines += ["", "## Сводная таблица", "",
              "| ID | Feature | Описание | Часы | v1 | v2 | v3 | Зависит от | Требования SRS |",
              "|----|---------|----------|-----:|:--:|:--:|:--:|------------|----------------|"]

    def pri(plan, fid):
        if fid in plan["deferred"]:
            return "R3"
        return str(plan["feats"][fid]["priority"]) if any(r["id"] == fid for r in plan["rows"]) else "—"

    for fid in feats:
        f = plans["v3"]["feats"][fid] if fid in plans["v3"]["feats"] else feats[fid]
        hours = {v: plans[v]["feats"][fid]["hours"] for v in ("v1", "v2", "v3")}
        h = str(hours["v1"]) if len(set(hours.values())) == 1 else " → ".join(dict.fromkeys(str(x) for x in hours.values()))
        lines.append(f"| {fid} | {f['name']} | {f['ru']} | {h} | {pri(plans['v1'], fid)} | {pri(plans['v2'], fid)} | "
                     f"{pri(plans['v3'], fid)} | {', '.join(f['depends']) or '—'} | {', '.join(f['srs'])} |")
    lines += ["", "## Декомпозиция функций на задачи", ""]
    for fid in feats:
        f = plans["v3"]["feats"][fid]
        lines += [f"### {fid} {f['name']} — {f['ru']} (priority {f['priority']}, {f['hours']} ч)", "",
                  "| Задача | Часы |", "|--------|-----:|"]
        lines += [f"| {t} | {h} |" for t, h in f["tasks"]]
        if fid == "F11":
            v1 = plans["v1"]["feats"]["F11"]
            lines += ["", f"Первоначальная оценка (план v1) — {v1['hours']} ч:", "", "| Задача | Часы |", "|--------|-----:|"]
            lines += [f"| {t} | {h} |" for t, h in v1["tasks"]]
        lines.append("")
    path = PLAN_DIR / "backlog.md"
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def write_plan(data: dict, p: dict) -> Path:
    bounds = iteration_bounds(data, p["days"])
    c = p["cost"]
    late = [r for r in p["rows"] if r["late"]]
    lines = [
        f"# План реализации QRGate — версия {p['name']}", "",
        f"{p['title']}. Сформирован скриптом `tools/plan_render.py`.", "",
        "## Исходные данные", "",
        f"- Начало разработки: {fmt(p['days'][0])}; длина итерации — 2 недели (10 рабочих дней); срок сдачи: {fmt(dt.date.fromisoformat(data['deadline']))}.",
        f"- Middle-разработчик: 8 оплачиваемых часов в день, из них 7,2 ч на задачи (10 % — встречи, демонстрации, ревью).",
    ]
    if p["has_junior"]:
        j = data["team"]["junior"]
        lines.append(f"- Junior-разработчик: с итерации {j['join_iteration']}, 4 ч в день; производительность 50 % в первой итерации, "
                     f"затем 70 %; middle тратит на наставничество и ревью {j['mentoring_hours_per_iteration']} ч за итерацию.")
    lines += [
        f"- Объём плана: **{p['hours']} ч**; ёмкость четырёх итераций: **{p['capacity4']:.0f} ч**.",
        f"- Окончание работ по плану: **{fmt(p['finish_date'])}**" + (" — **позже срока сдачи**." if late else " — в срок."), "",
        "## Итерации", "",
        "| Итерация | Даты | Ёмкость, ч | Запланировано, ч | Функции |", "|----------|------|-----------:|-----------------:|---------|",
    ]
    for it, d0, d1 in bounds:
        capi = sum(p["cap"][l][it - 1] for l in p["cap"]) * data["iteration_days"]
        items = [(r["id"], r["by_it"][it]) for r in p["rows"] if it in r["by_it"]]
        if not items:
            continue
        load = sum(h for _, h in items)
        lines.append(f"| I{it} | {fmt(d0)} – {fmt(d1)} | {capi:.0f} | {load:.0f} | "
                     + ", ".join(f"{fid} ({h:.0f})" for fid, h in items) + " |")
    lines += ["", "## Функции", "",
              "| ID | Feature | Priority | Часы | Исполнитель | Начало | Окончание | Итерации |",
              "|----|---------|---------:|-----:|-------------|--------|-----------|----------|"]
    for r in sorted(p["rows"], key=lambda r: (r["start"], r["lane"])):
        mark = " ⚠" if r["late"] else ""
        lines.append(f"| {r['id']} | {r['name']} | {r['priority']} | {r['hours']} | {LANE_NAME[r['lane']]} | "
                     f"{fmt(r['start_date'])} | {fmt(r['end_date'])}{mark} | {', '.join(f'I{i}' for i in sorted(r['by_it']))} |")
    if p["deferred"]:
        lines += ["", "Перенесены в релиз 3 (вне плана): " + ", ".join(f"{fid} {p['feats'][fid]['name']}" for fid in p["deferred"]) + "."]
    if late:
        lines += ["", "⚠ Не укладываются в срок: " + ", ".join(f"{r['id']} {r['name']}" for r in late) + "."]
    lines += ["", "## Стоимость", "", "| Исполнитель | Ставка, USD/ч | Оплачиваемые часы | Сумма, USD |", "|---|---:|---:|---:|",
              f"| Middle | {data['team']['middle']['rate_usd']} | {c['middle_hours']} | {c['middle_usd']} |"]
    if p["has_junior"]:
        lines.append(f"| Junior | {data['team']['junior']['rate_usd']} | {c['junior_hours']} | {c['junior_usd']} |")
    lines += [f"| **Итого** | | | **{c['total_usd']}** |", "",
              f"![Диаграмма Ганта](img/plan-{p['name']}.png)", ""]
    path = PLAN_DIR / f"plan-{p['name']}.md"
    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def draw_gantt(data: dict, p: dict) -> Path:
    rows = sorted(p["rows"], key=lambda r: (r["lane"] != "middle", r["start"]))
    n_it = max(4, max(math.ceil(r["end"] / data["iteration_days"]) for r in rows))
    fig, ax = plt.subplots(figsize=(13, 0.36 * len(rows) + 1.9), dpi=130)
    for i, r in enumerate(rows):
        ax.barh(i, r["end"] - r["start"], left=r["start"], height=0.62, color=PRIORITY_COLOR[r["priority"]],
                edgecolor="#7f1d1d" if r["late"] else "white", linewidth=1.6 if r["late"] else 0.6)
        ax.text(r["end"] + 0.2, i, f"{r['hours']} ч", va="center", fontsize=8, color="#374151")
    ax.set_yticks(range(len(rows)))
    ax.set_yticklabels([f"{r['id']} {r['name']}" + (" (J)" if r["lane"] == "junior" else "") for r in rows], fontsize=8.5)
    ax.invert_yaxis()
    per = data["iteration_days"]
    for it in range(n_it + 1):
        ax.axvline(it * per, color="#9ca3af", linewidth=0.8, linestyle="--")
    for it, d0, d1 in iteration_bounds(data, p["days"])[:n_it]:
        ax.text((it - 0.5) * per, -1.1, f"I{it}\n{d0:%d.%m}–{d1:%d.%m}", ha="center", va="bottom", fontsize=8.5)
    ax.axvline(p["deadline_day"], color="#dc2626", linewidth=2)
    ax.text(p["deadline_day"] + 0.2, len(rows) - 0.4, f"срок {fmt(dt.date.fromisoformat(data['deadline']))}",
            color="#dc2626", fontsize=8.5, va="bottom")
    if p["has_junior"]:
        k = sum(r["lane"] == "middle" for r in rows)
        ax.axhline(k - 0.5, color="#111827", linewidth=1)
    ax.set_xlim(0, n_it * per + 3)
    ax.set_ylim(len(rows) - 0.4, -1.6)
    ax.set_xlabel("рабочие дни от начала разработки", fontsize=9)
    handles = [plt.Rectangle((0, 0), 1, 1, color=PRIORITY_COLOR[k]) for k in PRIORITY_NAME]
    ax.legend(handles, [f"{k} {v}" for k, v in PRIORITY_NAME.items()], loc="lower right", fontsize=8, ncol=5, frameon=False,
              bbox_to_anchor=(1, 1.06))
    ax.set_title(f"План {p['name']}: {p['hours']} ч, окончание {fmt(p['finish_date'])}, {p['cost']['total_usd']} USD",
                 fontsize=11, loc="left", pad=30)
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    path = IMG / f"plan-{p['name']}.png"
    fig.savefig(path)
    plt.close(fig)
    return path


def main():
    data = json.loads((PLAN_DIR / "plan.json").read_text(encoding="utf-8"))
    IMG.mkdir(parents=True, exist_ok=True)
    plans = {name: schedule(data, name) for name in data["versions"]}
    outputs = [write_backlog(data, plans)]
    for p in plans.values():
        outputs += [write_plan(data, p), draw_gantt(data, p)]
        c = p["cost"]
        print(f"{p['name']}: {p['hours']} ч, ёмкость {p['capacity4']:.0f} ч, окончание {fmt(p['finish_date'])}, "
              f"{c['total_usd']} USD (middle {c['middle_hours']} ч, junior {c['junior_hours']} ч)")
    for f in outputs:
        print(f.relative_to(ROOT))


if __name__ == "__main__":
    main()
