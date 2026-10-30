// App.cpp — экраны консольного приложения HomeLedger
#include "App.h"

#include <algorithm>
#include <cstdio>
#include <initializer_list>
#include <iostream>
#include <random>
#include <sstream>

#include "Analytics.h"
#include "Console.h"
#include "Text.h"

using console::Color;
using console::paint;
using std::cout;

namespace {

std::string signedMoney(Money m, bool income) { return (income ? "+" : "−") + formatMoney(m); }

std::string pct0(double v) {
    char buf[16];
    std::snprintf(buf, sizeof buf, "%.0f %%", v);
    return buf;
}

Color budgetColor(BudgetState s) {
    return s == BudgetState::Over ? Color::Red : s == BudgetState::Near ? Color::Yellow : Color::Green;
}

bool isCmd(const std::string& in, std::initializer_list<const char*> variants) {
    for (const char* v : variants)
        if (toLowerAscii(in) == v) return true;
    return false;
}

// Команда вида "и 12" / "у12" -> номер операции
bool cmdWithId(const std::string& in, std::initializer_list<const char*> prefixes, int& id) {
    for (const char* p : prefixes) {
        std::string pre = p;
        if (in.rfind(pre, 0) == 0) {
            std::string rest = trim(in.substr(pre.size()));
            if (rest.empty()) {
                id = -1;
                return true;
            }
            try {
                size_t pos = 0;
                id = std::stoi(rest, &pos);
                return pos == rest.size();
            } catch (...) {
                return false;
            }
        }
    }
    return false;
}

}  // namespace

// ───────────────────────── общий цикл ─────────────────────────

int App::run(bool demo) {
    std::vector<std::string> warnings;
    storage_.load(ledger_, warnings);
    for (const auto& w : warnings) cout << paint("[!] " + w, Color::Yellow) << "\n";
    std::string err;
    if (!storage_.backup(err)) cout << paint("[!] " + err, Color::Yellow) << "\n";
    if (demo) {
        if (ledger_.operations().empty()) {
            generateDemo();
            cout << paint("Созданы демонстрационные данные за шесть месяцев.", Color::Cyan) << "\n";
        } else {
            cout << paint("Демонстрационные данные не созданы: в каталоге уже есть операции.", Color::Yellow) << "\n";
        }
    }
    if (!ledger_.wallets().empty()) lastWallet_ = ledger_.wallets().back().name;

    while (!eof_) {
        mainScreen();
        std::string choice;
        if (!ask("Выберите пункт: ", choice)) break;
        if (choice == "1") addOperation(OpType::Expense);
        else if (choice == "2") addOperation(OpType::Income);
        else if (choice == "3") addTransfer();
        else if (choice == "4") journal();
        else if (choice == "5") statistics();
        else if (choice == "6") budgets();
        else if (choice == "7") advice();
        else if (choice == "8") walletsAndCategories();
        else if (choice == "9") exportReport();
        else if (choice == "0") break;
        else cout << paint("Нет такого пункта меню.", Color::Yellow) << "\n";
    }
    cout << "\nДанные сохранены в каталоге «" << storage_.dir() << "». До свидания!\n";
    return 0;
}

bool App::ask(const std::string& prompt, std::string& out) {
    if (eof_) return false;
    if (!console::readLine(prompt, out)) {
        eof_ = true;
        cout << "\n";
        return false;
    }
    return true;
}

bool App::confirm(const std::string& question) {
    std::string a;
    if (!ask(question + " (д/н): ", a)) return false;
    return isCmd(a, {"д", "да", "y", "yes", "l"});
}

void App::persist() {
    std::string err;
    if (!storage_.save(ledger_, err)) cout << paint("[!] Ошибка сохранения: " + err, Color::Red) << "\n";
}

void App::printWrapped(const std::string& text, size_t width, const std::string& indent, bool indentFirst) {
    std::istringstream in(text);
    std::string word, cur;
    bool first = true;
    while (in >> word) {
        if (!cur.empty() && utf8Length(cur) + 1 + utf8Length(word) > width) {
            cout << (first && !indentFirst ? "" : indent) << cur << "\n";
            first = false;
            cur.clear();
        }
        cur += (cur.empty() ? "" : " ") + word;
    }
    if (!cur.empty()) cout << (first && !indentFirst ? "" : indent) << cur << "\n";
}

