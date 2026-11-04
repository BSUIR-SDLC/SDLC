#include "MainWindow.h"
#include "InputDialog.h"
#include <QVBoxLayout>
#include <QFrame>

MainWindow::MainWindow(SinModel* model, SinController* controller, QWidget *parent)
    : QMainWindow(parent), m_model(model), m_controller(controller) {
    
    setWindowTitle("Грехометр");
    // Минимальный размер вместо жесткого фиксирования, чтобы UI не ломался при масштабировании
    setMinimumSize(340, 460);
    resize(360, 480);

    // Темная палитра окна
    setStyleSheet("QMainWindow { background-color: #121214; }");

    QWidget* centralWidget = new QWidget(this);
    setCentralWidget(centralWidget);

    QVBoxLayout* rootLayout = new QVBoxLayout(centralWidget);
    rootLayout->setContentsMargins(20, 24, 20, 24);
    rootLayout->setSpacing(20);

    // Заголовок приложения
    QLabel* headerLabel = new QLabel("КАЛЬКУЛЯТОР ГРЕХОВ", this);
    headerLabel->setAlignment(Qt::AlignCenter);
    headerLabel->setStyleSheet(
        "font-size: 13px; font-weight: 700; letter-spacing: 1px; color: #8E8E93;"
    );
    rootLayout->addWidget(headerLabel);

    // Карточка с результатом
    QFrame* cardFrame = new QFrame(this);
    cardFrame->setStyleSheet(
        "QFrame {"
        "  background-color: #1C1C1E;"
        "  border: 1px solid #2C2C2E;"
        "  border-radius: 18px;"
        "}"
    );

    QVBoxLayout* cardLayout = new QVBoxLayout(cardFrame);
    cardLayout->setContentsMargins(16, 28, 16, 28);
    cardLayout->setSpacing(8);
    cardLayout->setAlignment(Qt::AlignCenter);

    QLabel* cardTitle = new QLabel("Совершено грехов", cardFrame);
    cardTitle->setAlignment(Qt::AlignCenter);
    cardTitle->setStyleSheet("font-size: 15px; color: #A1A1A6; border: none;");
    cardLayout->addWidget(cardTitle);

    // Большой акцентный счетчик
    countLabel = new QLabel("0", cardFrame);
    countLabel->setAlignment(Qt::AlignCenter);
    countLabel->setStyleSheet(
        "font-size: 54px; font-weight: 800; color: #FF453A; border: none; padding: 4px 0;"
    );
    cardLayout->addWidget(countLabel);

    // Статусная подпись
    statusLabel = new QLabel("Нажмите кнопку для расчета", cardFrame);
    statusLabel->setAlignment(Qt::AlignCenter);
    statusLabel->setStyleSheet("font-size: 13px; color: #636366; border: none;");
    cardLayout->addWidget(statusLabel);

    rootLayout->addWidget(cardFrame);
    rootLayout->addStretch();

    // Кнопка вызова диалога
    calcButton = new QPushButton("Рассчитать грехи", this);
    calcButton->setMinimumHeight(52);
    calcButton->setCursor(Qt::PointingHandCursor);
    calcButton->setStyleSheet(
        "QPushButton {"
        "  background-color: #0A84FF;"
        "  color: white;"
        "  font-size: 16px;"
        "  font-weight: 600;"
        "  border-radius: 14px;"
        "  border: none;"
        "}"
        "QPushButton:hover {"
        "  background-color: #0071E3;"
        "}"
        "QPushButton:pressed {"
        "  background-color: #005BB5;"
        "}"
    );
    rootLayout->addWidget(calcButton);

    connect(calcButton, &QPushButton::clicked, this, &MainWindow::onCalculateClicked);
    connect(m_model, &SinModel::sinsCalculated, this, &MainWindow::onModelDataChanged);
}

void MainWindow::onCalculateClicked() {
    InputDialog dialog(m_lastData, this);
    if (dialog.exec() == QDialog::Accepted) {
        m_lastData = dialog.getData();
        m_controller->processInput(m_lastData);
    }
}

void MainWindow::onModelDataChanged(int newTotal) {
    countLabel->setText(QString::number(newTotal));
    
    // Динамический вердикт в зависимости от суммы
    if (newTotal < 50) {
        statusLabel->setText("Уровень: Почти святой");
        countLabel->setStyleSheet("font-size: 54px; font-weight: 800; color: #30D158; border: none;");
    } else if (newTotal < 200) {
        statusLabel->setText("Уровень: Обычный смертный");
        countLabel->setStyleSheet("font-size: 54px; font-weight: 800; color: #FF9F0A; border: none;");
    } else {
        statusLabel->setText("Уровень: Требуется исповедь");
        countLabel->setStyleSheet("font-size: 54px; font-weight: 800; color: #FF453A; border: none;");
    }
}