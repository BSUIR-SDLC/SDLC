"""Generate the static UI board for the individual Lab 3 project."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
OUTPUT = ROOT / "ui-prototype.png"
W, H = 1920, 1200
BG = "#F4F3EE"
PANEL = "#FFFFFF"
INK = "#20342E"
MUTED = "#687871"
GREEN = "#2E7258"
GREEN_LIGHT = "#E7F1EB"
CORAL = "#C45B45"
CORAL_LIGHT = "#FBEEE9"
LINE = "#E4E9E5"
SOFT = "#F7F9F7"
FONT_REG = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 18)
FONT_SMALL = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 15)
FONT_BODY = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 17)
FONT_MED = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 21)
FONT_BOLD = ImageFont.truetype(r"C:\Windows\Fonts\segoeuib.ttf", 25)
FONT_TITLE = ImageFont.truetype(r"C:\Windows\Fonts\segoeuib.ttf", 34)
FONT_BOARD = ImageFont.truetype(r"C:\Windows\Fonts\segoeuib.ttf", 39)

image = Image.new("RGB", (W, H), BG)
draw = ImageDraw.Draw(image)


def width(text, font):
    return draw.textbbox((0, 0), text, font=font)[2]


def wrapped(text, font, max_width):
    lines, current = [], ""
    for word in text.split():
        candidate = f"{current} {word}".strip()
        if current and width(candidate, font) > max_width:
            lines.append(current)
            current = word
        else:
            current = candidate
    if current:
        lines.append(current)
    return lines


def text_block(x, y, text, font=FONT_BODY, fill=INK, max_width=500, spacing=5):
    lines = wrapped(text, font, max_width)
    draw.multiline_text((x, y), "\n".join(lines), font=font, fill=fill, spacing=spacing)
    line_h = draw.textbbox((0, 0), "Аg", font=font)[3] + spacing
    return y + len(lines) * line_h


def rounded(box, radius=14, fill=PANEL, outline=None, w=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=w)


def pill(x, y, label, fill=GREEN_LIGHT, color=GREEN, font=FONT_SMALL, padx=12, height=32):
    tw = width(label, font)
    rounded((x, y, x + tw + padx * 2, y + height), radius=height // 2, fill=fill)
    draw.text((x + padx, y + (height - (draw.textbbox((0, 0), label, font=font)[3])) // 2 - 1),
              label, font=font, fill=color)
    return x + tw + padx * 2


def paw(cx, cy, scale=1):
    # Simple vector paw mark, drawn directly into the PNG.
    r = int(6 * scale)
    for dx, dy in [(-12, -8), (-4, -15), (5, -15), (13, -8)]:
        draw.ellipse((cx + dx * scale - r, cy + dy * scale - r,
                      cx + dx * scale + r, cy + dy * scale + r), fill=GREEN)
    draw.ellipse((cx - 15 * scale, cy - 1 * scale, cx + 15 * scale, cy + 20 * scale), fill=GREEN)


def browser_frame(x, number, title, subtitle):
    y, w, h = 150, 590, 1000
    rounded((x, y, x + w, y + h), radius=23, fill=PANEL, outline=LINE, w=2)
    rounded((x, y, x + w, y + 34), radius=23, fill="#EEF1EE")
    draw.rectangle((x, y + 20, x + w, y + 34), fill="#EEF1EE")
    for i, color in enumerate(["#D98B7A", "#D9B76E", "#80AE8F"]):
        draw.ellipse((x + 19 + i * 18, y + 12, x + 29 + i * 18, y + 22), fill=color)
    draw.text((x + 92, y + 9), "lapa-ryadom.local", font=FONT_SMALL, fill=MUTED)
    # Application bar.
    bar_y = y + 34
    draw.rectangle((x + 1, bar_y, x + w - 1, bar_y + 64), fill=PANEL)
    draw.line((x + 1, bar_y + 64, x + w - 1, bar_y + 64), fill=LINE, width=1)
    paw(x + 39, bar_y + 33, .75)
    draw.text((x + 61, bar_y + 18), "Лапа рядом", font=FONT_MED, fill=INK)
    draw.text((x + 292, bar_y + 23), "Заявки", font=FONT_SMALL, fill=GREEN)
    draw.text((x + 366, bar_y + 23), "Моя помощь", font=FONT_SMALL, fill=MUTED)
    draw.ellipse((x + 528, bar_y + 15, x + 560, bar_y + 47), fill=GREEN_LIGHT)
    draw.text((x + 537, bar_y + 20), "К", font=FONT_SMALL, fill=GREEN)
    # Screen heading and short descriptor.
    draw.text((x + 25, y + 117), f"{number}  {title}", font=FONT_BOLD, fill=INK)
    text_block(x + 25, y + 153, subtitle, FONT_SMALL, MUTED, 530, 4)
    return x, y, w, h


# Board heading.
paw(70, 62, 1.35)
draw.text((103, 31), "Лапа рядом", font=FONT_BOARD, fill=INK)
draw.text((104, 82), "Ключевые сценарии · UI-прототип по модели SysML v2", font=FONT_REG, fill=MUTED)
draw.text((1598, 58), "ЛАБОРАТОРНАЯ РАБОТА 3", font=FONT_SMALL, fill=GREEN)

xs = [35, 665, 1295]
frames = [
    browser_frame(xs[0], "01", "Найти помощь", "Проверенные просьбы приютов и волонтёрские задачи рядом."),
    browser_frame(xs[1], "02", "Карточка заявки", "Детали, свободные места и безопасная запись волонтёра."),
    browser_frame(xs[2], "03", "Новая заявка", "Форма координатора приюта перед отправкой на модерацию."),
]

# Screen 1: public request catalogue.
x, y, _, _ = frames[0]
cy = y + 205
rounded((x + 25, cy, x + 565, cy + 49), radius=12, fill=SOFT, outline=LINE)
draw.text((x + 42, cy + 14), "Поиск по животному или задаче", font=FONT_SMALL, fill=MUTED)
pill(x + 25, cy + 62, "Минск", fill=SOFT, color=INK)
pill(x + 120, cy + 62, "Любая помощь", fill=SOFT, color=INK)
pill(x + 285, cy + 62, "Срок", fill=SOFT, color=INK)
draw.text((x + 25, cy + 112), "Открытые заявки", font=FONT_MED, fill=INK)
draw.text((x + 453, cy + 118), "12 найдено", font=FONT_SMALL, fill=MUTED)

cards = [
    ("Лаки", "Нужен корм для щенков", "Приют «Дорога домой» · Минск", "До пятницы", "3 из 5 мест", "Корм", True),
    ("Мурка", "Отвезти кошку в клинику", "Центр помощи · Минск", "Завтра, 18:00", "1 из 1 места", "Транспорт", False),
    ("Котята", "Нужна временная передержка", "Инициатива «Тёплый дом» · Минск", "На этой неделе", "0 из 2 мест", "Передержка", False),
]
card_y = cy + 148
for animal, heading, org, deadline, slots, category, urgent in cards:
    rounded((x + 25, card_y, x + 565, card_y + 188), radius=16, fill=PANEL, outline=LINE)
    # Photo placeholder.
    rounded((x + 42, card_y + 19, x + 130, card_y + 101), radius=12, fill="#F3EAE0")
    paw(x + 86, card_y + 59, .78)
    draw.text((x + 147, card_y + 16), animal, font=FONT_SMALL, fill=MUTED)
    pill(x + 147, card_y + 42, category, fill=GREEN_LIGHT, color=GREEN, height=28)
    if urgent:
        pill(x + 420, card_y + 42, "Скоро", fill=CORAL_LIGHT, color=CORAL, height=28)
    end = text_block(x + 42, card_y + 111, heading, FONT_MED, INK, 480, 2)
    draw.text((x + 42, end + 3), org, font=FONT_SMALL, fill=MUTED)
    draw.text((x + 42, card_y + 162), f"{deadline}  ·  {slots}", font=FONT_SMALL, fill=GREEN)
    card_y += 200

# Screen 2: request details and privacy-aware commitment.
x, y, _, _ = frames[1]
cy = y + 205
rounded((x + 25, cy, x + 565, cy + 157), radius=16, fill="#F1E7DB")
paw(x + 295, cy + 76, 1.5)
draw.text((x + 25, cy + 171), "Кошка Мурка", font=FONT_SMALL, fill=MUTED)
draw.text((x + 25, cy + 197), "Отвезти в ветеринарную клинику", font=FONT_BOLD, fill=INK)
text_block(x + 25, cy + 235,
           "Нужно помочь с поездкой на плановый осмотр. Переноска и оплата приёма уже подготовлены приютом.",
           FONT_BODY, MUTED, 530, 5)
pill(x + 25, cy + 328, "Транспорт", fill=GREEN_LIGHT, color=GREEN)
pill(x + 150, cy + 328, "Завтра · 18:00", fill=CORAL_LIGHT, color=CORAL)
draw.line((x + 25, cy + 378, x + 565, cy + 378), fill=LINE, width=2)
draw.text((x + 25, cy + 396), "Встреча", font=FONT_MED, fill=INK)
draw.text((x + 25, cy + 431), "Минск, район Центральный", font=FONT_BODY, fill=INK)
draw.text((x + 25, cy + 459), "Точный адрес откроется после записи", font=FONT_SMALL, fill=MUTED)
draw.text((x + 25, cy + 512), "Организация", font=FONT_MED, fill=INK)
draw.text((x + 25, cy + 546), "Центр помощи «Добрые лапы»", font=FONT_BODY, fill=INK)
draw.text((x + 25, cy + 575), "Свободных мест: 1", font=FONT_BODY, fill=GREEN)
rounded((x + 25, cy + 621, x + 565, cy + 674), radius=13, fill=GREEN)
draw.text((x + 175, cy + 635), "Записаться на помощь", font=FONT_BODY, fill=PANEL)
text_block(x + 25, cy + 691,
           "После записи координатор свяжется с вами. Контактные данные не показываются в открытом каталоге.",
           FONT_SMALL, MUTED, 530, 4)

# Screen 3: request creation by a verified shelter representative.
x, y, _, _ = frames[2]
cy = y + 205
steps = [("1  Описание", True), ("2  Место", False), ("3  Проверка", False)]
sx = x + 25
for label, active in steps:
    end = pill(sx, cy, label, fill=GREEN if active else SOFT,
               color=PANEL if active else MUTED, height=31, padx=10)
    sx = end + 8
draw.text((x + 25, cy + 51), "Расскажите, какая помощь нужна", font=FONT_MED, fill=INK)

def field(label, value, top, height=54, placeholder=False):
    draw.text((x + 25, top), label, font=FONT_SMALL, fill=INK)
    rounded((x + 25, top + 24, x + 565, top + 24 + height), radius=10,
            fill=SOFT, outline=LINE)
    color = MUTED if placeholder else INK
    draw.text((x + 39, top + 40), value, font=FONT_SMALL, fill=color)
    return top + 24 + height + 12

fy = cy + 91
fy = field("Животное", "Кошка / Мурка", fy)
fy = field("Заголовок заявки", "Например: отвезти в клинику", fy, placeholder=True)
fy = field("Вид помощи", "Выберите категорию", fy, placeholder=True)
fy = field("Описание", "Коротко опишите задачу и что уже подготовлено", fy, height=82, placeholder=True)
fy = field("Район и срок", "Центральный район · дата и время", fy, placeholder=True)
fy = field("Количество волонтёров", "1", fy)
draw.text((x + 25, fy + 1), "Заявка будет опубликована после проверки", font=FONT_SMALL, fill=GREEN)
rounded((x + 25, fy + 32, x + 280, fy + 83), radius=12, fill=SOFT, outline=LINE)
draw.text((x + 67, fy + 47), "Сохранить черновик", font=FONT_SMALL, fill=INK)
rounded((x + 295, fy + 32, x + 565, fy + 83), radius=12, fill=GREEN)
draw.text((x + 346, fy + 47), "На модерацию →", font=FONT_SMALL, fill=PANEL)

draw.text((35, 1162), "Учебный эскиз: демонстрационные данные вымышлены; точный адрес в публичном каталоге скрыт.",
          font=FONT_SMALL, fill=MUTED)
draw.text((1760, 1162), "v0.1", font=FONT_SMALL, fill=GREEN)
image.save(OUTPUT, format="PNG", optimize=True)
print(OUTPUT)
