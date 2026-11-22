import { applyFilters, freeSeats, minPriceMinor, paginate } from '../domain/catalog';
import { CATEGORY_LABELS, EventItem, Filters, formatMoney } from '../domain/types';

interface Props {
  events: EventItem[];
  filters: Filters;
  page: number;
  onPage: (p: number) => void;
  onAdd: (event: EventItem, ticketTypeId: string) => void;
}

export function CatalogPage({ events, filters, page, onPage, onAdd }: Props) {
  const filtered = applyFilters(events, filters);
  const view = paginate(filtered, page);
  if (view.total === 0) {
    return <p className="empty">События не найдены. Измените условия поиска или сбросьте фильтры.</p>;
  }
  return (
    <section aria-label="Каталог событий">
      <ul className="cards">
        {view.items.map((e) => {
          const min = minPriceMinor(e);
          return (
            <li key={e.id} className="card">
              <h3>{e.title}</h3>
              <p>{new Date(e.date).toLocaleDateString('ru-RU')} · {e.city}, {e.venue}</p>
              <p>{CATEGORY_LABELS[e.category]} · от {min === null ? '—' : formatMoney(min)} · мест: {freeSeats(e)}</p>
              {e.ticketTypes.map((t) => (
                <button key={t.id} disabled={t.free === 0} onClick={() => onAdd(e, t.id)}>
                  {t.name}: {formatMoney(t.priceMinor)}{t.free === 0 ? ' (нет мест)' : ''}
                </button>
              ))}
            </li>
          );
        })}
      </ul>
      <nav aria-label="Страницы">
        <button disabled={view.page <= 1} onClick={() => onPage(view.page - 1)}>Назад</button>
        <span> {view.page} / {view.totalPages} </span>
        <button disabled={view.page >= view.totalPages} onClick={() => onPage(view.page + 1)}>Вперёд</button>
      </nav>
    </section>
  );
}
