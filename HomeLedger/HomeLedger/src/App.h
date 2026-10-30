// App.h — консольный интерфейс приложения (экраны и меню)
#pragma once
#include <string>

#include "Ledger.h"
#include "Storage.h"

class App {
public:
    explicit App(Storage storage) : storage_(std::move(storage)) {}
    int run(bool demo);

private:
    void mainScreen();
    void addOperation(OpType type);
    void addTransfer();
    void journal();
    void statistics();
    void budgets();
    void advice();
    void walletsAndCategories();
    void exportReport();

    bool editOperation(int id);
    bool deleteOperation(int id);

    // вспомогательные
    bool ask(const std::string& prompt, std::string& out);  // false — конец ввода
    bool confirm(const std::string& question);
    bool askMoney(const std::string& prompt, Money& out, bool allowEmpty, Money def = 0);
    bool chooseCategory(OpType type, std::string& out, const std::string& def);
    bool chooseWallet(const std::string& prompt, std::string& out, const std::string& def);
    bool askMonth(Date& month);
    void persist();
    void showBudgetWarning(const std::string& category, const Date& date);
    void printWrapped(const std::string& text, size_t width, const std::string& indent, bool indentFirst = true);
    void generateDemo();

    Storage storage_;
    Ledger ledger_;
    bool eof_ = false;
    std::string lastCategory_[2];  // последняя выбранная категория расходов / доходов
    std::string lastWallet_;
};
