#include <QApplication>
#include "mainwindow.h"
#include "lifemodel.h"
#include "lifecontroller.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName("Калькулятор Жизни");

    LifeModel model;
    MainWindow view;
    view.setModel(&model);

    LifeController controller(&model, &view);

    view.show();
    return app.exec();
}