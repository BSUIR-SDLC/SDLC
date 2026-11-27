"""Рендер моделей SysML v2 из sdd/models в PNG для документа SDD.

Использует разбор текстовой нотации и средства рисования из tools/sysml_render.py.
Поддерживаемые виды диаграмм:
  * блочные (part с вложенными part и connection) — композиция, развёртывание,
    модель данных; раскладка задаётся атрибутами x, y, w, h;
  * последовательность (occurrence def с message ... from A to B);
  * состояния (state def с state и transition first A accept E then B).

Использование:
    python tools/sdd_render.py            # все модели из sdd/models -> sdd/img
"""
from __future__ import annotations

import math
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sysml_render import (  # noqa: E402
    FILL, HEAD, INK, Node, arrow_head, dashed, font, frame, parse, parse_value, text_center, text_left, wrap,
)

ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / "sdd" / "models"
OUT = ROOT / "sdd" / "img"

HEAD_COLORS = {
    "client": (220, 252, 231), "system": (219, 234, 254), "core": (254, 243, 199),
    "store": (237, 233, 254), "ok": (187, 247, 208), "deny": (254, 202, 202),
}
SUB = (71, 85, 105)


def attrs(nd: Node) -> dict:
    """Атрибуты вида `attribute name = value;` и `:>> name = value;`."""
    res = {}
    for ch in nd.children:
        m = re.match(r"(?:attribute|:>>)\s*(\w+)\s*=\s*(.+)$", ch.head, re.S)
        if m:
            res[m.group(1)] = parse_value(m.group(2).strip())
    return res


def load(name: str) -> Node:
    return parse((MODELS / name).read_text(encoding="utf-8"))[0]


def defs_of(pkg: Node) -> dict[str, Node]:
    res = {}
    for nd in pkg.children:
        m = re.match(r"(?:part|occurrence|state|item|attribute) def\s+(\w+)", nd.head)
        if m:
            res[m.group(1)] = nd
    return res


def label(d, center, text, fnt=None, width=230):
    fnt = fnt or font(14)
    lines = wrap(d, text, fnt, width)
    lh = fnt.size * 1.25
    w = max(d.textlength(ln, font=fnt) for ln in lines)
    x, y = center
    y0 = y - lh * len(lines) / 2
    d.rectangle([x - w / 2 - 4, y0 - 2, x + w / 2 + 4, y0 + lh * len(lines) + 2], fill="white")
    for i, ln in enumerate(lines):
        lw = d.textlength(ln, font=fnt)
        d.text((x - lw / 2, y0 + i * lh), ln, font=fnt, fill=SUB)


def anchor(b, other):
    """Точка на границе прямоугольника b в сторону центра other."""
    cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
    ox, oy = (other[0] + other[2]) / 2, (other[1] + other[3]) / 2
    dx, dy = ox - cx, oy - cy
    if dx == 0 and dy == 0:
        return cx, cy
    hw, hh = (b[2] - b[0]) / 2, (b[3] - b[1]) / 2
    t = min(hw / abs(dx) if dx else math.inf, hh / abs(dy) if dy else math.inf)
    return cx + dx * t, cy + dy * t


