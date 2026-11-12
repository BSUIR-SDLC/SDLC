"""Построение бэклога, планов по итерациям и диаграмм Ганта.

Использование:  python tools/plan_render.py
Читает docs/plan/plan.json, пишет docs/plan/backlog.md, plan-v*.md, img/*.png
и docs/plan/computed.json (числа для отчёта).
Проверка трассировки: python tools/plan_render.py --check  (сверка с srs/srs-rulehook.md)
"""
import json, re, sys
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Patch
import plan_lib as P

ROOT = P.ROOT
OUT = ROOT / "docs/plan"
COLORS = {10: "#b91c1c", 20: "#ea580c", 30: "#2563eb", 40: "#0d9488", 50: "#6b7280"}
NAMES = {10: "Critical", 20: "High", 30: "Medium", 40: "Low", 50: "Optional"}
plt.rcParams["font.family"] = "DejaVu Sans"


def fmt_reqs(reqs):
    """REQ-FUNC-002, REQ-FUNC-003, REQ-INT-001 -> REQ-FUNC-002, 003, INT-001"""
    out, prev = [], None
    for r in reqs:
        m = re.match(r"REQ-([A-Z]+)-(.+)$", r)
        cat, num = m.group(1), m.group(2)
        if prev is None:
            out.append(f"REQ-{cat}-{num}")
        elif cat == prev:
            out.append(num)
        else:
            out.append(f"{cat}-{num}")
        prev = cat
    return ", ".join(out)


def merge_segments(segs, fid):
    pts = sorted((d + a, d + b, w) for (i, r, d, a, b, w) in segs if i == fid)
    merged = []
    for a, b, w in pts:
        if merged and abs(merged[-1][1] - a) < 1e-6:
            merged[-1][1] = b
            merged[-1][2] += w
        else:
            merged.append([a, b, w])
    return merged


def gantt(data, res, ver, path, mark_after_deadline=False):
    feats = {f["id"]: f for f in data["features"]}
    ids = ver["features"]
    seg = res["segments"]
    first = {i: min(d + a for (j, r, d, a, b, w) in seg if j == i) for i in ids}
    mid = sorted([i for i in ids if res["assignee"][i] == "middle"], key=lambda i: first[i])
    jun = sorted([i for i in ids if res["assignee"][i] == "junior"], key=lambda i: first[i])
    rows = mid + jun
    n = len(rows)
    fig, ax = plt.subplots(figsize=(10.2, 0.46 * n + 2.3))
    dl = res["deadline_index"] + 1
    xmax = max(dl + 6, res["last_day"] + 4)
    iters = P.iter_dates(data)
    idays = data["calendar"]["iteration_days"]
    for k, i in enumerate(rows):
        y = n - 1 - k
        suffix = " (J)" if res["assignee"][i] == "junior" else ""
        for a, b, w in merge_segments(seg, i):
            ax.barh(y, b - a, left=a, height=0.62, color=COLORS[ver["priority"][i]], zorder=3)
        segs_i = merge_segments(seg, i)
        endx = segs_i[-1][1]
        hrs = sum(s[2] for s in segs_i)
        ax.text(endx + 0.35, y, f"{hrs:g} ч", va="center", fontsize=9, color="#374151", zorder=4)
        name = feats[i]["name"]
        if i == "F11" and ver.get("variants", {}).get("F11") == "B":
            name = "Rule Editor UI (JSON)"
        ax.text(-0.3, y, f"{i} {name}{suffix}", ha="right", va="center", fontsize=9.5)
        if mark_after_deadline and endx > dl + 1e-6:
            x0 = max(dl, segs_i[0][0]) if segs_i[0][0] > dl else segs_i[0][0]
            ax.add_patch(Rectangle((segs_i[0][0] - 0.15, y - 0.45), endx - segs_i[0][0] + 1.6, 0.9,
                                   fill=False, ec="#b91c1c", lw=1.4, ls="--", zorder=5))
    if jun and mid:
        ax.axhline(len(jun) - 0.5, color="black", lw=1.0, zorder=2)
    for k in range(1, data["calendar"]["iterations"]):
        ax.axvline(k * idays, color="#9ca3af", ls="--", lw=1, zorder=1)
    ax.axvline(dl, color="#e11d2e", lw=2.4, zorder=6)
    ax.text(dl - 0.25, -0.95, f"срок {P.ddmmyyyy(res['days'][res['deadline_index']])}", color="#e11d2e", fontsize=9.5, va="center", ha="right")
    for k, (a, b) in enumerate(iters):
        ax.text(k * idays + idays / 2, n + 0.15, f"I{k+1}\n{P.ddmm(a)}–{P.ddmm(b)}", ha="center", va="bottom", fontsize=9.5)
    ax.set_xlim(0, xmax)
    ax.set_ylim(-1.3, n + 0.9)
    ax.set_yticks([])
    ax.set_xlabel("рабочие дни от начала разработки")
    for s in ("top", "right", "left"):
        ax.spines[s].set_visible(False)
    title = f"План {ver['id']}: {res['total_hours']:g} ч, окончание {P.ddmmyyyy(res['end_date'])}, {res['total_cost']:g} USD"
    fig.text(0.02, 0.992, title, fontsize=13, va="top")
    handles = [Patch(color=COLORS[p], label=f"{p} {NAMES[p]}") for p in (10, 20, 30, 40, 50)]
    fig.legend(handles=handles, loc="upper left", ncol=5, fontsize=8.5, frameon=False, bbox_to_anchor=(0.02, 0.962))
    fig.subplots_adjust(left=0.31, right=0.985, top=0.905, bottom=0.09)
    fig.savefig(path, dpi=130)
    plt.close(fig)


