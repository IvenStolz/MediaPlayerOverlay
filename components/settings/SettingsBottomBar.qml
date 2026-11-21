import QtQuick
import QtQuick.Layouts

Rectangle {
    id: bottomBar

    signal quitRequested()
    signal discardRequested()
    signal saveRequested()

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: 56
    color: "#2A92B38F"

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 12
        anchors.bottomMargin: 12

        Rectangle {
            id: quitButton
            implicitWidth: 76
            Layout.preferredWidth: implicitWidth
            Layout.fillHeight: true
            radius: 6
            color: quitMouseArea.containsMouse ? "#55cc5555" : "#22ffffff"

            Text {
                anchors.centerIn: parent
                text: "Quit"
                color: "#f2ffffff"
                font.pixelSize: 14
            }

            MouseArea {
                id: quitMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bottomBar.quitRequested()
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            id: discardButton
            implicitWidth: 88
            Layout.preferredWidth: implicitWidth
            Layout.fillHeight: true
            radius: 6
            color: discardMouseArea.containsMouse ? "#44ffffff" : "#22ffffff"

            Text {
                anchors.centerIn: parent
                text: "Discard"
                color: "#f2ffffff"
                font.pixelSize: 14
            }

            MouseArea {
                id: discardMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bottomBar.discardRequested()
            }
        }

        Rectangle {
            id: saveButton
            implicitWidth: 76
            Layout.preferredWidth: implicitWidth
            Layout.fillHeight: true
            radius: 6
            color: saveMouseArea.containsMouse ? "#6692B38F" : "#4492B38F"
            border.color: "#6692B38F"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Save"
                color: "#f2ffffff"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: saveMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bottomBar.saveRequested()
            }
        }
    }
}
