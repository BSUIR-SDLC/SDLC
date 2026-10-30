// Money.h — денежные суммы хранятся в копейках (целое число), чтобы не было ошибок округления
#pragma once
#include <string>

using Money = long long;

constexpr Money kMaxAmount = 100000000LL * 100;  // 100 000 000,00 BYN — верхняя граница суммы операции

// "12", "12,5", "12.50", "1 200,00" -> копейки. false — если строка не является суммой.
bool parseMoney(const std::string& text, Money& out);
// 123456 -> "1 234,56"
std::string formatMoney(Money value);
// процент a от b (0..), b == 0 -> 0
double percent(Money a, Money b);
