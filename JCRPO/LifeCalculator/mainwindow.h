#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "lifemodel.h"

class QLabel;
class QPushButton;

class MainWindow : public QMainWindow, public ModelObserver {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);

    void onModelChanged() override;

    void setModel(LifeModel* model);

    void showSuccessMessage(const QString &msg);

signals:
    void openInputRequested();

private:
    void createUI();
    void updateResults();

    QLabel *m_sleepLabel;
    QLabel *m_blinksLabel;
    QLabel *m_heartLabel;
    QLabel *m_bloodLabel;
    QLabel *m_waterLabel;
    QLabel *m_laughsLabel;
    QLabel *m_statusLabel;

    QPushButton *m_inputButton;

    LifeModel *m_model;
};

#endif