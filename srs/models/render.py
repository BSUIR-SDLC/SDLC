"""Отрисовка моделей SysMLv2 из папки srs/models в PNG (папка srs/images).

Запуск из корня репозитория:  python srs/models/render.py
Нужна библиотека Pillow:      python -m pip install pillow

Скрипт читает модели как текст, поэтому понимает только конструкции,
которые используются в файлах ui-*.sysml и system-context.sysml.
"""
import math
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BASE = Path(__file__).resolve().parent
OUT = BASE.parent / "images"
FONT_DIR = Path("C:/Windows/Fonts")

INK = (33, 37, 41)
MUTED = (100, 108, 118)
LINE = (120, 128, 138)
PANEL = (246, 247, 249)
TITLE = (52, 58, 70)
PRIMARY = (32, 88, 170)
STAMP = "Макет, не итоговый вид"
STAMP_COLOR = (255, 205, 90)
TONES = {
    "normal": (46, 139, 87),
    "warning": (214, 150, 20),
    "incident": (200, 40, 40),
    "silent": (130, 136, 144),
    "unknown": (60, 120, 200),
}

warnings = []


def font(size, bold=False, mono=False):
    name = "consola.ttf" if mono else ("arialbd.ttf" if bold else "arial.ttf")
    return ImageFont.truetype(str(FONT_DIR / name), size)


TOKEN = re.compile(r'"(?:[^"\\]|\\.)*"|:>>|[{};=:]|[^\s{};=:"]+')


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.S)
    return re.sub(r"^\s*//.*$", " ", text, flags=re.M)


class Node:
    def __init__(self, name, kind):
        self.name, self.kind = name, kind
        self.attrs, self.children, self.parent = {}, [], None
        self.rect = (0, 0, 0, 0)

    def num(self, key, default=0):
        return int(self.attrs.get(key, default))

    def text(self, key):
        return self.attrs.get(key, "")


def parse(tokens, pos, parent, links):
    """Разбирает тело элемента до закрывающей скобки."""
    while pos < len(tokens):
        tok = tokens[pos]
        if tok == "}":
            return pos + 1
        if tok == "attribute" and tokens[pos + 1] == ":>>":
            key, value = tokens[pos + 2], tokens[pos + 4]
            parent.attrs[key] = value[1:-1] if value.startswith('"') else value
            pos += 6
        elif tok == "part":
            node = Node(tokens[pos + 1], tokens[pos + 3])
            node.parent = parent
            parent.children.append(node)
            pos += 4
            if tokens[pos] == "{":
                pos = parse(tokens, pos + 1, node, links)
            else:
                pos += 1
        elif tok == "connection":
            link = {"a": tokens[pos + 5], "b": tokens[pos + 7], "caption": ""}
            pos += 8
            if tokens[pos] == "{":
                body = Node("link", "Link")
                pos = parse(tokens, pos + 1, body, links)
                link["caption"] = body.text("caption")
            else:
                pos += 1
            links.append(link)
        else:
            pos += 1
    return pos


def load(path):
    tokens = TOKEN.findall(strip_comments(path.read_text(encoding="utf-8")))
    start = tokens.index("{", tokens.index("package")) + 1
    root, links = Node("root", "Root"), []
    parse(tokens, start, root, links)
    return root.children[0], links


def text_size(draw, text, fnt):
    box = draw.textbbox((0, 0), text, font=fnt)
    return box[2] - box[0], box[3] - box[1]


def fit(draw, node, text, fnt, limit):
    width = text_size(draw, text, fnt)[0]
    if width > limit:
        warnings.append(f"{node.name}: текст «{text}» шире элемента ({width} > {limit})")


def centered(draw, rect, text, fnt, fill):
    x, y, w, h = rect
    tw, _ = text_size(draw, text, fnt)
    draw.text((x + (w - tw) / 2, y + h / 2), text, font=fnt, fill=fill, anchor="lm")


def hatch(draw, rect, color):
    x, y, w, h = rect
    for d in range(-h, w, 22):
        x0, y0, x1, y1 = x + d, y + h, x + d + h, y
        if x0 < x:
            y0 -= x - x0
            x0 = x
        if x1 > x + w:
            y1 += x1 - (x + w)
            x1 = x + w
        draw.line((x0, y0, x1, y1), fill=color, width=1)


