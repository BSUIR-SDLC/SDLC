QT += widgets core

TARGET = L1
TEMPLATE = app

SOURCES += \
    main.cpp \
    MainWindow.cpp \
    InputDialog.cpp \
    Model.cpp \
    Controller.cpp

HEADERS += \
    MainWindow.h \
    InputDialog.h \
    Model.h \
    Controller.h

CONFIG += c++17