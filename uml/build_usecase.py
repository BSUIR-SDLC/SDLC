"""Диаграмма вариантов использования EasyTicket (UML 2.5) -> usecase.png
Запуск: python3 build_usecase.py   (нужен matplotlib и шрифт DejaVu Sans)
Текстовое описание той же диаграммы: src/usecase.puml (PlantUML)."""
import math
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, Rectangle, Circle

plt.rcParams['font.family'] = 'DejaVu Sans'
fig, ax = plt.subplots(figsize=(18.5, 11.5))
ax.set_xlim(0, 18.5); ax.set_ylim(0, 11.5); ax.axis('off')
COL = '#A80036'; FILL = '#FEFECE'

# граница системы
ax.add_patch(Rectangle((3.0, 0.4), 11.6, 10.7, fill=False, ec=COL, lw=1.6))
ax.text(8.8, 10.8, 'EasyTicket', ha='center', va='center', fontsize=14, fontweight='bold')

W, H = 3.4, 0.95
UC = {
 'UC01': (4.9, 9.6, 'UC-01\nПросмотреть афишу'),
 'UC02': (4.9, 8.35, 'UC-02\nПросмотреть мероприятие\nи схему зала'),
 'UC03': (4.9, 7.1, 'UC-03\nЗабронировать места'),
 'UC04': (4.9, 5.85, 'UC-04\nОформить заказ'),
 'UC05': (4.9, 4.6, 'UC-05\nВыдать и отправить билет'),
 'UC06': (4.9, 3.35, 'UC-06\nНайти билеты по заказу'),
 'UC07': (4.9, 2.1, 'UC-07\nВернуть билет'),
 'UC08': (12.4, 9.6, 'UC-08\nПроверить билет на входе'),
 'UC09': (12.4, 8.35, 'UC-09\nУправлять мероприятиями'),
 'UC10': (12.4, 7.1, 'UC-10\nПросмотреть статистику'),
 'UC11': (8.5, 8.2, 'UC-11\nВойти в систему'),
 'UC12': (12.4, 4.6, 'UC-12\nОтменить бронь'),
 'UC13': (12.4, 2.5, 'UC-13\nОсвободить просроченные\nброни'),
}
for k, (x, y, t) in UC.items():
    ax.add_patch(Ellipse((x, y), W, H, fc=FILL, ec=COL, lw=1.4))
    ax.text(x, y, t, ha='center', va='center', fontsize=9)

def actor(x, y, name):
    ax.add_patch(Circle((x, y + 0.55), 0.17, fill=False, ec='black', lw=1.4))
    ax.plot([x, x], [y + 0.38, y - 0.15], color='black', lw=1.4)
    ax.plot([x - 0.3, x + 0.3], [y + 0.25, y + 0.25], color='black', lw=1.4)
    ax.plot([x, x - 0.25], [y - 0.15, y - 0.65], color='black', lw=1.4)
    ax.plot([x, x + 0.25], [y - 0.15, y - 0.65], color='black', lw=1.4)
    ax.text(x, y - 0.95, name, ha='center', va='top', fontsize=10, fontweight='bold')
    return (x, y)

A = {
 'buyer': actor(1.3, 6.3, 'Покупатель'),
 'smtp':  actor(1.3, 2.6, 'SMTP-сервер\n(внешняя система)'),
 'admin': actor(17.0, 7.0, 'Администратор'),
 'ctl':   actor(17.0, 9.6, 'Контролёр'),
 'timer': actor(17.0, 2.5, 'Время\n(таймер)'),
}

def ep(c, toward, a=W / 2, b=H / 2):
    dx, dy = toward[0] - c[0], toward[1] - c[1]
    t = math.atan2(dy / b, dx / a) if True else 0
    return (c[0] + a * math.cos(t), c[1] + b * math.sin(t))

def arrow(p, q, style='-|>', ls='-', label=None, rad=0.0):
    ax.annotate('', xy=q, xytext=p, arrowprops=dict(arrowstyle=style, color=COL if ls != '-' else 'black', lw=1.3, ls=ls,
                connectionstyle=f'arc3,rad={rad}', shrinkA=0, shrinkB=0))
    if label:
        ax.text((p[0] + q[0]) / 2, (p[1] + q[1]) / 2 + 0.12, label, ha='center', va='bottom', fontsize=8.5, style='italic', color=COL,
                bbox=dict(fc='white', ec='none', pad=0.8))

def uc(k): return (UC[k][0], UC[k][1])
# коммуникация: актёр -> прецедент
for k in ['UC01', 'UC02', 'UC03', 'UC04', 'UC06', 'UC07']:
    arrow((A['buyer'][0] + 0.35, A['buyer'][1] + 0.25), ep(uc(k), A['buyer']), '->')
arrow(ep(uc('UC05'), A['smtp']), (A['smtp'][0] + 0.35, A['smtp'][1] + 0.25), '->')   # система -> внешняя система
arrow((A['ctl'][0] - 0.35, A['ctl'][1] + 0.25), ep(uc('UC08'), A['ctl']), '->')
for k in ['UC09', 'UC10', 'UC12']:
    arrow((A['admin'][0] - 0.35, A['admin'][1] + 0.25), ep(uc(k), A['admin']), '->')
arrow((A['timer'][0] - 0.35, A['timer'][1] + 0.25), ep(uc('UC13'), A['timer']), '->')

# include / extend
def rel(a, b, lab):
    arrow(ep(uc(a), uc(b)), ep(uc(b), uc(a)), '->', '--', lab)

rel('UC04', 'UC05', '«include»')
rel('UC07', 'UC06', '«extend»')
for k in ['UC08', 'UC09', 'UC10', 'UC12']:
    rel(k, 'UC11', '«include»')
plt.savefig('usecase.png', dpi=130, bbox_inches='tight', facecolor='white')
