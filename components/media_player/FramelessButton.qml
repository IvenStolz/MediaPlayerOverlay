import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: buttonRoot
    signal buttonPressed()

    property alias iconSource: image.source
    property int iconSize: 32

    property color iconColor: mouseArea.containsMouse ? Qt.tint(hoverIconColor, "#66ffffff") : "#ffffff"
    property color hoverIconColor: "#99ffff"

    height: 48; width: 48
    radius: 16
    color: "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        text: ""
    }

    Image {
        id: image
        anchors.centerIn: parent
        width: buttonRoot.iconSize
        height: buttonRoot.iconSize
        sourceSize.width: buttonRoot.iconSize
        sourceSize.height: buttonRoot.iconSize
        fillMode: Image.PreserveAspectFit
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: buttonRoot.iconColor
            Behavior on colorizationColor {
                ColorAnimation { duration: 150 }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: buttonRoot.buttonPressed()
    }
}


