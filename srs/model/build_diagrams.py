"""
Генерация диаграмм EasyTicket (SysML v2 нотация) -> PNG.
Запуск:  python3 build_diagrams.py
Требуется: Graphviz (команда dot), Python 3, matplotlib, шрифт DejaVu Sans.
Результат: ../diagrams/G1..G5/G6 *.png и исходники Graphviz в ../diagrams/src/*.dot
Модель-источник: easyticket.sysml (в этом же каталоге).
"""
import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyBboxPatch
import subprocess, html
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'diagrams') + os.sep
os.makedirs(OUT + 'src', exist_ok=True)
F = 'DejaVu Sans'
BG = '#FEFECE'; BD = '#A80036'; EXT = '#E8E8E8'

def esc(s): return html.escape(s, quote=False)

def box(stereo, name, comps=None, bg=BG, w=None):
    """SysML v2 style node as HTML table. comps: list of (title, [lines])"""
    rows = f'<TR><TD ALIGN="CENTER" BGCOLOR="{bg}"><FONT POINT-SIZE="10"><I>«{esc(stereo)}»</I></FONT><BR/><B>{esc(name)}</B></TD></TR>'
    for t, lines in (comps or []):
        body = '<BR ALIGN="LEFT"/>'.join(esc(l) for l in lines) + '<BR ALIGN="LEFT"/>'
        rows += f'<TR><TD ALIGN="LEFT" BGCOLOR="{bg}"><FONT POINT-SIZE="9" COLOR="#555555"><I>{esc(t)}</I></FONT><BR ALIGN="LEFT"/>{body}</TD></TR>'
    return f'<<TABLE BORDER="1" CELLBORDER="0" CELLSPACING="0" CELLPADDING="5" COLOR="{BD}">{rows}</TABLE>>'

def render(name, dot):
    open(OUT + 'src/' + name + '.dot', 'w', encoding='utf-8').write(dot)
    subprocess.run(['dot', '-Tpng', '-Gdpi=130', OUT + 'src/' + name + '.dot', '-o', OUT + name + '.png'], check=True)

HDR = f'digraph G {{ graph [fontname="{F}", fontsize=14, pad=0.3, bgcolor="white"]; node [fontname="{F}", fontsize=11, shape=plain]; edge [fontname="{F}", fontsize=10, color="{BD}"];\n'

# ---------------------------------------------------------------- 1. context / general view
d = HDR + 'rankdir=TB; nodesep=0.3; ranksep=0.8; \n'
for n, t in [('buyer', 'Buyer — Покупатель'), ('adm', 'Administrator — Администратор'), ('ctl', 'Controller — Контролёр')]:
    d += f'{n} [label={box("part def", t)}];\n'
d += 'subgraph cluster_sys { label=<<I>«part def»</I> <B>EasyTicketSystem</B>>; style="rounded"; color="%s"; fontsize=12; bgcolor="#FFFFF0";\n' % BD
for n, t, ty in [('web', 'webUI', 'WebUI'), ('api', 'api', 'RestApi'), ('cat', 'catalog', 'CatalogService'),
                 ('res', 'reservations', 'ReservationService'), ('ord', 'orders', 'OrderService'),
                 ('qr', 'qr', 'QrService'), ('mail', 'mail', 'MailService'), ('adms', 'admin', 'AdminService')]:
    d += f'{n} [label={box("part", t + " : " + ty)}];\n'
d += '}\n'
for n, t, ty in [('db', 'db', 'PostgreSQL'), ('qrl', 'qrlib', 'QrLibrary (qrcode)'), ('smtp', 'smtp', 'MockSmtp (порт 1025)')]:
    d += f'{n} [label={box("external part", t + " : " + ty, bg=EXT)}];\n'
for a in ['buyer', 'adm', 'ctl']:
    d += f'{a} -> web [arrowhead=none, style=dashed, label="HTTPS" ];\n' if a == 'buyer' else f'{a} -> web [arrowhead=none, style=dashed];\n'
d += 'web -> api [arrowhead=none, label="JSON/REST"];\n'
for s in ['cat', 'res', 'ord', 'adms']:
    d += f'api -> {s} [arrowhead=none];\n'
d += 'ord -> qr [arrowhead=none, label="билет"]; ord -> mail [arrowhead=none, label="письмо"];\n'
for s in ['cat', 'res', 'ord', 'adms']:
    d += f'{s} -> db [arrowhead=none];\n'
