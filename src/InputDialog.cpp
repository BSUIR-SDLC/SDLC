#include "InputDialog.h"
#include <QVBoxLayout>
#include <QLabel>
#include <QMessageBox>

InputDialog::InputDialog(const SinData& currentData, QWidget *parent) : QDialog(parent) {
    setWindowTitle("Вопросы утилиты");
    // Адаптация под компактный экран
    setMinimumSize(300, 450); 
    
    QVBoxLayout* layout = new QVBoxLayout(this);
    layout->setSpacing(15);

    // Вопрос 1: Дата рождения
    layout->addWidget(new QLabel("Дата рождения:"));
    dateEdit = new QDateEdit(currentData.birthDate);
    dateEdit->setCalendarPopup(true);
    dateEdit->setStyleSheet("font-size: 16px; padding: 5px;");
    layout->addWidget(dateEdit);

    // Вопрос 2: Ложь
    layout->addWidget(new QLabel("Сколько раз вы лгали за год?"));
    liesSpin = new QSpinBox();
    liesSpin->setRange(0, 10000);
    liesSpin->setValue(currentData.liesCount);
    liesSpin->setStyleSheet("font-size: 16px; padding: 5px;");
    layout->addWidget(liesSpin);

    // Вопрос 3: Кражи
    layout->addWidget(new QLabel("Сколько чужих вещей вы брали?"));
    stolenSpin = new QSpinBox();
    stolenSpin->setRange(0, 1000);
    stolenSpin->setValue(currentData.stolenItemsCount);
    stolenSpin->setStyleSheet("font-size: 16px; padding: 5px;");
    layout->addWidget(stolenSpin);

    // Вопрос 4: Поведение
    sworeCheck = new QCheckBox("Ругались ли вы на родителей?");
    sworeCheck->setChecked(currentData.sworeAtParents);
    sworeCheck->setStyleSheet("font-size: 16px;");
    layout->addWidget(sworeCheck);

    // Кнопка подтверждения
    QPushButton* okBtn = new QPushButton("Подтвердить");
    okBtn->setStyleSheet("font-size: 18px; font-weight: bold; padding: 10px; background-color: #4CAF50; color: white;");
    layout->addWidget(okBtn);

    connect(okBtn, &QPushButton::clicked, this, &InputDialog::validateAndAccept);
}

SinData InputDialog::getData() const {
    SinData data;
    data.birthDate = dateEdit->date();
    data.liesCount = liesSpin->value();
    data.stolenItemsCount = stolenSpin->value();
    data.sworeAtParents = sworeCheck->isChecked();
    return data;
}

void InputDialog::validateAndAccept() {
    // Проверка на некорректные данные
    if (dateEdit->date() > QDate::currentDate()) {
        QMessageBox::critical(this, "Ошибка ввода", "Дата рождения не может быть в будущем!");
        return; // Окно не закроется, пока данные некорректны
    }
    
    // Если всё ок - закрываем окно с кодом Accepted
    accept();
}