// MainWindow.cpp
#include "MainWindow.h"
#include <QMessageBox>
#include <QWidget>

MainWindow::MainWindow(QWidget* parent)
    : QMainWindow(parent), lastInput("") {

    // Создаем виджеты
    inputLabel = new QLabel("Введите предложение:", this);
    resultLabel = new QLabel("Результат: ", this);
    inputButton = new QPushButton("Ввести данные", this);
    clearButton = new QPushButton("Очистить", this);

    // Настраиваем layout
    QVBoxLayout* layout = new QVBoxLayout();
    layout->addWidget(inputLabel);
    layout->addWidget(resultLabel);
    layout->addWidget(inputButton);
    layout->addWidget(clearButton);

    QWidget* centralWidget = new QWidget(this);
    centralWidget->setLayout(layout);
    setCentralWidget(centralWidget);

    // Подключаем сигналы к слотам
    connect(inputButton, &QPushButton::clicked, this, &MainWindow::onInputButtonClicked);
    connect(clearButton, &QPushButton::clicked, this, &MainWindow::onClearButtonClicked);

    // Настройки окна
    setFixedSize(400, 200);
    setWindowTitle("Инвертор слов");
}

MainWindow::~MainWindow() {}

// Обработчик кнопки "Ввести данные"
void MainWindow::onInputButtonClicked() {
    InputDialog dialog(lastInput, this);

    if (dialog.exec() == QDialog::Accepted) {
        QString input = dialog.getInputText();
        lastInput = input;
        controller.processInput(input);
        updateDisplay();
    }
}

// Обработчик кнопки "Очистить" ← НОВЫЙ МЕТОД
void MainWindow::onClearButtonClicked() {
    lastInput = "";
    controller.processInput("");
    inputLabel->setText("Введите предложение:");
    resultLabel->setText("Результат: ");
}

// Обновление отображения
void MainWindow::updateDisplay() {
    if (controller.isValidData()) {
        inputLabel->setText("Исходное: " + controller.getInputText());
        resultLabel->setText("Результат: " + controller.getResultText());
    } else if (!controller.getInputText().isEmpty()) {
        QMessageBox::warning(this, "Ошибка",
            "Введены некорректные данные!\nПожалуйста, введите непустое предложение.");
    }
}