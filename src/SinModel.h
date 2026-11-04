#pragma once
#include <QObject>
#include "SinData.h"

class SinModel : public QObject {
    Q_OBJECT
public:
    explicit SinModel(QObject *parent = nullptr) : QObject(parent), m_totalSins(0) {}

    void calculate(const SinData& data) {
    
        int age = data.birthDate.daysTo(QDate::currentDate()) / 365;
        m_totalSins = (age * 2) + (data.liesCount * 5) + (data.stolenItemsCount * 50);
        if (data.sworeAtParents) {
            m_totalSins += 100;
        }
        
        emit sinsCalculated(m_totalSins); 
    }

    int getTotalSins() const { return m_totalSins; }

signals:
    void sinsCalculated(int newTotal);

private:
    int m_totalSins;
};