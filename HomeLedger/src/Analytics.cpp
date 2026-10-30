// Analytics.cpp
#include "Analytics.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <map>

namespace {

std::vector<CategoryTotal> toSortedTotals(const std::map<std::string, Money>& m, Money total) {
    std::vector<CategoryTotal> v;
    for (const auto& [name, sum] : m) v.push_back(CategoryTotal{name, sum, percent(sum, total)});
    std::sort(v.begin(), v.end(), [](const CategoryTotal& a, const CategoryTotal& b) {
        return a.amount != b.amount ? a.amount > b.amount : a.category < b.category;
    });
    return v;
}

std::string pct(double v) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.0f %%", v);
    return buf;
}

// неразрывные пробелы, чтобы сумма не разрывалась при переносе строки
std::string money(Money m) {
    std::string s = formatMoney(m), r;
    for (char c : s) r += (c == ' ') ? std::string("\xC2\xA0") : std::string(1, c);
    return r + "\xC2\xA0" "BYN";
}

}  // namespace

PeriodStats computeStats(const Ledger& ledger, const Date& from, const Date& to) {
    PeriodStats s;
    s.from = from;
    s.to = to;
    std::map<std::string, Money> exp, inc;
    for (const auto& o : ledger.between(from, to)) {
        if (o.type == OpType::Transfer) continue;  // переводы не меняют общий баланс
        ++s.operations;
        if (o.type == OpType::Income) {
            s.income += o.amount;
            inc[o.category] += o.amount;
        } else {
            s.expense += o.amount;
            exp[o.category] += o.amount;
            const Category* c = ledger.category(o.category, OpType::Expense);
            Group g = c ? c->group : Group::Wants;
            if (g == Group::Needs) s.needs += o.amount;
            else if (g == Group::Savings) s.savings += o.amount;
            else s.wants += o.amount;
        }
    }
    s.expenseByCategory = toSortedTotals(exp, s.expense);
    s.incomeByCategory = toSortedTotals(inc, s.income);
    return s;
}

PeriodStats monthStats(const Ledger& ledger, const Date& d) {
    return computeStats(ledger, d.firstOfMonth(), d.lastOfMonth());
}

BudgetStatus budgetStatus(const Ledger& ledger, const std::string& category, const Date& d) {
    BudgetStatus b;
    b.category = category;
    b.limit = ledger.budgetFor(category);
    b.spent = ledger.spent(category, d.firstOfMonth(), d.lastOfMonth());
    b.usedPercent = percent(b.spent, b.limit);
    if (b.limit > 0) {
        if (b.spent > b.limit) b.state = BudgetState::Over;
        else if (b.usedPercent >= kBudgetNearPercent) b.state = BudgetState::Near;
    }
    return b;
}

std::vector<BudgetStatus> budgetStatuses(const Ledger& ledger, const Date& d) {
    std::vector<BudgetStatus> res;
    for (const auto& b : ledger.budgets()) res.push_back(budgetStatus(ledger, b.category, d));
    std::sort(res.begin(), res.end(),
              [](const BudgetStatus& a, const BudgetStatus& b) { return a.usedPercent > b.usedPercent; });
    return res;
}

std::vector<PeriodStats> monthlyDynamics(const Ledger& ledger, const Date& lastMonth, int months) {
    std::vector<PeriodStats> res;
    for (int i = months - 1; i >= 0; --i) res.push_back(monthStats(ledger, lastMonth.firstOfMonth().addMonths(-i)));
    return res;
}

