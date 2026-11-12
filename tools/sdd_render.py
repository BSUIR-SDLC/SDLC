"""Построение диаграмм SDD из моделей SysML v2 (текстовая нотация).

Использование:  python tools/sdd_render.py
Читает sdd/models/*.sysml, пишет sdd/img/*.png. Нужны Graphviz (dot в PATH), matplotlib, Pillow.

Поддерживаемое подмножество нотации SysML v2:
  part / part def, attribute, doc /* ... */, @Метка;   (ibd: композиция, данные, развёртывание)
  connect A to B { doc /* подпись */ }                  (ibd)
  occurrence def { part ...; message m from A to B }    (sd: диаграмма последовательности)
  state def { state s { doc } transition t first A accept Ev then B }   (stm: диаграмма состояний)
Вид диаграммы и заголовок рамки задаются первой строкой:  // @diagram ibd "Заголовок"
"""
import html, re, subprocess, textwrap, tempfile, os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyBboxPatch, Polygon

ROOT = Path(__file__).resolve().parent.parent
FONT = "DejaVu Sans"
INK = "#1e293b"
HDR = {"Core": "#fef3c7", "Primary": "#dbeafe", "Client": "#dcfce7", "External": "#ede9fe",
       "Store": "#ede9fe", "Actor": "#dcfce7", "Ok": "#bbf7d0", "Error": "#fecaca", "Warn": "#fde68a"}
DEF_HDR = "#e2e8f0"
TINT = {"Primary": "#f1f6fe", "Core": "#fffbeb"}

# ------------------------------------------------------------------ разбор
TOK = re.compile(r"/\*(.*?)\*/|//[^\n]*|([{};:])|([^\s{};:]+)", re.S)


class N:
    def __init__(self, kind, **kw):
        self.kind, self.name, self.type, self.text = kind, None, None, ""
        self.children, self.__dict__.update(kw)

    children = ()

    def marks(self):
        return {c.name for c in self.children if c.kind == "mark"}

    def doc(self):
        for c in self.children:
            if c.kind == "doc":
                return re.sub(r"\s+", " ", c.text)
        return ""

    def of(self, kind):
        return [c for c in self.children if c.kind == kind]


def parse(text):
    toks = []
    for m in TOK.finditer(text):
        if m.group(0).startswith("//"):
            continue
        if m.group(1) is not None:
            toks.append(("DOC", m.group(1).strip()))
        elif m.group(2):
            toks.append(("P", m.group(2)))
        else:
            toks.append(("W", m.group(3)))
    pos = [0]

    def peek():
        return toks[pos[0]] if pos[0] < len(toks) else None

    def block():
        out = []
        while peek() and peek() != ("P", "}"):
            out.append(statement())
        return out

    def statement():
        words = []
        while True:
            t = peek()
            if t is None:
                return make(words, [])
            if t[0] == "DOC":
                pos[0] += 1
                return N("doc", text=t[1])
            if t == ("P", ";"):
                pos[0] += 1
                return make(words, [])
            if t == ("P", "{"):
                pos[0] += 1
                ch = block()
                pos[0] += 1
                return make(words, ch)
            words.append(t[1])
            pos[0] += 1

    def make(w, ch):
        h = w[0]
        if h == "package":
            return N("package", name=w[1], children=ch)
        if h == "part":
            if w[1] == "def":
                return N("partdef", name=w[2], children=ch)
            return N("part", name=w[1], type=w[3] if len(w) > 3 else "", children=ch)
        if h == "attribute":
            return N("attr", name=w[1], type=" ".join(w[3:]))
        if h == "connect":
            return N("connect", src=w[1], dst=w[3], children=ch)
        if h == "message":
            return N("message", name=w[1], src=w[3], dst=w[5], children=ch)
        if h == "state":
            return N("statedef" if w[1] == "def" else "state", name=w[2] if w[1] == "def" else w[1], children=ch)
        if h == "transition":
            return N("transition", name=w[1], src=w[3], ev=w[5], dst=w[7], children=ch)
        if h == "entry":
            return N("entry")
        if h == "then":
            return N("then", dst=w[1])
        if h == "occurrence":
            return N("occurrence", name=w[2], children=ch)
        if h.startswith("@"):
            return N("mark", name=h[1:])
        raise ValueError("неизвестная конструкция: " + " ".join(w))

    root = N("root", children=block())
    m = re.search(r"//\s*@diagram\s+(\w+)\s+\"([^\"]+)\"", text)
    return root, m.group(1), m.group(2)


