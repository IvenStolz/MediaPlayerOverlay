import QtQuick
import QtQuick.Controls

Item {
    id: colorPicker

    signal colorAccepted(color value)

    property real hue: 0
    property real saturation: 1
    property real value: 1
    readonly property color selectedColor: Qt.hsva(hue, saturation, value, 1)

    function openForColor(initialColor) {
        hue = initialColor.hsvHue >= 0 ? initialColor.hsvHue : 0
        saturation = initialColor.hsvSaturation
        value = initialColor.hsvValue
        colorDialog.open()
    }

    Popup {
        id: colorDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 330
        height: 390
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        padding: 18

        background: Rectangle {
            radius: 10
            color: "#ee26332d"
            border.color: "#7792B38F"
            border.width: 1
        }

        contentItem: Column {
            spacing: 12

            Text {
                text: "Choose color"
                color: "#f2ffffff"
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }

            Rectangle {
                id: saturationValueField
                width: parent.width
                height: 230
                radius: 6
                color: Qt.hsva(colorPicker.hue, 1, 1, 1)
                clip: true

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#ffffffff" }
                        GradientStop { position: 1; color: "#00ffffff" }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0; color: "#00000000" }
                        GradientStop { position: 1; color: "#ff000000" }
                    }
                }

                Rectangle {
                    x: colorPicker.saturation * parent.width - width / 2
                    y: (1 - colorPicker.value) * parent.height - height / 2
                    width: 14
                    height: 14
                    radius: width / 2
                    color: "transparent"
                    border.color: "#ffffffff"
                    border.width: 2
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => updateColor(mouse)
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            updateColor(mouse)
                        }
                    }

                    function updateColor(mouse) {
                        const fieldPoint = mapToItem(
                            saturationValueField, mouse.x, mouse.y)
                        colorPicker.saturation = Math.max(
                            0, Math.min(1, fieldPoint.x / saturationValueField.width))
                        colorPicker.value = 1 - Math.max(
                            0, Math.min(1, fieldPoint.y / saturationValueField.height))
                    }
                }
            }

            Rectangle {
                id: hueField
                width: parent.width
                height: 20
                radius: 6
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#ffff0000" }
                    GradientStop { position: 0.167; color: "#ffffff00" }
                    GradientStop { position: 0.333; color: "#ff00ff00" }
                    GradientStop { position: 0.5; color: "#ff00ffff" }
                    GradientStop { position: 0.667; color: "#ff0000ff" }
                    GradientStop { position: 0.833; color: "#ffff00ff" }
                    GradientStop { position: 1; color: "#ffff0000" }
                }

                Rectangle {
                    x: colorPicker.hue * (parent.width - width) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 26
                    radius: 4
                    color: "transparent"
                    border.color: "#ffffffff"
                    border.width: 2
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: (mouse) => updateHue(mouse)
                    onPositionChanged: (mouse) => {
                        if (pressed) {
                            updateHue(mouse)
                        }
                    }

                    function updateHue(mouse) {
                        colorPicker.hue = Math.max(0, Math.min(1, mouse.x / width))
                    }
                }
            }

            Row {
                width: parent.width
                height: 36
                spacing: 8

                Rectangle {
                    width: 28
                    height: 28
                    radius: 6
                    color: colorPicker.selectedColor
                    border.color: "#99ffffff"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: parent.width - 176; height: 1 }

                Rectangle {
                    width: 58
                    height: 32
                    radius: 6
                    color: cancelArea.containsMouse ? "#44ffffff" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        color: "#f2ffffff"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: colorDialog.close()
                    }
                }

                Rectangle {
                    width: 58
                    height: 32
                    radius: 6
                    color: acceptArea.containsMouse ? "#6692B38F" : "#4492B38F"

                    Text {
                        anchors.centerIn: parent
                        text: "Apply"
                        color: "#f2ffffff"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: acceptArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            colorPicker.colorAccepted(colorPicker.selectedColor)
                            colorDialog.close()
                        }
                    }
                }
            }
        }
    }
}
