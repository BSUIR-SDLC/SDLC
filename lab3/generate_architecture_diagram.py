from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


OUT = Path(__file__).with_name("system-architecture.png")
W, H = 1600, 1080
BG = "#F4F7FB"
INK = "#18324B"
MUTED = "#587086"
BLUE = "#DCEBFA"
BLUE_EDGE = "#4779A8"
TEAL = "#DDF2EC"
TEAL_EDGE = "#438878"
GOLD = "#FFF0D7"
GOLD_EDGE = "#B98334"
WHITE = "#FFFFFF"


def font(size, bold=False):
    name = "segoeuib.ttf" if bold else "segoeui.ttf"
    path = Path("C:/Windows/Fonts") / name
    return ImageFont.truetype(str(path), size)


img = Image.new("RGB", (W, H), BG)
draw = ImageDraw.Draw(img)
regular = font(25)
small = font(21)
medium = font(28, True)
heading = font(43, True)
subheading = font(24)
label_font = font(20, True)


def center_text(box, text, used_font, fill=INK, spacing=6):
    x1, y1, x2, y2 = box
    bounds = draw.multiline_textbbox((0, 0), text, font=used_font, align="center", spacing=spacing)
    width, height = bounds[2] - bounds[0], bounds[3] - bounds[1]
    draw.multiline_text((x1 + (x2 - x1 - width) / 2, y1 + (y2 - y1 - height) / 2),
                        text, font=used_font, fill=fill, align="center", spacing=spacing)


def arrow(points, color=BLUE_EDGE, width=5, dashed=False, head=14):
    if dashed:
        for (x1, y1), (x2, y2) in zip(points, points[1:]):
            dx, dy = x2 - x1, y2 - y1
            length = (dx * dx + dy * dy) ** 0.5
            if length == 0:
                continue
            ux, uy = dx / length, dy / length
            position = 0
            while position < length - head:
                end = min(position + 12, length - head)
                draw.line((x1 + ux * position, y1 + uy * position,
                           x1 + ux * end, y1 + uy * end), fill=color, width=width)
                position += 21
    else:
        draw.line(points, fill=color, width=width, joint="curve")
    x1, y1 = points[-2]
    x2, y2 = points[-1]
    dx, dy = x2 - x1, y2 - y1
    length = (dx * dx + dy * dy) ** 0.5
    ux, uy = dx / length, dy / length
    px, py = -uy, ux
    base_x, base_y = x2 - ux * head, y2 - uy * head
    draw.polygon([(x2, y2), (base_x + px * head * .58, base_y + py * head * .58),
                  (base_x - px * head * .58, base_y - py * head * .58)], fill=color)


def rounded_box(box, title, subtitle, fill, edge, title_size=medium, subtitle_size=small, radius=18):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=edge, width=3)
    x1, y1, x2, y2 = box
    center_text((x1 + 12, y1 + 8, x2 - 12, y1 + 58), title, title_size)
    center_text((x1 + 15, y1 + 57, x2 - 15, y2 - 8), subtitle, subtitle_size, MUTED)


# Header
center_text((70, 25, W - 70, 91), "Структурная модель системы «Лапа рядом»", heading)
center_text((100, 95, W - 100, 140),
            "Логическое разбиение приложения и основные взаимодействия компонентов", subheading, MUTED)

# System boundary and label
boundary = (55, 165, 1230, 1040)
draw.rounded_rectangle(boundary, radius=28, fill=WHITE, outline="#B7C8D8", width=3)
draw.rounded_rectangle((82, 146, 385, 184), radius=15, fill=BG, outline="#B7C8D8", width=2)
center_text((88, 146, 379, 184), "Система «Лапа рядом»", label_font)

# Component group, UI, storage, and external gateway
modules_area = (90, 390, 1195, 820)
draw.rounded_rectangle(modules_area, radius=24, fill="#F8FBFE", outline="#C9D8E6", width=2)
draw.rounded_rectangle((115, 372, 390, 409), radius=14, fill=WHITE, outline="#C9D8E6", width=2)
center_text((121, 372, 384, 409), "Прикладные модули", label_font, MUTED)

