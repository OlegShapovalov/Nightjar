cmake_minimum_required(VERSION 3.16)
project(Nightjar LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 Multimedia)

qt_standard_project_setup()
qt_policy(SET QTP0004 NEW)

qt_add_executable(nightjar
    src/main.cpp
    src/filemanager.h
    src/filemanager.cpp
)

qt_add_qml_module(nightjar
    URI Nightjar
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        qml/Main.qml
        qml/components/Theme.qml
        qml/components/TopToolBar.qml
        qml/components/FilePane.qml
        qml/components/CommandLine.qml
        qml/components/GlobalStatusBar.qml
        qml/components/HelpOverlay.qml
        qml/components/PreviewOverlay.qml
        qml/components/MultiRenameDialog.qml
        qml/components/GlobalSearchDialog.qml
        qml/components/SettingsDialog.qml
        qml/components/ConnectDialog.qml
)

target_link_libraries(nightjar PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
)

# Инсталляция для системы
install(TARGETS nightjar DESTINATION bin)
install(FILES nightjar.desktop DESTINATION share/applications)
install(FILES assets/nightjar.svg DESTINATION share/icons/hicolor/scalable/apps RENAME nightjar.svg)