def iter_rows(data, res, ver):
    """Функции по итерациям в порядке начала работы: [(id, часы, junior?)]."""
    out = []
    n = data["calendar"]["iterations"]
    for k in range(n + 1):
        fi = {}
        for (i, r, d, a, b, w) in res["segments"]:
            if d // data["calendar"]["iteration_days"] == k:
                fi.setdefault(i, [d + a, 0.0])
                fi[i][1] += w
        out.append(sorted(((i, round(v[1], 1), res["assignee"][i] == "junior") for i, v in fi.items()),
                          key=lambda t: fi[t[0]][0]))
    return out


def fmt_iter_cell(rows):
    return ", ".join(f"{i} ({h:g}){' (J)' if j else ''}" for i, h, j in rows)


def main():
    data = P.load()
    feats = {f["id"]: f for f in data["features"]}
    computed = {"versions": {}}
    results = {}
    for ver in data["versions"]:
        results[ver["id"]] = (ver, P.simulate(data, ver))
    iters = P.iter_dates(data)
    deadline = P.ddmmyyyy(results["v2"][1]["days"][results["v2"][1]["deadline_index"]])

    # --- backlog.md ---
    lines = ["# Бэклог RuleHook", "",
             "Файл сформирован скриптом `tools/plan_render.py` из `docs/plan/plan.json`. Не редактировать вручную.", "",
             "Приоритет: 10 (Critical) – 50 (Optional). Оценка – сумма задач по 1–10 ч.", ""]
    lines += ["| ID | Feature | Приоритет (v3) | Часы | Зависит от | Требования SRS |", "|---|---|---|---|---|---|"]
    v3 = dict(results["v3"][0]["priority"])
    for f in data["features"]:
        pr = v3.get(f["id"], f["priority"])
        hrs = f["hours"] if f["id"] != "F11" else f"{f['hours_b']} (вариант B; полный – {f['hours']})"
        lines.append(f"| {f['id']} | {f['name']} | {pr}{' (R3)' if f.get('release')=='R3' else ''} | {hrs} | {', '.join(f['deps']) or '–'} | {fmt_reqs(f['reqs'])} |")
    lines.append("")
    for f in data["features"]:
        lines += [f"## {f['id']} {f['name']} — {f['name_ru']}", "",
                  f"Приоритет {f['priority']}, {f['hours']} ч. Зависит от: {', '.join(f['deps']) or '–'}. "
                  f"Требования: {fmt_reqs(f['reqs'])}.", "", "| Задача | Часы |", "|---|---|"]
        for t, h in f["tasks"]:
            lines.append(f"| {t} | {h} |")
        lines.append(f"| **Итого** | **{f['hours']}** |")
        if "tasks_b" in f:
            lines += ["", f"Вариант B (согласован в раунде 1): {f['hours_b']} ч; задачи с 0 ч перенесены в F20 (релиз 3)."]
        lines.append("")
    (OUT / "backlog.md").write_text("\n".join(lines), encoding="utf-8")

    # --- планы ---
    for vid, (ver, res) in results.items():
        rows = iter_rows(data, res, ver)
        L = [f"# План {vid}: {ver['title']}", "",
             f"Объём {res['total_hours']:g} ч, ёмкость 4 итераций {res['capacity_total']:g} ч, окончание {P.ddmmyyyy(res['end_date'])}, "
             f"стоимость {res['total_cost']:g} USD (middle {res['middle_hours']:g} ч / {res['middle_cost']:g} USD"
             + (f", junior {res['junior_hours']:g} ч / {res['junior_cost']:g} USD" if res['junior_hours'] else "") + ").", "",
             "| Итерация | Даты | Ёмкость, ч | Функции (часы в итерации) | Загрузка, ч |", "|---|---|---|---|---|"]
        for k in range(4):
            load = sum(h for _, h, _ in rows[k])
            L.append(f"| I{k+1} | {P.ddmm(iters[k][0])} – {P.ddmm(iters[k][1])} | {res['capacity'][k]:g} | {fmt_iter_cell(rows[k])} | {load:g} |")
        if rows[4]:
            L.append(f"| после срока | – | – | {fmt_iter_cell(rows[4])} | {sum(h for _, h, _ in rows[4]):g} |")
        L.append("")
        L.append(f"Диаграмма Ганта: `img/gantt-{vid}.png`")
        (OUT / f"plan-{vid}.md").write_text("\n".join(L), encoding="utf-8")
        gantt(data, res, ver, OUT / "img" / f"gantt-{vid}.png", mark_after_deadline=(vid == "v1"))
        computed["versions"][vid] = dict(
            title=ver["title"], total_hours=res["total_hours"], capacity=res["capacity"],
            capacity_total=res["capacity_total"], end_date=P.ddmmyyyy(res["end_date"]),
            middle_hours=res["middle_hours"], middle_cost=res["middle_cost"],
            junior_hours=res["junior_hours"], junior_cost=res["junior_cost"], total_cost=res["total_cost"],
            iter_rows=[[[i, h, j] for i, h, j in r] for r in rows],
            loads=[round(sum(h for _, h, _ in rows[k]), 1) for k in range(5)],
            done={i: P.ddmm(res["days"][d]) for i, d in res["done_day"].items()})
    computed["iterations"] = [[P.ddmm(a), P.ddmm(b)] for a, b in iters]
    computed["deadline"] = deadline
    (OUT / "computed.json").write_text(json.dumps(computed, ensure_ascii=False, indent=1), encoding="utf-8")
    print("план рассчитан:", {k: (v["total_hours"], v["end_date"], v["total_cost"]) for k, v in computed["versions"].items()})


def check():
    data = P.load()
    srs = (ROOT / "srs/srs-rulehook.md").read_text(encoding="utf-8")
    ids = set(re.findall(r"\b(REQ-[A-Z]+-\d{3}(?:-\d)?)\b", srs))
    ids = {i for i in ids if i + "-2" not in ids}  # заменённая версия не считается отдельным требованием
    used = set()
    bad = []
    for f in data["features"]:
        for r in f["reqs"]:
            used.add(r)
            if r not in ids:
                bad.append((f["id"], r))
    # требование, заменённое версией (SEC-005 -> SEC-005-2), считается покрытым новой версией
    uncovered = sorted(r for r in ids if r not in used and not (r + "-2") in used)
    print(f"требований в SRS: {len(ids)}; ссылок на несуществующие: {bad}; не покрыто функциями: {uncovered}")
    sys.exit(1 if bad or uncovered else 0)


if __name__ == "__main__":
    check() if "--check" in sys.argv else main()
