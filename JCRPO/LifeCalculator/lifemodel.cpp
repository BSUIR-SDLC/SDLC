#include "lifemodel.h"
#include <QDate>
#include <QDateTime>

LifeModel::LifeModel(QObject *parent) : QObject(parent) {}

void LifeModel::addObserver(ModelObserver *observer) {
    if (observer && !m_observers.contains(observer)) {
        m_observers.append(observer);
    }
}

void LifeModel::removeObserver(ModelObserver *observer) {
    m_observers.removeOne(observer);
}

void LifeModel::setLastInput(int day, int month, int year) {
    m_lastDay = day;
    m_lastMonth = month;
    m_lastYear = year;
    m_hasLastInput = true;
}

int LifeModel::lastDay() const { return m_lastDay; }
int LifeModel::lastMonth() const { return m_lastMonth; }
int LifeModel::lastYear() const { return m_lastYear; }
bool LifeModel::hasLastInput() const { return m_hasLastInput; }

bool LifeModel::calculate(const QDate &birthDate, QString &error) {
    QDate today = QDate::currentDate();

    if (!birthDate.isValid()) {
        error = "Некорректная дата рождения!";
        return false;
    }
    if (birthDate > today) {
        error = "Дата рождения не может быть в будущем!";
        return false;
    }

    qint64 daysLived = birthDate.daysTo(today);
    if (daysLived <= 0) {
        error = "Некорректная дата!";
        return false;
    }

    // СТАТИСТИКА (средние значения)
    // Сон: 8 часов в сутки
    m_sleepHours = daysLived * 8.0;
    m_sleepDays = m_sleepHours / 24.0;

    // Моргания: 15 раз в минуту в бодрствование (16 часов)
    // 15 * 60 * 16 = 14,400 раз в день
    m_blinks = daysLived * 14400LL;

    // Удары сердца: 75 ударов в минуту
    // 75 * 60 * 24 = 108,000 ударов в день
    m_heartBeats = daysLived * 108000LL;

    // Кровь: 70 мл за один удар (ударный объём)
    // 108,000 * 0.07 = 7,560 литров в день
    m_bloodLiters = daysLived * 7560.0;

    // Вода: 2.5 литра в день
    m_waterLiters = daysLived * 2.5;

    // Смех: 17 раз в день (взрослые)
    m_laughs = daysLived * 17LL;

    notifyObservers();

    return true;
}

void LifeModel::notifyObservers() {
    for (ModelObserver *observer : m_observers) {
        observer->onModelChanged();
    }
    emit dataChanged();
}

double LifeModel::sleepHours() const { return m_sleepHours; }
double LifeModel::sleepDays() const { return m_sleepDays; }
long long LifeModel::blinks() const { return m_blinks; }
long long LifeModel::heartBeats() const { return m_heartBeats; }
double LifeModel::bloodLiters() const { return m_bloodLiters; }
double LifeModel::waterLiters() const { return m_waterLiters; }
long long LifeModel::laughs() const { return m_laughs; }