"""HTML-страницы на серверных шаблонах Jinja2 (ADR-0005). Автоэкранирование включено (REQ-SEC-004)."""
from datetime import datetime
from importlib import resources

from jinja2 import Environment, FileSystemLoader, select_autoescape


def _env() -> Environment:
    path = str(resources.files("easyticket").joinpath("templates"))
    return Environment(loader=FileSystemLoader(path), autoescape=select_autoescape(["html"]))


def _fmt_dt(value: str) -> str:
    return datetime.strptime(value, "%Y-%m-%dT%H:%M:%S").strftime("%d.%m.%Y, %H:%M")


def _fmt_price(value) -> str:
    return f"{float(value):.2f} BYN"


def render_catalog(result: dict, genres: list, query: dict) -> str:
    env = _env()
    env.filters["dt"] = _fmt_dt
    env.filters["price"] = _fmt_price
    return env.get_template("catalog.html").render(result=result, genres=genres, q=query)


def render_event(event: dict) -> str:
    env = _env()
    env.filters["dt"] = _fmt_dt
    env.filters["price"] = _fmt_price
    return env.get_template("event.html").render(e=event)
