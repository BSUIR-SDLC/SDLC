"""Строит изображения SDD из моделей Graphviz в sdd/models.

*.dot — контекст, модули, модель данных, развёртывание.
Диаграммы UML (прецеденты, активность, состояния, последовательности) с версии SDD 0.4
хранятся в uml/models и строятся скриптом uml/tools/uml.py (ADR-0008).
Запуск из корня репозитория: python sdd/tools/diagrams.py (нужен Graphviz).
"""
import glob
import os
import subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODELS, IMAGES = os.path.join(ROOT, "models"), os.path.join(ROOT, "images")


def render_dot(path):
    out = os.path.join(IMAGES, os.path.splitext(os.path.basename(path))[0] + ".png")
    subprocess.run(["dot", "-Tpng", "-Gdpi=150", path, "-o", out], check=True)
    return out


def main():
    os.makedirs(IMAGES, exist_ok=True)
    for p in sorted(glob.glob(os.path.join(MODELS, "*.dot"))):
        print("создан", os.path.relpath(render_dot(p), os.path.dirname(ROOT)))


if __name__ == "__main__":
    main()
