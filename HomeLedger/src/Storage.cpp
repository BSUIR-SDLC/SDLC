// Storage.cpp
#include "Storage.h"

#include <filesystem>
#include <fstream>
#include <sstream>

#include "Analytics.h"
#include "Text.h"

namespace fs = std::filesystem;

namespace {

const char* kOps = "operations.csv";
const char* kCats = "categories.csv";
const char* kWallets = "wallets.csv";
const char* kBudgets = "budgets.csv";

const char* typeCode(OpType t) {
    return t == OpType::Income ? "income" : t == OpType::Expense ? "expense" : "transfer";
}

bool parseType(const std::string& s, OpType& t) {
    if (s == "income") t = OpType::Income;
    else if (s == "expense") t = OpType::Expense;
    else if (s == "transfer") t = OpType::Transfer;
    else return false;
    return true;
}

const char* groupCode(Group g) {
    switch (g) {
        case Group::Needs: return "needs";
        case Group::Wants: return "wants";
        case Group::Savings: return "savings";
        default: return "income";
    }
}

Group parseGroup(const std::string& s) {
    if (s == "needs") return Group::Needs;
    if (s == "savings") return Group::Savings;
    if (s == "income") return Group::Income;
    return Group::Wants;
}

bool readLines(const std::string& file, std::vector<std::string>& lines) {
    std::ifstream in(fs::u8path(file), std::ios::binary);
    if (!in) return false;
    std::string line;
    bool first = true;
    while (std::getline(in, line)) {
        if (first && line.rfind("\xEF\xBB\xBF", 0) == 0) line.erase(0, 3);  // BOM
        if (first) {
            first = false;  // заголовок
            continue;
        }
        if (!trim(line).empty()) lines.push_back(line);
    }
    return true;
}

// Атомарная запись: сначала во временный файл, затем замена
bool writeFile(const std::string& file, const std::string& content, std::string& error) {
    fs::path target = fs::u8path(file), tmp = fs::u8path(file + ".tmp");
    {
        std::ofstream out(tmp, std::ios::binary | std::ios::trunc);
        if (!out) {
            error = "Не удалось открыть файл для записи: " + file;
            return false;
        }
        out << content;
        if (!out.good()) {
            error = "Ошибка записи в файл: " + file;
            return false;
        }
    }
    std::error_code ec;
    fs::rename(tmp, target, ec);
    if (ec) {  // на некоторых платформах rename не заменяет существующий файл
        fs::remove(target, ec);
        fs::rename(tmp, target, ec);
    }
    if (ec) {
        error = "Не удалось сохранить файл " + file + ": " + ec.message();
        return false;
    }
    return true;
}

}  // namespace

std::string moneyToCsv(Money m) {
    std::string s = formatMoney(m);
    std::string r;
    for (char c : s) {
        if (c == ' ') continue;
        r += (c == ',') ? '.' : c;
    }
    return r;
}

std::string Storage::path(const std::string& file) const { return (fs::u8path(dir_) / fs::u8path(file)).u8string(); }

bool Storage::load(Ledger& ledger, std::vector<std::string>& warnings) {
    ledger.clear();
    std::error_code ec;
    if (!fs::exists(fs::u8path(path(kCats)), ec)) {
        fs::create_directories(fs::u8path(dir_), ec);
        ledger.setDefaults();
        std::string err;
        if (!save(ledger, err)) warnings.push_back(err);
        return true;
    }
    std::vector<std::string> lines;
    readLines(path(kCats), lines);
    for (const auto& l : lines) {
        auto f = csvSplit(l);
        OpType t;
        if (f.size() < 3 || !parseType(f[1], t) || f[0].empty()) {
            warnings.push_back("categories.csv: пропущена строка «" + l + "»");
            continue;
        }
        ledger.loadCategory(Category{f[0], t, parseGroup(f[2])});
    }
    lines.clear();
    readLines(path(kWallets), lines);
    for (const auto& l : lines) {
        auto f = csvSplit(l);
        Money m = 0;
        if (f.size() < 2 || f[0].empty() || !parseMoney(f[1].rfind('-', 0) == 0 ? f[1].substr(1) : f[1], m)) {
            warnings.push_back("wallets.csv: пропущена строка «" + l + "»");
            continue;
        }
        if (f[1].rfind('-', 0) == 0) m = -m;
        ledger.loadWallet(Wallet{f[0], m});
    }
    if (ledger.wallets().empty()) ledger.loadWallet(Wallet{"Наличные", 0});
    lines.clear();
    readLines(path(kBudgets), lines);
    for (const auto& l : lines) {
        auto f = csvSplit(l);
        Money m = 0;
        if (f.size() < 2 || !parseMoney(f[1], m)) {
            warnings.push_back("budgets.csv: пропущена строка «" + l + "»");
            continue;
        }
        ledger.loadBudget(Budget{f[0], m});
    }
    lines.clear();
    readLines(path(kOps), lines);
    for (const auto& l : lines) {
        auto f = csvSplit(l);
        Operation op;
        if (f.size() < 8 || !parseType(f[2], op.type) || !Date::parse(f[1], op.date) || f[1].empty() ||
            !parseMoney(f[3], op.amount)) {
            warnings.push_back("operations.csv: пропущена повреждённая строка «" + l + "»");
            continue;
        }
        try {
            op.id = std::stoi(f[0]);
        } catch (...) {
            warnings.push_back("operations.csv: неверный номер в строке «" + l + "»");
            continue;
        }
        op.category = f[4];
        op.wallet = f[5];
        op.toWallet = f[6];
        op.comment = f[7];
        ledger.loadOperation(op);
    }
    return true;
}

