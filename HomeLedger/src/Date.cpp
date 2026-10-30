// Date.cpp — реализация операций с датами
#include "Date.h"

#include <cstdio>
#include <ctime>

namespace {
const char* kMonths[] = {"Январь", "Февраль", "Март",     "Апрель",  "Май",    "Июнь",
                         "Июль",   "Август",  "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"};

bool isLeap(int y) { return (y % 4 == 0 && y % 100 != 0) || y % 400 == 0; }
}  // namespace

Date Date::today() {
    std::time_t t = std::time(nullptr);
    std::tm tm{};
#ifdef _WIN32
    localtime_s(&tm, &t);
#else
    localtime_r(&t, &tm);
#endif
    return Date{tm.tm_year + 1900, tm.tm_mon + 1, tm.tm_mday};
}

int Date::daysInMonth(int y, int m) {
    static const int days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    if (m == 2 && isLeap(y)) return 29;
    return days[(m - 1) % 12];
}

bool Date::isValid(int y, int m, int d) {
    return y >= 1970 && y <= 2100 && m >= 1 && m <= 12 && d >= 1 && d <= daysInMonth(y, m);
}

bool Date::parse(const std::string& text, Date& out) {
    if (text.empty()) {
        out = today();
        return true;
    }
    int a = 0, b = 0, c = 0;
    char tail = 0;
    if (std::sscanf(text.c_str(), "%d-%d-%d%c", &a, &b, &c, &tail) == 3) {
        if (!isValid(a, b, c)) return false;
        out = Date{a, b, c};
        return true;
    }
    if (std::sscanf(text.c_str(), "%d.%d.%d%c", &a, &b, &c, &tail) == 3) {
        if (c < 100) c += 2000;
        if (!isValid(c, b, a)) return false;
        out = Date{c, b, a};
        return true;
    }
    if (std::sscanf(text.c_str(), "%d.%d%c", &a, &b, &tail) == 2) {
        int year = today().y;
        if (!isValid(year, b, a)) return false;
        out = Date{year, b, a};
        return true;
    }
    return false;
}

// Алгоритм перевода даты в номер дня (Howard Hinnant, days_from_civil)
long Date::toDays() const {
    int yy = y - (m <= 2 ? 1 : 0);
    const long era = (yy >= 0 ? yy : yy - 399) / 400;
    const unsigned yoe = static_cast<unsigned>(yy - era * 400);
    const unsigned doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    const unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + static_cast<long>(doe) - 719468;
}

Date Date::fromDays(long z) {
    z += 719468;
    const long era = (z >= 0 ? z : z - 146096) / 146097;
    const unsigned doe = static_cast<unsigned>(z - era * 146097);
    const unsigned yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    const long yy = static_cast<long>(yoe) + era * 400;
    const unsigned doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    const unsigned mp = (5 * doy + 2) / 153;
    const unsigned dd = doy - (153 * mp + 2) / 5 + 1;
    const unsigned mm = mp < 10 ? mp + 3 : mp - 9;
    return Date{static_cast<int>(yy + (mm <= 2 ? 1 : 0)), static_cast<int>(mm), static_cast<int>(dd)};
}

Date Date::addMonths(int n) const {
    int idx = y * 12 + (m - 1) + n;
    return Date{idx / 12, idx % 12 + 1, 1};
}

std::string Date::iso() const {
    char buf[16];
    std::snprintf(buf, sizeof buf, "%04d-%02d-%02d", y, m, d);
    return buf;
}

std::string Date::str() const {
    char buf[16];
    std::snprintf(buf, sizeof buf, "%02d.%02d.%04d", d, m, y);
    return buf;
}

std::string Date::monthName() const { return std::string(kMonths[m - 1]) + " " + std::to_string(y); }
