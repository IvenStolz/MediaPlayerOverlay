import QtQuick
import QtQuick.Controls

Rectangle {
    id: settingSelection

    property string title: "Setting"
    property string description: ""
    property var options: []
    property string selectedValue: ""
    readonly property int minimumWidth: 360

    signal selectionChanged(string value)

    width: Math.max(parent ? parent.width : 0, minimumWidth)
    height: Math.max(72, textContainer.height + 24)
    radius: 6
    color: "#22ffffff"

    Item {
        id: textContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 14
        anchors.topMargin: 10
        width: selectionCombo.x - x - 12
        height: settingTitle.implicitHeight + 3 + settingDescription.implicitHeight

        Text {
            id: settingTitle
            width: parent.width
            text: settingSelection.title
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
            text: settingSelection.description
            color: "#f2cccccc"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }

    ComboBox {
        id: selectionCombo
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 150
        model: settingSelection.options
        currentIndex: Math.max(0, model.indexOf(settingSelection.selectedValue))

        onActivated: function(index) {
            settingSelection.selectionChanged(model[index])
        }

        contentItem: Text {
            leftPadding: 10
            rightPadding: 30
            text: selectionCombo.displayText
            color: "#f2ffffff"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Image {
            x: selectionCombo.width - width - 8
            y: selectionCombo.topPadding
               + (selectionCombo.availableHeight - height) / 2
            width: 20
            height: 20
            source: "qrc:/MediaPlayerOverlay/assets/icons/arrow_drop_down.svg"
            sourceSize.width: 24
            sourceSize.height: 24
        }

        background: Rectangle {
            radius: 6
            color: selectionCombo.hovered ? "#4492B38F" : "#2292B38F"
            border.color: "#5592B38F"
            border.width: 1
        }

        delegate: ItemDelegate {
            id: selectionDelegate
            width: selectionCombo.width
            contentItem: Text {
                text: modelData
                color: "#f2ffffff"
                font.pixelSize: 13
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: selectionDelegate.highlighted ? "#6692B38F" : "#ee26332d"
            }
        }

        popup: Popup {
            y: selectionCombo.height + 4
            width: selectionCombo.width
            implicitHeight: contentItem.implicitHeight
            padding: 4

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: selectionCombo.popup.visible ? selectionCombo.delegateModel : null
                currentIndex: selectionCombo.highlightedIndex
            }

            background: Rectangle {
                radius: 6
                color: "#ee26332d"
                border.color: "#5592B38F"
                border.width: 1
            }
        }
    }
}
