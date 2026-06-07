cmake_minimum_required(VERSION 3.16)

project(HudProject VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network Positioning Location)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(HudProject
    src/main.cpp
    src/ObdValues.h
    src/ObdParser.h
    src/ObdParser.cpp
    src/ObdManager.h
    src/ObdManager.cpp
    src/VehicleData.h
    src/VehicleData.cpp
    src/ThemeManager.h
    src/ThemeManager.cpp
    src/WeatherData.h
    src/WeatherData.cpp
    src/Clock.h
    src/Clock.cpp
)

qt_add_qml_module(HudProject
    URI HudProject
    QML_FILES
        qml/main.qml
        qml/HudView.qml
        qml/VariantMinimal.qml
        qml/components/ArcGauge.qml
        qml/components/HudPanel.qml
        qml/components/SpeedCenter.qml
        qml/components/TopBar.qml
        qml/components/BottomBar.qml
        qml/components/MiniGauge.qml
        qml/components/WarningIcons.qml
        qml/hud2/qmldir
        qml/hud2/Hud2Theme.qml
        qml/hud2/ArcGauge.qml
        qml/hud2/RadialGauge.qml
        qml/hud2/BarGauge.qml
        qml/hud2/FuelGauge.qml
        qml/hud2/GearIndicator.qml
        qml/hud2/CompassRose.qml
        qml/hud2/O2Trace.qml
        qml/hud2/Page1Driving.qml
        qml/hud2/Page2Engine.qml
        qml/hud2/Page3Nav.qml
        qml/hud2/Hud2App.qml
    RESOURCES
        images/car_outline.png
)

set_target_properties(HudProject PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.kdt.hudproject"
    MACOSX_BUNDLE_BUNDLE_NAME "HudProject"
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2" # 1: iPhone, 2: iPad
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist.in"
)

target_link_libraries(HudProject PRIVATE
    Qt6::Quick
    Qt6::Network
    Qt6::Positioning
    Qt6::Location
)

install(TARGETS HudProject
    BUNDLE  DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
