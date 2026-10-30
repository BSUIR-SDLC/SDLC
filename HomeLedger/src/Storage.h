// Storage.h — хранение данных в CSV-файлах каталога данных
#pragma once
#include <string>
#include <vector>

#include "Ledger.h"

class Storage {
public:
    explicit Storage(std::string dir) : dir_(std::move(dir)) {}

    // Загружает данные. Если каталога нет — создаёт его и заполняет стандартными категориями.
    // Повреждённые строки пропускаются, описание проблем возвращается в warnings.
    bool load(Ledger& ledger, std::vector<std::string>& warnings);
    bool save(const Ledger& ledger, std::string& error) const;
    bool backup(std::string& error) const;  // копия файлов в каталог backup
    // Отчёт за месяц для Excel (CSV, UTF-8 с BOM, разделитель ';')
    bool exportMonth(const Ledger& ledger, const Date& month, std::string& path, std::string& error) const;

    const std::string& dir() const { return dir_; }

private:
    std::string path(const std::string& file) const;
    std::string dir_;
};

std::string moneyToCsv(Money m);  // 1234.56 (точка, без пробелов)
