#ifndef LIFEMODEL_H
#define LIFEMODEL_H

#include <QObject>
#include <QDate>
#include <QList>

class ModelObserver {
public:
    virtual ~ModelObserver() = default;
    virtual void onModelChanged() = 0;
};

class LifeModel : public QObject {
    Q_OBJECT

public:
    explicit LifeModel(QObject *parent = nullptr);

    void addObserver(ModelObserver *observer);
    void removeObserver(ModelObserver *observer);

    void setLastInput(int day, int month, int year);
    int lastDay() const;
    int lastMonth() const;
    int lastYear() const;
    bool hasLastInput() const;

    bool calculate(const QDate &birthDate, QString &error);

    double sleepHours() const;
    double sleepDays() const;
    long long blinks() const;
    long long heartBeats() const;
    double bloodLiters() const;
    double waterLiters() const;
    long long laughs() const;

signals:
    void dataChanged();

private:
    void notifyObservers();

    QList<ModelObserver*> m_observers;

    int m_lastDay = 0;
    int m_lastMonth = 0;
    int m_lastYear = 0;
    bool m_hasLastInput = false;

    double m_sleepHours = 0;
    double m_sleepDays = 0;
    long long m_blinks = 0;
    long long m_heartBeats = 0;
    double m_bloodLiters = 0;
    double m_waterLiters = 0;
    long long m_laughs = 0;
};

#endif