#include "lifecontroller.h"
#include "lifemodel.h"
#include "mainwindow.h"
#include "inputdialog.h"
#include <QDate>
#include <QMessageBox>

LifeController::LifeController(LifeModel *model, MainWindow *view)
    : m_model(model), m_view(view) {
    connect(m_view, &MainWindow::openInputRequested,
            this, &LifeController::onOpenInputDialog);
}

void LifeController::onOpenInputDialog() {
    InputDialog dialog(m_view);

    if (m_model->hasLastInput()) {
        dialog.setInitialValues(
            m_model->lastDay(),
            m_model->lastMonth(),
            m_model->lastYear()
        );
    }

    if (dialog.exec() == QDialog::Accepted) {
        int day = dialog.day();
        int month = dialog.month();
        int year = dialog.year();

        onInputConfirmed(day, month, year);
    }
}

void LifeController::onInputConfirmed(int day, int month, int year) {
    m_model->setLastInput(day, month, year);

    QDate birthDate(year, month, day);
    QString error;

    if (!m_model->calculate(birthDate, error)) {
        QMessageBox::warning(m_view, "Ошибка", error);
        return;
    }

    m_view->showSuccessMessage("Данные успешно рассчитаны!");
}