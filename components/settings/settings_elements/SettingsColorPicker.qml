import QtQuick
Rectangle {
    id: colorSelection

    property string title: "Colors"
    property string description: ""
    property var colors: ["#92B38F"]
    property int editingIndex: -1
    readonly property int minimumWidth: 360

    signal selectionChanged(var selectedColors)

    width: Math.max(parent ? parent.width : 0, minimumWidth)
    height: Math.max(72, textContainer.height + 24)
    radius: 6
    color: "#22ffffff"

    Item {
        id: textContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.topMargin: 10
        anchors.right: colorCircles.left
        anchors.rightMargin: 8
        height: colorTitle.implicitHeight + 3 + colorDescription.implicitHeight

        Text {
            id: colorTitle
            width: parent.width
            text: colorSelection.title
            color: "#f2ffffff"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }

        Text {
            id: colorDescription
            anchors.top: colorTitle.bottom
            anchors.topMargin: 3
            width: parent.width
            text: colorSelection.description
            color: "#f2cccccc"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }

    Row {
        id: colorCircles
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Repeater {
            model: colorSelection.colors

            delegate: Rectangle {
                id: colorCircle
                required property int index
                required property var modelData
                width: 28
                height: 28
                radius: width / 2
                color: modelData
                border.color: "#99ffffff"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        colorSelection.editingIndex = colorCircle.index
                        colorPicker.openForColor(colorCircle.color)
                    }
                }
            }
        }

    }

    HsvColorPicker {
        id: colorPicker

        onColorAccepted: function(selectedColor) {
            const updatedColors = colorSelection.colors.slice()
            if (colorSelection.editingIndex >= 0
                && colorSelection.editingIndex < updatedColors.length) {
            updatedColors[colorSelection.editingIndex] = selectedColor
            colorSelection.selectionChanged(updatedColors)
            }
        }
    }
}
