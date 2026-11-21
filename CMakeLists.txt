cmake_minimum_required(VERSION 3.21)
project(MediaPlayerOverlay VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

list(APPEND CMAKE_PREFIX_PATH "C:/Qt/6.11.2/mingw_64")

find_package(Qt6 REQUIRED COMPONENTS Quick Network QuickEffects)

qt_standard_project_setup()
include(CTest)
qt_policy(SET QTP0004 NEW)

qt_add_executable(MediaPlayerOverlay
        main.cpp
        WindowBlur.h
        WindowBlurController.h
        MediaManager.h
        MediaManager.cpp
        LyricsFetcher.h
        LyricsUtils.h
        PlaybackTimeline.h
        appicon.rc
        EdgeTrigger.h
        EdgeTrigger.h
)

set_target_properties(MediaPlayerOverlay PROPERTIES WIN32_EXECUTABLE TRUE)

qt_add_qml_module(MediaPlayerOverlay
        URI MediaPlayerOverlay
        VERSION 1.0
        QML_FILES
        Main.qml
        components/ResizeFrame.qml
        components/media_player/FramelessButton.qml
        components/media_player/MediaPlayerCard.qml
        components/media_player/MediaControlButton.qml
        components/media_player/LyricsBox.qml
        components/media_player/SourceBubblePanel.qml
        components/settings/SettingsBottomBar.qml
        components/settings/AppearanceSettingsTab.qml
        components/settings/SettingsPlaceholderTab.qml
        components/settings/SettingsWindow.qml
        components/settings/settings_elements/SettingsSelection.qml
        components/settings/settings_elements/SettingsToggle.qml
        components/settings/settings_elements/SettingsSlider.qml
        components/settings/settings_elements/SettingsColorPicker.qml
        components/settings/settings_elements/HsvColorPicker.qml
        RESOURCES
        assets/icons/play.svg
        assets/icons/pause.svg
        assets/icons/skip_next.svg
        assets/icons/skip_previous.svg
        assets/icons/pin.svg
        assets/icons/pin_filled.svg
        assets/icons/pin_outline.svg
        assets/icons/lyrics.svg
        assets/icons/settings.svg
        assets/icons/arrow_drop_down.svg
        assets/icons/add.svg
        assets/icons/close.svg
        assets/icons/minimize.svg
        assets/icons/fullscreen.svg
        assets/icons/fullscreen_exit.svg
        assets/icon.png
)

target_link_libraries(MediaPlayerOverlay PRIVATE
        Qt6::Quick
        Qt6::Network
        Qt6::QuickEffects
        dwmapi
        windowsapp
)

if(BUILD_TESTING)
    find_package(Qt6 REQUIRED COMPONENTS Test)
    qt_add_executable(MediaPlayerOverlayTests
            tests/CoreFunctionsTests.cpp
            LyricsUtils.h
            PlaybackTimeline.h
            EdgeTrigger.h
    )
    target_include_directories(MediaPlayerOverlayTests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(MediaPlayerOverlayTests PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME MediaPlayerOverlayTests COMMAND MediaPlayerOverlayTests)
endif()