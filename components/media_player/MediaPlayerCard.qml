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
    property string appearanceMode: "Acrylic"
    property string colorTheme: "Album Cover"
    property bool useSongAccentColors: false
    property var customColors: ["#92B38F", "#587A64"]
    property bool useAccentColorsForControls: true
    property var customControlColors: ["#92B38F", "#587A64"]
    property real overlayOpacity: 20
    property real albumCoverBlur: 80
    property real backgroundBrightness: 0
    property real backgroundSaturation: 0
    property bool overlayHovered: false
    property bool pinned: false
    readonly property real backgroundOpacity: appearanceMode === "Opaque"
        ? 1
        : Math.max(0, Math.min(1, overlayOpacity / 100))
    readonly property var themeColors: {
        const colors = colorTheme === "Album Cover" || useSongAccentColors
            ? accentColors : customColors
        const firstColor = colors && colors.length > 0 ? colors[0] : "#e3dc91"
        const secondColor = colorTheme === "Single Color"
            ? firstColor
            : (colors && colors.length > 1 ? colors[1] : firstColor)
        return [firstColor, secondColor]
    }
    readonly property var controlColors: {
        const colors = useAccentColorsForControls ? accentColors : customControlColors
        const firstColor = colors && colors.length > 0 ? colors[0] : "#e3dc91"
        const secondColor = colors && colors.length > 1 ? colors[1] : firstColor
        return [firstColor, secondColor]
    }

    signal playPauseClicked()
    signal nextClicked()
    signal previousClicked()
    signal skipToTime(int ms)
    signal settingsClicked()
    signal pinClicked()
    signal coverClicked()

    width: 404
    height: 180
    implicitWidth: width
    implicitHeight: height

    color: "transparent"
    radius: 8
    border.color: "#33ffffff"
    border.width: 0.5

    Rectangle {
        id: pinButton
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 6
        anchors.rightMargin: 6
        width: 30
        height: 30
        radius: 6
        z: 2
        visible: mediaPlayerRoot.overlayHovered
        color: pinMouseArea.containsMouse ? "#44ffffff" : "transparent"

        Image {
            anchors.centerIn: parent
            width: 20
            height: 20
            source: mediaPlayerRoot.pinned
                ? "qrc:/MediaPlayerOverlay/assets/icons/pin_filled.svg"
                : "qrc:/MediaPlayerOverlay/assets/icons/pin_outline.svg"
            sourceSize.width: 24
            sourceSize.height: 24
        }

        MouseArea {
            id: pinMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mediaPlayerRoot.pinClicked()
        }
    }

    function formatTime(ms) {
        if (ms <= 0) return "00:00"
        let totalSeconds = Math.floor(ms / 1000)
        let m = Math.floor(totalSeconds / 60)
        let s = totalSeconds % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function adjustColorBrightness(color, amount) {
        const factor = Math.max(-1, Math.min(1, amount / 100))
        const adjust = function(channel) {
            return factor >= 0
                ? channel + (1 - channel) * factor
                : channel * (1 + factor)
        }
        return Qt.rgba(adjust(color.r), adjust(color.g), adjust(color.b), color.a)
    }

    function adjustColorSaturation(color, amount) {
        const factor = Math.max(-1, Math.min(1, amount / 100))
        const gray = color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
        const scale = 1 + factor
        return Qt.rgba(
            Math.max(0, Math.min(1, gray + (color.r - gray) * scale)),
            Math.max(0, Math.min(1, gray + (color.g - gray) * scale)),
            Math.max(0, Math.min(1, gray + (color.b - gray) * scale)),
            color.a)
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
            saturation: Math.max(-1, Math.min(1, mediaPlayerRoot.backgroundSaturation / 100))
            brightness: Math.max(-1, Math.min(1, mediaPlayerRoot.backgroundBrightness / 100))
            blurEnabled: mediaPlayerRoot.colorTheme === "Album Cover"
            blur: Math.max(0, Math.min(1, mediaPlayerRoot.albumCoverBlur / 100))
            blurMax: 128
            opacity: mediaPlayerRoot.colorTheme === "Album Cover"
                ? mediaPlayerRoot.backgroundOpacity : 0
        }

        Rectangle {
            anchors.fill: parent
            visible: mediaPlayerRoot.colorTheme !== "Album Cover"
            opacity: mediaPlayerRoot.backgroundOpacity
            color: mediaPlayerRoot.adjustColorBrightness(
                mediaPlayerRoot.adjustColorSaturation(
                    mediaPlayerRoot.themeColors[0],
                    mediaPlayerRoot.backgroundSaturation),
                mediaPlayerRoot.backgroundBrightness)

            gradient: mediaPlayerRoot.colorTheme === "Gradient" ? gradientBackground : null

            Gradient {
                id: gradientBackground
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: mediaPlayerRoot.adjustColorBrightness(
                        mediaPlayerRoot.adjustColorSaturation(
                            mediaPlayerRoot.themeColors[0],
                            mediaPlayerRoot.backgroundSaturation),
                        mediaPlayerRoot.backgroundBrightness)
                }
                GradientStop {
                    position: 1
                    color: mediaPlayerRoot.adjustColorBrightness(
                        mediaPlayerRoot.adjustColorSaturation(
                            mediaPlayerRoot.themeColors[1],
                            mediaPlayerRoot.backgroundSaturation),
                        mediaPlayerRoot.backgroundBrightness)
                }
            }
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

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: mediaPlayerRoot.coverClicked()
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
                                    color: mediaPlayerRoot.controlColors[0]
                                }
                                GradientStop {
                                    position: 1.0
                                    color: mediaPlayerRoot.controlColors[1]
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
            iconSource: "qrc:/MediaPlayerOverlay/assets/icons/settings.svg"
            iconSize: 26
            hoverIconColor: mediaPlayerRoot.controlColors[0]
            Layout.fillWidth: true
            onButtonPressed: mediaPlayerRoot.settingsClicked()
        }

        RowLayout {
            spacing: 4
            Layout.fillWidth: true

            MediaControlButton {
                iconSource: "qrc:/MediaPlayerOverlay/assets/icons/skip_previous.svg"
                iconSize: 40
                hoverIconColor: mediaPlayerRoot.controlColors[0]
                onButtonPressed: mediaPlayerRoot.previousClicked()
            }
            MediaControlButton {
                iconSource: mediaPlayerRoot.isPlaying ? "qrc:/MediaPlayerOverlay/assets/icons/pause.svg" : "qrc:/MediaPlayerOverlay/assets/icons/play.svg"
                iconSize: 40
                hoverIconColor: mediaPlayerRoot.controlColors[0]
                onButtonPressed: mediaPlayerRoot.playPauseClicked()
            }
            MediaControlButton {
                iconSource: "qrc:/MediaPlayerOverlay/assets/icons/skip_next.svg"
                iconSize: 40
                hoverIconColor: mediaPlayerRoot.controlColors[0]
                onButtonPressed: mediaPlayerRoot.nextClicked()
            }
        }

        FramelessButton {
            iconSource: "qrc:/MediaPlayerOverlay/assets/icons/lyrics.svg"
            iconSize: 26
            hoverIconColor: mediaPlayerRoot.controlColors[0]
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