// ───────────────────────── главный экран ─────────────────────────

void App::mainScreen() {
    Date today = Date::today();
    console::header("HomeLedger — Домашняя бухгалтерия" + std::string(29, ' ') + today.str());
    Money total = ledger_.totalBalance();
    cout << " Баланс: " << paint(formatMoney(total) + " BYN", total < 0 ? Color::Red : Color::Bold) << "   (";
    bool first = true;
    for (const auto& w : ledger_.wallets()) {
        cout << (first ? "" : " · ") << w.name << ": " << formatMoney(ledger_.walletBalance(w.name));
        first = false;
    }
    cout << ")\n";
    PeriodStats s = monthStats(ledger_, today);
    cout << " " << today.monthName() << ": доходы " << paint(signedMoney(s.income, true), Color::Green)
         << " · расходы " << paint(signedMoney(s.expense, false), Color::Red) << " · остаток "
         << paint((s.balance() >= 0 ? "+" : "") + formatMoney(s.balance()),
                  s.balance() >= 0 ? Color::Green : Color::Red)
         << "\n";
    for (const auto& b : budgetStatuses(ledger_, today)) {
        if (b.state == BudgetState::Normal) continue;
        std::string msg = b.state == BudgetState::Over
                              ? "Лимит «" + b.category + "» превышен на " + formatMoney(b.spent - b.limit) + " BYN"
                              : "Лимит «" + b.category + "»: использовано " + pct0(b.usedPercent) + ", осталось " +
                                    formatMoney(b.limit - b.spent) + " BYN";
        cout << paint(" [!] " + msg, budgetColor(b.state)) << "\n";
    }
    cout << "\n";
    const char* items[] = {"Добавить расход",
                           "Добавить доход",
                           "Перевод между кошельками",
                           "Журнал операций",
                           "Статистика",
                           "Бюджеты (лимиты по категориям)",
                           "Советы по организации трат",
                           "Кошельки и категории",
                           "Экспорт отчёта за месяц в CSV"};
    for (int i = 0; i < 9; ++i) cout << "  " << paint(std::to_string(i + 1), Color::Cyan) << "  " << items[i] << "\n";
    cout << "  " << paint("0", Color::Cyan) << "  Выход\n\n";
}

// ───────────────────────── ввод операций ─────────────────────────

bool App::askMoney(const std::string& prompt, Money& out, bool allowEmpty, Money def) {
    while (true) {
        std::string in;
        if (!ask(prompt, in)) return false;
        if (in.empty() && allowEmpty) {
            out = def;
            return true;
        }
        if (in.empty()) return false;  // пустой ввод — отмена
        Money m = 0;
        if (parseMoney(in, m) && m > 0 && m <= kMaxAmount) {
            out = m;
            return true;
        }
        cout << paint("  Введите положительную сумму, например 12,50", Color::Yellow) << "\n";
    }
}

bool App::chooseCategory(OpType type, std::string& out, const std::string& def) {
    auto cats = ledger_.categories(type);
    if (cats.empty()) return false;
    int defIdx = 1;
    for (size_t i = 0; i < cats.size(); ++i)
        if (cats[i].name == def) defIdx = static_cast<int>(i) + 1;
    cout << "  Категория:\n";
    for (size_t i = 0; i < cats.size(); ++i) {
        std::string item = padLeft(std::to_string(i + 1), 2) + " " + padRight(cats[i].name, 19);
        cout << "   " << item << ((i % 3 == 2 || i + 1 == cats.size()) ? "\n" : "");
    }
    while (true) {
        std::string in;
        if (!ask("  Номер категории [" + std::to_string(defIdx) + "]: ", in)) return false;
        int n = defIdx;
        if (!in.empty()) {
            try {
                n = std::stoi(in);
            } catch (...) {
                n = 0;
            }
        }
        if (n >= 1 && n <= static_cast<int>(cats.size())) {
            out = cats[static_cast<size_t>(n - 1)].name;
            return true;
        }
        cout << paint("  Нет категории с таким номером.", Color::Yellow) << "\n";
    }
}

