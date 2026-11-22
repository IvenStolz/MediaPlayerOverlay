import QtQuick
import QtQuick.Controls

/**
 * Per-application behavior rule card with app selector, enable toggle, and optional hold key.
 */
Rectangle {
    id: appRuleCard

    property string exe: ""
    property string displayName: ""
    property string iconUrl: ""
    property bool ruleEnabled: true
    property string holdKey: ""
    property var runningApps: []
    property bool recordingKey: false
    readonly property int minimumWidth: 360

    signal ruleUpdated(var updatedRule)
    signal removeRequested()
    signal dropdownOpened()

    /** Merges currently running apps with the saved exe so closed apps remain selectable. */
    readonly property var comboOptions: {
        const list = []
        let foundCurrent = false
        for (let i = 0; i < runningApps.length; ++i) {
            const app = runningApps[i]
            list.push(app)
            if (app.exe.toLowerCase() === exe.toLowerCase()) {
                foundCurrent = true
            }
        }
        if (exe.length > 0 && !foundCurrent) {
            list.unshift({
                exe: exe,
                displayName: displayName.length > 0 ? displayName : exe,
                iconUrl: iconUrl
            })
        }
        return list
    }

    function emitUpdate(changes) {
        ruleUpdated({
            exe: changes.exe !== undefined ? changes.exe : appRuleCard.exe,
            displayName: changes.displayName !== undefined ? changes.displayName : appRuleCard.displayName,
            iconUrl: changes.iconUrl !== undefined ? changes.iconUrl : appRuleCard.iconUrl,
            enabled: changes.enabled !== undefined ? changes.enabled : appRuleCard.ruleEnabled,
            holdKey: changes.holdKey !== undefined ? changes.holdKey : appRuleCard.holdKey
        })
    }

    width: Math.max(parent ? parent.width : 0, minimumWidth)
    height: 92
    radius: 6
    color: "#22ffffff"

    Rectangle {
        id: iconContainer
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 58
        height: 58
        radius: 10
        color: "#2292B38F"
        border.color: "#4492B38F"
        border.width: 1

        Image {
            anchors.centerIn: parent
            width: 36
            height: 36
            source: appRuleCard.iconUrl.length > 0
                ? appRuleCard.iconUrl
                : "qrc:/MediaPlayerOverlay/assets/icons/music_note.svg"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    ComboBox {
        id: appCombo
        anchors.left: iconContainer.right
        anchors.leftMargin: 12
        anchors.right: removeButton.left
        anchors.rightMargin: 8
        anchors.top: parent.top
        anchors.topMargin: 10
        height: 32
        model: appRuleCard.comboOptions
        textRole: "displayName"
        currentIndex: {
            for (let i = 0; i < comboOptions.length; ++i) {
                if (comboOptions[i].exe.toLowerCase() === appRuleCard.exe.toLowerCase()) {
                    return i
                }
            }
            return -1
        }

        onPressedChanged: {
            if (pressed) {
                appRuleCard.dropdownOpened()
            }
        }

        onActivated: function(index) {
            const selected = appRuleCard.comboOptions[index]
            if (selected) {
                appRuleCard.emitUpdate({
                    exe: selected.exe,
                    displayName: selected.displayName,
                    iconUrl: selected.iconUrl
                })
            }
        }

        contentItem: Text {
            leftPadding: 10
            rightPadding: 28
            text: appCombo.currentIndex >= 0
                ? (appRuleCard.comboOptions[appCombo.currentIndex].displayName
                    + " (" + appRuleCard.comboOptions[appCombo.currentIndex].exe + ")")
                : "Select running application..."
            color: appCombo.currentIndex >= 0 ? "#f2ffffff" : "#99ffffff"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Image {
            x: appCombo.width - width - 8
            y: appCombo.topPadding + (appCombo.availableHeight - height) / 2
            width: 20
            height: 20
            source: "qrc:/MediaPlayerOverlay/assets/icons/arrow_drop_down.svg"
            sourceSize.width: 24
            sourceSize.height: 24
        }

        background: Rectangle {
            radius: 6
            color: appCombo.hovered ? "#4492B38F" : "#2292B38F"
            border.color: "#5592B38F"
            border.width: 1
        }

        delegate: ItemDelegate {
            id: appDelegate
            width: appCombo.width
            contentItem: Row {
                spacing: 8
                Image {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    source: modelData.iconUrl.length > 0
                        ? modelData.iconUrl
                        : "qrc:/MediaPlayerOverlay/assets/icons/music_note.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.displayName + " (" + modelData.exe + ")"
                    color: "#f2ffffff"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }
            background: Rectangle {
                color: appDelegate.highlighted ? "#6692B38F" : "#ee26332d"
            }
        }

        popup: Popup {
            y: appCombo.height + 4
            width: appCombo.width
            implicitHeight: Math.min(220, contentItem.implicitHeight)
            padding: 4

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: appCombo.popup.visible ? appCombo.delegateModel : null
                currentIndex: appCombo.highlightedIndex
            }

            background: Rectangle {
                radius: 6
                color: "#ee26332d"
                border.color: "#5592B38F"
                border.width: 1
            }
        }
    }

    Rectangle {
        id: removeButton
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: appCombo.verticalCenter
        width: 28
        height: 28
        radius: 4
        color: removeArea.containsMouse ? "#66cc3b3b" : "transparent"

        Text {
            anchors.centerIn: parent
            text: "×"
            color: "#f2ffffff"
            font.pixelSize: 18
        }

        MouseArea {
            id: removeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: appRuleCard.removeRequested()
        }
    }

    Row {
        anchors.left: iconContainer.right
        anchors.leftMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        spacing: 10

        Rectangle {
            id: toggleTrack
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            height: 24
            radius: height / 2
            color: appRuleCard.ruleEnabled ? "#b392B38F" : "#55777777"
            border.color: appRuleCard.ruleEnabled ? "#aaffffff" : "#77ffffff"
            border.width: 1

            Rectangle {
                x: appRuleCard.ruleEnabled ? parent.width - width - 3 : 3
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                radius: height / 2
                color: "#f2ffffff"

                Behavior on x { NumberAnimation { duration: 140 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: appRuleCard.emitUpdate({ enabled: !appRuleCard.ruleEnabled })
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: appRuleCard.ruleEnabled ? "Enabled" : "Disabled"
            color: "#f2ffffff"
            font.pixelSize: 13
            width: 58
        }

        Rectangle {
            id: holdKeyButton
            anchors.verticalCenter: parent.verticalCenter
            width: 78
            height: 28
            radius: 5
            opacity: appRuleCard.ruleEnabled ? 1.0 : 0.45
            color: appRuleCard.recordingKey ? "#44386a48" : "#33222222"
            border.color: appRuleCard.recordingKey ? "#bb92B38F" : "#55ffffff"
            border.width: 1
            focus: true

            Text {
                anchors.fill: parent
                anchors.margins: 4
                text: appRuleCard.recordingKey
                    ? "Press..."
                    : (appRuleCard.holdKey.length > 0 ? appRuleCard.holdKey : "None")
                color: "#f2ffffff"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                enabled: appRuleCard.ruleEnabled
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    holdKeyButton.forceActiveFocus()
                    appRuleCard.recordingKey = true
                }
            }

            Keys.onPressed: function(event) {
                if (!appRuleCard.recordingKey) return

                if (event.key === Qt.Key_Escape) {
                    appRuleCard.recordingKey = false
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
                    appRuleCard.emitUpdate({ holdKey: "" })
                    appRuleCard.recordingKey = false
                    event.accepted = true
                    return
                }

                let keyName = ""
                if (event.key === Qt.Key_Alt) keyName = "Alt"
                else if (event.key === Qt.Key_Control) keyName = "Ctrl"
                else if (event.key === Qt.Key_Shift) keyName = "Shift"
                else if (event.key === Qt.Key_Meta) keyName = "Meta"
                else if (event.key === Qt.Key_Space) keyName = "Space"
                else if (event.key === Qt.Key_Tab) keyName = "Tab"
                else if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) keyName = String.fromCharCode(event.key)
                else if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) keyName = String.fromCharCode(event.key)
                else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F24) keyName = "F" + (event.key - Qt.Key_F1 + 1)

                if (keyName.length > 0) {
                    appRuleCard.emitUpdate({ holdKey: keyName })
                    appRuleCard.recordingKey = false
                }
                event.accepted = true
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Hold key"
            color: "#f2cccccc"
            font.pixelSize: 12
            opacity: appRuleCard.ruleEnabled ? 1.0 : 0.45
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 26
            height: 26
            radius: 4
            visible: appRuleCard.holdKey.length > 0 && appRuleCard.ruleEnabled
            color: resetKeyArea.containsMouse ? "#44ffffff" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "↶"
                color: "#f2ffffff"
                font.pixelSize: 15
            }

            MouseArea {
                id: resetKeyArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: appRuleCard.emitUpdate({ holdKey: "" })
            }
        }
    }
}