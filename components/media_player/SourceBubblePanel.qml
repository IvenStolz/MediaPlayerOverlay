import QtQuick

/**
 * Collapsible source-selector bubble column that slides horizontally within a fixed-width container.
 */
Item {
    id: bubblePanel

    property bool expanded: true
    property int panelWidth: 52
    property int selectedIndex: 0
    property var model: ["#1DB954", "#FF0000", "#9146FF"]

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
                delegate: Rectangle {
                    required property color modelData
                    required property int index

                    readonly property bool isSelected: index === bubblePanel.selectedIndex
                    readonly property real targetSize: isSelected ? 36 : 28

                    width: targetSize
                    height: targetSize
                    radius: width / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: modelData
                    border.color: isSelected ? "#ccffffff" : "#55ffffff"
                    border.width: isSelected ? 1.5 : 1
                    opacity: isSelected || bubbleArea.containsMouse ? 1.0 : 0.8

                    Behavior on width {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Behavior on height {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    MouseArea {
                        id: bubbleArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bubblePanel.selectedIndex = index
                    }
                }
            }
        }
    }
}