bool App::chooseWallet(const std::string& prompt, std::string& out, const std::string& def) {
    const auto& ws = ledger_.wallets();
    int defIdx = 1;
    cout << "  " << prompt << ":";
    for (size_t i = 0; i < ws.size(); ++i) {
        if (ws[i].name == def) defIdx = static_cast<int>(i) + 1;
        cout << "  " << i + 1 << " " << ws[i].name << " (" << formatMoney(ledger_.walletBalance(ws[i].name)) << ")";
    }
    cout << "\n";
    while (true) {
        std::string in;
        if (!ask("  Номер кошелька [" + std::to_string(defIdx) + "]: ", in)) return false;
        int n = defIdx;
        if (!in.empty()) {
            try {
                n = std::stoi(in);
            } catch (...) {
                n = 0;
            }
        }
        if (n >= 1 && n <= static_cast<int>(ws.size())) {
            out = ws[static_cast<size_t>(n - 1)].name;
            return true;
        }
        cout << paint("  Нет кошелька с таким номером.", Color::Yellow) << "\n";
    }
}

void App::addOperation(OpType type) {
    bool income = type == OpType::Income;
    console::header(income ? "Новый доход" : "Новый расход");
    cout << paint("  Пустая сумма — отмена ввода.", Color::Gray) << "\n";
    Operation op;
    op.type = type;
    if (!askMoney("  Сумма, BYN: ", op.amount, false)) {
        cout << "  Ввод отменён.\n";
        return;
    }
    if (!chooseCategory(type, op.category, lastCategory_[income ? 1 : 0])) return;
    if (!chooseWallet(income ? "Зачислить в кошелёк" : "Списать с кошелька", op.wallet, lastWallet_)) return;
    while (true) {
        std::string in;
        if (!ask("  Дата [" + Date::today().str() + "]: ", in)) return;
        if (Date::parse(in, op.date) && !(op.date > Date::today())) break;
        cout << paint("  Введите дату в формате ДД.ММ.ГГГГ, не позже сегодняшней.", Color::Yellow) << "\n";
    }
    if (!ask("  Комментарий (необязательно): ", op.comment)) return;
    op.comment = utf8Truncate(op.comment, 100);

    std::string err = ledger_.validate(op);
    if (!err.empty()) {
        cout << paint("  Операция не сохранена: " + err, Color::Red) << "\n";
        return;
    }
    if (!income && op.amount > ledger_.walletBalance(op.wallet)) {
        cout << paint("  В кошельке «" + op.wallet + "» только " + formatMoney(ledger_.walletBalance(op.wallet)) +
                          " BYN.",
                      Color::Yellow)
             << "\n";
        if (!confirm("  Всё равно сохранить расход?")) {
            cout << "  Операция не сохранена.\n";
            return;
        }
    }
    int id = ledger_.add(op);
    persist();
    lastCategory_[income ? 1 : 0] = op.category;
    lastWallet_ = op.wallet;
    cout << paint("  ✓ " + std::string(typeName(type)) + " №" + std::to_string(id) + " на " +
                      formatMoney(op.amount) + " BYN («" + op.category + "», " + op.wallet +
                      ") сохранён. Баланс: " + formatMoney(ledger_.totalBalance()) + " BYN",
                  Color::Green)
         << "\n";
    if (!income) showBudgetWarning(op.category, op.date);
}

void App::showBudgetWarning(const std::string& category, const Date& date) {
    BudgetStatus b = budgetStatus(ledger_, category, date);
    if (b.limit == 0) return;
    if (b.state == BudgetState::Over)
        cout << paint("  [!] Лимит «" + category + "» превышен: потрачено " + formatMoney(b.spent) + " из " +
                          formatMoney(b.limit) + " BYN (" + pct0(b.usedPercent) + ").",
                      Color::Red)
             << "\n";
    else if (b.state == BudgetState::Near)
        cout << paint("  [!] Лимит «" + category + "» почти исчерпан: " + pct0(b.usedPercent) + ", осталось " +
                          formatMoney(b.limit - b.spent) + " BYN.",
                      Color::Yellow)
             << "\n";
    else
        cout << "  Лимит «" << category << "»: использовано " << pct0(b.usedPercent) << ".\n";
}

