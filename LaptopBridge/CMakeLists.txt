cmake_minimum_required(VERSION 3.16)

project(LaptopBridge VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Network SerialPort Widgets)

set(CMAKE_AUTOMOC ON)

add_executable(LaptopBridge main.cpp)

target_link_libraries(LaptopBridge PRIVATE
    Qt6::Core
    Qt6::Network
    Qt6::SerialPort
    Qt6::Widgets
)
