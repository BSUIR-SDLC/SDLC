"""Рендер моделей SysML v2 (текстовая нотация) проекта QRGate в PNG.

Поддерживается подмножество языка, которое используется в srs/models:
  * part def / part / attribute-переопределения вида `:>> name = value;`
  * doc-комментарии, connection ... connect A to B, use case, requirement,
    #derivation connection, satisfy.

Использование:
    python tools/sysml_render.py            # все модели из srs/models -> srs/img
"""
from __future__ import annotations

import math
import re
from dataclasses import dataclass, field
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
MODELS = ROOT / "srs" / "models"
OUT = ROOT / "srs" / "img"


def first_font(*candidates: str) -> Path:
    """Первый существующий шрифт: Windows, затем Linux (DejaVu), затем macOS."""
    for c in candidates:
        if Path(c).exists():
            return Path(c)
    raise FileNotFoundError("Не найден шрифт с кириллицей, проверьте пути: " + ", ".join(candidates))


FONT_REG = first_font("C:/Windows/Fonts/segoeui.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
                      "/System/Library/Fonts/Supplemental/Arial.ttf")
FONT_BOLD = first_font("C:/Windows/Fonts/segoeuib.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
                       "/System/Library/Fonts/Supplemental/Arial Bold.ttf")
FONT_MONO = first_font("C:/Windows/Fonts/consola.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
                       "/System/Library/Fonts/Supplemental/Courier New.ttf")


# --------------------------------------------------------------------------- #
# Разбор текстовой нотации SysML v2
# --------------------------------------------------------------------------- #
@dataclass
class Node:
    head: str
    children: list["Node"] = field(default_factory=list)
    doc: str = ""

    @property
    def attrs(self) -> dict:
        res = {}
        for ch in self.children:
            m = re.match(r":>>\s*(\w+)\s*=\s*(.+)$", ch.head, re.S)
            if m:
                res[m.group(1)] = parse_value(m.group(2).strip())
        return res


def parse_value(raw: str):
    if raw.startswith('"'):
        return raw[1:-1].replace('\\\\', '\\').replace('\\"', '"')
    try:
        return int(raw)
    except ValueError:
        return raw


def clean_doc(comment: str) -> str:
    body = comment[2:-2]
    lines = [re.sub(r"^\s*\*\s?", "", ln).strip() for ln in body.splitlines()]
    return " ".join(ln for ln in lines if ln)


def parse(text: str) -> list[Node]:
    pos = 0
    n = len(text)

    def block() -> list[Node]:
        nonlocal pos
        nodes: list[Node] = []
        head = ""
        doc = ""
        while pos < n:
            c = text[pos]
            if text.startswith("//", pos):
                pos = text.find("\n", pos)
                pos = n if pos < 0 else pos
                continue
            if text.startswith("/*", pos):
                end = text.index("*/", pos) + 2
                comment = text[pos:end]
                pos = end
                if head.strip() == "doc":
                    # doc-комментарий относится к владеющему элементу
                    nodes.append(Node("doc", doc=clean_doc(comment)))
                    head = ""
                else:
                    doc = clean_doc(comment)
                continue
            if c == '"':
                end = pos + 1
                while text[end] != '"':
                    end += 2 if text[end] == "\\" else 1
                head += text[pos:end + 1]
                pos = end + 1
                continue
            if c == ";":
                nodes.append(Node(" ".join(head.split()), doc=doc))
                head, doc = "", ""
                pos += 1
                continue
            if c == "{":
                pos += 1
                children = block()
                node = Node(" ".join(head.split()), children)
                node.doc = next((ch.doc for ch in children if ch.head == "doc"), doc)
                nodes.append(node)
                head, doc = "", ""
                continue
            if c == "}":
                pos += 1
                return nodes
            head += c
            pos += 1
        return nodes

    return block()


def load(name: str) -> list[Node]:
    return parse((MODELS / name).read_text(encoding="utf-8"))


# --------------------------------------------------------------------------- #
# Общие средства рисования
# --------------------------------------------------------------------------- #
_fonts: dict = {}


def font(size: float, bold: bool = False, mono: bool = False):
    key = (round(size), bold, mono)
    if key not in _fonts:
        path = FONT_MONO if mono else (FONT_BOLD if bold else FONT_REG)
        _fonts[key] = ImageFont.truetype(str(path), round(size))
    return _fonts[key]