void App::addTransfer() {
    console::header("Перевод между кошельками");
    if (ledger_.wallets().size() < 2) {
        cout << "  Для перевода нужно минимум два кошелька (меню 8).\n";
        return;
    }
    Operation op;
    op.type = OpType::Transfer;
    if (!askMoney("  Сумма, BYN: ", op.amount, false)) {
        cout << "  Ввод отменён.\n";
        return;
    }
    if (!chooseWallet("Откуда", op.wallet, ledger_.wallets().back().name)) return;
    if (!chooseWallet("Куда", op.toWallet, ledger_.wallets().front().name)) return;
    op.date = Date::today();
    if (!ask("  Комментарий (необязательно): ", op.comment)) return;
    std::string err = ledger_.validate(op);
    if (!err.empty()) {
        cout << paint("  Перевод не выполнен: " + err, Color::Red) << "\n";
        return;
    }
    ledger_.add(op);
    persist();
    cout << paint("  ✓ Переведено " + formatMoney(op.amount) + " BYN: " + op.wallet + " → " + op.toWallet, Color::Green)
         << "\n";
}

// ───────────────────────── журнал ─────────────────────────

void App::journal() {
    Date month = Date::today().firstOfMonth();
    std::string filterCat;  // пусто — все категории
    while (!eof_) {
        auto ops = ledger_.between(month.firstOfMonth(), month.lastOfMonth());
        if (!filterCat.empty())
            ops.erase(std::remove_if(ops.begin(), ops.end(),
                                     [&](const Operation& o) { return o.category != filterCat; }),
                      ops.end());
        console::header("Журнал операций — " + month.monthName() +
                        (filterCat.empty() ? "" : "  [категория: " + filterCat + "]"));
        cout << paint("  " + padLeft("№", 4) + "  " + padRight("Дата", 10) + "  " + padRight("Тип", 7) + "  " +
                          padRight("Категория", 17) + "  " + padRight("Кошелёк", 9) + "  " + padLeft("Сумма", 10) +
                          "  Комментарий",
                      Color::Gray)
             << "\n";
        Money inc = 0, exp = 0;
        for (const auto& o : ops) {
            std::string cat = o.type == OpType::Transfer ? "→ " + o.toWallet : o.category;
            std::string sum = o.type == OpType::Income    ? signedMoney(o.amount, true)
                              : o.type == OpType::Expense ? signedMoney(o.amount, false)
                                                          : formatMoney(o.amount);
            Color c = o.type == OpType::Income ? Color::Green : o.type == OpType::Expense ? Color::Default : Color::Blue;
            cout << "  " << padLeft(std::to_string(o.id), 4) << "  " << o.date.str() << "  "
                 << padRight(typeName(o.type), 7) << "  " << padRight(cat, 17) << "  " << padRight(o.wallet, 9) << "  "
                 << paint(padLeft(sum, 10), c) << "  " << utf8Truncate(o.comment, 18) << "\n";
            if (o.type == OpType::Income) inc += o.amount;
            if (o.type == OpType::Expense) exp += o.amount;
        }
        if (ops.empty()) cout << "  Операций нет.\n";
        cout << paint(console::line(), Color::Gray) << "\n";
        cout << "  Операций: " << ops.size() << "   доходы " << paint(signedMoney(inc, true), Color::Green)
             << "   расходы " << paint(signedMoney(exp, false), Color::Red) << "\n\n";
        cout << "  [<] пред. месяц  [>] след. месяц  [к] фильтр по категории  [и N] изменить №N\n"
                "  [у N] удалить №N  [0] назад\n";
        std::string in;
        if (!ask("Команда: ", in)) return;
        int id = 0;
        if (in == "0" || in.empty()) return;
        if (in == "<" || in == ",") month = month.addMonths(-1);
        else if (in == ">" || in == ".") month = month.addMonths(1);
        else if (isCmd(in, {"к", "k"})) {
            cout << "  0  Все категории\n";
            std::string cat;
            std::string t;
            if (!ask("  Фильтр: 1 — категория расходов, 2 — категория доходов, 0 — сбросить: ", t)) return;
            if (t == "1" && chooseCategory(OpType::Expense, cat, "")) filterCat = cat;
            else if (t == "2" && chooseCategory(OpType::Income, cat, "")) filterCat = cat;
            else filterCat.clear();
        } else if (cmdWithId(in, {"и", "i", "e"}, id)) {
            if (id < 0 && !ask("  Номер операции: ", in)) return;
            if (id < 0) try { id = std::stoi(in); } catch (...) { id = 0; }
            editOperation(id);
        } else if (cmdWithId(in, {"у", "d"}, id)) {
            if (id < 0 && !ask("  Номер операции: ", in)) return;
            if (id < 0) try { id = std::stoi(in); } catch (...) { id = 0; }
            deleteOperation(id);
        } else {
            cout << paint("Неизвестная команда.", Color::Yellow) << "\n";
        }
    }
}