d += 'qr -> qrl [arrowhead=none]; mail -> smtp [arrowhead=none];\n}'
render('G1_system_structure', d)

# ---------------------------------------------------------------- 2. use cases
d = HDR + 'rankdir=LR; nodesep=0.3; ranksep=1.3; \n'
def actor(n, t): return f'{n} [label={box("actor", t)}];\n'
d += actor('buyer', 'Покупатель') + actor('ctl', 'Контролёр') + actor('adm', 'Администратор')
d += f'subgraph cluster_s {{ label=<<I>«subject»</I> <B>EasyTicketSystem</B>>; style="rounded"; color="{BD}"; fontsize=12;\n'
ucs = [('u1', 'Просмотреть каталог\\n(REQ-FUNC-001, 002)'), ('u2', 'Выбрать места\\nи забронировать\\n(REQ-FUNC-003…005)'),
       ('u3', 'Оформить заказ\\n(REQ-FUNC-006)'), ('u4', 'Получить билет\\nс QR-кодом\\n(REQ-FUNC-007, 008)'),
       ('u5', 'Найти билеты\\nпо заказу\\n(REQ-FUNC-009)'), ('u6', 'Проверить билет\\nна входе\\n(REQ-FUNC-010)'),
       ('u7', 'Войти в систему\\n(REQ-FUNC-011)'), ('u8', 'Управлять\\nмероприятиями\\n(REQ-FUNC-012)'),
       ('u9', 'Смотреть статистику\\n(REQ-FUNC-013)'), ('u10', 'Отменить бронь\\n(REQ-FUNC-014)')]
for n, t in ucs:
    d += f'{n} [shape=ellipse, style=filled, fillcolor="{BG}", color="{BD}", label="{t}"];\n'
d += '}\n'
for u in ['u1', 'u2', 'u3', 'u4', 'u5']: d += f'buyer -> {u} [arrowhead=none];\n'
for u in ['u6']: d += f'ctl -> {u} [arrowhead=none];\n'
for u in ['u7', 'u8', 'u9', 'u10']: d += f'adm -> {u} [arrowhead=none];\n'
d += 'ctl -> u7 [arrowhead=none];\n'
inc = 'style=dashed, arrowhead=vee, label="«include»", fontsize=9'
d += f'u3 -> u4 [{inc}]; u3 -> u2 [style=dashed, arrowhead=vee, label="«include»", fontsize=9];\n'
for u in ['u6', 'u8', 'u9', 'u10']: d += f'{u} -> u7 [{inc}];\n'
d += '}'
render('G2_use_cases', d)

# ---------------------------------------------------------------- 3. requirements
d = HDR + 'rankdir=LR; nodesep=0.18; ranksep=2.2; \n'
reqs = [
 ('r1', 'REQ-FUNC-001', 'Каталог мероприятий с фильтрами', 'cat'),
 ('r3', 'REQ-FUNC-003', 'Схема зала со статусами мест', 'res'),
 ('r5', 'REQ-FUNC-005', 'Бронь места на 10 минут', 'res'),
 ('r6', 'REQ-FUNC-006', 'Оформление заказа по email', 'ord'),
 ('r7', 'REQ-FUNC-007', 'Уникальный QR-код билета', 'qr'),
 ('s2', 'REQ-SEC-002', 'Подпись QR-кода HMAC-SHA256', 'qr'),
 ('r8', 'REQ-FUNC-008', 'Письмо с билетом ≤ 60 с', 'mail'),
 ('r10', 'REQ-FUNC-010', 'Проверка билета на входе', 'ord'),
 ('r12', 'REQ-FUNC-012', 'Управление мероприятиями', 'adms'),
]
for n, i, t, _ in reqs:
    d += f'{n} [label={box("requirement", i, [("text", [t])])}];\n'
for n, t in [('cat', 'catalog : CatalogService'), ('res', 'reservations : ReservationService'), ('ord', 'orders : OrderService'),
             ('qr', 'qr : QrService'), ('mail', 'mail : MailService'), ('adms', 'admin : AdminService')]:
    d += f'{n} [label={box("part", t)}];\n'
for n, i, t, p in reqs:
    d += f'{n} -> {p} [style=dashed, arrowhead=vee, label="«satisfy»", fontsize=9];\n'
d += '}'
render('G3_requirements', d)

