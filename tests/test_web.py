import unittest

from easyticket import catalog, web
from easyticket.catalog import EventFilter
from tests.helpers import NOW, add_event, add_hall, days, make_db


class WebTests(unittest.TestCase):
    def setUp(self):
        self.db = make_db()
        self.hall = add_hall(self.db)

    def test_catalog_page_lists_events(self):
        add_event(self.db, self.hall, "Лебединое озеро", "Балет", days(3), prices={"Партер": 25})
        result = catalog.list_events(self.db, EventFilter(), NOW)
        html = web.render_catalog(result, catalog.list_genres(self.db), {})
        self.assertIn("Лебединое озеро", html)
        self.assertIn("25.00 BYN", html)
        self.assertIn('name="genre"', html)

    def test_catalog_page_empty_message(self):
        result = catalog.list_events(self.db, EventFilter(), NOW)
        self.assertIn("Мероприятия не найдены", web.render_catalog(result, [], {}))

    def test_titles_are_escaped(self):
        add_event(self.db, self.hall, "<script>alert(1)</script>", "Балет", days(3))
        result = catalog.list_events(self.db, EventFilter(), NOW)
        html = web.render_catalog(result, [], {})
        self.assertNotIn("<script>alert(1)</script>", html)
        self.assertIn("&lt;script&gt;", html)

    def test_event_page(self):
        ev = add_event(self.db, self.hall, "Лебединое озеро", "Балет", days(3), prices={"VIP": 70, "Партер": 25}, description="Описание")
        html = web.render_event(catalog.get_event(self.db, ev))
        for text in ("Лебединое озеро", "Описание", "VIP", "70.00 BYN", "Партер", "Большой зал"):
            self.assertIn(text, html)

    def test_pages_declare_viewport_and_language(self):
        html = web.render_catalog(catalog.list_events(self.db, EventFilter(), NOW), [], {})
        self.assertIn('name="viewport"', html)
        self.assertIn('lang="ru"', html)


if __name__ == "__main__":
    unittest.main()
