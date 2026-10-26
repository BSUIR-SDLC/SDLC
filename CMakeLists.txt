cmake_minimum_required(VERSION 3.10)
project(ProjectTemplate LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(project src/main.cpp)