# ---------------------------------------------------------------- 4. state machines
d = HDR + 'rankdir=LR; nodesep=0.5; ranksep=1.2; \n'
def st(n, t, sub=''):
    return f'{n} [shape=box, style="rounded,filled", fillcolor="{BG}", color="{BD}", label=<<B>{t}</B>{sub}>, margin="0.25,0.15"];\n'
d += f'subgraph cluster_seat {{ label=<<I>«state def»</I> <B>SeatLifecycle</B>>; style="rounded"; color="{BD}"; fontsize=12;\n'
d += 'i1 [shape=circle, style=filled, fillcolor=black, label="", width=0.2];\n'
d += st('free', 'Свободно') + st('res', 'Забронировано', '<BR/><FONT POINT-SIZE="9">entry / запуск таймера 10 мин</FONT>') + st('sold', 'Продано')
d += 'i1 -> free;\n'
d += 'free -> res [label="AddToCart\\n[место свободно]"];\n'
d += 'res -> free [label="after 10 мин\\nRemoveFromCart\\nAdminCancel", constraint=false, tailport=n, headport=n];\n'
d += 'res -> sold [label="PaymentConfirmed\\n[бронь действует]"];\n'
d += '}\n'
d += f'subgraph cluster_ticket {{ label=<<I>«state def»</I> <B>TicketLifecycle</B> <FONT POINT-SIZE="10">(билет создаётся, когда место становится «Продано»)</FONT>>; style="rounded"; color="{BD}"; fontsize=12;\n'
d += 'i2 [shape=circle, style=filled, fillcolor=black, label="", width=0.2];\n'
d += st('iss', 'Выдан', '<BR/><FONT POINT-SIZE="9">entry / QR + письмо<BR/>ScanInvalid / «Недействителен»</FONT>') + st('used', 'Использован', '<BR/><FONT POINT-SIZE="9">Scan / «Уже использован»</FONT>')
d += 'i2 -> iss;\n iss -> used [label="ScanValid\\n[подпись верна]"];\n'
d += '}\n}'
render('G4_states', d)


# ------------------------------------------------ G5 sequence
plt.rcParams['font.family'] = 'DejaVu Sans'
BDc = '#A80036'; BGc = '#FEFECE'
lifelines = ['Покупатель', 'WebUI', 'RestApi', 'ReservationService', 'OrderService', 'QrService', 'MailService', 'Mock SMTP']
stereo = ['actor', 'part', 'part', 'part', 'part', 'part', 'part', 'external part']
X = {n: 1.2 + i * 2.15 for i, n in enumerate(lifelines)}
msgs = [
 ('Покупатель', 'WebUI', '1: выбрать места', False),
 ('WebUI', 'RestApi', '2: POST /api/reservations', False),
 ('RestApi', 'ReservationService', '3: reserve(seats)', False),
 ('ReservationService', 'RestApi', '4: reservation_id, expiresAt (+10 мин)', True),
 ('RestApi', 'WebUI', '5: 201 Created', True),
 ('Покупатель', 'WebUI', '6: ввести email, «Оплатить»', False),
 ('WebUI', 'RestApi', '7: POST /api/orders, /pay (эмуляция)', False),
 ('RestApi', 'OrderService', '8: createOrder(reservation, email)', False),
 ('OrderService', 'ReservationService', '9: confirm(seats) → «Продано»', False),
 ('OrderService', 'QrService', '10: generate(ticket)', False),
 ('QrService', 'OrderService', '11: PNG + подпись HMAC', True),
 ('OrderService', 'MailService', '12: send(email, tickets) [async]', False),
 ('MailService', 'Mock SMTP', '13: SMTP DATA (≤ 60 с)', False),
 ('OrderService', 'RestApi', '14: order_id, tickets', True),
 ('RestApi', 'WebUI', '15: 200 OK', True),
 ('WebUI', 'Покупатель', '16: страница подтверждения с QR', True),
]
fig, ax = plt.subplots(figsize=(18, 11.5))
top = 11.0; step = 0.58
ax.set_xlim(0, 1.2 + 7 * 2.15 + 1.4); ax.set_ylim(0, top + 0.9); ax.axis('off')
for n, s in zip(lifelines, stereo):
    x = X[n]
    ax.add_patch(Rectangle((x - 0.95, top - 0.35), 1.9, 0.7, fc=BGc, ec=BDc, lw=1.4))
    ax.text(x, top + 0.14, f'«{s}»', ha='center', va='center', fontsize=8.5, style='italic')
    ax.text(x, top - 0.1, n, ha='center', va='center', fontsize=9.5, fontweight='bold')
    ax.plot([x, x], [top - 0.35, 0.4], color=BDc, lw=1, ls=(0, (6, 4)))
