#include <QApplication>
#include "MainWindow.h"
#include "SinModel.h"
#include "SinController.h"

int main(int argc, char *argv[]) {
    QApplication a(argc, argv);

    SinModel model;
    
    SinController controller(&model);
    
    MainWindow w(&model, &controller);
    w.show();

    return a.exec();
}