"""Расчёт планов по итерациям для RuleHook.

Читает docs/plan/plan.json и раскладывает функции по исполнителям в порядке
приоритета с учётом зависимостей и ёмкости каждого рабочего дня.
"""
import json, math, datetime as dt
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load(path=None):
    return json.load(open(path or ROOT / "docs/plan/plan.json", encoding="utf-8"))


def work_days(cal, n):
    """Первые n рабочих дней (пн–пт, без праздничных дней)."""
    d = dt.date.fromisoformat(cal["start"])
    hol = {dt.date.fromisoformat(x) for x in cal.get("holidays", [])}
    out = []
    while len(out) < n:
        if d.weekday() < 5 and d not in hol:
            out.append(d)
        d += dt.timedelta(days=1)
    return out


def hours_of(feat, variant):
    if variant == "B" and "hours_b" in feat:
        return feat["hours_b"]
    return feat["hours"]


def simulate(data, ver, max_days=90):
    cal, team = data["calendar"], data["team"]
    feats = {f["id"]: f for f in data["features"]}
    ids = ver["features"]
    iter_days = cal["iteration_days"]
    days = work_days(cal, max_days)
    junior_ids = set(ver.get("junior", []))
    has_junior = bool(junior_ids)
    jr = team["junior"]
    j_start = (jr["start_iteration"] - 1) * iter_days

    assignee = {i: ("junior" if i in junior_ids else "middle") for i in ids}
    prio = ver["priority"]
    order = sorted(ids, key=lambda i: (prio[i], feats[i]["seq"], i))
    rem = {i: float(hours_of(feats[i], ver.get("variants", {}).get(i))) for i in ids}
    jorder = [i for i in ver.get("junior", []) if i in ids]  # порядок junior задан списком
    queue = {"middle": [i for i in order if assignee[i] == "middle"], "junior": jorder}
    done_day = {}
    segs = []  # (feature, resource, day, pos0, pos1, hours)

    def cap(res, d):
        if res == "middle":
            c = team["middle"]["paid_hours_per_day"] * team["middle"]["focus"]
            if has_junior and d >= j_start:
                c -= jr["mentoring_per_iteration"] / iter_days
            return c
        if not has_junior or d < j_start:
            return 0.0
        perf = jr["perf_first"] if (d - j_start) // iter_days == 0 else jr["perf_next"]
        return jr["paid_hours_per_day"] * perf

    finished_prev = set()
    current = {"middle": None, "junior": None}  # начатая функция доделывается без переключений
    for d in range(max_days):
        finished_today = set()
        for res in ("middle", "junior"):
            c = cap(res, d)
            t = c
            while t > 1e-9:
                pick = None
                cur = current[res]
                cand = ([cur] if cur and rem[cur] > 1e-9 else []) + queue[res]
                for i in cand:
                    if rem[i] <= 1e-9:
                        continue
                    ok = all((x in finished_prev) or (x in finished_today and assignee.get(x) == res)
                             for x in feats[i]["deps"] if x in ids)
                    if ok:
                        pick = i
                        break
                current[res] = pick
                if pick is None:
                    break
                w = min(t, rem[pick])
                segs.append((pick, res, d, (c - t) / c, (c - t + w) / c, w))
                t -= w
                rem[pick] -= w
                if rem[pick] <= 1e-9:
                    done_day[pick] = d
                    finished_today.add(pick)
        finished_prev |= finished_today
        if all(v <= 1e-9 for v in rem.values()):
            last_day = d
            break
    else:
        raise RuntimeError("не хватило дней")

    # результаты
    n_iter = cal["iterations"]
    cap_total = n_iter * iter_days
    per_iter = {}
    for (i, res, d, a, b, w) in segs:
        per_iter.setdefault(d // iter_days, {}).setdefault(i, 0.0)
        per_iter[d // iter_days][i] += w
    res_days = {}
    for r in ("middle", "junior"):
        ds = [s[2] for s in segs if s[1] == r]
        res_days[r] = (max(ds) + 1) if ds else 0
    mid_days = res_days["middle"]
    mid_hours = mid_days * team["middle"]["paid_hours_per_day"]
    mid_cost = mid_hours * team["middle"]["rate_usd"]
    jr_cost = jr_hrs = 0
    if has_junior:
        jr_days = cap_total - j_start
        jr_hrs = jr_days * jr["paid_hours_per_day"]
        jr_cost = jr_hrs * jr["rate_usd"]
    # ёмкость итераций
    caps = []
    for k in range(n_iter):
        s = 0.0
        for d in range(k * iter_days, (k + 1) * iter_days):
            s += cap("middle", d) + cap("junior", d)
        caps.append(round(s, 1))
    total_hours = sum(hours_of(feats[i], ver.get("variants", {}).get(i)) for i in ids)
    return dict(id=ver["id"], title=ver["title"], total_hours=total_hours, capacity=caps,
                capacity_total=round(sum(caps), 1), order=order, assignee=assignee,
                segments=segs, per_iter=per_iter, days=days,
                done_day=done_day, last_day=last_day, end_date=days[last_day],
                middle_days=mid_days, middle_hours=mid_hours, middle_cost=mid_cost,
                junior_hours=jr_hrs, junior_cost=jr_cost, total_cost=mid_cost + jr_cost,
                deadline_index=cap_total - 1)


def ddmm(d):
    return d.strftime("%d.%m")


def ddmmyyyy(d):
    return d.strftime("%d.%m.%Y")


def iter_dates(data):
    cal = data["calendar"]
    n = cal["iteration_days"]
    ds = work_days(cal, n * cal["iterations"])
    return [(ds[k * n], ds[(k + 1) * n - 1]) for k in range(cal["iterations"])]
