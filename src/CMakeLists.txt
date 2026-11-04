cmake_minimum_required(VERSION 3.16)

project(SinCalculator LANGUAGES CXX)

# Требуемый стандарт C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Включаем автоматическую генерацию moc-файлов (критично для Q_OBJECT)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Поиск пакетов Qt (автоматически найдет установленную Qt6 или Qt5)
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets)

# Исходные файлы проекта
set(SOURCES
    main.cpp
    MainWindow.cpp
    InputDialog.cpp
)

# Заголовочные файлы
set(HEADERS
    SinData.h
    SinModel.h
    SinController.h
    MainWindow.h
    InputDialog.h
)

# Создание исполняемого файла
add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}
)

# Линковка с библиотеками Qt Widgets
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt${QT_VERSION_MAJOR}::Widgets
)