bool App::editOperation(int id) {
    const Operation* found = ledger_.find(id);
    if (!found) {
        cout << paint("  Операция №" + std::to_string(id) + " не найдена.", Color::Yellow) << "\n";
        return false;
    }
    Operation op = *found;
    cout << "  Изменение операции №" << id << ". Enter — оставить прежнее значение.\n";
    if (!askMoney("  Сумма [" + formatMoney(op.amount) + "]: ", op.amount, true, op.amount)) return false;
    if (op.type != OpType::Transfer) {
        if (!chooseCategory(op.type, op.category, op.category)) return false;
        if (!chooseWallet("Кошелёк", op.wallet, op.wallet)) return false;
    }
    while (true) {
        std::string in;
        if (!ask("  Дата [" + op.date.str() + "]: ", in)) return false;
        Date d = op.date;
        if (in.empty() || (Date::parse(in, d) && !(d > Date::today()))) {
            op.date = d;
            break;
        }
        cout << paint("  Неверная дата.", Color::Yellow) << "\n";
    }
    std::string comment;
    if (!ask("  Комментарий [" + op.comment + "] (\"-\" — очистить): ", comment)) return false;
    if (comment == "-") op.comment.clear();
    else if (!comment.empty()) op.comment = utf8Truncate(comment, 100);
    std::string err = ledger_.validate(op);
    if (!err.empty()) {
        cout << paint("  Изменения не сохранены: " + err, Color::Red) << "\n";
        return false;
    }
    ledger_.update(op);
    persist();
    cout << paint("  ✓ Операция №" + std::to_string(id) + " изменена.", Color::Green) << "\n";
    if (op.type == OpType::Expense) showBudgetWarning(op.category, op.date);
    return true;
}

bool App::deleteOperation(int id) {
    const Operation* op = ledger_.find(id);
    if (!op) {
        cout << paint("  Операция №" + std::to_string(id) + " не найдена.", Color::Yellow) << "\n";
        return false;
    }
    std::string what = std::string(typeName(op->type)) + " " + formatMoney(op->amount) + " BYN от " + op->date.str() +
                       (op->category.empty() ? "" : " («" + op->category + "»)");
    if (!confirm("  Удалить операцию №" + std::to_string(id) + ": " + what + "?")) {
        cout << "  Удаление отменено.\n";
        return false;
    }
    ledger_.remove(id);
    persist();
    cout << paint("  ✓ Операция удалена.", Color::Green) << "\n";
    return true;
}

// ───────────────────────── статистика ─────────────────────────

