#!/usr/bin/env python3
"""Строит PNG-изображения из моделей SysML v2 (текстовая нотация).

Поддерживается подмножество языка, использованное в srs/models:
  * мокапы экранов — дерево частей (part) на элементах библиотеки UiKit;
  * контекстная диаграмма — части и соединения (connection ... connect a to b);
  * карта экранов — state def с состояниями и переходами (transition).

Запуск из корня репозитория:
    python srs/tools/sysml2png.py

Зависимости: Pillow (pip install pillow); для диаграмм — Graphviz (dot).
"""
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / "models"
IMAGES = ROOT / "images"

# ----------------------------------------------------------------- разбор

TOKEN = re.compile(r'''
    (?P<doc>/\*.*?\*/) | (?P<line>//[^\n]*) |
    (?P<str>"(?:[^"\\]|\\.)*") |
    (?P<sym>:>>|:>|::|\.\.|[{};:=(),\[\]*]) |
    (?P<word>[^\s{};:=(),\[\]*"]+)
''', re.S | re.X)


def tokenize(text):
    out = []
    for m in TOKEN.finditer(text):
        kind = m.lastgroup
        if kind == "line":
            continue
        out.append((kind, m.group()))
    return out


class Node:
    def __init__(self, header, doc=""):
        self.header = header          # список лексем до '{' или ';'
        self.children = []
        self.doc = doc

    @property
    def words(self):
        return [v for _, v in self.header]

    def kind(self):
        w = self.words
        if not w:
            return ""
        if len(w) > 1 and w[1] == "def":
            return w[0] + " def"
        return w[0]

    def name(self):
        w = self.words
        skip = 2 if self.kind().endswith("def") else 1
        return w[skip] if len(w) > skip and re.match(r"\w", w[skip]) else ""

    def type(self):
        w = self.words
        return w[w.index(":") + 1].split("::")[-1] if ":" in w else ""

    def parts(self):
        return [c for c in self.children if c.kind() == "part"]

    def attrs(self):
        """Значения переопределённых атрибутов: attribute :>> имя = значение;"""
        res = {}
        for c in self.children:
            w = c.words
            if c.kind() == "attribute" and ":>>" in w and "=" in w:
                key = w[w.index(":>>") + 1]
                vals = [unquote(v) if k == "str" else v.split("::")[-1]
                        for k, v in c.header[w.index("=") + 1:] if v not in ("(", ")", ",", "::")]
                res[key] = vals if "(" in w else vals[-1]
        return res


def unquote(s):
    return s[1:-1].replace('\\"', '"')


def parse(tokens):
    root = Node([])
    stack = [root]
    header = []
    for kind, val in tokens:
        if kind == "doc":
            text = re.sub(r"^/\*+|\*+/$", "", val).strip()
            if header and header[-1][1] == "doc":
                header.pop()
                stack[-1].doc = text
            continue
        if val == "{":
            node = Node(header)
            stack[-1].children.append(node)
            stack.append(node)
            header = []
        elif val == "}":
            stack.pop()
            header = []
        elif val == ";":
            if header:
                stack[-1].children.append(Node(header))
            header = []
        else:
            header.append((kind, val))
    return root


def load(name):
    return parse(tokenize((MODELS / name).read_text(encoding="utf-8")))


def walk(node):
    yield node
    for c in node.children:
        yield from walk(c)


# ----------------------------------------------------------------- мокапы

def font(size, bold=False):
    names = (["DejaVuSans-Bold.ttf", "arialbd.ttf"] if bold
             else ["DejaVuSans.ttf", "arial.ttf"])
    for n in names:
        try:
            return ImageFont.truetype(n, size)
        except OSError:
            pass
    return ImageFont.load_default()


F, FB, FS, FH, FBIG = font(15), font(15, True), font(13), font(19, True), font(24, True)
INK, MUTED, LINE, FILL, ACCENT, DARK = "#1f2933", "#7b8794", "#9aa5b1", "#f5f7fa", "#2f6fde", "#323f4b"
GAP, PAD, W = 14, 16, 1280
CONTAINERS = {"Screen", "Row", "Column", "Panel"}


