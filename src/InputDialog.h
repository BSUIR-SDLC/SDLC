#pragma once
#include <QDialog>
#include <QDateEdit>
#include <QSpinBox>
#include <QCheckBox>
#include <QPushButton>
#include "SinData.h"

class InputDialog : public QDialog {
    Q_OBJECT
public:
    explicit InputDialog(const SinData& currentData, QWidget *parent = nullptr);
    SinData getData() const;

private slots:
    void validateAndAccept();

private:
    QDateEdit* dateEdit;
    QSpinBox* liesSpin;
    QSpinBox* stolenSpin;
    QCheckBox* sworeCheck;
};