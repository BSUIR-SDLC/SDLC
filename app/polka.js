"use strict";
const KEY = "polka.shelf.v1";
const integer = Number.isSafeInteger;
function check(condition, message) {
  if (!condition) throw new Error(message);
}
function localDate(d = new Date()) {
  return [d.getFullYear(), String(d.getMonth()+1).padStart(2,"0"), String(d.getDate()).padStart(2,"0")].join("-");
}
function validDate(value) {
  return typeof value === "string" && /^\d{4}-\d{2}-\d{2}$/.test(value) &&
    localDate(new Date(value + "T12:00:00")) === value;
}
function status(page, total) {
  return page === 0 ? "planned" : page === total ? "finished" : "reading";
}
function validate(data) {
  const ids = new Set();
  const nonempty = s => typeof s === "string" && s.trim().length > 0;
  check(integer(data?.goal?.monthPages) && data.goal.monthPages >= 0 && Array.isArray(data.books), "Некорректная структура полки.");
  for (const b of data.books) {
    check(b && nonempty(b.id) && !ids.has(b.id) && nonempty(b.title) && nonempty(b.author), "Проверьте название, автора и идентификатор книги.");
    ids.add(b.id);
    check(integer(b.pageCount) && b.pageCount > 0 && integer(b.currentPage) && b.currentPage >= 0 && b.currentPage <= b.pageCount, "Страница должна быть целым числом в пределах объёма.");
    check(b.status === status(b.currentPage,b.pageCount) && (b.status === "finished" ? validDate(b.finishedOn) : b.finishedOn === null), "Статус или дата завершения не соответствуют странице.");
    check(Array.isArray(b.pageEvents) && b.pageEvents.every(e => e && validDate(e.date) && integer(e.pages) && e.pages > 0), "Некорректное событие чтения.");
  }
  return data;
}
function mark(book, page, date = localDate()) {
  check(integer(page) && page >= 0 && page <= book.pageCount, "Проверьте номер страницы.");
  const delta = page - book.currentPage;
  if (delta > 0) book.pageEvents.push({date, pages:delta});
  book.currentPage = page;
  book.status = status(page, book.pageCount);
  book.finishedOn = book.status === "finished" ? book.finishedOn || date : null;
}
function monthTotal(books, today = localDate()) {
  return books.flatMap(b => b.pageEvents).reduce((sum,e) => sum + (e.date.slice(0,7) === today.slice(0,7) ? e.pages : 0), 0);
}
