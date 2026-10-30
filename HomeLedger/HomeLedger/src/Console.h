// Console.h — ввод/вывод в консоли с поддержкой UTF-8 (в том числе в Windows) и цветом
#pragma once
#include <string>

namespace console {

enum class Color { Default, Red, Green, Yellow, Blue, Cyan, Gray, Bold };

void init(bool useColor);  // настроить кодировку консоли и ANSI-цвета
std::string paint(const std::string& text, Color c);

// Прочитать строку. false — конец ввода (Ctrl+Z / Ctrl+D)
bool readLine(const std::string& prompt, std::string& out);

// Горизонтальная полоса-диаграмма шириной width символов
std::string bar(double fraction, int width);
std::string line(int width = 72, const char* ch = "─");
void header(const std::string& title);

}  // namespace console
