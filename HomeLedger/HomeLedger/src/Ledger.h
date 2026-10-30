// Ledger.h — предметная модель: операции, категории, кошельки, бюджеты (лимиты)
#pragma once
#include <string>
#include <vector>

#include "Date.h"
#include "Money.h"

enum class OpType { Income, Expense, Transfer };

// Группа категории для правила 50/30/20
enum class Group { Needs, Wants, Savings, Income };

struct Operation {
    int id = 0;
    Date date;
    OpType type = OpType::Expense;
    Money amount = 0;
    std::string category;  // для перевода — пусто
    std::string wallet;    // кошелёк списания/зачисления
    std::string toWallet;  // только для перевода
    std::string comment;
};

struct Category {
    std::string name;
    OpType type = OpType::Expense;
    Group group = Group::Needs;
};

struct Wallet {
    std::string name;
    Money initial = 0;  // начальный остаток
};

struct Budget {
    std::string category;
    Money limit = 0;  // месячный лимит расходов
};

const char* typeName(OpType t);
const char* groupName(Group g);

class Ledger {
public:
    // Возвращает пустую строку, если операция корректна, иначе текст ошибки
    std::string validate(const Operation& op) const;
    int add(Operation op);                     // присваивает id, возвращает его
    bool update(const Operation& op);          // по id
    bool remove(int id);
    const Operation* find(int id) const;

    std::vector<Operation> between(const Date& from, const Date& to) const;  // отсортировано по дате
    const std::vector<Operation>& operations() const { return ops_; }

    Money walletBalance(const std::string& wallet) const;
    Money totalBalance() const;
    Money spent(const std::string& category, const Date& from, const Date& to) const;

    // Категории
    std::vector<Category> categories(OpType type) const;
    const Category* category(const std::string& name, OpType type) const;
    bool addCategory(const Category& c);
    const std::vector<Category>& allCategories() const { return cats_; }

    // Кошельки
    const std::vector<Wallet>& wallets() const { return wallets_; }
    bool hasWallet(const std::string& name) const;
    bool addWallet(const Wallet& w);
    bool setWalletInitial(const std::string& name, Money initial);

    // Бюджеты
    const std::vector<Budget>& budgets() const { return budgets_; }
    void setBudget(const std::string& category, Money limit);  // limit == 0 — удалить
    Money budgetFor(const std::string& category) const;

    void setDefaults();  // стандартные категории и кошельки для нового пользователя
    void clear();

    // Доступ для хранилища
    void loadOperation(const Operation& op);
    void loadCategory(const Category& c) { cats_.push_back(c); }
    void loadWallet(const Wallet& w) { wallets_.push_back(w); }
    void loadBudget(const Budget& b) { budgets_.push_back(b); }

private:
    std::vector<Operation> ops_;
    std::vector<Category> cats_;
    std::vector<Wallet> wallets_;
    std::vector<Budget> budgets_;
    int nextId_ = 1;
};
