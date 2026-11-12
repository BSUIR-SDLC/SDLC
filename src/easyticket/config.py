import os


class Settings:
    """Настройки приложения из переменных окружения (REQ-INST-001, REQ-SEC-002)."""

    def __init__(self):
        self.database_url = os.environ.get("DATABASE_URL", "sqlite:///easyticket.db")
        # ключ подписи токенов и QR-кодов; в репозитории не хранится
        self.secret_key = os.environ.get("SECRET_KEY", "")
        self.session_ttl_seconds = int(os.environ.get("SESSION_TTL_SECONDS", "28800"))
        self.max_failed_logins = int(os.environ.get("MAX_FAILED_LOGINS", "5"))
        self.lockout_minutes = int(os.environ.get("LOCKOUT_MINUTES", "15"))

    def require_secret(self) -> str:
        if not self.secret_key:
            raise RuntimeError("Переменная окружения SECRET_KEY не задана")
        return self.secret_key
