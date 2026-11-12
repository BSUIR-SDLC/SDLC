"""Тонкий слой доступа к БД: SQLite (тесты, разработка) и PostgreSQL (Docker). SDD DV-002, ADR-0002."""
import sqlite3
from contextlib import contextmanager
from importlib import resources


class Database:
    def __init__(self, url: str):
        self.url = url
        if url.startswith("sqlite:///"):
            self.dialect = "sqlite"
            path = url[len("sqlite:///"):] or ":memory:"
            self._conn = sqlite3.connect(path, check_same_thread=False)
            self._conn.row_factory = sqlite3.Row
            self._conn.execute("PRAGMA foreign_keys = ON")
        elif url.startswith("postgresql://"):
            import psycopg2  # импорт отложен: нужен только для PostgreSQL
            import psycopg2.extras
            self.dialect = "postgresql"
            self._conn = psycopg2.connect(url)
            self._extras = psycopg2.extras
        else:
            raise ValueError("Неподдерживаемый DATABASE_URL: " + url)

    # --- служебное ---
    def _sql(self, sql: str) -> str:
        return sql.replace("?", "%s") if self.dialect == "postgresql" else sql

    def _cursor(self):
        if self.dialect == "postgresql":
            return self._conn.cursor(cursor_factory=self._extras.RealDictCursor)
        return self._conn.cursor()

    @contextmanager
    def transaction(self):
        try:
            yield
            self._conn.commit()
        except Exception:
            self._conn.rollback()
            raise

    # --- запросы ---
    def execute(self, sql: str, params=()):
        cur = self._cursor()
        cur.execute(self._sql(sql), params)
        return cur

    def insert(self, sql: str, params=()) -> int:
        """INSERT с возвратом идентификатора (RETURNING id для PostgreSQL)."""
        if self.dialect == "postgresql":
            cur = self.execute(sql + " RETURNING id", params)
            return cur.fetchone()["id"]
        return self.execute(sql, params).lastrowid

    def fetchall(self, sql: str, params=()) -> list:
        return [dict(r) for r in self.execute(sql, params).fetchall()]

    def fetchone(self, sql: str, params=()):
        row = self.execute(sql, params).fetchone()
        return dict(row) if row is not None else None

    def init_schema(self):
        pk = "INTEGER PRIMARY KEY AUTOINCREMENT" if self.dialect == "sqlite" else "SERIAL PRIMARY KEY"
        script = resources.files("easyticket").joinpath("schema.sql").read_text(encoding="utf-8").replace("{ID}", pk)
        with self.transaction():
            for stmt in script.split(";"):
                if stmt.strip():
                    self.execute(stmt)

    def close(self):
        self._conn.close()
