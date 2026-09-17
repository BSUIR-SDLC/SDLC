// MainWindow.h
#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>
#include "Controller.h"
#include "InputDialog.h"

class MainWindow : public QMainWindow {
    Q_OBJECT

private:
    Controller controller;
    QLabel* inputLabel;
    QLabel* resultLabel;
    QPushButton* inputButton;
    QPushButton* clearButton;
    QString lastInput;

public:
    MainWindow(QWidget* parent = nullptr);
    ~MainWindow();

private slots:
    void onInputButtonClicked();
    void onClearButtonClicked();   // ← ДОБАВЛЕН НОВЫЙ СЛОТ
    void updateDisplay();
};

#endif // MAINWINDOW_H