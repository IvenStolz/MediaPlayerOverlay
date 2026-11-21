import QtQuick
import QtQuick.Controls

Rectangle {
    id: settingSlider

    property string title: "Setting"
    property string description: ""
    property real from: 0
    property real to: 100
    property real value: 50
    property real stepSize: 1
    property int decimals: 0
    property string valueSuffix: ""
    readonly property int minimumWidth: 360

    signal valueEdited(real value)

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
        width: 230
        height: settingTitle.implicitHeight + 3 + settingDescription.implicitHeight

        Text {
            id: settingTitle
            anchors.left: parent.left
            anchors.top: parent.top
            width: parent.width
            text: settingSlider.title
            color: "#f2ffffff"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }

        Text {
            id: settingDescription
            anchors.left: parent.left
            anchors.top: settingTitle.bottom
            anchors.topMargin: 3
            width: parent.width
            text: settingSlider.description
            color: "#f2cccccc"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }

    Slider {
        id: valueSlider
        anchors.left: textContainer.right
        anchors.right: parent.right
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        height: 40
        from: settingSlider.from
        to: settingSlider.to
        stepSize: settingSlider.stepSize
        value: settingSlider.value
        onMoved: settingSlider.valueEdited(value)

        background: Rectangle {
            x: valueSlider.leftPadding
            y: valueSlider.topPadding + valueSlider.availableHeight / 2 - height / 2
            width: valueSlider.availableWidth
            height: 4
            radius: 2
            color: "#33ffffff"

            Rectangle {
                width: valueSlider.visualPosition * parent.width
                height: parent.height
                radius: 2
                color: "#b392B38F"
            }
        }

        handle: Rectangle {
            x: valueSlider.leftPadding + valueSlider.visualPosition
               * (valueSlider.availableWidth - width)
            y: valueSlider.topPadding + valueSlider.availableHeight / 2 - height / 2
            width: 16
            height: 16
            radius: width / 2
            color: valueSlider.pressed ? "#d9ffffff" : "#f2ffffff"
            border.color: "#b392B38F"
            border.width: 2

            HoverHandler {
                id: handleHover
            }

            ToolTip.visible: handleHover.hovered
            ToolTip.delay: 0
            ToolTip.text: settingSlider.value.toFixed(settingSlider.decimals)
                          + settingSlider.valueSuffix
        }
    }
}