# --------------------------------------------------------------------------- #
# Блочные диаграммы
# --------------------------------------------------------------------------- #
def render_blocks(model: str, out: str) -> Path:
    pkg = load(model)
    defs = defs_of(pkg)
    root = next(nd for nd in pkg.children if re.match(r"part\s+(?!def\b)\w+$", nd.head))
    ra = attrs(root)
    W, H = ra["w"], ra["h"]
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    frame(d, W, H, "ibd", ra["title"])

    boxes: dict[str, list] = {}
    items = []  # (путь, узел, тип, бокс, есть ли вложенные части)

    def collect(nd: Node, prefix: str, ox: float, oy: float):
        for ch in nd.children:
            m = re.match(r"part\s+(\w+)\s*:\s*(\w+)", ch.head)
            if not m:
                continue
            a = attrs(ch)
            x, y = ox + a["x"], oy + a["y"]
            typ = defs.get(m.group(2))
            if a.get("list"):
                rows = [c.head for c in typ.children if c.head.startswith("attribute ")]
                h = 62 + 24 * len(rows) + 10
            else:
                h = a["h"]
            box = [x, y, x + a["w"], y + h]
            path = prefix + m.group(1)
            boxes[path] = box
            nested = any(re.match(r"part\s+\w+\s*:", c.head) for c in ch.children)
            items.append((path, ch, m.group(2), box, nested, a, typ))
            collect(ch, path + ".", x, y)

    collect(root, "", 0, 0)

    def conns(nd: Node, prefix: str):
        for ch in nd.children:
            m = re.match(r"connection\s+\w+\s+connect\s+([\w.]+)\s+to\s+([\w.]+)", ch.head)
            if m:
                yield prefix + m.group(1), prefix + m.group(2), ch.doc, attrs(ch)
            mp = re.match(r"part\s+(\w+)\s*:", ch.head)
            if mp:
                yield from conns(ch, prefix + mp.group(1) + ".")

    links = list(conns(root, ""))

    # сначала контейнеры, затем линии, затем листовые блоки поверх
    def draw_block(path, nd, tname, box, nested, a, typ):
        stereo = a.get("stereo", "part")
        hf = HEAD_COLORS.get(a.get("color"), HEAD)
        name = f"{path.split('.')[-1]} : {tname}"
        x0, y0, x1, y1 = box
        d.rectangle(box, fill="white" if nested else FILL, outline=INK, width=3 if nested else 2)
        hh = 58 if not nested else 64
        d.rectangle([x0, y0, x1, y0 + hh], fill=hf, outline=INK, width=2)
        text_center(d, [x0, y0 + 4, x1, y0 + 26], f"«{stereo}»", font(15), INK)
        size = 17
        while size > 11 and d.textlength(name, font=font(size, True)) > x1 - x0 - 12:
            size -= 1
        text_center(d, [x0, y0 + 26, x1, y0 + hh - 2], name, font(size, True), INK)
        doc = nd.doc or (typ.doc if typ is not None else "")
        if a.get("list"):
            y = y0 + hh + 8
            for c in typ.children:
                ma = re.match(r"attribute\s+(\w+)\s*:\s*(\w+)", c.head)
                if ma:
                    t = ma.group(2).replace("_or_", "|").replace("_null", "?").replace("FK_", "→")
                    d.text((x0 + 12, y), ma.group(1), font=font(15, mono=True), fill=INK)
                    tw = d.textlength(t, font=font(14))
                    d.text((x1 - 12 - tw, y + 1), t, font=font(14), fill=SUB)
                    y += 24
        elif doc:
            text_left(d, (x0 + 12, y0 + hh + 8), doc, font(15 if not nested else 16), (51, 65, 85), width=x1 - x0 - 24)

    for it in items:
        if it[4]:
            draw_block(*it)
    labels = []
    for a, b, doc, la in links:
        p0, p1 = anchor(boxes[a], boxes[b]), anchor(boxes[b], boxes[a])
        d.line([p0, p1], fill=INK, width=2)
        arrow_head(d, p0, p1, 14, INK, open_=True, width=2)
        if doc:
            labels.append(((p0[0] + p1[0]) / 2 + la.get("lx", 0), (p0[1] + p1[1]) / 2 + la.get("ly", 0), doc))
    for it in items:
        if not it[4]:
            draw_block(*it)
    # подписи связей поверх блоков, чтобы короткие связи между соседями оставались читаемыми
    for mx, my, doc in labels:
        label(d, (mx, my), doc, width=200)
    path = OUT / out
    img.save(path)
    return path


# --------------------------------------------------------------------------- #
# Диаграмма последовательности
# --------------------------------------------------------------------------- #
def render_sequence(model: str, out: str) -> Path:
    pkg = load(model)
    occ = next(nd for nd in pkg.children if nd.head.startswith("occurrence def"))
    parts, msgs = [], []
    for ch in occ.children:
        m = re.match(r"part\s+(\w+)\s*:\s*(\w+)", ch.head)
        if m:
            parts.append((m.group(1), m.group(2)))
        m = re.match(r"message\s+(\w+)\s+of\s+(\w+)\s+from\s+(\w+)\s+to\s+(\w+)", ch.head)
        if m:
            msgs.append((m.group(1), m.group(2), m.group(3), m.group(4), ch.doc))
    W = 1900
    col = (W - 80) / len(parts)
    xs = {name: 40 + col * (i + 0.5) for i, (name, _) in enumerate(parts)}
    top, step = 90, 66
    H = int(top + 110 + step * len(msgs) + 60)
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    frame(d, W, H, "sd", "Проверка пропуска (UC-02)")
    bw = col - 24
    for name, typ in parts:
        x = xs[name]
        hf = HEAD_COLORS["core"] if typ == "ValidationService" else HEAD
        d.rectangle([x - bw / 2, top, x + bw / 2, top + 70], fill=hf, outline=INK, width=2)
        text_center(d, [x - bw / 2, top + 6, x + bw / 2, top + 34], name, font(16, True), INK)
        text_center(d, [x - bw / 2, top + 34, x + bw / 2, top + 64], ": " + typ, font(14), SUB)
        dashed(d, (x, top + 70), (x, H - 30), (148, 163, 184), width=2, dash=8, gap=6)
    y = top + 120
    for i, (mid, kind, a, b, doc) in enumerate(msgs, 1):
        xa, xb = xs[a], xs[b]
        txt = f"{i}. {doc}"
        reply = kind in ("Rows", "Decision", "Response")
        if a == b:
            d.line([(xa, y - 8), (xa + 40, y - 8), (xa + 40, y + 14), (xa + 6, y + 14)], fill=INK, width=2)
            arrow_head(d, (xa + 40, y + 14), (xa + 4, y + 14), 12, INK)
            text_left(d, (xa + 50, y - 22), txt, font(14), INK, width=330)
        else:
            if reply:
                dashed(d, (xa, y), (xb, y), INK, width=2)
                arrow_head(d, (xa, y), (xb, y), 13, INK, open_=True, width=2)
            else:
                d.line([(xa, y), (xb, y)], fill=INK, width=2)
                arrow_head(d, (xa, y), (xb, y), 13, INK)
            fnt = font(14)
            span = abs(xb - xa) - 16
            lines = wrap(d, txt, fnt, max(span, 300))
            ty = y - 6 - 18 * len(lines)
            for ln in lines:
                lw = d.textlength(ln, font=fnt)
                cx = (xa + xb) / 2
                d.rectangle([cx - lw / 2 - 2, ty, cx + lw / 2 + 2, ty + 18], fill="white")
                d.text((cx - lw / 2, ty), ln, font=fnt, fill=INK)
                ty += 18
        y += step
    path = OUT / out
    img.save(path)
    return path