def wrap(draw: ImageDraw.ImageDraw, text: str, fnt, width: float) -> list[str]:
    lines: list[str] = []
    for para in text.split("\n"):
        cur = ""
        for word in para.split(" "):
            probe = (cur + " " + word).strip()
            if draw.textlength(probe, font=fnt) <= width or not cur:
                cur = probe
            else:
                lines.append(cur)
                cur = word
        lines.append(cur)
    return lines


def text_center(draw, box, text, fnt, fill, spacing=1.15):
    x0, y0, x1, y1 = box
    lines = wrap(draw, text, fnt, x1 - x0 - 8)
    lh = fnt.size * spacing
    y = (y0 + y1) / 2 - lh * len(lines) / 2
    for ln in lines:
        w = draw.textlength(ln, font=fnt)
        draw.text(((x0 + x1) / 2 - w / 2, y), ln, font=fnt, fill=fill)
        y += lh


def text_left(draw, xy, text, fnt, fill, width=None, spacing=1.2):
    x, y = xy
    lines = wrap(draw, text, fnt, width) if width else [text]
    for ln in lines:
        draw.text((x, y), ln, font=fnt, fill=fill)
        y += fnt.size * spacing
    return y


def arrow_head(draw, p_from, p_to, size, fill, open_=False, width=2):
    ang = math.atan2(p_to[1] - p_from[1], p_to[0] - p_from[0])
    a1 = (p_to[0] - size * math.cos(ang - 0.4), p_to[1] - size * math.sin(ang - 0.4))
    a2 = (p_to[0] - size * math.cos(ang + 0.4), p_to[1] - size * math.sin(ang + 0.4))
    if open_:
        draw.line([a1, p_to, a2], fill=fill, width=width)
    else:
        draw.polygon([p_to, a1, a2], fill=fill)


def dashed(draw, p0, p1, fill, width=2, dash=10, gap=7):
    length = math.dist(p0, p1)
    if length == 0:
        return
    dx, dy = (p1[0] - p0[0]) / length, (p1[1] - p0[1]) / length
    t = 0.0
    while t < length:
        e = min(t + dash, length)
        draw.line([(p0[0] + dx * t, p0[1] + dy * t), (p0[0] + dx * e, p0[1] + dy * e)], fill=fill, width=width)
        t = e + gap


# --------------------------------------------------------------------------- #
# Мокапы GUI (qrgate-ui.sysml)
# --------------------------------------------------------------------------- #
C = {
    "bg": (245, 247, 250), "white": (255, 255, 255), "border": (208, 214, 222),
    "text": (33, 37, 41), "muted": (108, 117, 125), "primary": (37, 99, 235),
    "primary_dark": (29, 78, 216), "ok": (22, 163, 74), "ok_bg": (220, 252, 231),
    "deny": (220, 38, 38), "deny_bg": (254, 226, 226), "warn": (180, 83, 9),
    "warn_bg": (254, 243, 199), "dark": (17, 24, 39), "nav": (30, 41, 59),
}


