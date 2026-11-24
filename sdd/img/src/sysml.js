// Рисование диаграмм в графической нотации SysML v2 (общий вид, как у официальной
// реализации SysML v2): определения (def) — прямоугольник с острыми углами, использования —
// со скруглёнными; над именем — ключевое слово в «»; ниже — разделы (doc, subject, actors…).
// Связи: «определено как» — пунктир с полым треугольником; владение — линия с ромбом у владельца;
// satisfy, include, dependency — пунктир с открытой стрелкой и подписью.
const NS = 'http://www.w3.org/2000/svg';
let svg;

function init(w, h, frameTitle) {
  svg = document.createElementNS(NS, 'svg');
  svg.setAttribute('width', w); svg.setAttribute('height', h);
  svg.setAttribute('viewBox', `0 0 ${w} ${h}`);
  document.body.appendChild(svg);
  const defs = el('defs', {});
  defs.innerHTML = `
   <marker id="open" viewBox="0 0 12 12" refX="11" refY="6" markerWidth="12" markerHeight="12" orient="auto"><path d="M1,1 L11,6 L1,11" fill="none" stroke="#333" stroke-width="1.5"/></marker>
   <marker id="tri" viewBox="0 0 16 16" refX="15" refY="8" markerWidth="16" markerHeight="16" orient="auto"><path d="M1,1 L15,8 L1,15 Z" fill="#fff" stroke="#333" stroke-width="1.4"/></marker>
   <marker id="fill" viewBox="0 0 12 12" refX="11" refY="6" markerWidth="11" markerHeight="11" orient="auto"><path d="M1,1 L11,6 L1,11 Z" fill="#222"/></marker>
   <marker id="dia" viewBox="0 0 22 12" refX="1" refY="6" markerWidth="22" markerHeight="12" orient="auto-start-reverse"><path d="M1,6 L11,1 L21,6 L11,11 Z" fill="#fff" stroke="#333" stroke-width="1.4"/></marker>
   <marker id="diaf" viewBox="0 0 22 12" refX="1" refY="6" markerWidth="22" markerHeight="12" orient="auto-start-reverse"><path d="M1,6 L11,1 L21,6 L11,11 Z" fill="#222"/></marker>`;
  svg.appendChild(defs);
  el('rect', { x: 1, y: 1, width: w - 2, height: h - 2, fill: '#fff', stroke: '#888', 'stroke-width': 2 });
  if (frameTitle) text(16, 26, frameTitle, { cls: 'title' });
}

function el(tag, attrs, parent) {
  const e = document.createElementNS(NS, tag);
  for (const k in attrs) e.setAttribute(k, attrs[k]);
  (parent || svg).appendChild(e);
  return e;
}

function text(x, y, s, o = {}) {
  const t = el('text', { x, y, class: o.cls || '', 'text-anchor': o.anchor || 'start' });
  if (o.rotate) t.setAttribute('transform', `rotate(${o.rotate} ${x} ${y})`);
  t.textContent = s;
  return t;
}

// человечек — значок участника (actor) слева от имени
function person(x, y) {
  el('circle', { cx: x, cy: y - 7, r: 6, fill: '#222' });
  el('path', { d: `M${x - 10},${y + 9} Q${x},${y - 3} ${x + 10},${y + 9} Z`, fill: '#222' });
}

// Блок. o: kw, name, def, sections [{title, lines}], person, minH
function box(x, y, w, o) {
  const lineH = 19;
  let h = 52;
  for (const s of o.sections || []) h += 8 + (s.title ? lineH : 0) + s.lines.length * lineH;
  h = Math.max(h, o.minH || 0);
  el('rect', { x, y, width: w, height: h, rx: o.def ? 0 : 12, fill: '#fff', stroke: '#333', 'stroke-width': 1.6 });
  text(x + w / 2, y + 20, `«${o.kw}»`, { cls: 'kw', anchor: 'middle' });
  text(x + w / 2 + (o.person ? 12 : 0), y + 42, o.name, { cls: 'nm', anchor: 'middle' });
  if (o.person) person(x + 22, y + 38);
  let cy = y + 52;
  const rows = {};
  for (const s of o.sections || []) {
    el('line', { x1: x, y1: cy, x2: x + w, y2: cy, stroke: '#aaa', 'stroke-width': 1 });
    cy += 4;
    if (s.title) { cy += lineH - 2; text(x + w / 2, cy - 2, s.title, { cls: 'sec', anchor: 'middle' }); }
    for (const l of s.lines) { cy += lineH; text(x + 8, cy - 5, l, { cls: 'body' }); rows[l] = cy - 10; }
    cy += 4;
  }
  return { x, y, w, h, cx: x + w / 2, cy: y + h / 2, r: x + w, b: y + h, rows };
}

// Связь: d — путь; head: open|tri|fill; tail: dia|diaf; dash — пунктир; label — подпись
function link(d, o = {}) {
  const a = { d, fill: 'none', stroke: '#333', 'stroke-width': 1.4 };
  if (o.dash) a['stroke-dasharray'] = '7 5';
  if (o.head) a['marker-end'] = `url(#${o.head})`;
  if (o.tail) a['marker-start'] = `url(#${o.tail})`;
  el('path', a);
  if (o.label) text(o.lx, o.ly, o.label, { cls: o.lcls || 'lbl', anchor: o.anchor || 'middle', rotate: o.rotate });
}

// «определено как»: от использования вниз к определению
function typedBy(u, d) {
  link(`M${u.cx},${u.b} V${(u.b + d.y) / 2} H${d.cx} V${d.y}`, { dash: true, head: 'tri' });
}

// Порт: квадрат на границе блока
function port(x, y, name, o = {}) {
  el('rect', { x: x - 8, y: y - 8, width: 16, height: 16, fill: '#fff', stroke: '#333', 'stroke-width': 1.6 });
  text(x + (o.dx ?? 12), y + (o.dy ?? -12), name, { cls: 'small', anchor: o.anchor || 'start' });
}

// Узлы поведения
function startNode(x, y) { el('circle', { cx: x, cy: y, r: 11, fill: '#222' }); }
function doneNode(x, y) {
  el('circle', { cx: x, cy: y, r: 13, fill: '#fff', stroke: '#222', 'stroke-width': 2 });
  el('circle', { cx: x, cy: y, r: 7, fill: '#222' });
}
function decideNode(x, y, name) {
  el('path', { d: `M${x},${y - 24} L${x + 30},${y} L${x},${y + 24} L${x - 30},${y} Z`, fill: '#fff', stroke: '#333', 'stroke-width': 1.6 });
  if (name) text(x + 36, y - 14, name, { cls: 'small' });
}