def find_all(node, kind):
    out = []
    for c in node.children:
        if c.kind == kind:
            out.append(c)
        out += find_all(c, kind)
    return out


def hdr_color(n):
    for m in ("Core", "Primary", "Client", "External", "Store", "Actor", "Ok", "Error", "Warn"):
        if m in n.marks():
            return HDR[m]
    return DEF_HDR


def wrap(s, w):
    return textwrap.wrap(s, w) or [""]


def hx(s):
    return html.escape(s, quote=False)


# ------------------------------------------------------------------ рамка
def frame(png, kind, title, out):
    im = Image.open(png).convert("RGB")
    pad, tab_h = 36, 46
    W, H = im.width + 2 * pad, im.height + 2 * pad + tab_h
    canvas = Image.new("RGB", (W, H), "white")
    canvas.paste(im, (pad, pad + tab_h))
    d = ImageDraw.Draw(canvas)
    fnt = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
    label = f"{kind} [{title}]"
    tw = d.textlength(label, font=fnt)
    d.rectangle([6, 6, W - 7, H - 7], outline=INK, width=2)
    d.polygon([(6, 6), (6 + tw + 40, 6), (6 + tw + 40, 6 + 34), (6 + tw + 28, 6 + 46), (6, 6 + 46)],
              fill="#f8fafc", outline=INK)
    d.text((22, 12), label, fill=INK, font=fnt)
    canvas.save(out)


# ------------------------------------------------------------------ ibd (dot)
def part_table(n, wrap_w=30):
    hdr = hdr_color(n)
    title = f"{n.name} : {n.type}" if n.type else n.name
    t = ['<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="6" BGCOLOR="#f8fafc" COLOR="%s">' % INK,
         f'<TR><TD BGCOLOR="{hdr}"><FONT POINT-SIZE="10" COLOR="#475569">«part»</FONT><BR/><B>{hx(title)}</B></TD></TR>']
    attrs = n.of("attr")
    if attrs:
        t.append('<TR><TD><TABLE BORDER="0" CELLSPACING="0" CELLPADDING="2">')
        for a in attrs:
            t.append(f'<TR><TD ALIGN="LEFT">{hx(a.name)}</TD><TD ALIGN="RIGHT"><FONT COLOR="#475569" POINT-SIZE="11">&nbsp;&nbsp;{hx(a.type)}</FONT></TD></TR>')
        t.append("</TABLE></TD></TR>")
    elif n.doc():
        body = "".join(hx(l) + '<BR ALIGN="LEFT"/>' for l in wrap(n.doc(), wrap_w))
        t.append(f'<TR><TD ALIGN="LEFT" BALIGN="LEFT">{body}</TD></TR>')
    t.append("</TABLE>>")
    return "".join(t)