class Mockup:
    def __init__(self, root: Node, defs: dict[str, str]):
        self.root = root
        self.defs = defs  # имя part def -> базовый тип

    def render(self, path: Path):
        m = re.match(r"part\s+(\w+)\s*:\s*(\w+)", self.root.head)
        typ = m.group(2)
        a = self.root.attrs
        s = 2.0 if typ == "PhoneScreen" else 1.5
        self.s = s
        W, H = a["w"], a["h"]
        if typ == "PhoneScreen":
            pad, top = 18, 40
            img = Image.new("RGB", (int((W + 2 * pad) * s), int((H + top + 40) * s)), (255, 255, 255))
            d = ImageDraw.Draw(img)
            d.rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius=int(48 * s), fill=C["dark"])
            ox, oy = pad * s, top * s
            d.rounded_rectangle([ox, oy, ox + W * s, oy + H * s], radius=int(12 * s), fill=C["bg"])
            d.rounded_rectangle([img.width / 2 - 50 * s, 14 * s, img.width / 2 + 50 * s, 26 * s], radius=int(6 * s), fill=(55, 65, 81))
        else:
            bar = 44
            img = Image.new("RGB", (int(W * s), int((H + bar) * s)), C["bg"])
            d = ImageDraw.Draw(img)
            d.rectangle([0, 0, img.width, bar * s], fill=(229, 231, 235))
            for i, col in enumerate([(239, 68, 68), (245, 158, 11), (34, 197, 94)]):
                cx = (18 + i * 20) * s
                d.ellipse([cx - 6 * s, 16 * s, cx + 6 * s, 28 * s], fill=col)
            d.rounded_rectangle([90 * s, 8 * s, (W - 20) * s, 36 * s], radius=int(8 * s), fill=C["white"])
            d.text((104 * s, 12 * s), a.get("text", ""), font=font(14 * s), fill=C["muted"])
            ox, oy = 0, bar * s
        self.d = d
        self.img = img
        for ch in self.root.children:
            self.widget(ch, ox, oy)
        img.save(path)

    def widget(self, nd: Node, ox: float, oy: float):
        m = re.match(r"part\s+(\w+)\s*:\s*(\w+)", nd.head)
        if not m:
            return
        typ = m.group(2)
        a = nd.attrs
        s, d = self.s, self.d
        x0, y0 = ox + a["x"] * s, oy + a["y"] * s
        x1, y1 = x0 + a["w"] * s, y0 + a["h"] * s
        t = a.get("text", "")
        box = [x0, y0, x1, y1]
        r = int(8 * s)

        if typ == "AppBar":
            d.rectangle(box, fill=C["primary"])
            title, _, sub = t.partition("|")
            d.text((x0 + 16 * s, y0 + 14 * s), title.strip(), font=font(19 * s, True), fill=C["white"])
            d.text((x0 + 104 * s, y0 + 17 * s), sub.strip(), font=font(15 * s), fill=(219, 234, 254))
        elif typ == "Toggle":
            opts = t.split("|")
            d.rounded_rectangle(box, radius=r, fill=(226, 232, 240))
            ww = (x1 - x0) / len(opts)
            for i, o in enumerate(opts):
                b = [x0 + i * ww + 3 * s, y0 + 3 * s, x0 + (i + 1) * ww - 3 * s, y1 - 3 * s]
                sel = i == a.get("selected", 0)
                if sel:
                    d.rounded_rectangle(b, radius=r, fill=C["ok"] if i == 0 else C["primary"])
                text_center(d, b, o, font(16 * s, True), C["white"] if sel else C["muted"])
        elif typ == "CameraView":
            d.rounded_rectangle(box, radius=r, fill=(31, 41, 55))
            # имитация изображения с камеры: QR-код посередине
            cx, cy = (x0 + x1) / 2, (y0 + y1) / 2 - 10 * s
            q = 150 * s
            d.rectangle([cx - q / 2, cy - q / 2, cx + q / 2, cy + q / 2], fill=(229, 231, 235))
            import random
            rnd = random.Random(7)
            cell = q / 21
            for i in range(21):
                for j in range(21):
                    origin = next(((i0, j0) for i0, j0 in [(0, 0), (0, 14), (14, 0)]
                                   if i0 <= i < i0 + 7 and j0 <= j < j0 + 7), None)
                    if origin:
                        ii, jj = i - origin[0], j - origin[1]
                        on = ii in (0, 6) or jj in (0, 6) or (2 <= ii <= 4 and 2 <= jj <= 4)
                    else:
                        on = rnd.random() < 0.45
                    if on:
                        px, py = cx - q / 2 + j * cell, cy - q / 2 + i * cell
                        d.rectangle([px, py, px + cell, py + cell], fill=(17, 24, 39))
            # уголки рамки наведения
            f = 110 * s
            L = 34 * s
            for sx in (-1, 1):
                for sy in (-1, 1):
                    px, py = cx + sx * f, cy + sy * f
                    d.line([(px, py), (px - sx * L, py)], fill=(74, 222, 128), width=int(5 * s))
                    d.line([(px, py), (px, py - sy * L)], fill=(74, 222, 128), width=int(5 * s))
            d.line([(cx - f + 8 * s, cy + 20 * s), (cx + f - 8 * s, cy + 20 * s)], fill=(74, 222, 128), width=int(2 * s))
            text_center(d, [x0, y1 - 50 * s, x1, y1 - 10 * s], t, font(15 * s), (229, 231, 235))
        elif typ == "StatusCard":
            tone = a.get("tone", "ok")
            col, bg = (C["ok"], C["ok_bg"]) if tone == "ok" else (C["deny"], C["deny_bg"])
            d.rounded_rectangle(box, radius=int(14 * s), fill=bg, outline=col, width=int(3 * s))
            cx, cy, rr = (x0 + x1) / 2, y0 + 62 * s, 34 * s
            d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=col)
            if tone == "ok":
                d.line([(cx - 16 * s, cy), (cx - 4 * s, cy + 13 * s), (cx + 18 * s, cy - 12 * s)], fill=C["white"], width=int(7 * s), joint="curve")
            else:
                for sg in (-1, 1):
                    d.line([(cx - 14 * s, cy - sg * 14 * s), (cx + 14 * s, cy + sg * 14 * s)], fill=C["white"], width=int(7 * s))
            head, _, sub = t.partition("|")
            text_center(d, [x0, y0 + 104 * s, x1, y0 + 140 * s], head, font(24 * s, True), col)
            text_center(d, [x0 + 10 * s, y0 + 144 * s, x1 - 10 * s, y1 - 10 * s], sub, font(15 * s), C["text"])
        elif typ in ("Button", "PrimaryButton"):
            if typ == "PrimaryButton":
                d.rounded_rectangle(box, radius=r, fill=C["primary"])
                text_center(d, box, t, font(16 * s, True), C["white"])
            else:
                d.rounded_rectangle(box, radius=r, fill=C["white"], outline=C["border"], width=int(1.5 * s))
                text_center(d, box, t, font(15 * s), C["text"])
        elif typ in ("TextBox", "ComboBox"):
            d.rounded_rectangle(box, radius=int(6 * s), fill=C["white"], outline=C["border"], width=int(1.5 * s))
            d.text((x0 + 10 * s, y0 + (y1 - y0) / 2 - 10 * s), t, font=font(14 * s), fill=C["text"])
            if typ == "ComboBox":
                ax = x1 - 18 * s
                ay = (y0 + y1) / 2
                d.polygon([(ax - 6 * s, ay - 3 * s), (ax + 6 * s, ay - 3 * s), (ax, ay + 4 * s)], fill=C["muted"])
        elif typ in ("Label", "MutedLabel", "ValueLabel", "TitleLabel"):
            fnt = {"Label": font(15 * s), "MutedLabel": font(13 * s), "ValueLabel": font(16 * s, True),
                   "TitleLabel": font(22 * s, True)}[typ]
            col = C["muted"] if typ == "MutedLabel" else C["text"]
            d.text((x0, y0 + 2 * s), t, font=fnt, fill=col)
        elif typ == "NavMenu":
            d.rectangle(box, fill=C["nav"])
            d.text((x0 + 20 * s, y0 + 18 * s), "QRGate", font=font(22 * s, True), fill=C["white"])
            d.text((x0 + 20 * s, y0 + 50 * s), "Администратор", font=font(13 * s), fill=(148, 163, 184))
            for i, item in enumerate(t.split("|")):
                iy = y0 + (96 + i * 46) * s
                if i == a.get("selected", 0):
                    d.rounded_rectangle([x0 + 10 * s, iy, x1 - 10 * s, iy + 38 * s], radius=r, fill=C["primary"])
                d.text((x0 + 24 * s, iy + 8 * s), item, font=font(15 * s), fill=C["white"])
        elif typ == "Banner":
            d.rounded_rectangle(box, radius=r, fill=C["warn_bg"], outline=(251, 191, 36), width=int(1.5 * s))
            d.text((x0 + 14 * s, y0 + 7 * s), "!  " + t, font=font(15 * s), fill=C["warn"])
        elif typ == "KpiCard":
            cap, _, val = t.partition("|")
            d.rounded_rectangle(box, radius=r, fill=C["white"], outline=C["border"], width=int(1.5 * s))
            d.text((x0 + 16 * s, y0 + 12 * s), cap, font=font(14 * s), fill=C["muted"])
            d.text((x0 + 16 * s, y0 + 34 * s), val, font=font(30 * s, True), fill=C["text"])
        elif typ == "LineChart":
            self.chart(box, a)
        elif typ == "Table":
            self.table(box, a)
        for ch in nd.children:
            self.widget(ch, x0, y0)

    def chart(self, box, a):
        s, d = self.s, self.d
        x0, y0, x1, y1 = box
        d.rounded_rectangle(box, radius=int(8 * s), fill=C["white"], outline=C["border"], width=int(1.5 * s))
        d.text((x0 + 16 * s, y0 + 10 * s), a.get("text", ""), font=font(15 * s, True), fill=C["text"])
        pts = [p.split("=") for p in a["points"].split(";")]
        cap, thr = a["capacity"], a["threshold"]
        px0, py0, px1, py1 = x0 + 56 * s, y0 + 44 * s, x1 - 150 * s, y1 - 36 * s
        vmax = cap * 1.1

        def ty(v):
            return py1 - (py1 - py0) * v / vmax

        for v in range(0, int(vmax) + 1, 100):
            d.line([(px0, ty(v)), (px1, ty(v))], fill=(235, 238, 242), width=int(s))
            lbl = str(v)
            d.text((px0 - 8 * s - d.textlength(lbl, font=font(12 * s)), ty(v) - 8 * s), lbl, font=font(12 * s), fill=C["muted"])
        step = (px1 - px0) / (len(pts) - 1)
        xy = [(px0 + i * step, ty(int(v))) for i, (_, v) in enumerate(pts)]
        d.polygon(xy + [(xy[-1][0], py1), (xy[0][0], py1)], fill=(219, 234, 254))
        d.line(xy, fill=C["primary"], width=int(3 * s), joint="curve")
        for i, (tm, _) in enumerate(pts):
            if i % 2 == 0:
                w = d.textlength(tm, font=font(12 * s))
                d.text((xy[i][0] - w / 2, py1 + 8 * s), tm, font=font(12 * s), fill=C["muted"])
        lx, ly = xy[-1]
        d.ellipse([lx - 6 * s, ly - 6 * s, lx + 6 * s, ly + 6 * s], fill=C["primary"], outline=C["white"], width=int(2 * s))
        dashed(d, (px0, ty(cap)), (px1, ty(cap)), C["deny"], width=int(2 * s), dash=10 * s, gap=6 * s)
        dashed(d, (px0, ty(thr)), (px1, ty(thr)), (245, 158, 11), width=int(2 * s), dash=10 * s, gap=6 * s)
        lg = font(13 * s)
        d.text((px1 + 12 * s, ty(cap) - 9 * s), f"Вместимость {cap}", font=lg, fill=C["deny"])
        d.text((px1 + 12 * s, ty(thr) - 9 * s), f"Порог 90 % ({thr})", font=lg, fill=C["warn"])
        d.text((px1 + 12 * s, ly - 9 * s), f"Сейчас {pts[-1][1]}", font=font(13 * s, True), fill=C["primary"])
        d.ellipse([x1 - 92 * s, y0 + 15 * s, x1 - 82 * s, y0 + 25 * s], fill=C["ok"])
        d.text((x1 - 76 * s, y0 + 10 * s), "LIVE", font=font(13 * s, True), fill=C["ok"])

    def table(self, box, a):
        s, d = self.s, self.d
        x0, y0, x1, y1 = box
        cols = a["columns"].split("|")
        rows = [r.split("|") for r in a["rows"].split(";")]
        d.rounded_rectangle(box, radius=int(8 * s), fill=C["white"], outline=C["border"], width=int(1.5 * s))
        weights = [max(len(c), *(len(r[i]) for r in rows)) + 4 for i, c in enumerate(cols)]
        tot = sum(weights)
        xs = [x0]
        for wgt in weights:
            xs.append(xs[-1] + (x1 - x0) * wgt / tot)
        rh = min(34 * s, (y1 - y0) / (len(rows) + 1))
        d.rectangle([x0 + 1, y0 + 1, x1 - 1, y0 + rh], fill=(241, 245, 249))
        for i, c in enumerate(cols):
            d.text((xs[i] + 10 * s, y0 + rh / 2 - 9 * s), c, font=font(13 * s, True), fill=C["muted"])
        for ri, row in enumerate(rows):
            ry = y0 + rh * (ri + 1)
            d.line([(x0, ry), (x1, ry)], fill=(235, 238, 242), width=int(s))
            for i, cell in enumerate(row):
                col = C["text"]
                if cell.startswith("Разрешено"):
                    col = C["ok"]
                elif cell.startswith("Отказ"):
                    col = C["deny"]
                d.text((xs[i] + 10 * s, ry + rh / 2 - 9 * s), cell, font=font(13 * s), fill=col)