bool Storage::save(const Ledger& ledger, std::string& error) const {
    std::error_code ec;
    fs::create_directories(fs::u8path(dir_), ec);
    std::ostringstream ops, cats, wallets, budgets;
    ops << "id;date;type;amount;category;wallet;to_wallet;comment\n";
    for (const auto& o : ledger.operations())
        ops << o.id << ';' << o.date.iso() << ';' << typeCode(o.type) << ';' << moneyToCsv(o.amount) << ';'
            << csvField(o.category) << ';' << csvField(o.wallet) << ';' << csvField(o.toWallet) << ';'
            << csvField(o.comment) << '\n';
    cats << "name;type;group\n";
    for (const auto& c : ledger.allCategories())
        cats << csvField(c.name) << ';' << typeCode(c.type) << ';' << groupCode(c.group) << '\n';
    wallets << "name;initial\n";
    for (const auto& w : ledger.wallets()) wallets << csvField(w.name) << ';' << moneyToCsv(w.initial) << '\n';
    budgets << "category;limit\n";
    for (const auto& b : ledger.budgets()) budgets << csvField(b.category) << ';' << moneyToCsv(b.limit) << '\n';
    return writeFile(path(kOps), ops.str(), error) && writeFile(path(kCats), cats.str(), error) &&
           writeFile(path(kWallets), wallets.str(), error) && writeFile(path(kBudgets), budgets.str(), error);
}

bool Storage::backup(std::string& error) const {
    std::error_code ec;
    fs::path dst = fs::u8path(dir_) / "backup";
    fs::create_directories(dst, ec);
    for (const char* f : {kOps, kCats, kWallets, kBudgets}) {
        fs::path src = fs::u8path(path(f));
        if (!fs::exists(src, ec)) continue;
        fs::copy_file(src, dst / (std::string(f) + ".bak"), fs::copy_options::overwrite_existing, ec);
        if (ec) {
            error = "Не удалось создать резервную копию: " + ec.message();
            return false;
        }
    }
    return true;
}

namespace {
// для отчёта Excel с русской локалью: десятичная запятая
std::string moneyForExcel(Money m) {
    std::string s = moneyToCsv(m);
    for (auto& c : s)
        if (c == '.') c = ',';
    return s;
}
}  // namespace

bool Storage::exportMonth(const Ledger& ledger, const Date& month, std::string& outPath, std::string& error) const {
    char name[64];
    std::snprintf(name, sizeof name, "report_%04d-%02d.csv", month.y, month.m);
    outPath = path(name);
    PeriodStats s = monthStats(ledger, month);
    std::ostringstream out;
    out << "\xEF\xBB\xBF";  // BOM — чтобы Excel распознал UTF-8
    out << "Отчёт HomeLedger;" << month.monthName() << "\n\n";
    out << "Показатель;Сумма, BYN\n";
    out << "Доходы;" << moneyForExcel(s.income) << "\nРасходы;" << moneyForExcel(s.expense) << "\nОстаток месяца;"
        << moneyForExcel(s.balance()) << "\nБаланс всех кошельков;" << moneyForExcel(ledger.totalBalance()) << "\n\n";
    out << "Категория расходов;Сумма, BYN;Доля, %;Лимит, BYN\n";
    for (const auto& c : s.expenseByCategory) {
        char share[16];
        std::snprintf(share, sizeof share, "%.1f", c.share);
        for (char* p = share; *p; ++p)
            if (*p == '.') *p = ',';
        Money limit = ledger.budgetFor(c.category);
        out << csvField(c.category) << ';' << moneyForExcel(c.amount) << ';' << share << ';'
            << (limit ? moneyForExcel(limit) : "") << '\n';
    }
    out << "\nДата;Тип;Категория;Кошелёк;Сумма, BYN;Комментарий\n";
    for (const auto& o : ledger.between(month.firstOfMonth(), month.lastOfMonth())) {
        std::string cat = o.type == OpType::Transfer ? "→ " + o.toWallet : o.category;
        out << o.date.str() << ';' << typeName(o.type) << ';' << csvField(cat) << ';' << csvField(o.wallet) << ';'
            << moneyForExcel(o.amount) << ';' << csvField(o.comment) << '\n';
    }
    return writeFile(outPath, out.str(), error);
}
