cmake_minimum_required(VERSION 3.16)
project(L_1)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Указываем путь к Qt из MSYS2
set(CMAKE_PREFIX_PATH "C:/msys64/ucrt64")

find_package(Qt6 REQUIRED COMPONENTS Widgets Core)

set(SOURCES
    main.cpp
    MainWindow.cpp
    InputDialog.cpp
    Model.cpp
    Controller.cpp
)

set(HEADERS
    MainWindow.h
    InputDialog.h
    Model.h
    Controller.h
)

qt6_add_executable(L_1 ${SOURCES} ${HEADERS})

target_link_libraries(L_1 Qt6::Widgets Qt6::Core)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
