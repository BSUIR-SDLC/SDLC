// InputDialog.cpp
#include "InputDialog.h"

InputDialog::InputDialog(const QString& initialText, QWidget* parent)
    : QDialog(parent), lastInput(initialText) {
    
    setWindowTitle("Ввод предложения");
    setFixedSize(400, 150);
    
    // Создаем виджеты
    QLabel* label = new QLabel("Введите предложение:", this);
    inputLineEdit = new QLineEdit(this);
    inputLineEdit->setText(initialText);
    inputLineEdit->selectAll();
    
    okButton = new QPushButton("OK", this);
    cancelButton = new QPushButton("Отмена", this);
    
    // Создаем layout
    QVBoxLayout* mainLayout = new QVBoxLayout();
    mainLayout->addWidget(label);
    mainLayout->addWidget(inputLineEdit);
    
    QHBoxLayout* buttonLayout = new QHBoxLayout();
    buttonLayout->addWidget(okButton);
    buttonLayout->addWidget(cancelButton);
    mainLayout->addLayout(buttonLayout);
    
    setLayout(mainLayout);
    
    // Подключаем сигналы
    connect(okButton, &QPushButton::clicked, this, &InputDialog::onOkClicked);
    connect(cancelButton, &QPushButton::clicked, this, &QDialog::reject);
    connect(inputLineEdit, &QLineEdit::returnPressed, this, &InputDialog::onOkClicked);
}

QString InputDialog::getInputText() const {
    return inputLineEdit->text();
}

void InputDialog::onOkClicked() {
    QString text = inputLineEdit->text().trimmed();
    if (text.isEmpty()) {
        // Можно показать предупреждение или просто принять пустую строку
        accept();
    } else {
        accept();
    }
}