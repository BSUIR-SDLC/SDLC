"""Строит изображения UML-диаграмм из текстовых моделей uml/models (ADR-0008).

*.dot — диаграммы прецедентов (uc-*), активности (ad-*) и состояний (sm-*) на языке
        Graphviz DOT; значки актёра и временного события — actor.png, hourglass.png;
*.mmd — диаграммы последовательности (sq-*) на языке Mermaid; оформление — mermaid-config.json.

Запуск из корня репозитория:
    python uml/tools/uml.py            # все модели
    python uml/tools/uml.py sq-1-login # одна модель (имя без расширения)

Нужны Graphviz (команда dot) и Node.js 18+ (mermaid-cli загружается через npx).
Если Chrome для mermaid-cli уже установлен, путь к нему можно передать через
переменную окружения PUPPETEER_EXECUTABLE_PATH.
"""
import glob
import json
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODELS, IMAGES = os.path.join(ROOT, "models"), os.path.join(ROOT, "images")
DPI = "150"


def render_dot(path):
    out = os.path.join(IMAGES, os.path.splitext(os.path.basename(path))[0] + ".png")
    # cwd=MODELS: Graphviz ищет actor.png и hourglass.png рядом с моделью
    subprocess.run(["dot", "-Tpng", "-Gdpi=" + DPI, os.path.basename(path), "-o", out],
                   cwd=MODELS, check=True)
    return out


def mmdc_command():
    if shutil.which("mmdc"):
        return ["mmdc"]
    npx = shutil.which("npx") or shutil.which("npx.cmd")
    if not npx:
        sys.exit("Нужен Node.js (npx) или установленный mermaid-cli (mmdc)")
    return [npx, "-y", "-p", "@mermaid-js/mermaid-cli", "mmdc"]


def render_mmd(path):
    out = os.path.join(IMAGES, os.path.splitext(os.path.basename(path))[0] + ".png")
    cmd = mmdc_command() + ["-q", "-i", path, "-o", out, "-b", "white", "-s", "2",
                            "-c", os.path.join(MODELS, "mermaid-config.json")]
    chrome = os.environ.get("PUPPETEER_EXECUTABLE_PATH")
    tmp = None
    if chrome:
        tmp = tempfile.NamedTemporaryFile("w", suffix=".json", delete=False)
        json.dump({"executablePath": chrome, "args": ["--no-sandbox"]}, tmp)
        tmp.close()
        cmd += ["-p", tmp.name]
    try:
        subprocess.run(cmd, check=True, shell=(os.name == "nt"))
    finally:
        if tmp:
            os.unlink(tmp.name)
    return out


def main(names):
    os.makedirs(IMAGES, exist_ok=True)
    models = sorted(glob.glob(os.path.join(MODELS, "*.dot")) + glob.glob(os.path.join(MODELS, "*.mmd")))
    if names:
        models = [m for m in models if os.path.splitext(os.path.basename(m))[0] in names]
    for m in models:
        out = render_dot(m) if m.endswith(".dot") else render_mmd(m)
        print(os.path.relpath(out, ROOT))


if __name__ == "__main__":
    main(sys.argv[1:])
