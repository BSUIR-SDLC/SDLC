import { CATEGORY_LABELS, Category, Filters } from '../domain/types';
import { emptyFilters, validateFilters } from '../domain/catalog';

interface Props {
  filters: Filters;
  cities: string[];
  onChange: (f: Filters) => void;
}

const toMinor = (v: string): number | null => (v.trim() === '' ? null : Math.round(Number(v) * 100));

export function FilterPanel({ filters, cities, onChange }: Props) {
  const error = validateFilters(filters);
  const set = (patch: Partial<Filters>) => onChange({ ...filters, ...patch });
  return (
    <form className="filters" aria-label="Фильтры" onSubmit={(e) => e.preventDefault()}>
      <input type="search" placeholder="Поиск по названию" value={filters.query} onChange={(e) => set({ query: e.target.value })} />
      <select value={filters.city} onChange={(e) => set({ city: e.target.value })}>
        <option value="">Все города</option>
        {cities.map((c) => (
          <option key={c} value={c}>{c}</option>
        ))}
      </select>
      <select value={filters.category} onChange={(e) => set({ category: e.target.value as Category | '' })}>
        <option value="">Все категории</option>
        {(Object.keys(CATEGORY_LABELS) as Category[]).map((c) => (
          <option key={c} value={c}>{CATEGORY_LABELS[c]}</option>
        ))}
      </select>
      <input type="date" aria-label="Дата с" value={filters.dateFrom} onChange={(e) => set({ dateFrom: e.target.value })} />
      <input type="date" aria-label="Дата по" value={filters.dateTo} onChange={(e) => set({ dateTo: e.target.value })} />
      <input type="number" min="0" placeholder="Цена от" onChange={(e) => set({ priceMinMinor: toMinor(e.target.value) })} />
      <input type="number" min="0" placeholder="Цена до" onChange={(e) => set({ priceMaxMinor: toMinor(e.target.value) })} />
      <button type="button" onClick={() => onChange(emptyFilters)}>Сбросить</button>
      {error && <p role="alert" className="error">{error}</p>}
    </form>
  );
}
