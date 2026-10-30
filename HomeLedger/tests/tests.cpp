// tests.cpp — модульные тесты логики HomeLedger (без сторонних библиотек)
#include <cstdio>
#include <filesystem>
#include <iostream>
#include <string>

#include "Analytics.h"
#include "Storage.h"
#include "Text.h"

static int g_failed = 0, g_total = 0;

#define CHECK(...)                                                              \
    do {                                                                         \
        ++g_total;                                                               \
        if (!(__VA_ARGS__)) {                                                           \
            ++g_failed;                                                          \
            std::cout << "FAIL " << __FILE__ << ":" << __LINE__ << "  " #__VA_ARGS__ "\n"; \
        }                                                                        \
    } while (0)

static Operation makeOp(OpType t, Money amount, const char* cat, const char* wallet, Date d) {
    Operation op;
    op.type = t;
    op.amount = amount;
    op.category = cat;
    op.wallet = wallet;
    op.date = d;
    return op;
}

static void testMoney() {
    Money m = 0;
    CHECK(parseMoney("12,5", m) && m == 1250);
    CHECK(parseMoney("1 200.05", m) && m == 120005);
    CHECK(parseMoney("7", m) && m == 700);
    CHECK(!parseMoney("12,345", m));
    CHECK(!parseMoney("abc", m));
    CHECK(!parseMoney("", m));
    CHECK(formatMoney(123456789) == "1 234 567,89");
    CHECK(formatMoney(-5) == "-0,05");
    CHECK(moneyToCsv(123456) == "1234.56");
    Money a = 0, b = 0, c = 0;  // целые копейки: 0,10 + 0,20 == 0,30 ровно
    CHECK(parseMoney("0,10", a) && parseMoney("0,20", b) && parseMoney("0,30", c) && a + b == c);
}

static void testDate() {
    Date d;
    CHECK(Date::parse("2026-02-28", d) && d.toDays() == Date{2026, 2, 28}.toDays());
    CHECK(!Date::parse("2026-02-29", d));
    CHECK(Date::parse("29.02.2024", d) && d.d == 29);
    CHECK(Date{2026, 12, 31}.addDays(1) == (Date{2027, 1, 1}));
    CHECK(Date{2026, 1, 15}.addMonths(-1) == (Date{2025, 12, 1}));
    CHECK(Date::daysInMonth(2024, 2) == 29);
}

static void testText() {
    CHECK(utf8Length("Привет") == 6);
    CHECK(padRight("Да", 4) == "Да  ");
    auto f = csvSplit("1;\"а;б\";\"в \"\"г\"\"\"");
    CHECK(f.size() == 3 && f[1] == "а;б" && f[2] == "в \"г\"");
    CHECK(csvField("а;б") == "\"а;б\"");
}

static void testLedger() {
    Ledger l;
    l.setDefaults();
    l.setWalletInitial("Наличные", 1000);
    Date d{2026, 10, 1};
    CHECK(l.validate(makeOp(OpType::Expense, 0, "Продукты", "Карта", d)) != "");          // нулевая сумма
    CHECK(l.validate(makeOp(OpType::Expense, 100, "Неизвестно", "Карта", d)) != "");      // нет категории
    CHECK(l.validate(makeOp(OpType::Expense, 100, "Продукты", "Сейф", d)) != "");          // нет кошелька
    CHECK(l.validate(makeOp(OpType::Expense, 100, "Продукты", "Карта", Date::today().addDays(1))) != "");
    CHECK(l.validate(makeOp(OpType::Expense, 100, "Продукты", "Карта", d)).empty());

    l.add(makeOp(OpType::Income, 100000, "Зарплата", "Карта", d));
    l.add(makeOp(OpType::Expense, 30000, "Продукты", "Карта", d));
    int id = l.add(makeOp(OpType::Expense, 5000, "Кафе и рестораны", "Наличные", d));
    Operation tr = makeOp(OpType::Transfer, 20000, "", "Карта", d);
    tr.toWallet = "Наличные";
    l.add(tr);
    CHECK(l.walletBalance("Карта") == 100000 - 30000 - 20000);
    CHECK(l.walletBalance("Наличные") == 1000 - 5000 + 20000);
    CHECK(l.totalBalance() == 1000 + 100000 - 35000);  // перевод не меняет общий баланс

    PeriodStats s = monthStats(l, d);
    CHECK(s.income == 100000 && s.expense == 35000 && s.balance() == 65000);
    CHECK(s.expenseByCategory.front().category == "Продукты");
    CHECK(s.needs == 30000 && s.wants == 5000);

    l.setBudget("Кафе и рестораны", 6000);
    CHECK(budgetStatus(l, "Кафе и рестораны", d).state == BudgetState::Near);  // 83 %
    l.setBudget("Кафе и рестораны", 4000);
    CHECK(budgetStatus(l, "Кафе и рестораны", d).state == BudgetState::Over);
    l.setBudget("Кафе и рестораны", 0);
    CHECK(l.budgets().empty());

    CHECK(l.remove(id) && !l.find(id));
    CHECK(!makeAdvice(l, d, Date{2026, 10, 15}).empty());
}

static void testStorage() {
    namespace fs = std::filesystem;
    std::string dir = (fs::temp_directory_path() / "homeledger_test").u8string();
    fs::remove_all(fs::u8path(dir));
    Storage st(dir);
    Ledger a;
    std::vector<std::string> w;
    CHECK(st.load(a, w) && w.empty() && !a.allCategories().empty());  // новый каталог — стандартные категории
    Operation op = makeOp(OpType::Expense, 1234, "Продукты", "Карта", Date{2026, 10, 2});
    op.comment = "хлеб; молоко \"2,5%\"";
    a.add(op);
    a.setBudget("Продукты", 50000);
    std::string err;
    CHECK(st.save(a, err));
    Ledger b;
    CHECK(st.load(b, w) && w.empty());
    CHECK(b.operations().size() == 1 && b.operations()[0].comment == op.comment && b.operations()[0].amount == 1234);
    CHECK(b.budgetFor("Продукты") == 50000);
    std::string path;
    CHECK(st.exportMonth(b, Date{2026, 10, 1}, path, err) && fs::exists(fs::u8path(path)));
    fs::remove_all(fs::u8path(dir));
}

int main() {
    testMoney();
    testDate();
    testText();
    testLedger();
    testStorage();
    std::cout << (g_total - g_failed) << " из " << g_total << " проверок пройдено\n";
    return g_failed ? 1 : 0;
}
