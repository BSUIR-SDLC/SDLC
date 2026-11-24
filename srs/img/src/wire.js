// Прототипы экранов (wireframe) в стиле эскиза: чёрные линии, рукописный шрифт, без цвета.
// Каждый экран подписан элементом модели SysML v2, который он изображает («part» имя : Screen).
const NS = 'http://www.w3.org/2000/svg';
let svg;

function init(w, h) {
  svg = document.createElementNS(NS, 'svg');
  svg.setAttribute('width', w); svg.setAttribute('height', h);
  svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
  document.body.appendChild(svg);
  el('rect', { x: 0, y: 0, width: w, height: h, fill: '#fff' });
}
function el(tag, a) { const e = document.createElementNS(NS, tag); for (const k in a) e.setAttribute(k, a[k]); svg.appendChild(e); return e; }
function t(x, y, s, size = 16, o = {}) {
  const e = el('text', { x, y, 'font-size': size, 'text-anchor': o.anchor || 'start', 'font-weight': o.bold ? 700 : 400, fill: o.color || '#111' });
  e.textContent = s; return e;
}
// прямоугольник «от руки»: толстая линия и смещённая тень снизу-справа, как у кнопок на эскизе
function r(x, y, w, h, o = {}) {
  if (o.shadow) el('rect', { x: x + 4, y: y + 4, width: w, height: h, rx: o.rx ?? 4, fill: '#111' });
  return el('rect', { x, y, width: w, height: h, rx: o.rx ?? 4, fill: o.fill || '#fff', stroke: '#111', 'stroke-width': o.sw ?? 2.5 });
}
function btn(x, y, w, h, s, size = 17) { r(x, y, w, h, { shadow: true }); t(x + w / 2, y + h / 2 + size / 3, s, size, { anchor: 'middle' }); }
function field(x, y, w, label, value = '', o = {}) {
  if (label) t(x, y - 8, label, 15);
  r(x, y, w, 36, { sw: 2.5 });
  if (value) t(x + 10, y + 24, value, 15, { color: o.hint ? '#888' : '#111' });
  if (o.error) t(x, y + 54, '⚠ ' + o.error, 14);
}
function img(x, y, w, h) { r(x, y, w, h, { sw: 2 }); el('path', { d: `M${x},${y} L${x + w},${y + h} M${x + w},${y} L${x},${y + h}`, stroke: '#111', 'stroke-width': 1.5 }); }
function chip(x, y, s, on = false) {
  const w = s.length * 8.6 + 26;
  r(x, y, w, 30, { rx: 15, fill: on ? '#111' : '#fff', sw: 2 });
  t(x + w / 2, y + 20, s, 14, { anchor: 'middle', color: on ? '#fff' : '#111' });
  return w;
}
function stepper(x, y, v) { r(x, y, 112, 34, { sw: 2 }); t(x + 18, y + 24, '−', 20, { anchor: 'middle' }); t(x + 56, y + 23, v, 16, { anchor: 'middle' }); t(x + 94, y + 24, '+', 20, { anchor: 'middle' });
  el('path', { d: `M${x + 36},${y} V${y + 34} M${x + 76},${y} V${y + 34}`, stroke: '#111', 'stroke-width': 2 }); }
function check(x, y, s, on) { r(x, y, 20, 20, { sw: 2, rx: 3 }); if (on) t(x + 10, y + 16, '✓', 16, { anchor: 'middle' }); t(x + 30, y + 16, s, 15); }
// значки линиями (без цветных эмодзи)
function lens(x, y) { el('circle', { cx: x, cy: y, r: 7, fill: 'none', stroke: '#111', 'stroke-width': 2 }); line(x + 5, y + 5, x + 11, y + 11, 2.5); }
function bell(x, y) { el('path', { d: `M${x - 8},${y + 6} Q${x - 8},${y - 10} ${x},${y - 10} Q${x + 8},${y - 10} ${x + 8},${y + 6} Z M${x - 3},${y + 9} H${x + 3}`, fill: 'none', stroke: '#111', 'stroke-width': 2 }); }
function search(x, y, w, s) { r(x, y, w, 40, { rx: 20, sw: 2 }); lens(x + 22, y + 18); t(x + 40, y + 26, s, 15, { color: '#666' }); }
function line(x1, y1, x2, y2, sw = 2) { el('line', { x1, y1, x2, y2, stroke: '#111', 'stroke-width': sw }); }

// телефон: рамка экрана, подпись модели сверху и подпись рисунка снизу
function phone(x, y, model, caption) {
  t(x + 190, y - 14, model, 15, { anchor: 'middle' });
  r(x, y, 380, 740, { rx: 26, sw: 3 });
  return { x: x + 18, y: y + 22, w: 344 };
}
// нижняя карусель вкладок: видно три, остальные листаются
function carousel(p, active) {
  const y = p.y + 652;
  r(p.x, y, p.w, 52, { rx: 26, sw: 2.5 });
  const names = ['Главная', 'Каталог', 'Собрать', 'Корзина', 'Профиль'];
  const start = Math.min(Math.max(active - 1, 0), 2);
  for (let i = 0; i < 3; i++) {
    const n = start + i, cx = p.x + 57 + i * 115;
    if (n === active) r(cx - 50, y + 6, 100, 40, { rx: 20, fill: '#111', sw: 2 });
    t(cx, y + 32, names[n], 15, { anchor: 'middle', color: n === active ? '#fff' : '#111' });
  }
  t(p.x + p.w - 8, y + 33, '›', 22, { anchor: 'end' });
}