void App::statistics() {
    Date month = Date::today().firstOfMonth();
    while (!eof_) {
        PeriodStats s = monthStats(ledger_, month);
        console::header("Статистика — " + month.monthName());
        cout << "  Доходы " << paint(signedMoney(s.income, true), Color::Green) << "    Расходы "
             << paint(signedMoney(s.expense, false), Color::Red) << "    Остаток "
             << paint((s.balance() >= 0 ? "+" : "") + formatMoney(s.balance()),
                      s.balance() >= 0 ? Color::Green : Color::Red)
             << "    Операций: " << s.operations << "\n\n";

        cout << paint("  Расходы по категориям", Color::Bold) << "\n";
        if (s.expenseByCategory.empty()) cout << "  нет расходов\n";
        double maxShare = s.expenseByCategory.empty() ? 1 : s.expenseByCategory.front().share;
        for (const auto& c : s.expenseByCategory)
            cout << "   " << padRight(c.category, 18) << padLeft(formatMoney(c.amount), 10) << padLeft(pct0(c.share), 6)
                 << "  " << paint(console::bar(c.share / std::max(maxShare, 1.0), 24), Color::Cyan) << "\n";

        cout << "\n" << paint("  Доходы по категориям", Color::Bold) << "\n";
        if (s.incomeByCategory.empty()) cout << "  нет доходов\n";
        for (const auto& c : s.incomeByCategory)
            cout << "   " << padRight(c.category, 18) << padLeft(formatMoney(c.amount), 10) << padLeft(pct0(c.share), 6)
                 << "\n";

        if (s.income > 0) {
            cout << "\n" << paint("  Структура расходов от дохода (правило 50/30/20)", Color::Bold) << "\n";
            struct {
                const char* name;
                Money value;
                double norm;
                bool atMost;
            } rows[] = {{"Необходимое", s.needs, 50, true},
                        {"Желания", s.wants, 30, true},
                        {"Сбережения", s.savings, 20, false}};
            for (const auto& r : rows) {
                double p = percent(r.value, s.income);
                bool ok = r.atMost ? p <= r.norm : p >= r.norm;
                cout << "   " << padRight(r.name, 14) << padLeft(pct0(p), 6) << "  "
                     << paint(console::bar(p / 100.0, 20), ok ? Color::Green : Color::Yellow) << "  норма "
                     << (r.atMost ? "≤ " : "≥ ") << r.norm << " %\n";
            }
        }

        cout << "\n" << paint("  Динамика за 6 месяцев", Color::Bold) << "\n";
        auto dyn = monthlyDynamics(ledger_, month, 6);
        Money maxV = 1;
        for (const auto& d : dyn) maxV = std::max({maxV, d.income, d.expense});
        for (const auto& d : dyn) {
            cout << "   " << padRight(d.from.monthName(), 15) << " доходы "
                 << paint(console::bar(static_cast<double>(d.income) / maxV, 12), Color::Green)
                 << padLeft(formatMoney(d.income), 10) << "  расходы "
                 << paint(console::bar(static_cast<double>(d.expense) / maxV, 12), Color::Red)
                 << padLeft(formatMoney(d.expense), 10) << "\n";
        }
        cout << "\n  [<] пред. месяц  [>] след. месяц  [0] назад\n";
        std::string in;
        if (!ask("Команда: ", in)) return;
        if (in == "<" || in == ",") month = month.addMonths(-1);
        else if (in == ">" || in == ".") month = month.addMonths(1);
        else return;
    }
}

// ───────────────────────── бюджеты ─────────────────────────

void App::budgets() {
    while (!eof_) {
        Date today = Date::today();
        console::header("Бюджеты (месячные лимиты) — " + today.monthName());
        auto list = budgetStatuses(ledger_, today);
        if (list.empty()) {
            cout << "  Лимиты не установлены. Лимит помогает не потратить на категорию больше, чем запланировано.\n";
        } else {
            cout << paint("   " + padRight("Категория", 18) + padLeft("Лимит", 10) + padLeft("Потрачено", 11) +
                              padLeft("Осталось", 10) + "  Использовано",
                          Color::Gray)
                 << "\n";
            for (const auto& b : list) {
                cout << "   " << padRight(b.category, 18) << padLeft(formatMoney(b.limit), 10)
                     << padLeft(formatMoney(b.spent), 11) << padLeft(formatMoney(std::max<Money>(0, b.limit - b.spent)), 10)
                     << "  " << paint(console::bar(b.usedPercent / 100.0, 15), budgetColor(b.state)) << " "
                     << paint(padLeft(pct0(b.usedPercent), 6), budgetColor(b.state))
                     << (b.state == BudgetState::Over ? paint("  превышен", Color::Red)
                         : b.state == BudgetState::Near ? paint("  ≥ 80 %", Color::Yellow)
                                                        : "")
                     << "\n";
            }
        }
        cout << "\n  [1] установить или изменить лимит  [2] снять лимит  [0] назад\n";
        std::string in;
        if (!ask("Команда: ", in)) return;
        if (in == "1") {
            std::string cat;
            if (!chooseCategory(OpType::Expense, cat, "")) continue;
            Money spentNow = ledger_.spent(cat, today.firstOfMonth(), today.lastOfMonth());
            cout << "  В этом месяце на «" << cat << "» уже потрачено " << formatMoney(spentNow) << " BYN.\n";
            Money limit = 0;
            if (!askMoney("  Лимит в месяц, BYN: ", limit, false)) continue;
            ledger_.setBudget(cat, limit);
            persist();
            cout << paint("  ✓ Лимит для «" + cat + "»: " + formatMoney(limit) + " BYN в месяц.", Color::Green) << "\n";
        } else if (in == "2") {
            std::string cat;
            if (!chooseCategory(OpType::Expense, cat, "")) continue;
            ledger_.setBudget(cat, 0);
            persist();
            cout << "  Лимит для «" << cat << "» снят.\n";
        } else {
            return;
        }
    }
}