def fit(d, text, f, width):
    if d.textlength(text, font=f) <= width:
        return text
    while text and d.textlength(text + "…", font=f) > width:
        text = text[:-1]
        if not text:
            return ""
    return text + "…"


def horizontal(node):
    return node.type() == "Row" or node.attrs().get("orientation") == "horizontal"


def height(node, width):
    t, a = node.type(), node.attrs()
    if t in CONTAINERS:
        kids = node.parts()
        inner = width - (2 * PAD if t in ("Panel", "Screen") else 0)
        if horizontal(node):
            h = max([height(k, w) for k, w in zip(kids, split(kids, inner))], default=0)
        else:
            h = sum(height(k, inner) for k in kids) + GAP * max(len(kids) - 1, 0)
        if t == "Panel":
            h += 2 * PAD + (34 if a.get("text") else 0)
        return h
    if t == "NavBar":
        return 52
    if t in ("TextField", "PasswordField", "DateField", "Select"):
        return 38 + (22 if a.get("label") else 0)
    if t == "Button":
        return 38
    if t == "StatCard":
        return 86
    if t == "Table":
        return 36 * (1 + len(node.parts()))
    if t == "Chart":
        return 250
    return 24  # Label, Link, Checkbox


def split(kids, width):
    weights = [int(k.attrs().get("weight", 1)) for k in kids]
    free = width - GAP * (len(kids) - 1)
    return [free * w // sum(weights) for w in weights]


def draw(d, node, x, y, w):
    t, a = node.type(), node.attrs()
    text = a.get("text", "")
    h = height(node, w)
    if t in CONTAINERS:
        kids = node.parts()
        if t == "Panel":
            d.rounded_rectangle([x, y, x + w, y + h], 8, fill="white", outline=LINE)
            x, y, w = x + PAD, y + PAD, w - 2 * PAD
            if text:
                d.text((x, y), text, font=FH, fill=INK)
                y += 34
        if horizontal(node):
            for k, kw in zip(kids, split(kids, w)):
                draw(d, k, x, y, kw)
                x += kw + GAP
        else:
            for k in kids:
                draw(d, k, x, y, w)
                y += height(k, w) + GAP
    elif t == "NavBar":
        d.rectangle([x, y, x + w, y + h], fill=DARK)
        d.text((x + PAD, y + 15), text, font=FH, fill="white")
        cx = x + 170
        for item in a.get("items", []):
            f = FB if item == a.get("active") else F
            d.text((cx, y + 17), item, font=f, fill="white" if item == a.get("active") else "#cbd2d9")
            if item == a.get("active"):
                d.line([cx, y + h - 6, cx + d.textlength(item, font=f), y + h - 6], fill="white", width=3)
            cx += d.textlength(item, font=f) + 30
        if a.get("user"):
            d.text((x + w - PAD - d.textlength(a["user"], font=FS), y + 18), a["user"], font=FS, fill="#cbd2d9")
    elif t in ("TextField", "PasswordField", "DateField", "Select"):
        if a.get("label"):
            d.text((x, y), a["label"], font=FS, fill=INK)
            y += 22
        d.rounded_rectangle([x, y, x + w, y + 38], 5, fill="white", outline=LINE)
        d.text((x + 10, y + 10), fit(d, text, F, w - 44), font=F, fill=MUTED)
        mark = {"Select": "▾", "DateField": "▦"}.get(t)
        if mark:
            d.text((x + w - 24, y + 9), mark, font=F, fill=INK)
    elif t == "Button":
        primary = a.get("primary") == "true"
        d.rounded_rectangle([x, y, x + w, y + 38], 6, fill=ACCENT if primary else "white",
                            outline=ACCENT if primary else INK)
        label = fit(d, text, FB, w - 12)
        d.text((x + (w - d.textlength(label, font=FB)) / 2, y + 10), label, font=FB,
               fill="white" if primary else INK)
    elif t == "Checkbox":
        d.rectangle([x, y + 3, x + 16, y + 19], outline=INK, fill="white")
        if a.get("checked") == "true":
            d.line([x + 3, y + 11, x + 7, y + 15, x + 13, y + 6], fill=ACCENT, width=3)
        d.text((x + 26, y + 2), fit(d, text, F, w - 26), font=F, fill=INK)
    elif t == "StatCard":
        d.rounded_rectangle([x, y, x + w, y + h], 8, fill=FILL, outline=LINE)
        d.text((x + PAD, y + 14), fit(d, a.get("label", ""), FS, w - 2 * PAD), font=FS, fill=MUTED)
        d.text((x + PAD, y + 40), fit(d, text, FBIG, w - 2 * PAD), font=FBIG, fill=INK)
    elif t == "Table":
        cols = a.get("columns", [])
        d.rectangle([x, y, x + w, y + 36], fill=FILL)
        rows = [cols] + [r.attrs().get("cells", []) for r in node.parts()]
        # ширина колонок пропорциональна самому длинному значению
        need = [max(d.textlength(r[j], font=FB if i == 0 else FS) for i, r in enumerate(rows) if j < len(r)) + 22
                for j in range(len(cols))]
        cws = [n * w / sum(need) for n in need]
        for i, row in enumerate(rows):
            ry = y + 36 * i
            cx = x
            for cell, cw in zip(row, cws):
                d.text((cx + 8, ry + 10), fit(d, cell, FB if i == 0 else FS, cw - 14),
                       font=FB if i == 0 else FS, fill=INK)
                cx += cw
            d.line([x, ry + 36, x + w, ry + 36], fill=LINE)
        d.rectangle([x, y, x + w, y + 36 * len(rows)], outline=LINE)
    elif t == "Chart":
        d.rectangle([x, y, x + w, y + h], fill=FILL, outline=LINE)
        d.text((x + 10, y + 8), fit(d, text, FS, w - 20), font=FS, fill=MUTED)
        kind = a.get("kind", "bar")
        bx, by, bw, bh = x + 30, y + 40, w - 60, h - 70
        if kind == "pie":
            r = min(bw, bh) / 2
            cx, cy = x + w / 2, by + bh / 2
            box = [cx - r, cy - r, cx + r, cy + r]
            for s, e, c in [(-90, 60, ACCENT), (60, 160, "#7fa8ea"), (160, 230, "#b8cdf3"), (230, 270, DARK)]:
                d.pieslice(box, s, e, fill=c, outline="white", width=2)
        else:
            d.line([bx, by, bx, by + bh, bx + bw, by + bh], fill=INK, width=2)
            vals = [52, 55, 55, 61, 64, 60, 72, 74, 79, 83, 85, 87]
            step = bw / len(vals)
            pts = []
            for i, v in enumerate(vals):
                px, top = bx + step * i + step * 0.2, by + bh - bh * v / 100
                if kind == "bar":
                    d.rectangle([px, top, px + step * 0.6, by + bh - 1], fill=ACCENT)
                pts.append((px + step * 0.3, top))
            if kind == "line":
                d.line(pts, fill=ACCENT, width=3)
                for p in pts:
                    d.ellipse([p[0] - 4, p[1] - 4, p[0] + 4, p[1] + 4], fill=ACCENT)
    else:  # Label, Link
        style = a.get("style", "normal")
        f, col = (FH, INK) if style == "heading" else (FS, MUTED) if style == "muted" else (F, INK)
        d.text((x, y + 3), fit(d, text, f, w), font=f, fill=ACCENT if t == "Link" else col)


def render_screen(node, path):
    a = node.attrs()
    chrome = 44
    body = height(node, W) + 2 * PAD
    img = Image.new("RGB", (W, chrome + body), "white")
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, W, chrome], fill="#e4e7eb")
    for i, c in enumerate(("#e66767", "#f0c05a", "#63c174")):
        d.ellipse([14 + i * 22, 15, 28 + i * 22, 29], fill=c)
    d.rounded_rectangle([90, 9, W - 330, 35], 12, fill="white")
    d.text((104, 14), a.get("url", ""), font=FS, fill=MUTED)
    title = a.get("title", "")
    d.text((W - 14 - d.textlength(title, font=FS), 14), title, font=FS, fill=INK)
    kids = node.parts()
    y = chrome
    if kids and kids[0].type() == "NavBar":      # меню — во всю ширину окна
        draw(d, kids[0], 0, y, W)
        y += height(kids[0], W) + PAD
        kids = kids[1:]
    else:
        y += PAD
    for k in kids:
        draw(d, k, PAD, y, W - 2 * PAD)
        y += height(k, W - 2 * PAD) + GAP
    img = img.crop((0, 0, W, y + PAD - GAP))
    ImageDraw.Draw(img).rectangle([0, 0, W - 1, img.height - 1], outline=LINE)
    img.save(path)


