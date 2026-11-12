import unittest

from easyticket import catalog
from easyticket.catalog import EventFilter
from tests.helpers import NOW, add_event, add_hall, days, make_db


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.db = make_db()
        self.hall = add_hall(self.db)
        self.swan = add_event(self.db, self.hall, "Лебединое озеро", "Балет", days(3), prices={"VIP": 70, "Партер": 25})
        self.opera = add_event(self.db, self.hall, "Травиата", "Опера", days(10), prices={"Партер": 60})
        self.jazz = add_event(self.db, self.hall, "Джаз", "Концерт", days(20), prices={"Партер": 120})

    def ids(self, **kw):
        return [e["id"] for e in catalog.list_events(self.db, EventFilter(**kw), NOW)["events"]]

    # REQ-FUNC-001 п.1: только будущие
    def test_only_future_events(self):
        add_event(self.db, self.hall, "Прошедшее", "Балет", days(-1))
        self.assertEqual(self.ids(), [self.swan, self.opera, self.jazz])

    def test_draft_and_ended_are_hidden(self):
        add_event(self.db, self.hall, "Черновик", "Балет", days(2), status="draft")
        add_event(self.db, self.hall, "Завершено", "Балет", days(2), status="ended")
        self.assertEqual(self.ids(), [self.swan, self.opera, self.jazz])

    # п.2: карточка содержит поля и минимальную цену
    def test_item_fields_and_min_price(self):
        item = catalog.list_events(self.db, EventFilter(), NOW)["events"][0]
        self.assertEqual(item["title"], "Лебединое озеро")
        self.assertEqual(item["genre"], "Балет")
        self.assertEqual(item["venue"], "Большой зал")
        self.assertEqual(float(item["min_price"]), 25.0)

    # п.3: фильтры
    def test_filter_by_genre(self):
        self.assertEqual(self.ids(genre="Опера"), [self.opera])

    def test_filter_by_date_range_is_inclusive(self):
        d = days(10).date().isoformat()
        self.assertEqual(self.ids(date_from=d, date_to=d), [self.opera])

    def test_filter_by_price_range(self):
        self.assertEqual(self.ids(price_min=50, price_max=100), [self.swan, self.opera])
        self.assertEqual(self.ids(price_min=100), [self.jazz])

    def test_filters_combine(self):
        self.assertEqual(self.ids(genre="Балет", price_max=30), [self.swan])
        self.assertEqual(self.ids(genre="Опера", price_max=30), [])

    # п.4: пустой результат
    def test_empty_result(self):
        result = catalog.list_events(self.db, EventFilter(genre="Мюзикл"), NOW)
        self.assertEqual(result["events"], [])
        self.assertEqual(result["total"], 0)
        self.assertEqual(result["pages"], 1)

    # п.5: постраничная выдача
    def test_pagination(self):
        first = catalog.list_events(self.db, EventFilter(page=1, page_size=2), NOW)
        second = catalog.list_events(self.db, EventFilter(page=2, page_size=2), NOW)
        self.assertEqual([e["id"] for e in first["events"]], [self.swan, self.opera])
        self.assertEqual([e["id"] for e in second["events"]], [self.jazz])
        self.assertEqual((first["total"], first["pages"]), (3, 2))

    def test_invalid_arguments(self):
        with self.assertRaises(ValueError):
            catalog.list_events(self.db, EventFilter(page=0), NOW)
        with self.assertRaises(ValueError):
            catalog.list_events(self.db, EventFilter(page_size=100), NOW)
        with self.assertRaises(ValueError):
            catalog.list_events(self.db, EventFilter(date_from="не дата"), NOW)

    def test_sql_injection_in_genre_is_harmless(self):
        self.assertEqual(self.ids(genre="x' OR '1'='1"), [])

    def test_genres(self):
        self.assertEqual(catalog.list_genres(self.db), ["Балет", "Концерт", "Опера"])


class EventDetailsTests(unittest.TestCase):
    def setUp(self):
        self.db = make_db()
        self.hall = add_hall(self.db, vip=2, parter=3)
        self.ev = add_event(self.db, self.hall, "Лебединое озеро", "Балет", days(3), prices={"VIP": 70, "Партер": 25}, description="Балет в двух актах")

    # REQ-FUNC-002
    def test_details(self):
        e = catalog.get_event(self.db, self.ev)
        self.assertEqual(e["title"], "Лебединое озеро")
        self.assertEqual(e["description"], "Балет в двух актах")
        self.assertEqual(e["venue"], "Большой зал")
        self.assertEqual([(p["category"], float(p["price_byn"])) for p in e["prices"]], [("VIP", 70.0), ("Партер", 25.0)])
        self.assertEqual({s["category"]: s["seats"] for s in e["seat_counts"]}, {"VIP": 2, "Партер": 3})

    def test_not_found(self):
        self.assertIsNone(catalog.get_event(self.db, 9999))

    def test_draft_is_not_available(self):
        draft = add_event(self.db, self.hall, "Черновик", "Балет", days(5), status="draft")
        self.assertIsNone(catalog.get_event(self.db, draft))


if __name__ == "__main__":
    unittest.main()