// ───────────────────────── советы ─────────────────────────

void App::advice() {
    Date today = Date::today();
    console::header("Советы по организации трат — " + today.monthName());
    for (const auto& a : makeAdvice(ledger_, today, today)) {
        const char* mark = a.level == AdviceLevel::Good ? "[+]" : a.level == AdviceLevel::Warning ? "[!]" : "[i]";
        Color c = a.level == AdviceLevel::Good ? Color::Green : a.level == AdviceLevel::Warning ? Color::Yellow : Color::Cyan;
        cout << "  " << paint(std::string(mark) + " " + a.title, c) << "\n";
        printWrapped(a.text, 66, "      ");
    }
    std::string in;
    ask("\nEnter — вернуться в меню ", in);
}

// ───────────────────────── кошельки и категории ─────────────────────────

void App::walletsAndCategories() {
    while (!eof_) {
        console::header("Кошельки и категории");
        cout << paint("  Кошельки", Color::Bold) << "\n";
        for (const auto& w : ledger_.wallets())
            cout << "   " << padRight(w.name, 18) << padLeft(formatMoney(ledger_.walletBalance(w.name)), 12) << " BYN\n";
        cout << "\n" << paint("  Категории расходов", Color::Bold) << "\n";
        for (Group g : {Group::Needs, Group::Wants, Group::Savings}) {
            std::string names;
            for (const auto& c : ledger_.categories(OpType::Expense))
                if (c.group == g) names += (names.empty() ? "" : ", ") + c.name;
            cout << "   " << padRight(std::string(groupName(g)) + ":", 13);
            printWrapped(names, 56, std::string(16, ' '), false);
        }
        std::string inc;
        for (const auto& c : ledger_.categories(OpType::Income)) inc += (inc.empty() ? "" : ", ") + c.name;
        cout << "\n" << paint("  Категории доходов", Color::Bold) << "\n";
        printWrapped(inc, 66, "   ");
        cout << "\n  [1] добавить кошелёк  [2] категорию расходов  [3] категорию доходов  [0] назад\n";
        std::string in;
        if (!ask("Команда: ", in)) return;
        if (in == "1") {
            Wallet w;
            if (!ask("  Название кошелька: ", w.name) || w.name.empty()) continue;
            w.name = utf8Truncate(w.name, 20);
            Money initial = 0;
            if (!askMoney("  Начальный остаток, BYN [0]: ", initial, true, 0)) continue;
            w.initial = initial;
            if (ledger_.addWallet(w)) {
                persist();
                cout << paint("  ✓ Кошелёк добавлен.", Color::Green) << "\n";
            } else {
                cout << paint("  Кошелёк с таким названием уже есть.", Color::Yellow) << "\n";
            }
        } else if (in == "2" || in == "3") {
            Category c;
            c.type = in == "2" ? OpType::Expense : OpType::Income;
            c.group = Group::Income;
            if (!ask("  Название категории: ", c.name) || c.name.empty()) continue;
            c.name = utf8Truncate(c.name, 30);
            if (c.type == OpType::Expense) {
                std::string g;
                if (!ask("  Группа: 1 — необходимое, 2 — желания, 3 — сбережения [2]: ", g)) return;
                c.group = g == "1" ? Group::Needs : g == "3" ? Group::Savings : Group::Wants;
            }
            if (ledger_.addCategory(c)) {
                persist();
                cout << paint("  ✓ Категория добавлена.", Color::Green) << "\n";
            } else {
                cout << paint("  Такая категория уже есть.", Color::Yellow) << "\n";
            }
        } else {
            return;
        }
    }
}

// ───────────────────────── экспорт ─────────────────────────