def render_ui():
    nodes = load("qrgate-ui.sysml")
    pkg = nodes[0]
    defs = {}
    for nd in pkg.children:
        m = re.match(r"(?:abstract\s+)?part def\s+(\w+)(?:\s*:>\s*(\w+))?", nd.head)
        if m:
            defs[m.group(1)] = m.group(2) or ""
    files = []
    for nd in pkg.children:
        m = re.match(r"part\s+(\w+)\s*:\s*(PhoneScreen|BrowserWindow)", nd.head)
        if m:
            out = OUT / f"ui-{camel_to_kebab(m.group(1))}.png"
            Mockup(nd, defs).render(out)
            files.append(out)
    return files


def camel_to_kebab(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "-", name).lower()


# --------------------------------------------------------------------------- #
# Диаграммы SysML: блоки, варианты использования, требования
# --------------------------------------------------------------------------- #
INK = (30, 41, 59)
FILL = (248, 250, 252)
HEAD = (226, 232, 240)


def block(d, box, stereo, name, doc="", head_fill=HEAD):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=FILL, outline=INK, width=2)
    d.rectangle([x0, y0, x1, y0 + 56], fill=head_fill, outline=INK, width=2)
    text_center(d, [x0, y0 + 4, x1, y0 + 26], f"«{stereo}»", font(15), INK)
    text_center(d, [x0, y0 + 26, x1, y0 + 54], name, font(18, True), INK)
    if doc:
        text_left(d, (x0 + 12, y0 + 66), doc, font(15), (51, 65, 85), width=x1 - x0 - 24)


