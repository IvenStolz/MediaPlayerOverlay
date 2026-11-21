import QtQuick
import "settings_elements"

Column {
    id: generalSettingsTab

    property string dockEdge: "right"
    property real edgeHoldDurationMs: 500
    property real peekAutoHideMs: 1000
    property real expandedAutoHideMs: 800
    property bool autostartEnabled: false
    property string globalShortcut: ""
    property string globalShortcutError: ""
    readonly property int minimumWidth: 360

    signal dockEdgeEdited(string edge)
    signal edgeHoldDurationEdited(real durationMs)
    signal peekAutoHideEdited(real durationMs)
    signal expandedAutoHideEdited(real durationMs)
    signal autostartEdited(bool enabled)
    signal globalShortcutEdited(string sequence)

    width: Math.max(parent ? parent.width : 0, minimumWidth)
    spacing: 8

    Text {
        text: "General"
        color: "#f2ffffff"
        font.pixelSize: 20
        font.weight: Font.DemiBold
        bottomPadding: 4
    }

    SettingsSelection {
        title: "Dock edge"
        description: "Choose which screen edge reveals the overlay."
        options: ["Right", "Left"]
        selectedValue: generalSettingsTab.dockEdge === "left" ? "Left" : "Right"
        onSelectionChanged: function(value) {
            generalSettingsTab.dockEdgeEdited(value === "Left" ? "left" : "right")
        }
    }

    SettingsSlider {
        title: "Edge hold duration"
        description: "How long the pointer must stay at the edge to reveal the overlay."
        from: 100
        to: 3000
        stepSize: 100
        value: generalSettingsTab.edgeHoldDurationMs
        valueSuffix: " ms"
        onValueEdited: function(value) {
            generalSettingsTab.edgeHoldDurationEdited(value)
        }
    }

    SettingsSlider {
        title: "Peek auto-hide delay"
        description: "How long the edge arrow stays visible before hiding."
        from: 500
        to: 5000
        stepSize: 250
        value: generalSettingsTab.peekAutoHideMs
        valueSuffix: " ms"
        onValueEdited: function(value) {
            generalSettingsTab.peekAutoHideEdited(value)
        }
    }

    SettingsSlider {
        title: "Overlay auto-hide delay"
        description: "How long the expanded overlay stays visible after the pointer leaves."
        from: 200
        to: 5000
        stepSize: 100
        value: generalSettingsTab.expandedAutoHideMs
        valueSuffix: " ms"
        onValueEdited: function(value) {
            generalSettingsTab.expandedAutoHideEdited(value)
        }
    }

    SettingsToggle {
        title: "Start with Windows"
        description: "Automatically start the overlay when you sign in. This setting is not active yet."
        checked: generalSettingsTab.autostartEnabled
        onToggled: function(enabled) {
            generalSettingsTab.autostartEdited(enabled)
        }
    }

    SettingsKeybind {
        title: "Global overlay shortcut"
        description: "Press a key combination to show the overlay. Leave it unset to disable."
        sequence: generalSettingsTab.globalShortcut
        error: generalSettingsTab.globalShortcutError
        onSequenceEdited: function(value) {
            generalSettingsTab.globalShortcutEdited(value)
        }
    }
}
