cmake_minimum_required(VERSION 3.16)
project(HomeLedger VERSION 0.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_options(/utf-8 /W4 /permissive-)   # исходники в UTF-8
    add_compile_definitions(_CRT_SECURE_NO_WARNINGS NOMINMAX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Библиотека логики — общая для программы и тестов
add_library(ledger_core STATIC
    src/Date.cpp src/Money.cpp src/Text.cpp src/Ledger.cpp src/Analytics.cpp src/Storage.cpp)
target_include_directories(ledger_core PUBLIC src)
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9)
    target_link_libraries(ledger_core PUBLIC stdc++fs)
endif()

add_executable(HomeLedger src/main.cpp src/App.cpp src/Console.cpp)
target_link_libraries(HomeLedger PRIVATE ledger_core)
if(MINGW)
    target_link_options(HomeLedger PRIVATE -static)   # exe без зависимостей от DLL MinGW
endif()

enable_testing()
add_executable(ledger_tests tests/tests.cpp)
target_link_libraries(ledger_tests PRIVATE ledger_core)
add_test(NAME ledger_tests COMMAND ledger_tests)