def draw_node(draw, node, ox, oy):
    x, y = ox + node.num("posX"), oy + node.num("posY")
    w, h = node.num("width"), node.num("height")
    node.rect = (x, y, w, h)
    tone = node.text("tone")
    caption = node.text("caption")
    sub = node.text("subcaption")
    kind = node.kind
    child_x, child_y = x, y

    if kind == "Screen":
        draw.rectangle((x, y, x + w - 1, y + h - 1), fill="white", outline=LINE, width=2)
        draw.rectangle((x, y, x + w - 1, y + 40), fill=TITLE)
        draw.text((x + 16, y + 20), caption, font=font(20, True), fill="white", anchor="lm")
        child_y = y + 40
    elif kind == "Panel":
        draw.rounded_rectangle((x, y, x + w, y + h), 6, fill=PANEL, outline=LINE)
        if caption:
            fit(draw, node, caption, font(20, True), w - 28)
            draw.text((x + 14, y + 12), caption, font=font(20, True), fill=INK)
    elif kind == "Heading":
        fit(draw, node, caption, font(24, True), w)
        draw.text((x, y + h / 2), caption, font=font(24, True), fill=INK, anchor="lm")
    elif kind in ("Label", "Mono"):
        fnt = font(18, mono=kind == "Mono")
        fill = TONES.get(tone, MUTED if tone == "muted" else INK)
        fit(draw, node, caption, fnt, w)
        draw.text((x, y + h / 2), caption, font=fnt, fill=fill, anchor="lm")
    elif kind == "TextField":
        if caption:
            draw.text((x, y - 26), caption, font=font(18), fill=INK)
        draw.rectangle((x, y, x + w, y + h), fill="white", outline=LINE)
        fit(draw, node, sub, font(18), w - 24)
        draw.text((x + 12, y + h / 2), sub, font=font(18), fill=MUTED, anchor="lm")
    elif kind in ("Button", "PrimaryButton"):
        primary = kind == "PrimaryButton"
        draw.rounded_rectangle((x, y, x + w, y + h), 6, fill=PRIMARY if primary else "white", outline=PRIMARY if primary else LINE)
        fit(draw, node, caption, font(19, True), w - 12)
        centered(draw, (x, y, w, h), caption, font(19, True), "white" if primary else INK)
    elif kind == "Badge":
        draw.rounded_rectangle((x, y, x + w, y + h), 8, fill=TONES.get(tone, MUTED))
        fit(draw, node, caption, font(18, True), w - 10)
        centered(draw, (x, y, w, h), caption, font(18, True), "white")
    elif kind == "ListRow":
        draw.rectangle((x, y, x + w, y + h), fill="white", outline=LINE)
        draw.rectangle((x, y, x + 8, y + h), fill=TONES.get(tone, MUTED))
        fit(draw, node, caption, font(19, True), w - 30)
        fit(draw, node, sub, font(17), w - 30)
        draw.text((x + 20, y + 12), caption, font=font(19, True), fill=INK)
        draw.text((x + 20, y + 42), sub, font=font(17), fill=MUTED)
    elif kind == "Room":
        alarm = tone == "alarm"
        draw.rectangle((x, y, x + w, y + h), fill=(253, 236, 236) if alarm else "white")
        if tone == "restricted":
            hatch(draw, (x, y, w, h), (205, 205, 225))
        elif tone == "service":
            draw.rectangle((x, y, x + w, y + h), fill=(238, 242, 248))
        draw.rectangle((x, y, x + w, y + h), outline=TONES["incident"] if alarm else LINE, width=3 if alarm else 2)
        draw.text((x + 12, y + 8), caption, font=font(22, True), fill=INK)
    elif kind == "Host":
        color = TONES.get(tone, MUTED)
        if tone == "incident":
            draw.ellipse((x - 26, y - 26, x + 56, y + 56), outline=color, width=3)
            draw.ellipse((x - 14, y - 14, x + 44, y + 44), outline=color, width=2)
        draw.rectangle((x, y, x + 30, y + 30), fill=color, outline=INK)
        tw, _ = text_size(draw, caption, font(17))
        draw.text((x + 15 - tw / 2, y + 62), caption, font=font(17), fill=INK)
    elif kind == "Slider":
        mid = y + 14
        draw.line((x, mid, x + w, mid), fill=LINE, width=4)
        for mark in node.text("marks").split("|"):
            place, color = mark.split(":")
            mx = x + float(place) * w
            draw.rectangle((mx - 4, mid - 12, mx + 4, mid + 12), fill=TONES[color])
        left, right = sub.split("|")
        draw.text((x, y + 30), left, font=font(17), fill=MUTED)
        draw.text((x + w, y + 30), right, font=font(17), fill=MUTED, anchor="ra")
    elif kind == "Table":
        draw_table(draw, node, x, y, w, h)
    elif kind == "Block":
        outer = bool(node.children)
        external = tone == "external"
        fill = (238, 242, 248) if external else ("white" if not outer else PANEL)
        draw.rectangle((x, y, x + w, y + h), fill=fill, outline=INK, width=2)
        stereotype = "«внешний элемент»" if external else ("«система»" if outer else "«часть»")
        if outer:
            centered(draw, (x, y + 10, w, 26), stereotype, font(18), MUTED)
            centered(draw, (x, y + 38, w, 30), caption, font(24, True), INK)
        else:
            fit(draw, node, caption, font(21, True), w - 12)
            centered(draw, (x, y + h / 2 - 34, w, 28), stereotype, font(17), MUTED)
            centered(draw, (x, y + h / 2 - 2, w, 30), caption, font(21, True), INK)
    elif kind == "Actor":
        draw.ellipse((x - 16, y, x + 16, y + 32), outline=INK, width=2, fill="white")
        draw.line((x, y + 32, x, y + 80), fill=INK, width=2)
        draw.line((x - 26, y + 48, x + 26, y + 48), fill=INK, width=2)
        draw.line((x, y + 80, x - 22, y + 112), fill=INK, width=2)
        draw.line((x, y + 80, x + 22, y + 112), fill=INK, width=2)
        tw, _ = text_size(draw, caption, font(19))
        draw.text((x - tw / 2, y + 118), caption, font=font(19), fill=INK)
        node.rect = (x - 30, y, 60, 112)

    if kind != "Table":
        for child in node.children:
            draw_node(draw, child, child_x, child_y)


