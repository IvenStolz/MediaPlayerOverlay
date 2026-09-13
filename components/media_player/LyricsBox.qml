import QtQuick
import QtQuick.Controls

Item {
    id: rootItem
    property int currentPositionMs: 0

    onCurrentPositionMsChanged: {
        if (lyricsList.currentIndex < lyricsList.count - 1) {
            let nextLineTime = lyricsList.model[lyricsList.currentIndex + 1].timeMs;
            if (currentPositionMs >= nextLineTime) {
                lyricsList.currentIndex++;
            }
        }
    }

    ListView {
        anchors.margins: 0
        id: lyricsList
        anchors.fill: parent
        clip: true
        model: mediaManager.parsedLyrics

        delegate: Text {
            width: lyricsList.width
            text: modelData.text
            font.pixelSize: ListView.isCurrentItem ? 25 : 26
            font.weight: ListView.isCurrentItem ? 700 : 500
            color: "white"
            opacity: ListView.isCurrentItem ? 1.0 : 0.6
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.Wrap

            Behavior on font.pixelSize { NumberAnimation { duration: 300 } }
            Behavior on font.weight { NumberAnimation { duration: 300 } }
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }

        preferredHighlightBegin: height / 2 - 60
        preferredHighlightEnd: height / 2 - 20
        highlightRangeMode: ListView.StrictlyEnforceRange

        Behavior on contentY { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }}
    }

}