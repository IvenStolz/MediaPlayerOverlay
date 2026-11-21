import QtQuick

Rectangle {
    id: settingToggle

    property string title: "Setting"
    property string description: ""
    property bool checked: false
    readonly property int minimumWidth: 360

    signal toggled(bool checked)

    width: Math.max(parent ? parent.width : 0, minimumWidth)
    height: Math.max(72, textContainer.height + 20)
    radius: 6
    color: "#22ffffff"

    Item {
        id: textContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.topMargin: 10
        width: toggleTrack.x - x - 12
        height: settingTitle.implicitHeight + 3 + settingDescription.implicitHeight

        Text {
            id: settingTitle
            width: parent.width
            text: settingToggle.title
            color: "#f2ffffff"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }

        Text {
            id: settingDescription
            anchors.top: settingTitle.bottom
            anchors.topMargin: 3
            width: parent.width
            text: settingToggle.description
            color: "#f2cccccc"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        id: toggleTrack
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 42
        height: 24
        radius: height / 2
        color: settingToggle.checked ? "#b392B38F" : "#55777777"
        border.color: settingToggle.checked ? "#aaffffff" : "#77ffffff"
        border.width: 1

        Rectangle {
            x: settingToggle.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: height / 2
            color: "#f2ffffff"

            Behavior on x {
                NumberAnimation { duration: 140 }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            settingToggle.checked = !settingToggle.checked
            settingToggle.toggled(settingToggle.checked)
        }
    }
}