bool App::askMonth(Date& month) {
    std::string in;
    if (!ask("  Месяц в формате ММ.ГГГГ [" + std::to_string(month.m) + "." + std::to_string(month.y) + "]: ", in))
        return false;
    if (in.empty()) return true;
    int m = 0, y = 0;
    if (std::sscanf(in.c_str(), "%d.%d", &m, &y) == 2 && Date::isValid(y, m, 1)) {
        month = Date{y, m, 1};
        return true;
    }
    cout << paint("  Неверный формат месяца.", Color::Yellow) << "\n";
    return false;
}

void App::exportReport() {
    console::header("Экспорт отчёта за месяц");
    Date month = Date::today().firstOfMonth();
    if (!askMonth(month)) return;
    std::string path, err;
    if (storage_.exportMonth(ledger_, month, path, err))
        cout << paint("  ✓ Отчёт за " + month.monthName() + " сохранён: " + path, Color::Green)
             << "\n  Файл открывается в Excel или LibreOffice Calc.\n";
    else
        cout << paint("  Не удалось сохранить отчёт: " + err, Color::Red) << "\n";
}

// ───────────────────────── демонстрационные данные ─────────────────────────

void App::generateDemo() {
    std::mt19937 rng(2026);
    auto rnd = [&](int lo, int hi) { return std::uniform_int_distribution<int>(lo, hi)(rng); };
    Date today = Date::today();
    Date start = today.firstOfMonth().addMonths(-5);
    ledger_.clear();
    ledger_.setDefaults();
    ledger_.setWalletInitial("Наличные", 5000);
    ledger_.setWalletInitial("Карта", 30000);
    ledger_.setBudget("Продукты", 45000);
    ledger_.setBudget("Кафе и рестораны", 15000);
    ledger_.setBudget("Развлечения", 10000);
    auto add = [&](const Date& d, OpType t, Money amount, const char* cat, const char* wallet, const char* comment,
                   const char* to = "") {
        if (d > today) return;
        Operation op;
        op.date = d;
        op.type = t;
        op.amount = amount;
        op.category = cat;
        op.wallet = wallet;
        op.toWallet = to;
        op.comment = comment;
        ledger_.add(op);
    };
    for (Date m = start; !(m > today); m = m.addMonths(1)) {
        int days = Date::daysInMonth(m.y, m.m);
        auto day = [&](int d) { return Date{m.y, m.m, std::min(d, days)}; };
        add(day(5), OpType::Income, 90000, "Зарплата", "Карта", "основная часть");
        add(day(20), OpType::Income, 60000, "Зарплата", "Карта", "аванс");
        add(day(25), OpType::Income, 18500, "Стипендия", "Карта", "");
        if (rnd(0, 1)) add(day(rnd(10, 18)), OpType::Income, rnd(80, 200) * 100, "Подработка", "Наличные", "репетиторство");
        add(day(1), OpType::Expense, 4500, "Транспорт", "Карта", "проездной");
        add(day(3), OpType::Expense, 2490, "Связь и интернет", "Карта", "мобильная связь");
        add(day(10), OpType::Expense, rnd(15000, 17500), "Жильё и ЖКУ", "Карта", "коммунальные услуги");
        add(day(6), OpType::Transfer, 20000, "", "Карта", "снятие в банкомате", "Наличные");
        add(day(21), OpType::Expense, 15000, "Сбережения", "Карта", "на отпуск");
        for (int d = 1; d <= days; ++d) {
            Date dt = day(d);
            if (d % 3 == 1) add(dt, OpType::Expense, rnd(1500, 6000) + rnd(0, 99), "Продукты", d % 2 ? "Карта" : "Наличные", "");
            if (d % 4 == 2) add(dt, OpType::Expense, rnd(700, 3500), "Кафе и рестораны", "Карта", d % 8 == 2 ? "обед" : "кофе");
            if (d % 7 == 5) add(dt, OpType::Expense, rnd(1000, 3500), "Развлечения", "Карта", "кино / игры");
        }
        add(day(rnd(8, 24)), OpType::Expense, rnd(40, 140) * 100, "Одежда", "Карта", "");
        if (rnd(0, 2) == 0) add(day(rnd(2, 27)), OpType::Expense, rnd(15, 60) * 100, "Здоровье", "Карта", "аптека");
        if (rnd(0, 1)) add(day(rnd(2, 27)), OpType::Expense, rnd(20, 50) * 100, "Подарки", "Наличные", "день рождения друга");
    }
    persist();
}
