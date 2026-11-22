cmake_minimum_required(VERSION 3.20)
project(LifeCalculator LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(LifeCalculator WIN32
    src/main.cpp
    src/Model.cpp
    src/View.cpp
    src/Controller.cpp
)

target_include_directories(LifeCalculator PRIVATE include)

if (MINGW)
    target_link_options(LifeCalculator PRIVATE -municode)
endif()

target_compile_definitions(LifeCalculator PRIVATE UNICODE _UNICODE)

# Исходные файлы сохранены в UTF-8. Эти параметры нужны для корректного
# отображения русских Unicode-строк в Windows-приложении.
if (MSVC)
    target_compile_options(LifeCalculator PRIVATE /utf-8)
elseif (MINGW OR CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
    target_compile_options(LifeCalculator PRIVATE -finput-charset=UTF-8 -fexec-charset=UTF-8)
endif()