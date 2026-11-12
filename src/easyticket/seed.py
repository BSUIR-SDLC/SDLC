"""Демонстрационные данные: зал, мероприятия, цены и учётная запись администратора.
Запуск: python -m easyticket.seed   (пароль администратора берётся из ADMIN_PASSWORD)."""
import os
from datetime import timedelta

from .auth import create_staff
from .catalog import utc_now
from .config import Settings
from .db import Database

CATEGORIES = [("VIP", 2, 10), ("Партер", 5, 12), ("Балкон", 4, 12)]  # (категория, рядов, мест в ряду)


def seed(db: Database, admin_password: str = None) -> None:
    db.init_schema()
    if db.fetchone("SELECT COUNT(*) AS n FROM halls")["n"]:
        return  # уже заполнено
    now = utc_now().replace(hour=19, minute=0, second=0)
    with db.transaction():
        hall_id = db.insert("INSERT INTO halls (name) VALUES (?)", ("Большой зал",))
        row = 0
        for category, rows, per_row in CATEGORIES:
            for _ in range(rows):
                row += 1
                for n in range(1, per_row + 1):
                    db.execute("INSERT INTO seats (hall_id, row_label, number, category) VALUES (?, ?, ?, ?)",
                               (hall_id, str(row), n, category))
        events = [
            ("Лебединое озеро", "Балет", "Классический балет в двух актах.", 5, {"VIP": 70, "Партер": 45, "Балкон": 25}),
            ("Щелкунчик", "Балет", "Рождественская сказка.", 9, {"VIP": 80, "Партер": 50, "Балкон": 30}),
            ("Травиата", "Опера", "Опера Верди.", 12, {"VIP": 90, "Партер": 60, "Балкон": 35}),
            ("Джазовый вечер", "Концерт", "Живой джаз.", 15, {"VIP": 60, "Партер": 40, "Балкон": 20}),
        ]
        for title, genre, desc, days, prices in events:
            ev_id = db.insert(
                "INSERT INTO events (hall_id, title, genre, description, venue, starts_at, status) VALUES (?, ?, ?, ?, ?, ?, 'active')",
                (hall_id, title, genre, desc, "Большой зал", (now + timedelta(days=days)).strftime("%Y-%m-%dT%H:%M:%S")))
            for category, price in prices.items():
                db.execute("INSERT INTO event_prices (event_id, category, price_byn) VALUES (?, ?, ?)", (ev_id, category, price))
    password = admin_password or os.environ.get("ADMIN_PASSWORD", "")
    if password:
        create_staff(db, "admin", password, "admin")


if __name__ == "__main__":
    database = Database(Settings().database_url)
    seed(database)
    print("Демонстрационные данные загружены")
