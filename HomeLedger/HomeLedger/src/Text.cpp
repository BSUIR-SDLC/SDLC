// Text.cpp
#include "Text.h"

#include <cctype>

size_t utf8Length(const std::string& s) {
    size_t n = 0;
    for (unsigned char c : s)
        if ((c & 0xC0) != 0x80) ++n;
    return n;
}

std::string utf8Truncate(const std::string& s, size_t chars) {
    if (utf8Length(s) <= chars) return s;
    if (chars == 0) return {};
    size_t n = 0, i = 0;
    for (; i < s.size(); ++i) {
        unsigned char c = static_cast<unsigned char>(s[i]);
        if ((c & 0xC0) != 0x80) {
            if (n == chars - 1) break;
            ++n;
        }
    }
    return s.substr(0, i) + "…";
}

std::string padRight(const std::string& s, size_t width) {
    std::string t = utf8Truncate(s, width);
    size_t len = utf8Length(t);
    return len < width ? t + std::string(width - len, ' ') : t;
}

std::string padLeft(const std::string& s, size_t width) {
    std::string t = utf8Truncate(s, width);
    size_t len = utf8Length(t);
    return len < width ? std::string(width - len, ' ') + t : t;
}

std::string trim(const std::string& s) {
    size_t b = 0, e = s.size();
    while (b < e && std::isspace(static_cast<unsigned char>(s[b]))) ++b;
    while (e > b && std::isspace(static_cast<unsigned char>(s[e - 1]))) --e;
    return s.substr(b, e - b);
}

std::string toLowerAscii(const std::string& s) {
    std::string r = s;
    for (auto& c : r) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return r;
}

std::vector<std::string> csvSplit(const std::string& line, char sep) {
    std::vector<std::string> fields;
    std::string cur;
    bool quoted = false;
    for (size_t i = 0; i < line.size(); ++i) {
        char c = line[i];
        if (quoted) {
            if (c == '"') {
                if (i + 1 < line.size() && line[i + 1] == '"') {
                    cur += '"';
                    ++i;
                } else {
                    quoted = false;
                }
            } else {
                cur += c;
            }
        } else if (c == '"') {
            quoted = true;
        } else if (c == sep) {
            fields.push_back(cur);
            cur.clear();
        } else if (c != '\r') {
            cur += c;
        }
    }
    fields.push_back(cur);
    return fields;
}

std::string csvField(const std::string& value, char sep) {
    if (value.find(sep) == std::string::npos && value.find('"') == std::string::npos &&
        value.find('\n') == std::string::npos)
        return value;
    std::string r = "\"";
    for (char c : value) {
        if (c == '"') r += '"';
        r += c;
    }
    return r + "\"";
}
