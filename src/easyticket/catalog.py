"""Каталог мероприятий и карточка мероприятия (REQ-FUNC-001, REQ-FUNC-002; UC-01, UC-02)."""
import math
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from typing import Optional

ISO = "%Y-%m-%dT%H:%M:%S"


def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None, microsecond=0)


@dataclass
class EventFilter:
    date_from: Optional[str] = None   # ГГГГ-ММ-ДД, включительно
    date_to: Optional[str] = None     # ГГГГ-ММ-ДД, включительно
    genre: Optional[str] = None
    price_min: Optional[float] = None
    price_max: Optional[float] = None
    page: int = 1
    page_size: int = 6


def _day(value: str, name: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError:
        raise ValueError(f"Неверная дата в поле {name}: {value}")


def list_events(db, flt: EventFilter, now: Optional[datetime] = None) -> dict:
    """Предстоящие активные мероприятия с фильтрами и постраничной выдачей, сортировка по дате."""
    now = now or utc_now()
    if flt.page < 1:
        raise ValueError("Номер страницы должен быть не меньше 1")
    if not 1 <= flt.page_size <= 50:
        raise ValueError("Размер страницы должен быть от 1 до 50")

    where = ["e.status = 'active'", "e.starts_at > ?"]
    params = [now.strftime(ISO)]
    if flt.date_from:
        where.append("e.starts_at >= ?")
        params.append(_day(flt.date_from, "date_from").isoformat() + "T00:00:00")
    if flt.date_to:
        where.append("e.starts_at < ?")
        params.append((_day(flt.date_to, "date_to") + timedelta(days=1)).isoformat() + "T00:00:00")
    if flt.genre:
        where.append("e.genre = ?")
        params.append(flt.genre)
    if flt.price_min is not None or flt.price_max is not None:
        lo = flt.price_min if flt.price_min is not None else 0
        hi = flt.price_max if flt.price_max is not None else 10 ** 9
        where.append("EXISTS (SELECT 1 FROM event_prices p WHERE p.event_id = e.id AND p.price_byn >= ? AND p.price_byn <= ?)")
        params += [lo, hi]
    cond = " AND ".join(where)

    total = db.fetchone(f"SELECT COUNT(*) AS n FROM events e WHERE {cond}", params)["n"]
    offset = (flt.page - 1) * flt.page_size
    rows = db.fetchall(
        f"""SELECT e.id, e.title, e.genre, e.starts_at, e.venue,
                   (SELECT MIN(p.price_byn) FROM event_prices p WHERE p.event_id = e.id) AS min_price
            FROM events e WHERE {cond}
            ORDER BY e.starts_at, e.id LIMIT ? OFFSET ?""",
        params + [flt.page_size, offset],
    )
    return {
        "events": rows,
        "total": total,
        "page": flt.page,
        "pages": max(1, math.ceil(total / flt.page_size)),
    }


def list_genres(db) -> list:
    rows = db.fetchall("SELECT DISTINCT genre FROM events WHERE status = 'active' ORDER BY genre")
    return [r["genre"] for r in rows]


def get_event(db, event_id: int) -> Optional[dict]:
    """Карточка активного мероприятия: описание, дата, место, цены и состав зала по категориям."""
    ev = db.fetchone(
        "SELECT id, hall_id, title, genre, description, venue, starts_at, status FROM events WHERE id = ? AND status = 'active'",
        (event_id,),
    )
    if ev is None:
        return None
    ev["prices"] = db.fetchall(
        "SELECT category, price_byn FROM event_prices WHERE event_id = ? ORDER BY price_byn DESC", (event_id,))
    ev["seat_counts"] = db.fetchall(
        "SELECT category, COUNT(*) AS seats FROM seats WHERE hall_id = ? GROUP BY category ORDER BY category", (ev["hall_id"],))
    return ev