def render_ibd(root, title, out, rankdir="LR", wrap_w=30, nodesep=0.45, ranksep=0.9, extra=""):
    parts = {}
    top = []
    lines = [f'digraph G {{ rankdir={rankdir}; compound=true; nodesep={nodesep}; ranksep={ranksep}; bgcolor="white";',
             f'fontname="{FONT}"; node [shape=plain fontname="{FONT}" fontsize=12 fontcolor="{INK}"];',
             f'edge [fontname="{FONT}" fontsize=10 color="{INK}" fontcolor="#334155" arrowsize=0.9];', extra]
    pkg = root.of("package")[0]
    anchor = {}

    def emit(n, indent=""):
        parts[n.name] = n
        kids = n.of("part")
        if kids:
            tint = next((TINT[m] for m in ("Primary", "Core") if m in n.marks()), "#ffffff")
            hdr = hdr_color(n)
            body = "".join(hx(l) + "<BR/>" for l in wrap(n.doc(), 46))
            lines.append(f'subgraph cluster_{n.name} {{ style="filled,rounded"; fillcolor="{tint}"; color="{INK}"; penwidth=1.6; margin=18;')
            lines.append(f'label=<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0"><TR><TD BGCOLOR="{hdr}" CELLPADDING="5"><FONT POINT-SIZE="10" COLOR="#475569">«part»</FONT><BR/><B>{hx(n.name)} : {hx(n.type)}</B></TD></TR><TR><TD><FONT POINT-SIZE="11">{body}</FONT></TD></TR></TABLE>>; labelloc=t; labeljust=l;')
            for k in kids:
                emit(k, indent + " ")
            anchor[n.name] = kids[0].name if not kids[0].of("part") else anchor.get(kids[0].name, kids[0].name)
            lines.append("}")
        else:
            lines.append(f'{n.name} [label={part_table(n, wrap_w)}];')

    for n in pkg.of("part"):
        emit(n)
    for c in pkg.of("connect"):
        s, d = c.src.split(".")[-1], c.dst.split(".")[-1]
        a = []
        sa, da = anchor.get(s, s), anchor.get(d, d)
        if s in anchor:
            a.append(f'ltail=cluster_{s}')
        if d in anchor:
            a.append(f'lhead=cluster_{d}')
        if "Back" in c.marks():
            a.append("constraint=false")
        lab = c.doc()
        if lab:
            a.append(f'label=<<FONT POINT-SIZE="10">{hx(lab)}</FONT>>')
        lines.append(f'{sa} -> {da} [{", ".join(a)}];')
    lines.append("}")
    with tempfile.TemporaryDirectory() as td:
        g = Path(td) / "g.dot"
        g.write_text("\n".join(lines), encoding="utf-8")
        png = Path(td) / "g.png"
        subprocess.run(["dot", "-Tpng", "-Gdpi=110", str(g), "-o", str(png)], check=True)
        frame(png, "ibd", title, out)


# ------------------------------------------------------------------ stm (dot)
def render_stm(root, title, out):
    sd = find_all(root, "statedef")[0]
    states = sd.of("state")
    lines = [f'digraph G {{ rankdir=TB; nodesep=0.55; ranksep=0.85; bgcolor="white";',
             f'node [shape=plain fontname="{FONT}" fontsize=12 fontcolor="{INK}"];',
             f'edge [fontname="{FONT}" fontsize=10 color="{INK}" fontcolor="#334155"];',
             f'__start [shape=circle label="" width=0.28 style=filled fillcolor="{INK}"];']
    for s in states:
        body = "".join(hx(l) + "<BR/>" for l in wrap(s.doc(), 24))
        lines.append(f'{s.name} [label=<<TABLE BORDER="1" STYLE="ROUNDED" CELLBORDER="0" CELLSPACING="0" CELLPADDING="7" BGCOLOR="#f8fafc" COLOR="{INK}">'
                     f'<TR><TD BGCOLOR="{hdr_color(s)}" STYLE="ROUNDED"><B>{hx(s.name)}</B></TD></TR><TR><TD>{body}</TD></TR></TABLE>>];')
    then = sd.of("then")[0].dst
    lines.append(f"__start -> {then};")
    for t in sd.of("transition"):
        lab = f"{t.ev} / {t.doc()}" if t.doc() else t.ev
        lab = "<BR/>".join(hx(l) for l in wrap(lab, 26))
        lines.append(f'{t.src} -> {t.dst} [label=<<FONT POINT-SIZE="10">{lab}</FONT>>];')
    lines.append("}")
    with tempfile.TemporaryDirectory() as td:
        g = Path(td) / "g.dot"
        g.write_text("\n".join(lines), encoding="utf-8")
        png = Path(td) / "g.png"
        subprocess.run(["dot", "-Tpng", "-Gdpi=110", str(g), "-o", str(png)], check=True)
        frame(png, "stm", title, out)


