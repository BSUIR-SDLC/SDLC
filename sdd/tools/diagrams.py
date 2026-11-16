"""Строит изображения SDD из моделей в sdd/models.

*.dot — диаграммы Graphviz (контекст, модули, данные, развёртывание, состояния);
*.seq — диаграммы последовательности в простом текстовом формате:
    title: заголовок
    participant ID: подпись
    A -> B: сообщение        (сплошная стрелка)
    A --> B: ответ           (пунктирная стрелка)
    == текст ==              (разделитель: условие, цикл, альтернатива)
Запуск из корня репозитория: python sdd/tools/diagrams.py (нужны Graphviz и Pillow).
"""
import glob
import os
import subprocess

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MODELS, IMAGES = os.path.join(ROOT, "models"), os.path.join(ROOT, "images")
FONT_CANDIDATES = ["/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
                   "C:/Windows/Fonts/arial.ttf", "/Library/Fonts/Arial.ttf"]
BOLD_CANDIDATES = ["/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
                   "C:/Windows/Fonts/arialbd.ttf", "/Library/Fonts/Arial Bold.ttf"]
INK, BLUE, GREY = "#222222", "#2f6db3", "#888888"


def font(cands, size):
    for c in cands:
        if os.path.exists(c):
            return ImageFont.truetype(c, size)
    return ImageFont.load_default()


def render_dot(path):
    out = os.path.join(IMAGES, os.path.splitext(os.path.basename(path))[0] + ".png")
    subprocess.run(["dot", "-Tpng", "-Gdpi=150", path, "-o", out], check=True)
    return out


def parse_seq(path):
    title, parts, steps = "", [], []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("//"):
                continue
            if line.startswith("title:"):
                title = line[6:].strip()
            elif line.startswith("participant "):
                pid, label = line[12:].split(":", 1)
                parts.append((pid.strip(), label.strip()))
            elif line.startswith("=="):
                steps.append(("sep", line.strip("= ").strip()))
            else:
                head, text = line.split(":", 1)
                dashed = "-->" in head
                a, b = [x.strip() for x in head.replace("-->", "->").split("->")]
                steps.append(("msg", a, b, text.strip(), dashed))
    return title, parts, steps


def render_seq(path):
    title, parts, steps = parse_seq(path)
    f, fb, fs = font(FONT_CANDIDATES, 15), font(BOLD_CANDIDATES, 15), font(FONT_CANDIDATES, 14)
    colw, top, row = 230, 110, 46
    width = colw * len(parts) + 40
    height = top + row * (len(steps) + 1) + 40
    img = Image.new("RGB", (width, height), "white")
    d = ImageDraw.Draw(img)
    d.text((20, 14), title, font=fb, fill=INK)
    x = {pid: 20 + colw * i + colw // 2 for i, (pid, _) in enumerate(parts)}
    for pid, label in parts:
        lines = wrap(d, label, fs, colw - 30)
        h = 18 * len(lines) + 14
        d.rounded_rectangle([x[pid] - colw // 2 + 12, 48, x[pid] + colw // 2 - 12, 48 + h], 6, fill="#dbe8f7", outline=BLUE)
        for k, ln in enumerate(lines):
            d.text((x[pid] - d.textlength(ln, font=fs) / 2, 55 + 18 * k), ln, font=fs, fill=INK)
        for yy in range(48 + h, height - 20, 10):
            d.line([x[pid], yy, x[pid], yy + 5], fill=GREY, width=1)
    y = top + 20
    for st in steps:
        if st[0] == "sep":
            d.rectangle([14, y - 14, width - 14, y + 14], fill="#fff6dd", outline="#d0a64a")
            d.text((24, y - 9), "[" + st[1] + "]", font=fs, fill="#6b4e00")
        else:
            _, a, b, text, dashed = st
            xa, xb = x[a], x[b]
            if a == b:
                d.line([xa, y - 6, xa + 40, y - 6, xa + 40, y + 10, xa + 6, y + 10], fill=INK, width=2)
                arrow(d, xa + 6, y + 10, -1)
                d.text((xa + 46, y - 4), text, font=fs, fill=INK)
            else:
                if dashed:
                    step = 9 if xb > xa else -9
                    for xx in range(xa, xb, step):
                        d.line([xx, y + 8, xx + step * 0.6, y + 8], fill=INK, width=2)
                else:
                    d.line([xa, y + 8, xb, y + 8], fill=INK, width=2)
                arrow(d, xb, y + 8, 1 if xb > xa else -1)
                tx = min(xa, xb) + 8
                maxw = abs(xb - xa) - 16 if abs(xb - xa) > 260 else colw * 2
                lines = wrap(d, text, fs, maxw)
                for k, ln in enumerate(lines[::-1]):
                    d.text((tx, y - 10 - 16 * k), ln, font=fs, fill=INK)
        y += row
    out = os.path.join(IMAGES, os.path.splitext(os.path.basename(path))[0] + ".png")
    img.save(out)
    return out


def arrow(d, x, y, direction):
    d.polygon([(x, y), (x - 11 * direction, y - 6), (x - 11 * direction, y + 6)], fill=INK)


def wrap(d, text, f, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if d.textlength(t, font=f) <= width or not cur:
            cur = t
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def main():
    os.makedirs(IMAGES, exist_ok=True)
    for p in sorted(glob.glob(os.path.join(MODELS, "*.dot"))):
        print("создан", os.path.relpath(render_dot(p), os.path.dirname(ROOT)))
    for p in sorted(glob.glob(os.path.join(MODELS, "*.seq"))):
        print("создан", os.path.relpath(render_seq(p), os.path.dirname(ROOT)))


if __name__ == "__main__":
    main()
