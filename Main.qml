import QtQuick
import QtQuick.Controls
import "components/media_player"

Window {
    id: root
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    readonly property real cardScale: 0.8

    width: card.width * cardScale
    height: card.height * cardScale

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

        onPlayPauseClicked: mediaManager.togglePlayPause()
        onNextClicked: mediaManager.next()
        onPreviousClicked: mediaManager.previous()
        onSkipToTime: (ms) => mediaManager.skipToTime(ms)
    }
}