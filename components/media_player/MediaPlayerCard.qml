// noinspection BadExpressionStatementJS

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: mediaPlayerRoot

    property string trackTitle: "No Media Playing"
    property string trackArtist: "-"
    property string coverUrl: ""
    property bool isPlaying: false
    property int songPositionMs: 0
    property int songDurationMs: 0
    property list<color> accentColors: ["#e3dc91", "#1f4026"]

    signal playPauseClicked()

    signal nextClicked()

    signal previousClicked()

    signal skipToTime(int ms)

    width: 404
    height: 180
    implicitWidth: width
    implicitHeight: height

    color: "transparent"
    radius: 8
    border.color: "#33ffffff"
    border.width: 0.5

    function formatTime(ms) {
        if (ms <= 0) return "00:00"
        let totalSeconds = Math.floor(ms / 1000)
        let m = Math.floor(totalSeconds / 60)
        let s = totalSeconds % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    Item {
        id: backgroundClip
        anchors.fill: parent
        clip: true

        Image {
            id: imgBackground
            anchors.centerIn: parent
            width: parent.width * 1.3
            height: parent.height * 1.3
            fillMode: Image.PreserveAspectCrop
            source: mediaPlayerRoot.coverUrl
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: imgBackground
            source: imgBackground
            autoPaddingEnabled: false
            saturation: 1
            brightness: 0.1
            blurEnabled: true
            blur: 1.0
            blurMax: 80
            opacity: 0.1
        }
    }
    RowLayout {
        id: songInfoRoot
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 8
        Layout.fillHeight: true
        spacing: 24

        Item {
            id: coverRoot
            Layout.preferredWidth: 96
            Layout.preferredHeight: 96

            Rectangle {
                id: coverRect
                anchors.fill: parent
                radius: 10
                color: "white"
                visible: false
                layer.enabled: true
            }

            Image {
                id: img
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: mediaPlayerRoot.coverUrl
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: img
                maskEnabled: true
                maskSource: coverRect
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 4

            Text {
                text: mediaPlayerRoot.trackTitle
                font.family: "Helvetica"
                font.weight: 700
                font.pixelSize: 26
                color: "#ccffffff"

                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: mediaPlayerRoot.trackArtist
                font.family: "Helvetica"
                font.weight: 500
                font.pixelSize: 20
                color: "#77ffffff"

                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            RowLayout {
                id: playBar
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                spacing: 10
                visible: true

                property bool isDragging: false
                property int dragPositionMs: 0

                Text {
                    text: mediaPlayerRoot.formatTime(playBar.isDragging ? playBar.dragPositionMs : mediaPlayerRoot.songPositionMs)
                    color: "#77ffffff"
                    Layout.minimumWidth: 30
                    Layout.leftMargin: 0
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 14
                }
                Item {
                    height: 4
                    Layout.fillWidth: true

                    Rectangle {
                        anchors.fill: parent
                        radius: 2
                        color: "#10ffffff"
                    }

                    Item {
                        height: parent.height
                        width: mediaPlayerRoot.songDurationMs > 0
                            ? ((playBar.isDragging ? playBar.dragPositionMs : mediaPlayerRoot.songPositionMs) / mediaPlayerRoot.songDurationMs) * parent.width
                            : 0
                        clip: true

                        Rectangle {
                            width: parent.parent.width
                            height: parent.height
                            radius: 2
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: (mediaPlayerRoot.accentColors && mediaPlayerRoot.accentColors[0]) ? mediaPlayerRoot.accentColors[0] : "#ff3366"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: (mediaPlayerRoot.accentColors && mediaPlayerRoot.accentColors[1]) ? mediaPlayerRoot.accentColors[1] : "#77c0ff"
                                }
                            }
                        }
                    }

                    MouseArea {
                        height: 20
                        anchors.right: parent.right
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true

                        function getMsFromMousePos(mouseX) {
                            let clampedX = Math.max(0, Math.min(mouseX, width));
                            return Math.floor((clampedX / width) * mediaPlayerRoot.songDurationMs);
                        }

                        onPressed: (mouse) => {
                            playBar.isDragging = true;
                            playBar.dragPositionMs = getMsFromMousePos(mouse.x);
                        }

                        onPositionChanged: (mouse) => {
                            if (playBar.isDragging) {
                                playBar.dragPositionMs = getMsFromMousePos(mouse.x);
                            }
                        }

                        onReleased: (mouse) => {
                            if (playBar.isDragging) {
                                playBar.dragPositionMs = getMsFromMousePos(mouse.x);
                                playBar.isDragging = false;
                                mediaPlayerRoot.skipToTime(playBar.dragPositionMs);
                            }
                        }

                        onCanceled: {
                            playBar.isDragging = false;
                        }
                    }
                }

                Text {
                    text: mediaPlayerRoot.formatTime(mediaPlayerRoot.songDurationMs)
                    color: "#77ffffff"
                    Layout.minimumWidth: 30
                    Layout.rightMargin: 8
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 14
                }
            }
        }
    }
    // Lyrics
    LyricsBox {
        id: lyricsRoot

        currentPositionMs: mediaPlayerRoot.songPositionMs

        anchors.top: songInfoRoot.bottom
        anchors.bottom: buttonBarRoot.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 26
        opacity: 0
    }

    RowLayout {
        id: buttonBarRoot
        Layout.alignment: Qt.AlignHCenter
        anchors.left: parent.left
        anchors.right: parent.right
        Layout.margins: 8
        anchors.bottomMargin: 8
        anchors.bottom: parent.bottom

        FramelessButton {
            iconSource: "qrc:/SpotifyRemote/assets/icons/settings.svg"
            iconSize: 26
            hoverIconColor: accentColors[0]
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: 4
            Layout.fillWidth: true

            MediaControlButton {
                iconSource: "qrc:/SpotifyRemote/assets/icons/skip_previous.svg"
                iconSize: 40
                hoverIconColor: accentColors[0]
                onButtonPressed: mediaPlayerRoot.previousClicked()
            }
            MediaControlButton {
                iconSource: mediaPlayerRoot.isPlaying ? "qrc:/SpotifyRemote/assets/icons/pause.svg" : "qrc:/SpotifyRemote/assets/icons/play.svg"
                iconSize: 40
                hoverIconColor: accentColors[0]
                onButtonPressed: mediaPlayerRoot.playPauseClicked()
            }
            MediaControlButton {
                iconSource: "qrc:/SpotifyRemote/assets/icons/skip_next.svg"
                iconSize: 40
                hoverIconColor: accentColors[0]
                onButtonPressed: mediaPlayerRoot.nextClicked()
            }
        }

        FramelessButton {
            iconSource: "qrc:/SpotifyRemote/assets/icons/lyrics.svg"
            iconSize: 26
            hoverIconColor: accentColors[0]
            Layout.fillWidth: true
            onButtonPressed: {
                if (mediaPlayerRoot.state === "showLyrics") {
                    mediaPlayerRoot.state = ""
                } else {
                    mediaPlayerRoot.state = "showLyrics"
                }
            }
        }
    }
    states: [
        State {
            name: "showLyrics"
            PropertyChanges {
                target: mediaPlayerRoot
                height: 440
            }
            PropertyChanges {
                target: lyricsRoot
                opacity: 1
            }
        }
    ]
    transitions: [
        Transition {
            from: "*"
            to: "*"
            NumberAnimation {
                properties: "height, width"
                duration: 300
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                properties: "opacity"
                duration: 300
                easing.type: Easing.InOutQuad
            }
        }
    ]
}