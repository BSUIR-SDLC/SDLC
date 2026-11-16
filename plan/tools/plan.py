"""Строит plan/plan.md и диаграммы plan/images/plan-v*.png из plan_data.py.

Запуск из корня репозитория: python plan/tools/plan.py
Требуется matplotlib.
"""
import os
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle

sys.path.insert(0, os.path.dirname(__file__))
from plan_data import *  # noqa: E402,F401

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
IMG = os.path.join(ROOT, "plan", "images")
FEAT = {f[0]: f for f in FEATURES}
VERSIONS = ("v1", "v2", "v3")
PRIO_COLOR = {10: "#2f6db3", 20: "#4f9a5c", 30: "#d08c2c", 40: "#9a6fb0", 50: "#9a9a9a"}


def num(x):
    """Число в формате с запятой: 52.5 -> 52,5; 38.0 -> 38."""
    if abs(x - round(x)) < 1e-9:
        return str(int(round(x)))
    return ("%.1f" % x).replace(".", ",")


def money(x):
    return "{:,}".format(int(round(x))).replace(",", " ")


def tasks(v):
    """Задачи версии v (0, 1, 2): (id, feature, title, est, iteration, who, hours)."""
    out = []
    for tid, fid, title, est, it, who in TASKS:
        e, i = est[v], it[v]
        if e is None:
            continue
        w = who if v == 2 else "M"
        h = e * JUNIOR_FACTOR if w == "J" else e
        out.append((tid, fid, title, e, i, w, h))
    return out


def iterations(v):
    return sorted({t[4] for t in tasks(v)})


def capacity(i):
    days = ITERATIONS[i][2]
    return days * HOURS_PER_DAY - OVERHEAD


def load(v):
    """Загрузка по итерациям: {(итерация, исполнитель): часы}."""
    res = {}
    for t in tasks(v):
        res[(t[4], t[5])] = res.get((t[4], t[5]), 0) + t[6]
    if v == 2:
        for i in JUNIOR_ITERATIONS:
            res[(i, "M")] = res.get((i, "M"), 0) + MENTORING
            res[(i, "J")] = res.get((i, "J"), 0) + (JUNIOR_ONBOARDING if i == JUNIOR_ITERATIONS[0] else 0)
    return res


def check(v):
    ld = load(v)
    for (i, w), h in ld.items():
        cap = capacity(i) if w == "M" else JUNIOR_HOURS
        assert h <= cap + 1e-9, (v, i, w, h, cap)
    # зависимости: задачи функции не раньше итерации, в которой начаты задачи функций-зависимостей
    first = {}
    for t in tasks(v):
        first[t[1]] = min(first.get(t[1], 99), t[4])
    last = {}
    for t in tasks(v):
        last[t[1]] = max(last.get(t[1], 0), t[4])
    for fid, f in FEAT.items():
        if fid not in first or f[4] in ("—", "все"):
            continue
        for dep in f[4].split(", "):
            if dep in first:
                assert first[fid] >= first[dep], (v, fid, dep)


def cost(v):
    its = iterations(v)
    middle_hours = sum(ITERATIONS[i][2] * HOURS_PER_DAY for i in its)
    junior_hours = JUNIOR_HOURS * len(JUNIOR_ITERATIONS) if v == 2 else 0
    return middle_hours, junior_hours, middle_hours * MIDDLE_RATE + junior_hours * JUNIOR_RATE


def feature_hours(v):
    res = {}
    for t in tasks(v):
        res[t[1]] = res.get(t[1], 0) + t[3]
    return res


