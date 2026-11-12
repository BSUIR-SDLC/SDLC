import unittest

from easyticket import auth, catalog
from easyticket.catalog import EventFilter
from easyticket.seed import seed
from tests.helpers import make_db


class SeedTests(unittest.TestCase):
    def test_seed_loads_events_and_admin(self):
        db = make_db()
        seed(db, admin_password="DemoAdmin1")
        self.assertEqual(db.fetchone("SELECT COUNT(*) AS n FROM seats")["n"], 2 * 10 + 5 * 12 + 4 * 12)
        self.assertEqual(catalog.list_events(db, EventFilter(page_size=50))["total"], 4)
        self.assertEqual(auth.login(db, "admin", "DemoAdmin1", "k", catalog.utc_now())["role"], "admin")

    def test_seed_is_idempotent(self):
        db = make_db()
        seed(db, admin_password="DemoAdmin1")
        seed(db, admin_password="DemoAdmin1")
        self.assertEqual(db.fetchone("SELECT COUNT(*) AS n FROM halls")["n"], 1)


if __name__ == "__main__":
    unittest.main()