# ----------------------------------------------------------------- диаграммы

def dot(src, path):
    subprocess.run(["dot", "-Tpng", "-Gdpi=130", "-o", str(path)], input=src.encode("utf-8"), check=True)


BASE = ('graph [fontname="DejaVu Sans" bgcolor=white pad=0.3];\n'
        'node [fontname="DejaVu Sans" fontsize=12 style="rounded,filled" fillcolor="#f5f7fa" color="#52606d"];\n'
        'edge [fontname="DejaVu Sans" fontsize=10 color="#52606d" fontcolor="#323f4b"];\n')


def render_context(root, path):
    ctx = next(n for n in walk(root) if n.kind() == "part" and n.name() == "systemContext")
    shapes = {"Person": "shape=oval", "Database": "shape=cylinder", "ExternalService": 'shape=box style="rounded,dashed,filled"',
              "WebApplication": 'shape=box penwidth=2 fillcolor="#dbe7fb"'}
    out = ["digraph context {", "rankdir=LR; nodesep=0.6; ranksep=1.0;", BASE]
    for p in ctx.parts():
        out.append(f'{p.name()} [label="{p.doc}\\n«{p.type()}»" {shapes.get(p.type(), "shape=box")}];')
    for c in ctx.children:
        w = c.words
        if c.kind() == "connection":
            out.append(f'{w[w.index("connect") + 1]} -> {w[w.index("to") + 1]} [label="{c.doc}" dir=none];')
    out.append("}")
    dot("\n".join(out), path)


