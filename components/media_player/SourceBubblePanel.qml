import QtQuick

/**
 * Collapsible source-selector bubble column that slides horizontally within a fixed-width container.
 */
Item {
    id: bubblePanel

    property bool expanded: true
    property int panelWidth: 52
    property string selectedAppId: ""
    property var model: []

    signal sessionSelected(string appId)

    /** True while the panel is visible or mid-animation. */
    readonly property bool active: content.opacity > 0.01

    width: panelWidth
    clip: true

    Item {
        id: content
        width: bubblePanel.panelWidth
        height: parent.height
        x: bubblePanel.expanded ? 0 : bubblePanel.panelWidth
        opacity: bubblePanel.expanded ? 1.0 : 0.0

        Behavior on x {
            NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
        }

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
        }

        Column {
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Repeater {
                model: bubblePanel.model
                delegate: Item {
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: modelData.appId === bubblePanel.selectedAppId
                    readonly property real targetSize: isSelected ? 36 : 28

                    width: targetSize
                    height: targetSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: isSelected || bubbleArea.containsMouse ? 1.0 : 0.7

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Behavior on height {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    Image {
                        anchors.fill: parent
                        source: modelData.iconUrl !== ""
                            ? modelData.iconUrl
                            : "qrc:/MediaPlayerOverlay/assets/icons/music_note.svg"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    MouseArea {
                        id: bubbleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bubblePanel.sessionSelected(modelData.appId)
                    }
                }
            }
        }
    }
}