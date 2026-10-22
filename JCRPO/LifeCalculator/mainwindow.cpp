#include "mainwindow.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QGroupBox>
#include <QMessageBox>

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent) {
    setWindowTitle("Калькулятор Жизни");
    resize(500, 400);

    m_model = nullptr;
    createUI();
}

void MainWindow::createUI() {
    QWidget *central = new QWidget(this);
    QVBoxLayout *mainLayout = new QVBoxLayout(central);

    QLabel *title = new QLabel("Калькулятор Жизни", this);
    title->setAlignment(Qt::AlignCenter);
    QFont font = title->font();
    font.setPointSize(16);
    font.setBold(true);
    title->setFont(font);
    mainLayout->addWidget(title);

    m_inputButton = new QPushButton("Ввести данные", this);
    m_inputButton->setMinimumHeight(40);
    mainLayout->addWidget(m_inputButton);

    connect(m_inputButton, &QPushButton::clicked,
            this, &MainWindow::openInputRequested);

    QGroupBox *resultsGroup = new QGroupBox("Результаты", this);
    QVBoxLayout *resultsLayout = new QVBoxLayout(resultsGroup);

    m_sleepLabel = new QLabel("Сон: —", this);
    m_blinksLabel = new QLabel("Моргания: —", this);
    m_heartLabel = new QLabel("Удары сердца: —", this);
    m_bloodLabel = new QLabel("Перекачано крови: —", this);
    m_waterLabel = new QLabel("Выпито воды: —", this);
    m_laughsLabel = new QLabel("Смех: —", this);

    resultsLayout->addWidget(m_sleepLabel);
    resultsLayout->addWidget(m_blinksLabel);
    resultsLayout->addWidget(m_heartLabel);
    resultsLayout->addWidget(m_bloodLabel);
    resultsLayout->addWidget(m_waterLabel);
    resultsLayout->addWidget(m_laughsLabel);

    mainLayout->addWidget(resultsGroup);

    m_statusLabel = new QLabel("Введите дату рождения для расчёта", this);
    m_statusLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_statusLabel);

    setCentralWidget(central);
}

void MainWindow::onModelChanged() {
    updateResults();
}

void MainWindow::updateResults() {
    m_sleepLabel->setText(QString(" Сон: %1 часов (%2 суток)")
        .arg(m_model->sleepHours(), 0, 'f', 0)
        .arg(m_model->sleepDays(), 0, 'f', 1));

    m_blinksLabel->setText(QString(" Моргания: %1 раз")
        .arg(m_model->blinks()));

    m_heartLabel->setText(QString(" Удары сердца: %1 раз")
        .arg(m_model->heartBeats()));

    m_bloodLabel->setText(QString(" Перекачано крови: %1 литров")
        .arg(m_model->bloodLiters(), 0, 'f', 0));

    m_waterLabel->setText(QString(" Выпито воды: %1 литров")
        .arg(m_model->waterLiters(), 0, 'f', 0));

    m_laughsLabel->setText(QString(" Смех: %1 раз")
        .arg(m_model->laughs()));

    m_statusLabel->setText(" Расчёт выполнен успешно!");
}

void MainWindow::showSuccessMessage(const QString &msg) {
    m_statusLabel->setText(msg);
}

void MainWindow::setModel(LifeModel *model) {
    m_model = model;
    m_model->addObserver(this);
}