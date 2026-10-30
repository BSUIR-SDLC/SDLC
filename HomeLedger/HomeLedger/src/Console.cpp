// Console.cpp
#include "Console.h"

#include <iostream>

#include "Text.h"

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

namespace console {

namespace {
bool g_color = true;
#ifdef _WIN32
bool g_consoleInput = false;
#endif
}  // namespace

void init(bool useColor) {
    g_color = useColor;
#ifdef _WIN32
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);
    HANDLE out = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD mode = 0;
    if (GetConsoleMode(out, &mode)) {
        if (!SetConsoleMode(out, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING)) g_color = false;
    } else {
        g_color = false;  // вывод перенаправлен в файл
    }
    DWORD inMode = 0;
    g_consoleInput = GetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), &inMode) != 0;
#endif
}

std::string paint(const std::string& text, Color c) {
    if (!g_color || c == Color::Default) return text;
    const char* code = "";
    switch (c) {
        case Color::Red: code = "\x1b[31m"; break;
        case Color::Green: code = "\x1b[32m"; break;
        case Color::Yellow: code = "\x1b[33m"; break;
        case Color::Blue: code = "\x1b[34m"; break;
        case Color::Cyan: code = "\x1b[36m"; break;
        case Color::Gray: code = "\x1b[90m"; break;
        case Color::Bold: code = "\x1b[1m"; break;
        default: break;
    }
    return std::string(code) + text + "\x1b[0m";
}

bool readLine(const std::string& prompt, std::string& out) {
    std::cout << prompt << std::flush;
#ifdef _WIN32
    if (g_consoleInput) {
        // Ввод кириллицы в консоли Windows надёжно работает только через ReadConsoleW
        wchar_t buf[1024];
        DWORD read = 0;
        if (!ReadConsoleW(GetStdHandle(STD_INPUT_HANDLE), buf, 1023, &read, nullptr) || read == 0) return false;
        std::wstring w(buf, read);
        while (!w.empty() && (w.back() == L'\n' || w.back() == L'\r')) w.pop_back();
        if (!w.empty() && w[0] == 0x1A) return false;  // Ctrl+Z
        int len = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), static_cast<int>(w.size()), nullptr, 0, nullptr, nullptr);
        out.assign(static_cast<size_t>(len), '\0');
        WideCharToMultiByte(CP_UTF8, 0, w.c_str(), static_cast<int>(w.size()), &out[0], len, nullptr, nullptr);
        out = trim(out);
        return true;
    }
#endif
    if (!std::getline(std::cin, out)) return false;
    out = trim(out);
    return true;
}

std::string bar(double fraction, int width) {
    if (fraction < 0) fraction = 0;
    if (fraction > 1) fraction = 1;
    int filled = static_cast<int>(fraction * width + 0.5);
    if (fraction > 0 && filled == 0) filled = 1;
    std::string s;
    for (int i = 0; i < width; ++i) s += i < filled ? "█" : "░";
    return s;
}

std::string line(int width, const char* ch) {
    std::string s;
    for (int i = 0; i < width; ++i) s += ch;
    return s;
}

void header(const std::string& title) {
    std::cout << "\n" << paint(line(), Color::Gray) << "\n " << paint(title, Color::Bold) << "\n"
              << paint(line(), Color::Gray) << "\n";
}

}  // namespace console
