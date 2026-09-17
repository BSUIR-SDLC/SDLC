// Controller.h
#ifndef CONTROLLER_H
#define CONTROLLER_H

#include <QObject>
#include "Model.h"

class Controller : public QObject {
    Q_OBJECT

private:
    Model model;

public:
    Controller();
    void processInput(const QString& text);
    QString getInputText() const;
    QString getResultText() const;
    bool isValidData() const;
};

#endif // CONTROLLER_H