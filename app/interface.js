"use strict";
const el = id => document.getElementById(id);
let data = {goal:{monthPages:0}, books:[]};
let damaged = false;
const labels = {planned:"Запланирована", reading:"Читается", finished:"Прочитана"};
function attempt(action) {
  el("message").textContent = "";
  try { action(); } catch (error) { el("message").textContent = error.message; }
}
function commit(next, importing = false) {
  check(!damaged || importing, "Загрузите исправную копию для восстановления полки.");
  validate(next);
  localStorage.setItem(KEY, JSON.stringify(next));
  data = next;
  damaged = false;
  render();
}
function render() {
  el("summary").textContent = "Пройдено за месяц: " + monthTotal(data.books) + " стр. · Норма: " + (data.goal.monthPages || "не задана");
  el("goal").elements.pages.value = data.goal.monthPages || "";
  el("shelf").replaceChildren();
  if (!data.books.length) el("shelf").textContent = "Полка пока пуста.";
  for (const b of data.books) {
    const card = document.createElement("article");
    card.innerHTML = '<h3></h3><span></span><p></p><progress max="100"></progress><form><label>Текущая страница<input type="number" required min="0" name="page"></label><button>Отметить страницу</button></form>';
    card.querySelector("h3").textContent = b.title;
    card.querySelector("span").textContent = b.author;
    const percent = Math.round(100 * b.currentPage / b.pageCount);
    card.querySelector("progress").value = percent;
    card.querySelector("p").textContent = b.currentPage + " из " + b.pageCount + " · " + percent + " % · Осталось: " + (b.pageCount-b.currentPage) + " стр. · " + labels[b.status] + (b.finishedOn ? " · " + b.finishedOn : "");
    const form = card.querySelector("form");
    form.elements.page.value = b.currentPage;
    form.elements.page.max = b.pageCount;
    form.onsubmit = e => {
      e.preventDefault();
      attempt(() => {
        const next = structuredClone(data);
        mark(next.books.find(item => item.id === b.id), form.elements.page.valueAsNumber);
        commit(next);
      });
    };
    el("shelf").append(card);
  }
}
el("book").onsubmit = e => {
  e.preventDefault();
  const form = e.currentTarget;
  attempt(() => {
    const next = structuredClone(data);
    const {title,author,total} = form.elements;
    next.books.push({id:crypto.randomUUID(),title:title.value.trim(),author:author.value.trim(),pageCount:total.valueAsNumber,currentPage:0,status:"planned",finishedOn:null,pageEvents:[]});
    commit(next);
    form.reset();
  });
};
el("goal").onsubmit = e => {
  e.preventDefault();
  attempt(() => commit({...data,goal:{monthPages:el("goal").elements.pages.valueAsNumber}}));
};
el("save").onclick = () => attempt(() => {
  check(!damaged, "Сначала восстановите полку из исправной копии.");
  const url = URL.createObjectURL(new Blob([JSON.stringify(data,null,2)],{type:"application/json"}));
  const a = document.createElement("a");
  a.href = url;
  a.download = "polka-shelf.json";
  a.click();
  setTimeout(() => URL.revokeObjectURL(url),1000);
});
el("open").onclick = () => el("file").click();
el("file").onchange = async () => {
  const file = el("file").files[0];
  if (!file) return;
  try {
    const next = JSON.parse(await file.text());
    commit(next,true);
    el("message").textContent = "Копия загружена.";
  } catch (error) { el("message").textContent = "Ошибка загрузки. " + error.message; }
  el("file").value = "";
};
attempt(() => {
  damaged = true;
  const saved = localStorage.getItem(KEY);
  if (saved !== null) data = validate(JSON.parse(saved));
  damaged = false;
});
render();
