#pragma once
#include <QMainWindow>
#include <QLabel>
#include <QPushButton>
#include "SinData.h"
#include "SinModel.h"
#include "SinController.h"

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    MainWindow(SinModel* model, SinController* controller, QWidget *parent = nullptr);

private slots:
    void onCalculateClicked();
    void onModelDataChanged(int newTotal);

private:
    QLabel* countLabel;
    QLabel* statusLabel;
    QPushButton* calcButton;
    
    SinModel* m_model;
    SinController* m_controller;
    SinData m_lastData;
};