def gantt(v, path, title):
    its = iterations(v)
    feats = [f for f in FEATURES if f[0] in feature_hours(v)]
    cell = {}
    for t in tasks(v):
        key = (t[1], t[4])
        m, j = cell.get(key, (0, 0))
        if t[5] == "J":
            j += t[6]
        else:
            m += t[6]
        cell[key] = (m, j)
    n = len(feats)
    fig, ax = plt.subplots(figsize=(11, 0.42 * (n + 3) + 0.6), dpi=150)
    for r, f in enumerate(feats):
        y = n - r
        prio = f[5][v]
        for c, i in enumerate(its):
            if (f[0], i) not in cell:
                continue
            m, j = cell[(f[0], i)]
            color = PRIO_COLOR[prio]
            if m and j:
                ax.add_patch(Rectangle((c + 0.04, y - 0.38), 0.92, 0.38, color=color))
                ax.add_patch(Rectangle((c + 0.04, y - 0.0), 0.92, 0.36, facecolor="white", edgecolor=color, hatch="///", lw=1))
                ax.text(c + 0.5, y - 0.19, "M " + num(m) + " ч", ha="center", va="center", color="white", fontsize=8)
                ax.text(c + 0.5, y + 0.18, "J " + num(j) + " ч", ha="center", va="center", color="black", fontsize=8,
                        bbox=dict(facecolor="white", edgecolor="none", pad=0.3))
            elif j:
                ax.add_patch(Rectangle((c + 0.04, y - 0.36), 0.92, 0.72, facecolor="white", edgecolor=color, hatch="///", lw=1.2))
                ax.text(c + 0.5, y, "J " + num(j) + " ч", ha="center", va="center", color="black", fontsize=8,
                        bbox=dict(facecolor="white", edgecolor="none", pad=0.5))
            else:
                ax.add_patch(Rectangle((c + 0.04, y - 0.36), 0.92, 0.72, color=color))
                ax.text(c + 0.5, y, num(m) + " ч", ha="center", va="center", color="white", fontsize=8)
    ld = load(v)
    for c, i in enumerate(its):
        txt = "M %s/%s" % (num(ld.get((i, "M"), 0)), capacity(i))
        if v == 2 and i in JUNIOR_ITERATIONS:
            txt += "\nJ %s/%s" % (num(ld.get((i, "J"), 0)), JUNIOR_HOURS)
        ax.text(c + 0.5, 0.05, txt, ha="center", va="center", fontsize=8)
    ax.set_xlim(0, len(its))
    ax.set_ylim(-0.6, n + 0.6)
    ax.set_xticks([c + 0.5 for c in range(len(its))])
    ax.set_xticklabels(["Итерация %d\n%s–%s" % (i, ITERATIONS[i][0][:5], ITERATIONS[i][1][:5]) for i in its], fontsize=8)
    ax.xaxis.tick_top()
    ax.set_yticks([n - r for r in range(n)] + [0.05])
    ax.set_yticklabels(["%s %s (%s)" % (f[0], f[1], f[5][v]) for f in feats] + ["Загрузка, ч"], fontsize=8)
    for c in range(len(its) + 1):
        ax.axvline(c, color="#cccccc", lw=0.6)
    ax.axhline(0.5, color="#888888", lw=0.6)
    if v == 0:
        ax.axvline(5, color="#c0392b", lw=2)
        ax.text(5.03, n + 0.35, "срок 25.12", color="#c0392b", fontsize=8, va="center")
    for s in ax.spines.values():
        s.set_visible(False)
    ax.tick_params(length=0)
    handles = [Rectangle((0, 0), 1, 1, color=PRIO_COLOR[p]) for p in (10, 20, 30, 40)]
    labels = ["приоритет 10", "20", "30", "40"]
    if v == 2:
        handles.append(Rectangle((0, 0), 1, 1, facecolor="white", edgecolor="#555555", hatch="///"))
        labels.append("junior (J), ч с учётом ×1,5")
    ax.legend(handles, labels, loc="upper center", bbox_to_anchor=(0.5, -0.02), ncol=len(labels), fontsize=8, frameon=False)
    ax.set_title(title, fontsize=10, pad=30)
    fig.tight_layout()
    fig.savefig(path)
    plt.close(fig)


def iteration_table(v):
    rows = ["| Итерация | Даты | Задачи | Часы |", "|----------|------|--------|------|"]
    ld = load(v)
    for i in iterations(v):
        a, b, _ = ITERATIONS[i]
        ts = [t for t in tasks(v) if t[4] == i]
        mid = ", ".join(t[0] for t in ts if t[5] == "M")
        hours = "%s из %s" % (num(ld.get((i, "M"), 0)), capacity(i))
        if v == 2 and i in JUNIOR_ITERATIONS:
            jun = ", ".join(t[0] for t in ts if t[5] == "J")
            extra = ["наставничество %d ч" % MENTORING]
            mid = mid + "; " + ", ".join(extra)
            jextra = "знакомство с проектом %d ч; " % JUNIOR_ONBOARDING if i == JUNIOR_ITERATIONS[0] else ""
            mid = "middle: " + mid + "<br>junior: " + jextra + jun
            hours = "M: %s из %s<br>J: %s из %s" % (num(ld.get((i, "M"), 0)), capacity(i),
                                                   num(ld.get((i, "J"), 0)), JUNIOR_HOURS)
        rows.append("| %d | %s–%s | %s | %s |" % (i, a[:5], b, mid, hours))
    return "\n".join(rows)


def feature_table(v, with_change=None):
    fh = feature_hours(v)
    first, last = {}, {}
    for t in tasks(v):
        first[t[1]] = min(first.get(t[1], 99), t[4])
        last[t[1]] = max(last.get(t[1], 0), t[4])
    head = "| ID | Function | Функция | Приоритет | Требования SRS | Зависит от | Оценка, ч | Итерации |"
    rows = [head, "|----|----------|---------|-----------|----------------|------------|-----------|----------|"]
    for f in FEATURES:
        p = f[5][v]
        if f[0] not in fh:
            if p is None and (v == 0 or FEAT[f[0]][5][v - 1] is None):
                continue
            rows.append("| %s | %s | %s | %s | %s | %s | — | вне релиза 1.0 |" % (
                f[0], f[1], f[2], p if p else "—", f[3], f[4]))
            continue
        its = "%d" % first[f[0]] if first[f[0]] == last[f[0]] else "%d–%d" % (first[f[0]], last[f[0]])
        prio = str(p)
        if v > 0 and FEAT[f[0]][5][v - 1] not in (None, p):
            prio = "%s (было %s)" % (p, FEAT[f[0]][5][v - 1])
        rows.append("| %s | %s | %s | %s | %s | %s | %s | %s |" % (
            f[0], f[1], f[2], prio, f[3], f[4], num(fh[f[0]]), its))
    rows.append("| | **Итого** | | | | | **%s** | |" % num(sum(fh.values())))
    return "\n".join(rows)