# --------------------------------------------------------------------------- #
# Диаграмма состояний
# --------------------------------------------------------------------------- #
def render_states(model: str, out: str) -> Path:
    pkg = load(model)
    sd = next(nd for nd in pkg.children if nd.head.startswith("state def"))
    ra = attrs(sd)
    W, H = ra["w"], ra["h"]
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    frame(d, W, H, "stm", ra["title"])
    sw, sh = 300, 130
    boxes, states, trans, initial = {}, [], [], None
    for ch in sd.children:
        m = re.match(r"state\s+(\w+)$", ch.head)
        if m:
            a = attrs(ch)
            boxes[m.group(1)] = [a["x"], a["y"], a["x"] + sw, a["y"] + sh]
            states.append((m.group(1), ch.doc, a))
        m = re.match(r"then\s+(\w+)$", ch.head)
        if m:
            initial = m.group(1)
        m = re.match(r"transition\s+\w+\s+first\s+(\w+)\s+accept\s+(\w+)\s+then\s+(\w+)", ch.head)
        if m:
            trans.append((m.group(1), m.group(2), m.group(3), ch.doc, attrs(ch)))
    pairs = {(a, b) for a, _, b, _, _ in trans}
    labels = []
    for a, ev, b, doc, la in trans:
        p0, p1 = anchor(boxes[a], boxes[b]), anchor(boxes[b], boxes[a])
        nx = ny = 0.0
        if (b, a) in pairs:  # встречные переходы разводим параллельно, подписи — по разные стороны
            ang = math.atan2(p1[1] - p0[1], p1[0] - p0[0])
            nx, ny = -math.sin(ang), math.cos(ang)
            p0, p1 = (p0[0] + nx * 16, p0[1] + ny * 16), (p1[0] + nx * 16, p1[1] + ny * 16)
        d.line([p0, p1], fill=INK, width=2)
        arrow_head(d, p0, p1, 15, INK)
        t = la.get("t", 50) / 100  # положение подписи вдоль перехода, % от начала
        mx = p0[0] + (p1[0] - p0[0]) * t + nx * 95 + la.get("lx", 0)
        my = p0[1] + (p1[1] - p0[1]) * t + ny * 40 + la.get("ly", 0)
        labels.append((mx, my, f"{ev} / {doc}"))
    if initial:
        bx = boxes[initial]
        c = (bx[0] + sw / 2, bx[1] - 60)
        d.ellipse([c[0] - 13, c[1] - 13, c[0] + 13, c[1] + 13], fill=INK)
        d.line([(c[0], c[1] + 13), (c[0], bx[1])], fill=INK, width=2)
        arrow_head(d, (c[0], c[1]), (c[0], bx[1]), 14, INK)
    for name, doc, a in states:
        x0, y0, x1, y1 = boxes[name]
        hf = HEAD_COLORS.get(a.get("color"), HEAD)
        d.rounded_rectangle(boxes[name], radius=22, fill=FILL, outline=INK, width=2)
        d.rounded_rectangle([x0, y0, x1, y0 + 42], radius=22, fill=hf, outline=INK, width=2)
        d.rectangle([x0 + 2, y0 + 22, x1 - 2, y0 + 41], fill=hf)
        d.line([(x0, y0 + 42), (x1, y0 + 42)], fill=INK, width=2)
        text_center(d, [x0, y0 + 4, x1, y0 + 40], name, font(17, True), INK)
        text_center(d, [x0 + 6, y0 + 46, x1 - 6, y1 - 4], doc, font(16), (51, 65, 85))
    for mx, my, txt in labels:
        label(d, (mx, my), txt, font(14), width=170)
    path = OUT / out
    img.save(path)
    return path


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    files = [
        render_blocks("qrgate-components.sysml", "components-diagram.png"),
        render_blocks("qrgate-deployment.sysml", "deployment-diagram.png"),
        render_blocks("qrgate-data.sysml", "data-model.png"),
        render_sequence("qrgate-validate-sequence.sysml", "validate-sequence.png"),
        render_states("qrgate-scanner-states.sysml", "scanner-states.png"),
    ]
    for f in files:
        print(f.relative_to(ROOT))


if __name__ == "__main__":
    main()
