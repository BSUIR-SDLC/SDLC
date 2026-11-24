"""Рендер UML-моделей PlantUML из uml/models в PNG (uml/img).

Модели хранятся как текст (*.puml) — их можно сравнивать в diff и обсуждать в
pull request. Изображения строятся сервером PlantUML: по умолчанию Kroki
(https://kroki.io), запасной — https://www.plantuml.com. Свой сервер задаётся
переменной окружения PLANTUML_SERVER (например, http://localhost:8080 для
docker run -p 8080:8080 plantuml/plantuml-server), локальный plantuml.jar —
переменной PLANTUML_JAR (нужна Java).

Использование:
    python tools/uml_render.py               # все модели
    python tools/uml_render.py usecase       # только модели, имя которых содержит "usecase"
    python tools/uml_render.py --check       # проверить, что PNG не старше моделей
"""
from __future__ import annotations

import os
import string
import subprocess
import sys
import urllib.request
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / "uml" / "models"
OUT = ROOT / "uml" / "img"
UA = {"User-Agent": "qrgate-uml-render/1.0", "Content-Type": "text/plain; charset=utf-8"}

# Алфавит base64 PlantUML: 0-9 A-Z a-z - _
_PUML_ALPHABET = string.digits + string.ascii_uppercase + string.ascii_lowercase + "-_"


def plantuml_encode(text: str) -> str:
    """Кодирование текста для URL сервера PlantUML: deflate + собственный base64."""
    data = zlib.compress(text.encode("utf-8"), 9)[2:-4]  # сырой deflate без заголовка zlib
    res = []
    for i in range(0, len(data), 3):
        chunk = data[i:i + 3] + b"\0\0"
        b1, b2, b3 = chunk[0], chunk[1], chunk[2]
        res.append(_PUML_ALPHABET[b1 >> 2])
        res.append(_PUML_ALPHABET[((b1 & 0x3) << 4) | (b2 >> 4)])
        res.append(_PUML_ALPHABET[((b2 & 0xF) << 2) | (b3 >> 6)])
        res.append(_PUML_ALPHABET[b3 & 0x3F])
    return "".join(res)


def render_jar(src: Path, jar: str) -> bytes:
    out = subprocess.run(["java", "-jar", jar, "-tpng", "-charset", "UTF-8", "-pipe"],
                         input=src.read_bytes(), capture_output=True, check=True)
    return out.stdout


def render_http(text: str) -> bytes:
    custom = os.environ.get("PLANTUML_SERVER")
    attempts = []
    if custom:
        attempts.append(("GET", f"{custom.rstrip('/')}/png/{plantuml_encode(text)}"))
    attempts.append(("POST", "https://kroki.io/plantuml/png"))
    attempts.append(("GET", f"https://www.plantuml.com/plantuml/png/{plantuml_encode(text)}"))
    errors = []
    for method, url in attempts:
        try:
            body = text.encode("utf-8") if method == "POST" else None
            req = urllib.request.Request(url, data=body, headers=UA, method=method)
            with urllib.request.urlopen(req, timeout=60) as resp:
                png = resp.read()
            if png[:8] == b"\x89PNG\r\n\x1a\n":
                return png
            errors.append(f"{url[:40]}: ответ не PNG")
        except Exception as exc:  # noqa: BLE001 — пробуем следующий сервер
            errors.append(f"{url[:40]}: {exc}")
    raise RuntimeError("; ".join(errors))


def main(argv: list[str]) -> int:
    check = "--check" in argv
    filters = [a for a in argv if not a.startswith("--")]
    OUT.mkdir(parents=True, exist_ok=True)
    models = sorted(p for p in MODELS.glob("*.puml") if not filters or any(f in p.stem for f in filters))
    if not models:
        print("Нет моделей для рендера", file=sys.stderr)
        return 1
    stale = 0
    for src in models:
        dst = OUT / f"{src.stem}.png"
        if check:
            if not dst.exists() or dst.stat().st_mtime < src.stat().st_mtime:
                print(f"устарело: {dst.relative_to(ROOT)}")
                stale += 1
            continue
        text = src.read_text(encoding="utf-8")
        jar = os.environ.get("PLANTUML_JAR")
        png = render_jar(src, jar) if jar else render_http(text)
        dst.write_bytes(png)
        print(f"{src.relative_to(ROOT)} -> {dst.relative_to(ROOT)} ({len(png) // 1024} КБ)")
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