def task_table():
    rows = ["| Задача | Функция | Содержание | v1, ч | v2, ч | v3, ч | Исполнитель v3 |",
            "|--------|---------|------------|-------|-------|-------|----------------|"]
    for tid, fid, title, est, it, who in TASKS:
        e = ["—" if x is None else num(x) for x in est]
        w = "—" if est[2] is None else ("junior" if who == "J" else "middle")
        rows.append("| %s | %s | %s | %s | %s | %s | %s |" % (tid, fid, title, e[0], e[1], e[2], w))
    tot = [num(sum(t[3] for t in tasks(v))) for v in range(3)]
    rows.append("| | | **Итого** | **%s** | **%s** | **%s** | |" % tuple(tot))
    return "\n".join(rows)


def summary():
    rows = ["| Версия | Дата | Объём, ч | Итераций | Выпуск 1.0 | Middle, ч × 40 BYN | Junior, ч × 15 BYN | Стоимость, BYN |",
            "|--------|------|----------|----------|------------|--------------------|--------------------|----------------|"]
    dates = ("12.11.2026", "14.11.2026", "16.11.2026")
    for v in range(3):
        its = iterations(v)
        mh, jh, c = cost(v)
        rows.append("| %s | %s | %s | %d | %s | %s | %s | %s |" % (
            VERSIONS[v], dates[v], num(sum(t[3] for t in tasks(v))), len(its), ITERATIONS[its[-1]][1],
            mh, jh if jh else "—", money(c)))
    return "\n".join(rows)


def main():
    for v in range(3):
        check(v)
    os.makedirs(IMG, exist_ok=True)
    gantt(0, os.path.join(IMG, "plan-v1.png"), "План v1 (12.11.2026): исходная оценка, один middle-разработчик")
    gantt(1, os.path.join(IMG, "plan-v2.png"), "План v2 (14.11.2026): после первого раунда обсуждения")
    gantt(2, os.path.join(IMG, "plan-v3.png"), "План v3 (16.11.2026): согласованный, middle + junior с итерации 3")
    with open(os.path.join(os.path.dirname(__file__), "plan_template.md"), encoding="utf-8") as f:
        text = f.read()
    mh2, _, c2 = cost(1)
    mh1, _, c1 = cost(0)
    mh3, jh3, c3 = cost(2)
    ld3 = load(2)
    repl = {
        "{{FEATURES_V1}}": feature_table(0), "{{FEATURES_V2}}": feature_table(1), "{{FEATURES_V3}}": feature_table(2),
        "{{ITER_V1}}": iteration_table(0), "{{ITER_V2}}": iteration_table(1), "{{ITER_V3}}": iteration_table(2),
        "{{TASKS}}": task_table(), "{{SUMMARY}}": summary(),
        "{{TOTAL_V1}}": num(sum(t[3] for t in tasks(0))), "{{TOTAL_V2}}": num(sum(t[3] for t in tasks(1))),
        "{{TOTAL_V3}}": num(sum(t[3] for t in tasks(2))),
        "{{COST_V1}}": money(c1), "{{COST_V2}}": money(c2), "{{COST_V3}}": money(c3),
        "{{COST_SHIFT}}": money(c2 + ITERATIONS[6][2] * HOURS_PER_DAY * MIDDLE_RATE),
        "{{DELTA_SHIFT}}": money(ITERATIONS[6][2] * HOURS_PER_DAY * MIDDLE_RATE),
        "{{DELTA_V3}}": money(c3 - c2), "{{PCT_V3}}": num(round((c3 - c2) / c2 * 100, 1)),
        "{{PCT_SHIFT}}": num(round(ITERATIONS[6][2] * HOURS_PER_DAY * MIDDLE_RATE / c2 * 100, 1)),
        "{{JUNIOR_TOTAL}}": num(sum(ld3.get((i, "J"), 0) for i in JUNIOR_ITERATIONS)),
        "{{MIDDLE_TOTAL_V3}}": num(sum(ld3.get((i, "M"), 0) for i in iterations(2))),
        "{{MIDDLE_TOTAL_V2}}": num(sum(load(1).get((i, "M"), 0) for i in iterations(1))),
    }
    for k, val in repl.items():
        text = text.replace(k, val)
    assert "{{" not in text, text[text.index("{{"):text.index("{{") + 40]
    with open(os.path.join(ROOT, "plan", "plan.md"), "w", encoding="utf-8") as f:
        f.write(text)
    print("plan/plan.md, plan/images/plan-v1.png … plan-v3.png")
    for v in range(3):
        print(VERSIONS[v], {k: num(x) for k, x in sorted(load(v).items())}, cost(v))


if __name__ == "__main__":
    main()