def render_flow(root, path):
    flow = next(n for n in walk(root) if n.kind() == "state def")
    out = ["digraph flow {", "rankdir=LR; nodesep=0.5; ranksep=0.9;", BASE,
           'start [shape=circle label="" width=0.22 fillcolor="#323f4b"];']
    first = None
    for c in flow.children:
        w = c.words
        if c.kind() == "then" and first is None:
            first = w[1]
        elif c.kind() == "state":
            out.append(f'{c.name()} [shape=box label="{c.doc}\\n{c.name()}"];')
        elif c.kind() == "transition":
            out.append(f'{w[w.index("first") + 1]} -> {w[w.index("then") + 1]} [label="{w[w.index("accept") + 1]}"];')
    out.append(f"start -> {first};")
    out.append("}")
    dot("\n".join(out), path)


def main():
    IMAGES.mkdir(exist_ok=True)
    mock = load("Mockups.sysml")
    screens = [n for n in walk(mock) if n.kind() == "part" and n.type() == "Screen"]
    for i, s in enumerate(screens, 1):
        name = re.sub(r"Screen$", "", s.name())
        name = re.sub(r"(?<!^)([A-Z])", r"-\1", name).lower()
        target = IMAGES / f"mockup-{i:02d}-{name}.png"
        render_screen(s, target)
        print("создан", target.relative_to(ROOT.parent))
    ctx = load("Context.sysml")
    for fn, target in ((render_context, "context.png"), (render_flow, "screen-flow.png")):
        try:
            fn(ctx, IMAGES / target)
            print("создан", (IMAGES / target).relative_to(ROOT.parent))
        except FileNotFoundError:
            print("Graphviz (dot) не найден — пропущено:", target, file=sys.stderr)


if __name__ == "__main__":
    main()
