import QtQuick
import QtQuick.Controls

Item {
    id: rootItem
    property int currentPositionMs: 0
    property bool isSynced: true
    property bool lyricsAvailable: false

    onCurrentPositionMsChanged: {
        let lyricsArray = lyricsList.model;
        if (!lyricsArray || lyricsArray.length === 0) {
            lyricsAvailable = false
            return;
        }
        lyricsAvailable = true;

        let targetIndex = getTargetIndex();

        if (Math.abs(lyricsList.currentIndex - targetIndex) > 1) {
            rootItem.isSynced = false;
        } else {
            rootItem.isSynced = true;
        }

        if (lyricsList.currentIndex !== targetIndex && isSynced) {
            lyricsList.currentIndex = targetIndex;
        }
    }

    function getTargetIndex() {
        let lyricsArray = lyricsList.model;

        let targetIndex = 0;
        for (let i = lyricsArray.length - 1; i >= 0; i--) {
            if (currentPositionMs >= lyricsArray[i].timeMs) {
                targetIndex = i;
                break;
            }
        }
        return targetIndex;
    }

    function syncLyrics() {
        let targetIndex = getTargetIndex();
        lyricsList.currentIndex = targetIndex;
        rootItem.isSynced = true;
    }

    ListView {
        visible: rootItem.lyricsAvailable
        anchors.margins: 0
        id: lyricsList
        anchors.fill: parent
        anchors.left: parent.left
        clip: true
        model: mediaManager.parsedLyrics

        delegate: Text {
            width: lyricsList.width
            text: modelData.text
            font.pixelSize: 26
            font.weight: 600
            scale: ListView.isCurrentItem ? 1.0 : 0.9
            transformOrigin: Item.Left
            color: "white"
            opacity: ListView.isCurrentItem ? 1.0 : 0.4
            horizontalAlignment: Text.AlignLeft
            wrapMode: Text.Wrap

            Behavior on scale { NumberAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        preferredHighlightBegin: height / 2 - 60
        preferredHighlightEnd: height / 2 - 20
        highlightRangeMode: ListView.StrictlyEnforceRange

        Behavior on contentY { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }}
    }

    Text {
        anchors.centerIn: parent
        visible: !rootItem.lyricsAvailable
        text: "No lyrics available\n:("
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: 30
        font.weight: 600
        color: "white"
    }

    Rectangle {
        visible: !rootItem.isSynced
        width: 120
        height: 36
        radius: 18
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.margins: 8
        scale: syncBtnMouseArea.containsMouse ? 1 : 0.95
        Behavior on opacity { NumberAnimation { duration: 150 }}
        Behavior on scale { NumberAnimation { duration: 150 }}
        opacity: syncBtnMouseArea.containsMouse ? 1 : 0.7
        color: "#ffffffff"
        MouseArea {
            id: syncBtnMouseArea
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            onClicked: rootItem.syncLyrics()
        }
        Text {
            text: "Sync Lyrics"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.fill: parent
            font.pixelSize: 18
            font.weight: 700
        }
    }

}