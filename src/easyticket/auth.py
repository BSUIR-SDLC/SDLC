"""Аутентификация сотрудников (REQ-FUNC-011, REQ-SEC-003; UC-11).
Пароли: scrypt с солью. Токен сессии: JSON + подпись HMAC-SHA256."""
import base64
import hashlib
import hmac
import json
import os
from datetime import datetime, timedelta
from typing import Optional

ISO = "%Y-%m-%dT%H:%M:%S"
ROLES = ("admin", "controller")


class AuthError(Exception):
    """Неверные учётные данные или недействительный токен."""


class LockedError(AuthError):
    """Вход временно заблокирован после серии неудачных попыток."""

    def __init__(self, until: datetime):
        super().__init__("Вход заблокирован до " + until.strftime(ISO))
        self.until = until


# ---------- пароли ----------
_N, _R, _P = 2 ** 14, 8, 1


def hash_password(password: str, salt: Optional[bytes] = None) -> str:
    salt = salt or os.urandom(16)
    digest = hashlib.scrypt(password.encode("utf-8"), salt=salt, n=_N, r=_R, p=_P, dklen=32)
    return f"scrypt${_N}${_R}${_P}${salt.hex()}${digest.hex()}"


def verify_password(password: str, stored: str) -> bool:
    try:
        scheme, n, r, p, salt_hex, digest_hex = stored.split("$")
        if scheme != "scrypt":
            return False
        digest = hashlib.scrypt(password.encode("utf-8"), salt=bytes.fromhex(salt_hex), n=int(n), r=int(r), p=int(p), dklen=32)
        return hmac.compare_digest(digest, bytes.fromhex(digest_hex))
    except (ValueError, TypeError):
        return False


# ---------- токены ----------
def _b64(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _unb64(text: str) -> bytes:
    return base64.urlsafe_b64decode(text + "=" * (-len(text) % 4))


def make_token(user_id: int, role: str, secret: str, now: datetime, ttl_seconds: int) -> str:
    payload = {"u": user_id, "r": role, "exp": int((now + timedelta(seconds=ttl_seconds)).timestamp())}
    body = _b64(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    sig = _b64(hmac.new(secret.encode("utf-8"), body.encode("ascii"), hashlib.sha256).digest())
    return f"{body}.{sig}"


def verify_token(token: str, secret: str, now: datetime) -> dict:
    try:
        body, sig = token.split(".")
        expected = _b64(hmac.new(secret.encode("utf-8"), body.encode("ascii"), hashlib.sha256).digest())
        if not hmac.compare_digest(sig, expected):
            raise AuthError("Подпись токена неверна")
        payload = json.loads(_unb64(body))
    except (ValueError, TypeError, KeyError):
        raise AuthError("Токен повреждён")
    if payload.get("exp", 0) < int(now.timestamp()):
        raise AuthError("Срок действия токена истёк")
    return {"user_id": payload["u"], "role": payload["r"]}


# ---------- пользователи ----------
def create_staff(db, login: str, password: str, role: str) -> int:
    if role not in ROLES:
        raise ValueError("Неизвестная роль: " + role)
    if len(password) < 8:
        raise ValueError("Пароль должен содержать не менее 8 символов")
    with db.transaction():
        return db.insert("INSERT INTO staff_users (login, password_hash, role) VALUES (?, ?, ?)",
                         (login, hash_password(password), role))


def login(db, login_name: str, password: str, secret: str, now: datetime,
          ttl_seconds: int = 28800, max_failed: int = 5, lockout_minutes: int = 15) -> dict:
    """Возвращает {'token', 'role'} или бросает AuthError / LockedError."""
    user = db.fetchone("SELECT id, password_hash, role, failed_attempts, locked_until FROM staff_users WHERE login = ?", (login_name,))
    if user is None:
        # выравнивание времени ответа, чтобы не раскрывать существование логина
        verify_password(password, hash_password("dummy-password"))
        raise AuthError("Неверный логин или пароль")

    if user["locked_until"]:
        until = datetime.strptime(user["locked_until"], ISO)
        if until > now:
            raise LockedError(until)

    if not verify_password(password, user["password_hash"]):
        failed = user["failed_attempts"] + 1
        locked = None
        if failed >= max_failed:
            locked = (now + timedelta(minutes=lockout_minutes)).strftime(ISO)
            failed = 0
        with db.transaction():
            db.execute("UPDATE staff_users SET failed_attempts = ?, locked_until = ? WHERE id = ?", (failed, locked, user["id"]))
        if locked:
            raise LockedError(datetime.strptime(locked, ISO))
        raise AuthError("Неверный логин или пароль")

    with db.transaction():
        db.execute("UPDATE staff_users SET failed_attempts = 0, locked_until = NULL WHERE id = ?", (user["id"],))
    return {"token": make_token(user["id"], user["role"], secret, now, ttl_seconds), "role": user["role"]}