y = top - 0.95
for a, b, t, ret in msgs:
    xa, xb = X[a], X[b]
    ax.annotate('', xy=(xb, y), xytext=(xa, y), arrowprops=dict(arrowstyle='->' if ret else '-|>', color=BDc, lw=1.3, ls='--' if ret else '-'))
    ax.text((xa + xb) / 2, y + 0.09, t, ha='center', va='bottom', fontsize=9, bbox=dict(fc='white', ec='none', pad=1.2), zorder=5)
    y -= step
# activation of lifeline note
ax.add_patch(FancyBboxPatch((X['ReservationService'] - 0.9, 0.45), 6.4, 0.5, boxstyle='round,pad=0.05', fc='#FFFFF0', ec=BDc, lw=1, zorder=5))
ax.text(X['ReservationService'] + 2.3, 0.7, 'alt: бронь истекла → 409 Conflict, места «Свободно»', ha='center', va='center', fontsize=9, style='italic', zorder=6)
plt.savefig(OUT + 'G5_purchase_sequence.png', dpi=130, bbox_inches='tight', facecolor='white')
plt.close()

# ------------------------------------------------ G6 UI structure
d = HDR + 'rankdir=LR; nodesep=0.45; ranksep=1.0; \n'
def scr(n, name, parts, attrs, acts, mock):
    comps = []
    if parts: comps.append(('parts', parts))
    if attrs: comps.append(('attributes', attrs))
    if acts: comps.append(('actions', acts))
    comps.append(('satisfies', [mock]))
    return f'{n} [label={box("part def", name, comps)}];\n'
d += scr('home', 'HomePage', ['filters : FilterPanel', 'cards : EventCard[*]', 'pagination : Pagination'],
         ['sortBy : String = "date"', 'dateFrom, dateTo : String', 'genre : String', 'priceMin, priceMax : Real'], ['book(event)'], 'REQ-FUNC-001, REQ-INT-001')
d += scr('event', 'EventPage', ['seatMap : SeatMap', 'cart : CartPanel', 'timer : ReservationTimer'],
         ['title, dateTime, venue : String', 'legend : Free | Reserved | Sold', 'subtotal, total : Real (BYN)'], ['selectSeat', 'removeSeat', 'checkout'], 'REQ-FUNC-002…005, REQ-INT-002')
d += scr('conf', 'ConfirmationPage', ['ticketCard : TicketCard'],
         ['orderId : String', 'email : String', 'qrImage : Image'], ['downloadPdf  (0.2)'], 'REQ-FUNC-006…008, REQ-INT-003')
d += scr('my', 'MyTicketsPage', [], ['orderId : String', 'email : String'], ['find'], 'REQ-FUNC-009, REQ-INT-005')
d += scr('login', 'AdminLoginPage', [], ['login : String', 'password : String'], ['signIn'], 'REQ-FUNC-011')
d += scr('admin', 'AdminPanel', ['kpiCards : KpiCard[4]', 'eventsTable : EventsTable', 'searchBar, statusFilter'],
         ['totalEvents, activeEvents : Integer', 'totalRevenueByn : Real', 'ticketsSold : Integer'], ['createEvent', 'editEvent', 'deleteEvent', 'cancelReservation'], 'REQ-FUNC-012…014, REQ-INT-004')
d += scr('verify', 'VerifyPage', [], ['scanResult : VerifyResult'], ['scan'], 'REQ-FUNC-010, REQ-INT-006')
nav = 'arrowhead=vee, fontsize=10'
d += f'home -> event [{nav}, label="book"];\n'
d += f'event -> conf [{nav}, label="checkout\\n(email + оплата)"];\n'
d += f'conf -> home [{nav}, style=dashed, label="на главную"];\n'
d += f'home -> my [{nav}, style=dashed, label="My Tickets"];\n'
d += f'my -> conf [{nav}, style=dashed, label="билеты найдены"];\n'
d += f'login -> admin [{nav}, label="signIn\\n[роль: администратор]"];\n'
d += f'login -> verify [{nav}, label="signIn\\n[роль: контролёр]"];\n'
d += '}'
render('G6_ui_structure', d)
print('ok')