def frame(d, W, H, kind, title):
    d.rectangle([10, 10, W - 10, H - 10], outline=INK, width=2)
    label = f"{kind} [{title}]"
    tw = d.textlength(label, font=font(17, True))
    d.polygon([(10, 10), (30 + tw, 10), (30 + tw, 34), (18 + tw, 44), (10, 44)], fill=(241, 245, 249), outline=INK)
    d.text((20, 15), label, font=font(17, True), fill=INK)


def render_context():
    pkg = load("qrgate-context.sysml")[0]
    defs = {}
    for nd in pkg.children:
        m = re.match(r"part def\s+(\w+)", nd.head)
        if m:
            defs[m.group(1)] = nd.doc
    ctx = next(nd for nd in pkg.children if re.match(r"part\s+(?!def\b)\w+$", nd.head))
    parts, conns = {}, []
    for nd in ctx.children:
        m = re.match(r"part\s+(\w+)\s*:\s*(\w+)", nd.head)
        if m:
            parts[m.group(1)] = m.group(2)
        m = re.match(r"connection\s+\w+\s+connect\s+(\w+)\s+to\s+(\w+)", nd.head)
        if m:
            conns.append((m.group(1), m.group(2), nd.doc))

    W, H = 1700, 1000
    bw, bh = 330, 190
    layout = {  # раскладка блоков по колонкам: люди слева, система в центре, сервисы справа
        "visitor": (60, 90), "controller": (60, 400), "admin": (60, 710),
        "qrgate": (690, 400), "db": (1300, 230), "mail": (1300, 590),
    }
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    frame(d, W, H, "ibd", "Контекст системы QRGate")
    boxes = {}
    for name, (x, y) in layout.items():
        boxes[name] = [x, y, x + bw, y + bh]

    def anchor(b, other):
        cx, cy = (b[0] + b[2]) / 2, (b[1] + b[3]) / 2
        ox, oy = (other[0] + other[2]) / 2, (other[1] + other[3]) / 2
        if abs(ox - cx) > abs(oy - cy):
            return (b[2] if ox > cx else b[0], cy)
        return (cx, b[3] if oy > cy else b[1])

    for a, b, doc in conns:
        p0, p1 = anchor(boxes[a], boxes[b]), anchor(boxes[b], boxes[a])
        d.line([p0, p1], fill=INK, width=2)
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        lines = wrap(d, doc, font(14), 230)
        lh = 18
        bx0 = mx - 120
        by0 = my - lh * len(lines) / 2 - 4
        d.rectangle([bx0, by0, mx + 120, by0 + lh * len(lines) + 8], fill="white")
        y = by0 + 4
        for ln in lines:
            w = d.textlength(ln, font=font(14))
            d.text((mx - w / 2, y), ln, font=font(14), fill=(71, 85, 105))
            y += lh
    for name, box in boxes.items():
        typ = parts[name]
        hf = (191, 219, 254) if typ == "QRGate" else HEAD
        block(d, box, "part", f"{name} : {typ}", defs.get(typ, ""), head_fill=hf)
    path = OUT / "context-diagram.png"
    img.save(path)
    return path