std::vector<Advice> makeAdvice(const Ledger& ledger, const Date& month, const Date& today) {
    std::vector<Advice> res;
    PeriodStats s = monthStats(ledger, month);
    PeriodStats prev = monthStats(ledger, month.firstOfMonth().addMonths(-1));

    if (s.operations == 0) {
        res.push_back({AdviceLevel::Info, "Нет данных",
                       "За " + month.monthName() + " операций нет. Вносите доходы и расходы сразу после покупки — "
                       "так статистика будет точной."});
        return res;
    }
    if (s.income == 0) {
        res.push_back({AdviceLevel::Warning, "Нет доходов",
                       "В этом месяце не записано ни одного дохода. Без доходов нельзя оценить долю трат: "
                       "добавьте зарплату, стипендию или другие поступления."});
    }

    // 1. Правило 50/30/20: необходимое / желания / сбережения от дохода
    if (s.income > 0) {
        double needs = percent(s.needs, s.income), wants = percent(s.wants, s.income),
               savings = percent(s.savings + std::max<Money>(0, s.balance()), s.income);
        std::string fact = "Необходимое " + pct(needs) + " (норма ≤ 50 %), желания " + pct(wants) +
                           " (≤ 30 %), сбережения и остаток " + pct(savings) + " (≥ 20 %).";
        if (needs <= 50 && wants <= 30 && savings >= 20) {
            res.push_back({AdviceLevel::Good, "Правило 50/30/20 выполняется", fact});
        } else {
            std::string tip;
            if (needs > 50) tip += " Обязательные траты велики: проверьте тарифы связи, ЖКУ, транспорт.";
            if (wants > 30)
                tip += " На желания уходит больше 30 % — установите лимиты на кафе, развлечения и покупки.";
            if (savings < 20) tip += " Откладывайте 20 % дохода сразу в день его получения.";
            res.push_back({AdviceLevel::Warning, "Правило 50/30/20 нарушено", fact + tip});
        }
    }

    // 2. Прогноз до конца текущего месяца и дневной лимит
    if (month.sameMonth(today)) {
        int day = today.d, days = Date::daysInMonth(today.y, today.m), left = days - day;
        Money forecast = s.expense * days / std::max(day, 1);
        std::string text = "Средний расход " + money(s.expense / std::max(day, 1)) + " в день, прогноз расходов на месяц " +
                           money(forecast) + ".";
        if (s.income > 0 && forecast > s.income) {
            res.push_back({AdviceLevel::Warning, "Прогноз: расходы превысят доходы",
                           text + " Это больше доходов (" + money(s.income) + ") на " + money(forecast - s.income) + "."});
        } else {
            res.push_back({AdviceLevel::Info, "Прогноз на месяц", text});
        }
        if (s.income > 0 && left > 0) {
            Money free = s.income - s.expense - s.income / 5;  // остаток после откладывания 20 %
            if (free > 0)
                res.push_back({AdviceLevel::Info, "Дневной лимит",
                               "Чтобы отложить 20 % дохода, тратьте не больше " + money(free / left) +
                                   " в день до конца месяца (осталось дней: " + std::to_string(left) + ")."});
            else
                res.push_back({AdviceLevel::Warning, "Дневной лимит исчерпан",
                               "Отложить 20 % дохода в этом месяце уже не получится. Сократите траты на желания до "
                               "конца месяца."});
        }
    }

    // 3. Крупнейшие категории расходов
    if (!s.expenseByCategory.empty()) {
        std::string text;
        for (size_t i = 0; i < s.expenseByCategory.size() && i < 3; ++i) {
            const auto& c = s.expenseByCategory[i];
            if (i) text += ", ";
            text += c.category + " — " + pct(c.share);
        }
        res.push_back({AdviceLevel::Info, "Больше всего денег уходит на", text + "."});
    }

    // 4. Рост расходов по сравнению с прошлым месяцем
    for (const auto& c : s.expenseByCategory) {
        Money before = 0;
        for (const auto& p : prev.expenseByCategory)
            if (p.category == c.category) before = p.amount;
        if (before > 0 && c.amount > before * 12 / 10 && c.amount - before >= 2000) {
            res.push_back({AdviceLevel::Warning, "Рост расходов: " + c.category,
                           "По сравнению с прошлым месяцем траты выросли на " +
                               pct(percent(c.amount - before, before)) + " (" + money(before) + " → " +
                               money(c.amount) + ")."});
        }
    }

    // 5. Бюджеты
    bool anyBudget = false;
    for (const auto& b : budgetStatuses(ledger, month)) {
        anyBudget = true;
        if (b.state == BudgetState::Over)
            res.push_back({AdviceLevel::Warning, "Лимит превышен: " + b.category,
                           "Потрачено " + money(b.spent) + " при лимите " + money(b.limit) + "."});
        else if (b.state == BudgetState::Near)
            res.push_back({AdviceLevel::Warning, "Лимит почти исчерпан: " + b.category,
                           "Использовано " + pct(b.usedPercent) + " лимита, осталось " +
                               money(b.limit - b.spent) + "."});
    }
    if (!anyBudget && !s.expenseByCategory.empty()) {
        const auto& top = s.expenseByCategory.front();
        res.push_back({AdviceLevel::Info, "Установите лимиты",
                       "Лимиты не заданы. Начните с самой затратной категории «" + top.category +
                           "»: например, " + money(top.amount * 9 / 10 / 100 * 100) + " в месяц (на 10 % меньше, чем сейчас)."});
    }

    // 6. Итог месяца
    if (s.income > 0 && s.balance() >= 0 && s.balance() >= s.income / 5)
        res.push_back({AdviceLevel::Good, "Хороший месяц",
                       "Остаток месяца " + money(s.balance()) + " — " + pct(percent(s.balance(), s.income)) +
                           " дохода. Переведите его в «Сбережения»."});
    return res;
}
