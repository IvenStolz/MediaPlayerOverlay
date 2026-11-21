import QtQuick

Rectangle {
    id: settingKeybind

    property string title: "Global shortcut"
    property string description: ""
    property string sequence: ""
    property string error: ""
    property bool recording: false
    readonly property int minimumWidth: 360

    signal sequenceEdited(string sequence)

    width: Math.max(parent ? parent.width : 0, minimumWidth)
    height: Math.max(72, errorText.visible
                     ? errorText.y + errorText.implicitHeight + 8
                     : textContainer.height + 20)
    radius: 6
    color: "#22ffffff"

    Item {
        id: textContainer
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.topMargin: 10
        width: keybindButton.x - x - 12
        height: settingTitle.implicitHeight + 3 + settingDescription.implicitHeight

        Text {
            id: settingTitle
            width: parent.width
            text: settingKeybind.title
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
            text: settingKeybind.description
            color: "#f2cccccc"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }

    Rectangle {
        id: keybindButton
        anchors.right: clearButton.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 136
        height: 34
        radius: 5
        color: recording ? "#44386a48" : "#33222222"
        border.color: recording ? "#bb92B38F" : "#55ffffff"
        border.width: 1
        focus: true
        activeFocusOnTab: true

        Text {
            anchors.fill: parent
            anchors.margins: 5
            text: settingKeybind.recording
                  ? "Press shortcut"
                  : (settingKeybind.sequence || "Not set")
            color: "#f2ffffff"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                keybindButton.forceActiveFocus()
                settingKeybind.recording = true
            }
        }

        Keys.onPressed: function(event) {
            if (!settingKeybind.recording)
                return

            if (event.key === Qt.Key_Escape) {
                settingKeybind.recording = false
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
                settingKeybind.sequenceEdited("")
                settingKeybind.recording = false
                event.accepted = true
                return
            }
            if ([Qt.Key_Control, Qt.Key_Alt, Qt.Key_Shift, Qt.Key_Meta].indexOf(event.key) >= 0) {
                event.accepted = true
                return
            }

            const parts = []
            if (event.modifiers & Qt.ControlModifier) parts.push("Ctrl")
            if (event.modifiers & Qt.AltModifier) parts.push("Alt")
            if (event.modifiers & Qt.ShiftModifier) parts.push("Shift")
            if (event.modifiers & Qt.MetaModifier) parts.push("Meta")

            let keyName = ""
            if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
                keyName = String.fromCharCode(event.key)
            } else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                keyName = String.fromCharCode(event.key)
            } else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F24) {
                keyName = "F" + (event.key - Qt.Key_F1 + 1)
            } else {
                const specialKeys = {}
                specialKeys[Qt.Key_Space] = "Space"
                specialKeys[Qt.Key_Tab] = "Tab"
                specialKeys[Qt.Key_Return] = "Return"
                specialKeys[Qt.Key_Enter] = "Enter"
                specialKeys[Qt.Key_Left] = "Left"
                specialKeys[Qt.Key_Right] = "Right"
                specialKeys[Qt.Key_Up] = "Up"
                specialKeys[Qt.Key_Down] = "Down"
                specialKeys[Qt.Key_Home] = "Home"
                specialKeys[Qt.Key_End] = "End"
                specialKeys[Qt.Key_PageUp] = "PgUp"
                specialKeys[Qt.Key_PageDown] = "PgDown"
                specialKeys[Qt.Key_Insert] = "Ins"
                keyName = specialKeys[event.key] || ""
            }

            if (keyName !== "") {
                parts.push(keyName)
                settingKeybind.sequenceEdited(parts.join("+"))
                settingKeybind.recording = false
            }
            event.accepted = true
        }
    }

    Rectangle {
        id: clearButton
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: keybindButton.verticalCenter
        width: 28
        height: 28
        radius: 4
        color: clearArea.containsMouse ? "#44ffffff" : "transparent"
        visible: settingKeybind.sequence.length > 0

        Text {
            anchors.centerIn: parent
            text: "×"
            color: "#f2ffffff"
            font.pixelSize: 18
        }

        MouseArea {
            id: clearArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: settingKeybind.sequenceEdited("")
        }
    }

    Text {
        id: errorText
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.top: textContainer.bottom
        anchors.topMargin: 4
        width: parent.width - 24
        visible: settingKeybind.error.length > 0
        text: settingKeybind.error
        color: "#ffff7777"
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
}
