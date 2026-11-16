cmake_minimum_required(VERSION 3.21)
project(MediaPlayerOverlay VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

list(APPEND CMAKE_PREFIX_PATH "C:/Qt/6.11.2/mingw_64")

find_package(Qt6 REQUIRED COMPONENTS Quick Network QuickEffects)

qt_standard_project_setup()
include(CTest)

qt_add_executable(MediaPlayerOverlay
        main.cpp
        WindowBlur.h
        MediaManager.h
        MediaManager.cpp
        LyricsFetcher.h
        LyricsUtils.h
        PlaybackTimeline.h
        appicon.rc
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
        RESOURCES
        assets/icons/play.svg
        assets/icons/pause.svg
        assets/icons/skip_next.svg
        assets/icons/skip_previous.svg
        assets/icons/pin.svg
        assets/icons/lyrics.svg
        assets/icons/settings.svg
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
    )
    target_include_directories(MediaPlayerOverlayTests PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(MediaPlayerOverlayTests PRIVATE Qt6::Core Qt6::Test)
    add_test(NAME MediaPlayerOverlayTests COMMAND MediaPlayerOverlayTests)
endif()