ui = (390, 220, 900, 330)
storage = (390, 880, 900, 1005)
smtp = (1280, 640, 1550, 780)

# Modules
boxes = {
    "access": (125, 445, 440, 570),
    "org": (485, 445, 800, 570),
    "requests": (845, 445, 1160, 570),
    "catalog": (125, 665, 440, 790),
    "volunteers": (485, 665, 800, 790),
    "notifications": (845, 665, 1160, 790),
}

# Draw connectors first so all nodes stay on top.
arrow([(645, 330), (645, 365), (645, 390)], color=BLUE_EDGE)
# Logical communication among services.
arrow([(800, 507), (845, 507)], color=TEAL_EDGE)
arrow([(920, 570), (920, 620), (440, 620), (440, 690)], color=TEAL_EDGE)
arrow([(1000, 570), (1000, 620), (800, 620), (800, 690)], color=TEAL_EDGE)
arrow([(800, 727), (845, 727)], color=TEAL_EDGE)
# Shared persistence for the application modules.
arrow([(645, 820), (645, 880)], color=BLUE_EDGE)
# Optional external email transport.
arrow([(1160, 727), (1280, 727)], color=GOLD_EDGE, width=4, dashed=True)

# Nodes
rounded_box(ui, "Пользовательский интерфейс",
            "Каталог, карточка заявки, профиль и формы", BLUE, BLUE_EDGE, title_size=font(30, True))
rounded_box(boxes["access"], "Доступ и профили", "Регистрация, вход,\nроли и права", BLUE, BLUE_EDGE)
rounded_box(boxes["org"], "Организации и модерация", "Проверка приютов\nи заявок", TEAL, TEAL_EDGE, title_size=font(22, True))
rounded_box(boxes["requests"], "Управление заявками", "Создание, изменение и статусы", TEAL, TEAL_EDGE, title_size=font(24, True))
rounded_box(boxes["catalog"], "Каталог и поиск", "Публикация, поиск и фильтры", BLUE, BLUE_EDGE)
rounded_box(boxes["volunteers"], "Координация волонтёров", "Запись на место\nи отчёт о помощи", TEAL, TEAL_EDGE, title_size=font(22, True))
rounded_box(boxes["notifications"], "Уведомления", "События в приложении\nи их доставка", BLUE, BLUE_EDGE)
rounded_box(storage, "Хранилище данных", "Пользователи, организации, заявки,\nзаписи и история", "#E9EEF4", "#6C8298", title_size=font(30, True))

# External optional service
draw.rounded_rectangle(smtp, radius=20, fill=GOLD, outline=GOLD_EDGE, width=3)
center_text((smtp[0] + 12, smtp[1] + 15, smtp[2] - 12, smtp[1] + 73),
            "SMTP-шлюз", font(28, True))
center_text((smtp[0] + 18, smtp[1] + 75, smtp[2] - 18, smtp[3] - 12),
            "Необязательная отправка\nкопий писем", small, MUTED)
draw.text((1278, 600), "внешний сервис", font=label_font, fill=MUTED)

# Compact legend and interaction notes
draw.line((92, 1058, 148, 1058), fill=TEAL_EDGE, width=4)
draw.polygon([(148, 1058), (136, 1051), (136, 1065)], fill=TEAL_EDGE)
draw.text((160, 1044), "взаимодействие компонентов", font=small, fill=MUTED)
draw.line((510, 1058, 566, 1058), fill=GOLD_EDGE, width=4)
for x in range(510, 552, 20):
    draw.line((x, 1058, x + 11, 1058), fill=GOLD_EDGE, width=4)
draw.polygon([(566, 1058), (554, 1051), (554, 1065)], fill=GOLD_EDGE)
draw.text((579, 1044), "необязательная интеграция", font=small, fill=MUTED)
draw.text((1015, 1044), "Модель логическая, без фиксации технологий развёртывания", font=font(18), fill=MUTED)

img.save(OUT, optimize=True)
print(OUT)
