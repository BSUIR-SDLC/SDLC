#ifndef INPUTDIALOG_H
#define INPUTDIALOG_H

#include <QDialog>

class QSpinBox;
class QPushButton;

class InputDialog : public QDialog {
    Q_OBJECT

public:
    explicit InputDialog(QWidget *parent = nullptr);

    void setInitialValues(int day, int month, int year);

    int day() const;
    int month() const;
    int year() const;

private:
    QSpinBox *m_daySpin;
    QSpinBox *m_monthSpin;
    QSpinBox *m_yearSpin;
    QPushButton *m_okButton;
    QPushButton *m_cancelButton;
};

#endif