// Analytics.h — статистика, контроль бюджета и советы по организации трат
#pragma once
#include <string>
#include <utility>
#include <vector>

#include "Ledger.h"

struct CategoryTotal {
    std::string category;
    Money amount = 0;
    double share = 0;  // доля от всех расходов (доходов) периода, %
};

struct PeriodStats {
    Date from, to;
    Money income = 0;
    Money expense = 0;
    Money balance() const { return income - expense; }
    std::vector<CategoryTotal> expenseByCategory;  // по убыванию суммы
    std::vector<CategoryTotal> incomeByCategory;
    Money needs = 0, wants = 0, savings = 0;      // расходы по группам 50/30/20
    int operations = 0;
};

enum class BudgetState { Normal, Near, Over };

struct BudgetStatus {
    std::string category;
    Money limit = 0;
    Money spent = 0;
    double usedPercent = 0;
    BudgetState state = BudgetState::Normal;
};

enum class AdviceLevel { Good, Info, Warning };

struct Advice {
    AdviceLevel level;
    std::string title;
    std::string text;
};

constexpr double kBudgetNearPercent = 80.0;  // порог предупреждения о приближении к лимиту

PeriodStats computeStats(const Ledger& ledger, const Date& from, const Date& to);
PeriodStats monthStats(const Ledger& ledger, const Date& anyDayOfMonth);
std::vector<BudgetStatus> budgetStatuses(const Ledger& ledger, const Date& anyDayOfMonth);
BudgetStatus budgetStatus(const Ledger& ledger, const std::string& category, const Date& anyDayOfMonth);
// Помесячная динамика за months месяцев, заканчивая месяцем lastMonth
std::vector<PeriodStats> monthlyDynamics(const Ledger& ledger, const Date& lastMonth, int months);
// Советы для месяца (today — текущая дата, нужна для прогноза)
std::vector<Advice> makeAdvice(const Ledger& ledger, const Date& month, const Date& today);