def stick(d, cx, top, name):
    d.ellipse([cx - 18, top, cx + 18, top + 36], outline=INK, width=3)
    d.line([(cx, top + 36), (cx, top + 96)], fill=INK, width=3)
    d.line([(cx - 34, top + 56), (cx + 34, top + 56)], fill=INK, width=3)
    d.line([(cx, top + 96), (cx - 28, top + 140)], fill=INK, width=3)
    d.line([(cx, top + 96), (cx + 28, top + 140)], fill=INK, width=3)
    text_center(d, [cx - 110, top + 146, cx + 110, top + 172], name, font(17, True), INK)


def render_usecases():
    pkg = load("qrgate-usecases.sysml")[0]
    actor_of = {}
    for nd in pkg.children:
        m = re.match(r"use case def\s+(\w+)", nd.head)
        if m:
            for ch in nd.children:
                ma = re.match(r"actor\s+\w+\s*:\s*(\w+)", ch.head)
                if ma:
                    actor_of[m.group(1)] = ma.group(1)
    ucs = []
    for nd in pkg.children:
        m = re.match(r"use case\s+<'([^']+)'>\s+(\w+)\s*:\s*(\w+)", nd.head)
        if m:
            ucs.append((m.group(1), nd.doc, actor_of[m.group(3)]))

    W, H = 1500, 1000
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    frame(d, W, H, "uc", "Варианты использования QRGate")
    sx0, sy0, sx1, sy1 = 330, 80, 1170, 960
    d.rectangle([sx0, sy0, sx1, sy1], outline=INK, width=2, fill=(250, 251, 253))
    text_center(d, [sx0, sy0 + 8, sx1, sy0 + 40], "«subject» QRGate", font(19, True), INK)
    actors = list(dict.fromkeys(a for *_, a in ucs))
    sides = {actors[0]: "left", actors[1]: "right"}
    names = {"Controller": "Контролёр", "Administrator": "Администратор"}
    groups = {a: [u for u in ucs if u[2] == a] for a in actors}
    pos = {}
    for a, items in groups.items():
        n = len(items)
        top = sy0 + 70
        gap = (sy1 - top - 30) / n
        for i, (uid, doc, _) in enumerate(items):
            cy = top + gap * (i + 0.5)
            cx = sx0 + 230 if sides[a] == "left" else sx1 - 230
            pos[uid] = (cx, cy)
    act_pos = {}
    for a in actors:
        cx = 170 if sides[a] == "left" else W - 170
        act_pos[a] = (cx, H / 2 - 90)
    for uid, doc, a in ucs:
        cx, cy = pos[uid]
        ax, ay = act_pos[a]
        edge = cx - 190 if sides[a] == "left" else cx + 190
        d.line([(ax + (40 if sides[a] == "left" else -40), ay + 56), (edge, cy)], fill=INK, width=2)
    for uid, doc, a in ucs:
        cx, cy = pos[uid]
        d.ellipse([cx - 190, cy - 52, cx + 190, cy + 52], fill=(239, 246, 255), outline=INK, width=2)
        text_center(d, [cx - 160, cy - 44, cx + 160, cy - 14], uid, font(15, True), (37, 99, 235))
        text_center(d, [cx - 165, cy - 18, cx + 165, cy + 44], doc, font(16), INK)
    for a in actors:
        stick(d, act_pos[a][0], act_pos[a][1], names.get(a, a))
    path = OUT / "usecase-diagram.png"
    img.save(path)
    return path


