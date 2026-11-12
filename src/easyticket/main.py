"""Точка входа FastAPI (ADR-0001). Запуск: uvicorn easyticket.main:app"""
from datetime import datetime
from typing import Optional

from fastapi import FastAPI, Header, HTTPException, Query
from fastapi.responses import HTMLResponse
from pydantic import BaseModel

from . import auth, catalog, web
from .config import Settings
from .db import Database


class LoginRequest(BaseModel):
    login: str
    password: str


def create_app(db: Optional[Database] = None, settings: Optional[Settings] = None) -> FastAPI:
    settings = settings or Settings()
    db = db or Database(settings.database_url)
    db.init_schema()
    app = FastAPI(title="EasyTicket API", version="0.1.0")

    def now() -> datetime:
        return catalog.utc_now()

    def current_staff(authorization: Optional[str]) -> dict:
        if not authorization or not authorization.lower().startswith("bearer "):
            raise HTTPException(401, "Требуется вход")
        try:
            return auth.verify_token(authorization[7:], settings.require_secret(), now())
        except auth.AuthError as exc:
            raise HTTPException(401, str(exc))

    @app.get("/healthz")
    def healthz():
        return {"status": "ok"}

    @app.get("/api/events")
    def api_events(date_from: Optional[str] = None, date_to: Optional[str] = None, genre: Optional[str] = None,
                   price_min: Optional[float] = None, price_max: Optional[float] = None,
                   page: int = Query(1, ge=1), page_size: int = Query(6, ge=1, le=50)):
        try:
            return catalog.list_events(db, catalog.EventFilter(date_from, date_to, genre, price_min, price_max, page, page_size), now())
        except ValueError as exc:
            raise HTTPException(422, str(exc))

    @app.get("/api/events/{event_id}")
    def api_event(event_id: int):
        event = catalog.get_event(db, event_id)
        if event is None:
            raise HTTPException(404, "Мероприятие не найдено")
        return event

    @app.post("/api/admin/login")
    def api_login(body: LoginRequest):
        try:
            return auth.login(db, body.login, body.password, settings.require_secret(), now(),
                              settings.session_ttl_seconds, settings.max_failed_logins, settings.lockout_minutes)
        except auth.LockedError as exc:
            raise HTTPException(423, str(exc))
        except auth.AuthError as exc:
            raise HTTPException(401, str(exc))

    @app.get("/api/admin/me")
    def api_me(authorization: Optional[str] = Header(None)):
        return current_staff(authorization)

    @app.get("/", response_class=HTMLResponse)
    def page_catalog(date_from: Optional[str] = None, date_to: Optional[str] = None, genre: Optional[str] = None,
                     price_min: Optional[float] = None, price_max: Optional[float] = None, page: int = Query(1, ge=1)):
        query = {k: v for k, v in dict(date_from=date_from, date_to=date_to, genre=genre, price_min=price_min, price_max=price_max).items() if v not in (None, "")}
        try:
            result = catalog.list_events(db, catalog.EventFilter(date_from or None, date_to or None, genre or None, price_min, price_max, page), now())
        except ValueError as exc:
            raise HTTPException(422, str(exc))
        return web.render_catalog(result, catalog.list_genres(db), query)

    @app.get("/events/{event_id}", response_class=HTMLResponse)
    def page_event(event_id: int):
        event = catalog.get_event(db, event_id)
        if event is None:
            raise HTTPException(404, "Мероприятие не найдено")
        return web.render_event(event)

    return app


def get_app() -> FastAPI:
    return create_app()


app = None  # создаётся фабрикой: uvicorn easyticket.main:get_app --factory
