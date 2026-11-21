import QtQuick
import QtQuick.Controls
import "components/media_player"
import "components/settings"

Window {
    id: root
    objectName: "overlayWindow"
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    readonly property real cardScale: 0.8

    width: card.width * cardScale
    height: card.height * cardScale

    Component.onCompleted: {
        windowBlurController.configureOverlayWindow(root)
        windowBlurController.setOverlayWindowBlur(
            root, settingsWindow.appearanceMode === "Acrylic")
    }

    Connections {
        target: settingsWindow
        function onAppearanceModeChanged() {
            windowBlurController.setOverlayWindowBlur(
                root, settingsWindow.appearanceMode === "Acrylic")
        }
    }

    SettingsWindow {
        id: settingsWindow
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    DragHandler {
        target: null
        onActiveChanged: if (active) root.startSystemMove()
    }

    MediaPlayerCard {
        id: card
        anchors.centerIn: parent
        scale: root.cardScale

        trackTitle: mediaManager.title
        trackArtist: mediaManager.artist
        coverUrl: mediaManager.coverURL
        isPlaying: mediaManager.isPlaying
        songDurationMs: mediaManager.songDurationMs
        songPositionMs: mediaManager.songPositionMs
        accentColors: mediaManager.accentColors
        colorTheme: settingsWindow.colorTheme
        useSongAccentColors: settingsWindow.useSongAccentColors
        customColors: settingsWindow.customColors
        useAccentColorsForControls: settingsWindow.useAccentColorsForControls
        customControlColors: settingsWindow.customControlColors
        overlayOpacity: settingsWindow.overlayOpacity
        albumCoverBlur: settingsWindow.albumCoverBlur
        backgroundBrightness: settingsWindow.backgroundBrightness
        backgroundSaturation: settingsWindow.backgroundSaturation
        appearanceMode: settingsWindow.appearanceMode

        onPlayPauseClicked: mediaManager.togglePlayPause()
        onNextClicked: mediaManager.next()
        onPreviousClicked: mediaManager.previous()
        onSkipToTime: (ms) => mediaManager.skipToTime(ms)
        onSettingsClicked: settingsWindow.show()
    }
}