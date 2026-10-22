#ifndef LIFECONTROLLER_H
#define LIFECONTROLLER_H

#include <QObject>

class LifeModel;
class MainWindow;

class LifeController : public QObject {
    Q_OBJECT

public:
    LifeController(LifeModel *model, MainWindow *view);

public slots:
    void onOpenInputDialog();
    void onInputConfirmed(int day, int month, int year);

private:
    LifeModel *m_model;
    MainWindow *m_view;
};

#endif