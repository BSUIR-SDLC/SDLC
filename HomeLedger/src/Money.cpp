// Money.cpp — разбор и форматирование денежных сумм
#include "Money.h"

#include <cctype>

bool parseMoney(const std::string& text, Money& out) {
    Money whole = 0;
    int frac = 0, fracDigits = 0;
    bool seenDigit = false, seenSep = false;
    for (char ch : text) {
        unsigned char c = static_cast<unsigned char>(ch);
        if (c == ' ' || c == '\t' || c == '\'') continue;  // разделители тысяч
        if (std::isdigit(c)) {
            seenDigit = true;
            if (seenSep) {
                if (++fracDigits > 2) return false;  // не больше двух знаков после запятой
                frac = frac * 10 + (c - '0');
            } else {
                whole = whole * 10 + (c - '0');
                if (whole > kMaxAmount / 100) return false;
            }
        } else if ((c == ',' || c == '.') && !seenSep) {
            seenSep = true;
        } else {
            return false;
        }
    }
    if (!seenDigit) return false;
    if (fracDigits == 1) frac *= 10;
    out = whole * 100 + frac;
    return true;
}

std::string formatMoney(Money value) {
    bool negative = value < 0;
    unsigned long long v = negative ? static_cast<unsigned long long>(-value) : static_cast<unsigned long long>(value);
    std::string whole = std::to_string(v / 100);
    std::string grouped;
    int count = 0;
    for (auto it = whole.rbegin(); it != whole.rend(); ++it) {
        if (count && count % 3 == 0) grouped.insert(grouped.begin(), ' ');
        grouped.insert(grouped.begin(), *it);
        ++count;
    }
    unsigned cents = static_cast<unsigned>(v % 100);
    std::string result = (negative ? "-" : "") + grouped + "," + (cents < 10 ? "0" : "") + std::to_string(cents);
    return result;
}

double percent(Money a, Money b) { return b == 0 ? 0.0 : 100.0 * static_cast<double>(a) / static_cast<double>(b); }
