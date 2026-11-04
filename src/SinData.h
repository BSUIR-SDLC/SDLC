#pragma once
#include <QDate>

struct SinData {
    QDate birthDate = QDate::currentDate().addYears(-20);
    int liesCount = 0;
    int stolenItemsCount = 0;
    bool sworeAtParents = false;
};