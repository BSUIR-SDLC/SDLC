#!/usr/bin/env python3
"""Построение PNG из моделей PlantUML (ADR-0009).

python tools/uml_render.py          # все модели uml/models/*.puml -> uml/img/*.png
python tools/uml_render.py --check  # ошибка, если для модели нет PNG или комментария «Связи»

Источник PlantUML: переменная PLANTUML_JAR (путь к plantuml.jar) или
PLANTUML_SERVER (например http://localhost:8080) – тогда используется
POST /png на сервер PlantUML.
"""
import os, subprocess, sys, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / 'uml' / 'models'
IMG = ROOT / 'uml' / 'img'

def render_jar(jar, files):
    subprocess.run(['java', '-jar', jar, '-charset', 'UTF-8', '-tpng', '-o', str(IMG), *map(str, files)], check=True)

def render_server(url, files):
    for f in files:
        req = urllib.request.Request(url.rstrip('/') + '/png', data=f.read_bytes(), method='POST')
        (IMG / (f.stem + '.png')).write_bytes(urllib.request.urlopen(req, timeout=60).read())

def main():
    files = sorted(MODELS.glob('*.puml'))
    if '--check' in sys.argv:
        stale = [f.name for f in files if not (IMG / (f.stem + '.png')).exists()]
        for f in files:
            if not f.read_text(encoding='utf-8').splitlines()[1].startswith("' Связи"):
                stale.append(f.name + ' (нет комментария «Связи»)')
        if stale:
            print('Нужно перестроить:', ', '.join(stale)); sys.exit(1)
        print(f'OK: {len(files)} моделей'); return
    IMG.mkdir(parents=True, exist_ok=True)
    if os.environ.get('PLANTUML_JAR'):
        render_jar(os.environ['PLANTUML_JAR'], files)
    elif os.environ.get('PLANTUML_SERVER'):
        render_server(os.environ['PLANTUML_SERVER'], files)
    else:
        sys.exit('Задайте PLANTUML_JAR или PLANTUML_SERVER')
    print(f'Построено: {len(files)}')

if __name__ == '__main__':
    main()
