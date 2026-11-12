from datetime import datetime, timedelta

from easyticket.db import Database

NOW = datetime(2026, 11, 12, 12, 0, 0)


def make_db() -> Database:
    db = Database("sqlite:///:memory:")
    db.init_schema()
    return db


def add_event(db, hall_id, title, genre, starts_at, status="active", prices=None, venue="Большой зал", description=""):
    with db.transaction():
        ev_id = db.insert(
            "INSERT INTO events (hall_id, title, genre, description, venue, starts_at, status) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (hall_id, title, genre, description, venue, starts_at.strftime("%Y-%m-%dT%H:%M:%S"), status))
        for category, price in (prices or {"Партер": 40}).items():
            db.execute("INSERT INTO event_prices (event_id, category, price_byn) VALUES (?, ?, ?)", (ev_id, category, price))
    return ev_id


def add_hall(db, vip=2, parter=3):
    with db.transaction():
        hall_id = db.insert("INSERT INTO halls (name) VALUES (?)", ("Тестовый зал",))
        for n in range(1, vip + 1):
            db.execute("INSERT INTO seats (hall_id, row_label, number, category) VALUES (?, '1', ?, 'VIP')", (hall_id, n))
        for n in range(1, parter + 1):
            db.execute("INSERT INTO seats (hall_id, row_label, number, category) VALUES (?, '2', ?, 'Партер')", (hall_id, n))
    return hall_id


def days(n):
    return NOW + timedelta(days=n)
