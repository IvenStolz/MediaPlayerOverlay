import QtQuick
import "settings_elements"

Column {
    id: behaviorSettingsTab

    property bool fullscreenEnabled: true
    property string fullscreenHoldKey: ""
    property var appRules: []
    property var runningApps: []
    readonly property int minimumWidth: 360

    signal fullscreenEnabledEdited(bool enabled)
    signal fullscreenHoldKeyEdited(string key)
    signal appRulesEdited(var rules)

    function refreshRunningApps() {
        runningApps = edgeTrigger.getRunningApplications()
    }

    function updateRuleAt(index, updatedRule) {
        const next = appRules.slice()
        next[index] = updatedRule
        appRulesEdited(next)
    }

    function removeRuleAt(index) {
        const next = appRules.slice()
        next.splice(index, 1)
        appRulesEdited(next)
    }

    function addEmptyRule() {
        refreshRunningApps()
        const next = appRules.slice()
        next.push({
            exe: "",
            displayName: "",
            iconUrl: "",
            enabled: false,
            holdKey: ""
        })
        appRulesEdited(next)
    }

    Component.onCompleted: refreshRunningApps()

    width: Math.max(parent ? parent.width : 0, minimumWidth)
    spacing: 8

    Text {
        text: "Behavior"
        color: "#f2ffffff"
        font.pixelSize: 20
        font.weight: Font.DemiBold
        bottomPadding: 4
    }

    SettingsToggle {
        title: "Enable in fullscreen apps"
        description: "Allow the edge trigger while a fullscreen application or game is focused."
        checked: behaviorSettingsTab.fullscreenEnabled
        onToggled: function(enabled) {
            behaviorSettingsTab.fullscreenEnabledEdited(enabled)
        }
    }

    SettingsSelection {
        visible: behaviorSettingsTab.fullscreenEnabled
        title: "Fullscreen hold key"
        description: "Require holding a modifier key to trigger the overlay in fullscreen."
        options: ["None", "Alt", "Ctrl", "Shift"]
        selectedValue: behaviorSettingsTab.fullscreenHoldKey.length > 0
            ? behaviorSettingsTab.fullscreenHoldKey
            : "None"
        onSelectionChanged: function(value) {
            behaviorSettingsTab.fullscreenHoldKeyEdited(value === "None" ? "" : value)
        }
    }

    Text {
        text: "Application rules"
        color: "#f2ffffff"
        font.pixelSize: 16
        font.weight: Font.DemiBold
        topPadding: 8
        bottomPadding: 2
    }

    Repeater {
        model: behaviorSettingsTab.appRules

        delegate: SettingsAppRule {
            required property var modelData
            required property int index

            exe: modelData.exe || ""
            displayName: modelData.displayName || ""
            iconUrl: modelData.iconUrl || ""
            ruleEnabled: modelData.enabled !== undefined ? modelData.enabled : true
            holdKey: modelData.holdKey || ""
            runningApps: behaviorSettingsTab.runningApps

            onDropdownOpened: behaviorSettingsTab.refreshRunningApps()
            onRuleUpdated: function(updatedRule) {
                behaviorSettingsTab.updateRuleAt(index, updatedRule)
            }
            onRemoveRequested: behaviorSettingsTab.removeRuleAt(index)
        }
    }

    SettingsAddButton {
        onClicked: behaviorSettingsTab.addEmptyRule()
    }
}