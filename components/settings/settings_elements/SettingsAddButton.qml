import QtQuick

/**
 * Full-width add-item card used to append new rule entries.
 */
Rectangle {
    id: addButton

    property string label: "+"
    readonly property int minimumWidth: 360

    signal clicked()

    width: Math.max(parent ? parent.width : 0, minimumWidth)
    height: 60
    radius: 6
    color: addArea.containsMouse ? "#3392B38F" : "#22ffffff"
    border.color: addArea.containsMouse ? "#6692B38F" : "#33ffffff"
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: addButton.label
        color: "#f2ffffff"
        font.pixelSize: 28
        font.weight: Font.Medium
    }

    MouseArea {
        id: addArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: addButton.clicked()
    }
}