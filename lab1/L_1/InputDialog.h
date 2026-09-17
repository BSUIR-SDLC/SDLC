// InputDialog.h
#ifndef INPUTDIALOG_H
#define INPUTDIALOG_H

#include <QDialog>
#include <QLabel>
#include <QLineEdit>
#include <QPushButton>
#include <QVBoxLayout>

class InputDialog : public QDialog {
    Q_OBJECT

private:
    QLineEdit* inputLineEdit;
    QPushButton* okButton;
    QPushButton* cancelButton;
    QString lastInput;

public:
    InputDialog(const QString& initialText = "", QWidget* parent = nullptr);
    QString getInputText() const;

private slots:
    void onOkClicked();
};

#endif // INPUTDIALOG_H