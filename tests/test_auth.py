import unittest
from datetime import timedelta

from easyticket import auth
from tests.helpers import NOW, make_db

SECRET = "test-secret"


class PasswordTests(unittest.TestCase):
    def test_hash_is_salted_and_verifiable(self):
        h1, h2 = auth.hash_password("correct horse"), auth.hash_password("correct horse")
        self.assertNotEqual(h1, h2)               # соль разная
        self.assertTrue(auth.verify_password("correct horse", h1))
        self.assertFalse(auth.verify_password("wrong", h1))

    def test_password_not_stored_in_clear(self):
        self.assertNotIn("correct horse", auth.hash_password("correct horse"))

    def test_broken_hash_is_rejected(self):
        self.assertFalse(auth.verify_password("x", "garbage"))


class TokenTests(unittest.TestCase):
    def test_roundtrip(self):
        t = auth.make_token(7, "admin", SECRET, NOW, 60)
        self.assertEqual(auth.verify_token(t, SECRET, NOW), {"user_id": 7, "role": "admin"})

    def test_expired(self):
        t = auth.make_token(7, "admin", SECRET, NOW, 60)
        with self.assertRaises(auth.AuthError):
            auth.verify_token(t, SECRET, NOW + timedelta(seconds=120))

    def test_tampered_payload(self):
        t = auth.make_token(7, "controller", SECRET, NOW, 60)
        body, sig = t.split(".")
        forged = auth.make_token(7, "admin", "другой-ключ", NOW, 60).split(".")[0]
        with self.assertRaises(auth.AuthError):
            auth.verify_token(forged + "." + sig, SECRET, NOW)

    def test_wrong_secret_and_garbage(self):
        t = auth.make_token(7, "admin", SECRET, NOW, 60)
        with self.assertRaises(auth.AuthError):
            auth.verify_token(t, "other", NOW)
        with self.assertRaises(auth.AuthError):
            auth.verify_token("мусор", SECRET, NOW)


class LoginTests(unittest.TestCase):
    def setUp(self):
        self.db = make_db()
        auth.create_staff(self.db, "admin", "StrongPass1", "admin")
        auth.create_staff(self.db, "ctl", "StrongPass2", "controller")

    def login(self, login, pw, now=NOW):
        return auth.login(self.db, login, pw, SECRET, now)

    # REQ-FUNC-011 п.1, п.4
    def test_success_returns_token_with_role(self):
        res = self.login("ctl", "StrongPass2")
        self.assertEqual(res["role"], "controller")
        self.assertEqual(auth.verify_token(res["token"], SECRET, NOW)["role"], "controller")

    def test_wrong_password_and_unknown_user_give_same_error(self):
        with self.assertRaises(auth.AuthError) as a:
            self.login("admin", "bad")
        with self.assertRaises(auth.AuthError) as b:
            self.login("nobody", "bad")
        self.assertEqual(str(a.exception), str(b.exception))

    # п.3: блокировка после 5 неудач на 15 минут
    def test_lockout_after_five_failures(self):
        for _ in range(4):
            with self.assertRaises(auth.AuthError):
                self.login("admin", "bad")
        with self.assertRaises(auth.LockedError):
            self.login("admin", "bad")
        with self.assertRaises(auth.LockedError):       # даже верный пароль не пускает
            self.login("admin", "StrongPass1", NOW + timedelta(minutes=14))

    def test_unlock_after_fifteen_minutes(self):
        for _ in range(5):
            with self.assertRaises(auth.AuthError):
                self.login("admin", "bad")
        res = self.login("admin", "StrongPass1", NOW + timedelta(minutes=16))
        self.assertEqual(res["role"], "admin")

    def test_success_resets_counter(self):
        for _ in range(4):
            with self.assertRaises(auth.AuthError):
                self.login("admin", "bad")
        self.login("admin", "StrongPass1")
        for _ in range(4):                               # снова 4 неудачи без блокировки
            with self.assertRaises(auth.AuthError):
                self.login("admin", "bad")
        self.assertEqual(self.login("admin", "StrongPass1")["role"], "admin")

    # п.2: пароль хранится только в виде хеша
    def test_password_stored_as_hash(self):
        stored = self.db.fetchone("SELECT password_hash FROM staff_users WHERE login = 'admin'")["password_hash"]
        self.assertTrue(stored.startswith("scrypt$"))
        self.assertNotIn("StrongPass1", stored)

    def test_create_staff_validation(self):
        with self.assertRaises(ValueError):
            auth.create_staff(self.db, "x", "short", "admin")
        with self.assertRaises(ValueError):
            auth.create_staff(self.db, "x", "LongEnough1", "hacker")


if __name__ == "__main__":
    unittest.main()
