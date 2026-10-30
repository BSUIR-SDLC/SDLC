// Ledger.cpp — правила ведения учёта
#include "Ledger.h"

#include <algorithm>

#include "Text.h"

const char* typeName(OpType t) {
    switch (t) {
        case OpType::Income: return "Доход";
        case OpType::Expense: return "Расход";
        case OpType::Transfer: return "Перевод";
    }
    return "";
}

const char* groupName(Group g) {
    switch (g) {
        case Group::Needs: return "Необходимое";
        case Group::Wants: return "Желания";
        case Group::Savings: return "Сбережения";
        case Group::Income: return "Доход";
    }
    return "";
}

std::string Ledger::validate(const Operation& op) const {
    if (op.amount <= 0) return "Сумма должна быть больше нуля.";
    if (op.amount > kMaxAmount) return "Сумма слишком большая.";
    if (op.date > Date::today()) return "Дата операции не может быть позже сегодняшней.";
    if (!hasWallet(op.wallet)) return "Кошелёк «" + op.wallet + "» не найден.";
    if (utf8Length(op.comment) > 100) return "Комментарий длиннее 100 символов.";
    if (op.type == OpType::Transfer) {
        if (!hasWallet(op.toWallet)) return "Кошелёк «" + op.toWallet + "» не найден.";
        if (op.toWallet == op.wallet) return "Нельзя перевести деньги в тот же кошелёк.";
    } else if (!category(op.category, op.type)) {
        return "Категория «" + op.category + "» не найдена.";
    }
    return {};
}

int Ledger::add(Operation op) {
    op.id = nextId_++;
    ops_.push_back(op);
    return op.id;
}

void Ledger::loadOperation(const Operation& op) {
    ops_.push_back(op);
    nextId_ = std::max(nextId_, op.id + 1);
}

bool Ledger::update(const Operation& op) {
    for (auto& o : ops_)
        if (o.id == op.id) {
            o = op;
            return true;
        }
    return false;
}

bool Ledger::remove(int id) {
    auto it = std::find_if(ops_.begin(), ops_.end(), [id](const Operation& o) { return o.id == id; });
    if (it == ops_.end()) return false;
    ops_.erase(it);
    return true;
}

const Operation* Ledger::find(int id) const {
    for (const auto& o : ops_)
        if (o.id == id) return &o;
    return nullptr;
}

std::vector<Operation> Ledger::between(const Date& from, const Date& to) const {
    std::vector<Operation> res;
    for (const auto& o : ops_)
        if (from <= o.date && o.date <= to) res.push_back(o);
    std::stable_sort(res.begin(), res.end(), [](const Operation& a, const Operation& b) {
        if (!(a.date == b.date)) return a.date < b.date;
        return a.id < b.id;
    });
    return res;
}

Money Ledger::walletBalance(const std::string& wallet) const {
    Money sum = 0;
    for (const auto& w : wallets_)
        if (w.name == wallet) sum += w.initial;
    for (const auto& o : ops_) {
        if (o.type == OpType::Income && o.wallet == wallet) sum += o.amount;
        if (o.type == OpType::Expense && o.wallet == wallet) sum -= o.amount;
        if (o.type == OpType::Transfer) {
            if (o.wallet == wallet) sum -= o.amount;
            if (o.toWallet == wallet) sum += o.amount;
        }
    }
    return sum;
}

Money Ledger::totalBalance() const {
    Money sum = 0;
    for (const auto& w : wallets_) sum += walletBalance(w.name);
    return sum;
}

Money Ledger::spent(const std::string& category, const Date& from, const Date& to) const {
    Money sum = 0;
    for (const auto& o : ops_)
        if (o.type == OpType::Expense && o.category == category && from <= o.date && o.date <= to) sum += o.amount;
    return sum;
}

std::vector<Category> Ledger::categories(OpType type) const {
    std::vector<Category> res;
    for (const auto& c : cats_)
        if (c.type == type) res.push_back(c);
    return res;
}

const Category* Ledger::category(const std::string& name, OpType type) const {
    for (const auto& c : cats_)
        if (c.name == name && c.type == type) return &c;
    return nullptr;
}

bool Ledger::addCategory(const Category& c) {
    if (c.name.empty() || category(c.name, c.type)) return false;
    cats_.push_back(c);
    return true;
}

bool Ledger::hasWallet(const std::string& name) const {
    return std::any_of(wallets_.begin(), wallets_.end(), [&](const Wallet& w) { return w.name == name; });
}

bool Ledger::addWallet(const Wallet& w) {
    if (w.name.empty() || hasWallet(w.name)) return false;
    wallets_.push_back(w);
    return true;
}

bool Ledger::setWalletInitial(const std::string& name, Money initial) {
    for (auto& w : wallets_)
        if (w.name == name) {
            w.initial = initial;
            return true;
        }
    return false;
}

void Ledger::setBudget(const std::string& category, Money limit) {
    budgets_.erase(std::remove_if(budgets_.begin(), budgets_.end(),
                                  [&](const Budget& b) { return b.category == category; }),
                   budgets_.end());
    if (limit > 0) budgets_.push_back(Budget{category, limit});
}

Money Ledger::budgetFor(const std::string& category) const {
    for (const auto& b : budgets_)
        if (b.category == category) return b.limit;
    return 0;
}

void Ledger::clear() {
    ops_.clear();
    cats_.clear();
    wallets_.clear();
    budgets_.clear();
    nextId_ = 1;
}

void Ledger::setDefaults() {
    const struct {
        const char* name;
        Group group;
    } expense[] = {
        {"Продукты", Group::Needs},          {"Жильё и ЖКУ", Group::Needs},     {"Транспорт", Group::Needs},
        {"Связь и интернет", Group::Needs},  {"Здоровье", Group::Needs},       {"Кафе и рестораны", Group::Wants},
        {"Развлечения", Group::Wants},       {"Одежда", Group::Wants},         {"Подарки", Group::Wants},
        {"Прочее", Group::Wants},            {"Сбережения", Group::Savings},
    };
    for (const auto& e : expense) cats_.push_back(Category{e.name, OpType::Expense, e.group});
    for (const char* name : {"Зарплата", "Стипендия", "Подработка", "Подарки", "Прочие доходы"})
        cats_.push_back(Category{name, OpType::Income, Group::Income});
    wallets_.push_back(Wallet{"Наличные", 0});
    wallets_.push_back(Wallet{"Карта", 0});
}