# ------------------------------------------------------------------ sd (matplotlib)
def render_sd(root, title, out):
    occ = find_all(root, "occurrence")[0]
    life = occ.of("part")
    msgs = occ.of("message")
    n = len(life)
    step = 2.15
    xs = {p.name: 0.9 + i * step for i, p in enumerate(life)}
    W = 0.9 * 2 + (n - 1) * step
    ys, y = [], -1.75
    for m in msgs:
        ln = len(wrap(m.doc(), int(max(abs(xs[m.dst] - xs[m.src]), 2.4) * 11.5))) if m.src != m.dst else len(wrap(m.doc(), 34))
        y -= 0.42 + 0.27 * ln
        ys.append(y)
        if m.src == m.dst:
            y -= 0.4
    H = -y + 1.0
    fig = plt.figure(figsize=(W, H), dpi=110)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_xlim(0, W)
    ax.set_ylim(-H, 0)
    ax.axis("off")
    ax.add_patch(Rectangle((0.06, -H + 0.06), W - 0.12, H - 0.12, fill=False, ec=INK, lw=1.6))
    label = f"sd [{title}]"
    tw = 0.115 * len(label) + 0.5
    ax.add_patch(Polygon([(0.06, -0.06), (0.06 + tw, -0.06), (0.06 + tw, -0.4), (0.06 + tw - 0.12, -0.52), (0.06, -0.52)],
                         closed=True, fc="#f8fafc", ec=INK, lw=1.2))
    ax.text(0.2, -0.29, label, fontsize=12.5, fontweight="bold", color=INK, va="center")
    for p in life:
        x = xs[p.name]
        hdrc = hdr_color(p)
        ax.add_patch(FancyBboxPatch((x - 0.92, -1.55), 1.84, 0.62, boxstyle="square,pad=0", fc=hdrc, ec=INK, lw=1.2))
        ax.text(x, -1.12, p.name, ha="center", va="center", fontsize=11.5, fontweight="bold", color=INK)
        ax.text(x, -1.37, f": {p.type}", ha="center", va="center", fontsize=9.5, color="#475569")
        ax.plot([x, x], [-1.55, -H + 0.35], ls=(0, (6, 4)), color="#64748b", lw=1.1, zorder=1)
    for k, (m, y) in enumerate(zip(msgs, ys), 1):
        x0, x1 = xs[m.src], xs[m.dst]
        txt = f"{k}. {m.doc()}"
        reply = "Reply" in m.marks()
        ls = (0, (5, 3)) if reply else "-"
        if m.src == m.dst:
            ax.plot([x0, x0 + 0.42, x0 + 0.42, x0 + 0.04], [y, y, y - 0.3, y - 0.3], color=INK, lw=1.3, zorder=3)
            ax.annotate("", xy=(x0, y - 0.3), xytext=(x0 + 0.18, y - 0.3),
                        arrowprops=dict(arrowstyle="-|>", color=INK, lw=1.3, mutation_scale=13))
            for j, l in enumerate(wrap(txt, 36)):
                ax.text(x0 + 0.55, y - 0.04 - 0.27 * j, l, fontsize=10, va="center", color=INK)
            ys[k - 1] = y - 0.3
        else:
            ax.annotate("", xy=(x1, y), xytext=(x0, y),
                        arrowprops=dict(arrowstyle="->" if reply else "-|>", color=INK, lw=1.3, ls=ls, mutation_scale=14, shrinkA=0, shrinkB=0))
            lines_ = wrap(txt, int(max(abs(x1 - x0), 2.4) * 11.5))
            for j, l in enumerate(reversed(lines_)):
                ax.text((x0 + x1) / 2, y + 0.16 + 0.27 * j, l, fontsize=10, ha="center", va="center", color=INK)
    fig.savefig(out, dpi=110)
    plt.close(fig)


# ------------------------------------------------------------------ main
OUT_NAMES = {"context": "001-context", "composition": "002-composition", "data": "004-information",
             "interaction": "006-interaction", "states": "007-states", "deployment": "009-deployment"}
OPTS = {"context": dict(rankdir="LR", wrap_w=34, nodesep=0.55, ranksep=1.3),
        "composition": dict(rankdir="LR", wrap_w=28, nodesep=0.35, ranksep=0.85),
        "data": dict(rankdir="TB", nodesep=0.5, ranksep=0.8),
        "deployment": dict(rankdir="LR", wrap_w=28, nodesep=0.4, ranksep=1.0)}


def main():
    (ROOT / "sdd/img").mkdir(parents=True, exist_ok=True)
    for f in sorted((ROOT / "sdd/models").glob("*.sysml")):
        root, kind, title = parse(f.read_text(encoding="utf-8"))
        out = ROOT / "sdd/img" / (OUT_NAMES[f.stem] + ".png")
        if kind == "ibd":
            render_ibd(root, title, out, **OPTS.get(f.stem, {}))
        elif kind == "stm":
            render_stm(root, title, out)
        elif kind == "sd":
            render_sd(root, title, out)
        print("построено:", out.relative_to(ROOT))


if __name__ == "__main__":
    main()