def draw_table(draw, node, x, y, w, h):
    columns = node.text("columns").split("|")
    widths = [int(v) for v in node.text("columnWidths").split("|")]
    if sum(widths) != w:
        warnings.append(f"{node.name}: сумма ширин столбцов {sum(widths)} не равна {w}")
    row_h = 46
    title = node.text("caption")
    draw.text((x, y), title, font=font(20, True), fill=INK)
    top = y + 34
    rows = [columns] + [c.text("cells").split("|") for c in node.children]
    for index, row in enumerate(rows):
        cx = x
        ry = top + index * row_h
        for cell, width in zip(row, widths):
            draw.rectangle((cx, ry, cx + width, ry + row_h), fill=(232, 235, 240) if index == 0 else "white", outline=LINE)
            fnt = font(18, index == 0)
            fit(draw, node, cell, fnt, width - 20)
            draw.text((cx + 10, ry + row_h / 2), cell, font=fnt, fill=INK, anchor="lm")
            cx += width


def find(node, path):
    current = node
    for part in path.split("."):
        current = next(c for c in current.children if c.name == part)
    return current


def edge(rect, tx, ty):
    x, y, w, h = rect
    cx, cy = x + w / 2, y + h / 2
    dx, dy = tx - cx, ty - cy
    scale = min(w / 2 / abs(dx) if dx else math.inf, h / 2 / abs(dy) if dy else math.inf)
    return cx + dx * scale, cy + dy * scale


def draw_link(draw, screen, link):
    a, b = find(screen, link["a"]).rect, find(screen, link["b"]).rect
    ca = (a[0] + a[2] / 2, a[1] + a[3] / 2)
    cb = (b[0] + b[2] / 2, b[1] + b[3] / 2)
    p1, p2 = edge(a, *cb), edge(b, *ca)
    draw.line((*p1, *p2), fill=INK, width=2)
    if link["caption"]:
        mx, my = (p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2
        tw, th = text_size(draw, link["caption"], font(18))
        draw.rectangle((mx - tw / 2 - 4, my - 34, mx + tw / 2 + 4, my - 8), fill="white")
        draw.text((mx - tw / 2, my - 32), link["caption"], font=font(18), fill=INK)


def main():
    OUT.mkdir(exist_ok=True)
    for path in sorted(BASE.glob("*.sysml")):
        if path.name == "ui-library.sysml":
            continue
        screen, links = load(path)
        image = Image.new("RGB", (screen.num("width"), screen.num("height")), "white")
        draw = ImageDraw.Draw(image)
        draw_node(draw, screen, 0, 0)
        for link in links:
            draw_link(draw, screen, link)
        if path.stem.startswith("ui-"):
            draw.text((screen.num("width") - 16, 20), STAMP, font=font(19, True), fill=STAMP_COLOR, anchor="rm")
        target = OUT / f"{path.stem}.png"
        image.save(target)
        print(target.name)
    for item in warnings:
        print("ВНИМАНИЕ:", item, file=sys.stderr)
    return 1 if warnings else 0


if __name__ == "__main__":
    sys.exit(main())
