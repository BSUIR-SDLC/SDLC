"""Диаграмма вариантов использования EventPass (UML 2.5) -> usecase.png
Запуск: python3 build_usecase.py   (нужен matplotlib и шрифт DejaVu Sans)
Текстовое описание той же диаграммы: src/usecase.puml (PlantUML)."""
import math
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse, Rectangle, Circle

plt.rcParams['font.family'] = 'DejaVu Sans'
fig, ax = plt.subplots(figsize=(17, 11.5))
ax.set_xlim(0, 17); ax.set_ylim(0, 11.5); ax.axis('off')
COL = '#A80036'; FILL = '#FEFECE'

ax.add_patch(Rectangle((3.0, 0.5), 9.0, 10.6, fill=False, ec=COL, lw=1.6))
ax.text(7.5, 10.8, 'EventPass', ha='center', va='center', fontsize=14, fontweight='bold')

W, H = 3.3, 0.95
UC = {
 'UC02': (4.8, 9.9, 'UC-02\nПросмотреть каталог'),
 'UC04': (4.8, 8.7, 'UC-04\nПросмотреть карточку\nсобытия'),
 'UC05': (4.8, 7.5, 'UC-05\nУправлять корзиной'),
 'UC08': (4.8, 6.3, 'UC-08\nОформить заказ'),
 'UC10': (4.8, 5.1, 'UC-10\nПросмотреть историю\nпокупок'),
 'UC09': (4.8, 3.9, 'UC-09\nПросмотреть билет\nс QR-кодом'),
 'UC11': (4.8, 2.7, 'UC-11\nСкачать билет в PDF'),
 'UC03': (9.6, 9.9, 'UC-03\nНайти и отфильтровать\nсобытия'),
 'UC06': (9.6, 8.3, 'UC-06\nЗарезервировать места\nна 15 минут'),
 'UC07': (9.6, 6.7, 'UC-07\nПрименить промокод'),
 'UC01': (9.6, 4.9, 'UC-01\nВойти в систему'),
 'UC12': (9.6, 1.9, 'UC-12\nОсвободить просроченную\nбронь'),
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
 'visitor': actor(1.3, 6.3, 'Посетитель'),
 'api':     actor(14.6, 6.5, 'REST API\n(серверная часть)'),
 'timer':   actor(14.6, 1.9, 'Время\n(таймер брони)'),
}

def ep(c, toward, a=W / 2, b=H / 2):
    dx, dy = toward[0] - c[0], toward[1] - c[1]
    t = math.atan2(dy / b, dx / a)
    return (c[0] + a * math.cos(t), c[1] + b * math.sin(t))

def arrow(p, q, style='-|>', ls='-', label=None, rad=0.0):
    ax.annotate('', xy=q, xytext=p, arrowprops=dict(arrowstyle=style, color=COL if ls != '-' else 'black', lw=1.3, ls=ls,
                connectionstyle=f'arc3,rad={rad}', shrinkA=0, shrinkB=0))
    if label:
        ax.text((p[0] + q[0]) / 2, (p[1] + q[1]) / 2 + 0.12, label, ha='center', va='bottom', fontsize=8.5, style='italic', color=COL,
                bbox=dict(fc='white', ec='none', pad=0.8))

def uc(k): return (UC[k][0], UC[k][1])
# коммуникация: посетитель -> прецедент
for k in ['UC02', 'UC04', 'UC05', 'UC08', 'UC10', 'UC09']:
    arrow((A['visitor'][0] + 0.35, A['visitor'][1] + 0.25), ep(uc(k), A['visitor']), '->')
# система -> внешняя система
for k in ['UC06', 'UC01']:
    arrow(ep(uc(k), A['api']), (A['api'][0] - 0.35, A['api'][1] + 0.25), '->')
arrow((A['timer'][0] - 0.35, A['timer'][1] + 0.25), ep(uc('UC12'), A['timer']), '->')

def rel(a, b, lab):
    arrow(ep(uc(a), uc(b)), ep(uc(b), uc(a)), '->', '--', lab)

rel('UC05', 'UC06', '«include»')
rel('UC08', 'UC01', '«include»')
rel('UC10', 'UC01', '«include»')
rel('UC09', 'UC01', '«include»')
rel('UC03', 'UC02', '«extend»')
rel('UC07', 'UC05', '«extend»')
rel('UC11', 'UC09', '«extend»')
plt.savefig('usecase.png', dpi=130, bbox_inches='tight', facecolor='white')
