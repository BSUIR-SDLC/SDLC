#include "inputdialog.h"
#include <QSpinBox>
#include <QPushButton>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QFormLayout>

InputDialog::InputDialog(QWidget *parent) : QDialog(parent) {
    setWindowTitle("Ввод даты рождения");
    setMinimumWidth(300);

    QVBoxLayout *mainLayout = new QVBoxLayout(this);

    QLabel *info = new QLabel("Введите дату рождения\n", this);
    info->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(info);

    QFormLayout *formLayout = new QFormLayout;

    m_daySpin = new QSpinBox(this);
    m_daySpin->setRange(1, 31);
    m_daySpin->setValue(1);

    m_monthSpin = new QSpinBox(this);
    m_monthSpin->setRange(1, 12);
    m_monthSpin->setValue(1);

    m_yearSpin = new QSpinBox(this);
    m_yearSpin->setRange(1900, 2026);
    m_yearSpin->setValue(2000);

    formLayout->addRow("День:", m_daySpin);
    formLayout->addRow("Месяц:", m_monthSpin);
    formLayout->addRow("Год:", m_yearSpin);

    mainLayout->addLayout(formLayout);

    QHBoxLayout *buttonLayout = new QHBoxLayout;
    m_okButton = new QPushButton("OK", this);
    m_cancelButton = new QPushButton("Отмена", this);

    buttonLayout->addWidget(m_okButton);
    buttonLayout->addWidget(m_cancelButton);
    mainLayout->addLayout(buttonLayout);

    connect(m_okButton, &QPushButton::clicked, this, &QDialog::accept);
    connect(m_cancelButton, &QPushButton::clicked, this, &QDialog::reject);
}

void InputDialog::setInitialValues(int day, int month, int year) {
    m_daySpin->setValue(day);
    m_monthSpin->setValue(month);
    m_yearSpin->setValue(year);
}

int InputDialog::day() const { return m_daySpin->value(); }
int InputDialog::month() const { return m_monthSpin->value(); }
int InputDialog::year() const { return m_yearSpin->value(); }