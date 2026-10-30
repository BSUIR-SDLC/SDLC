// Text.h — работа со строками UTF-8 и форматом CSV
#pragma once
#include <string>
#include <vector>

size_t utf8Length(const std::string& s);                      // число символов (а не байт)
std::string utf8Truncate(const std::string& s, size_t chars);  // обрезать до chars символов, с «…»
std::string padRight(const std::string& s, size_t width);      // выравнивание по левому краю
std::string padLeft(const std::string& s, size_t width);       // выравнивание по правому краю
std::string trim(const std::string& s);
std::string toLowerAscii(const std::string& s);

// CSV с разделителем ';' (так файлы сразу открываются в Excel с русской локалью)
std::vector<std::string> csvSplit(const std::string& line, char sep = ';');
std::string csvField(const std::string& value, char sep = ';');