def render_requirements():
    pkg = load("qrgate-requirements.sysml")[0]
    reqs = {}
    order = []
    for nd in pkg.children:
        m = re.match(r"requirement\s+<'([^']+)'>\s+(\w+)\s*:\s*(\w+)", nd.head)
        if m:
            reqs[m.group(2)] = (m.group(1), m.group(3), nd.doc)
            order.append(m.group(2))
    derivs, sats = [], []
    for nd in pkg.children:
        if nd.head.startswith("#derivation"):
            ends = {}
            for ch in nd.children:
                me = re.match(r"end\s+#(\w+)\s*::>\s*(\w+)", ch.head)
                if me:
                    ends[me.group(1)] = me.group(2)
            derivs.append((ends["original"], ends["derive"]))
        m = re.match(r"satisfy\s+(\w+)\s+by\s+(\w+)", nd.head)
        if m:
            sats.append(m.group(1))
            satisfier = m.group(2)
    sys_type = next(re.match(r"part\s+\w+\s*:\s*(\w+)", nd.head).group(1) for nd in pkg.children
                    if re.match(rf"part\s+{satisfier}\s*:", nd.head))

    goals = [r for r in order if reqs[r][1] == "BusinessGoal"]
    others = [r for r in order if r not in goals]
    # упорядочиваем требования под их бизнес-целями, чтобы линии не пересекались
    parent = {der: orig for orig, der in derivs}
    others.sort(key=lambda r: goals.index(parent[r]) if r in parent else len(goals))

    bw, bh, gap = 250, 170, 26
    W = len(others) * (bw + gap) + 80
    H = 1080
    img = Image.new("RGB", (W, H), "white")
    d = ImageDraw.Draw(img)
    frame(d, W, H, "req", "Требования QRGate")
    boxes = {}
    for i, r in enumerate(others):
        x = 50 + i * (bw + gap)
        boxes[r] = [x, 430, x + bw, 430 + bh]
    for g in goals:
        kids = [boxes[r] for r in others if parent.get(r) == g]
        cx = (kids[0][0] + kids[-1][2]) / 2
        boxes[g] = [cx - 160, 90, cx + 160, 90 + bh]
    sys_box = [W / 2 - 200, 820, W / 2 + 200, 1000]

    for orig, der in derivs:
        a, b = boxes[der], boxes[orig]
        p0 = ((a[0] + a[2]) / 2, a[1])
        p1 = ((b[0] + b[2]) / 2 + ((a[0] + a[2]) / 2 - (b[0] + b[2]) / 2) * 0.35, b[3])
        dashed(d, p0, p1, INK, width=2)
        arrow_head(d, p0, p1, 16, INK, open_=True, width=2)
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        lbl = "«deriveReqt»"
        w = d.textlength(lbl, font=font(13))
        d.rectangle([mx - w / 2 - 3, my - 9, mx + w / 2 + 3, my + 9], fill="white")
        d.text((mx - w / 2, my - 9), lbl, font=font(13), fill=(71, 85, 105))
    sats.sort(key=lambda r: boxes[r][0])
    for i, r in enumerate(sats):
        b = boxes[r]
        step = (sys_box[2] - sys_box[0] - 40) / max(len(sats) - 1, 1)
        p0 = (sys_box[0] + 20 + i * step, sys_box[1])
        p1 = ((b[0] + b[2]) / 2, b[3])
        dashed(d, p0, p1, (37, 99, 235), width=2)
        arrow_head(d, p0, p1, 16, (37, 99, 235), open_=True, width=2)
    lbl = "«satisfy»"
    d.text((W / 2 - d.textlength(lbl, font=font(15)) / 2, 760), lbl, font=font(15, True), fill=(37, 99, 235))

    for r, box in boxes.items():
        rid, kind, doc = reqs[r]
        stereo = "businessGoal" if kind == "BusinessGoal" else "requirement"
        hf = (254, 243, 199) if kind == "BusinessGoal" else ((220, 252, 231) if kind == "FunctionalRequirement" else (237, 233, 254))
        x0, y0, x1, y1 = box
        d.rectangle(box, fill=FILL, outline=INK, width=2)
        d.rectangle([x0, y0, x1, y0 + 56], fill=hf, outline=INK, width=2)
        text_center(d, [x0, y0 + 4, x1, y0 + 26], f"«{stereo}»", font(14), INK)
        text_center(d, [x0, y0 + 26, x1, y0 + 54], r, font(16, True), INK)
        d.text((x0 + 10, y0 + 62), f"id = \"{rid}\"", font=font(13, mono=True), fill=(37, 99, 235))
        text_left(d, (x0 + 10, y0 + 84), f"text = \"{doc}\"", font(14), (51, 65, 85), width=x1 - x0 - 20, spacing=1.15)
    block(d, sys_box, "part", f"{satisfier} : {sys_type}",
          "Мобильный веб-сканер, панель администратора, сервер валидации", head_fill=(191, 219, 254))

    path = OUT / "requirements-diagram.png"
    img.save(path)
    return path


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    files = [render_context(), render_usecases(), render_requirements(), *render_ui()]
    for f in files:
        print(f.relative_to(ROOT))


if __name__ == "__main__":
    main()
