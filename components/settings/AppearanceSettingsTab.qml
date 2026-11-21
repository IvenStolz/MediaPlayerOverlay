import QtQuick
import "settings_elements"

Column {
    id: appearanceSettingsTab

    property string appearanceMode: "Acrylic"
    property string colorTheme: "Album Cover"
    property bool useSongAccentColors: false
    property var customColors: ["#92B38F", "#587A64"]
    property bool useAccentColorsForControls: true
    property var customControlColors: ["#92B38F", "#587A64"]
    property real overlayOpacity: 20
    property real albumCoverBlur: 80
    property real backgroundBrightness: 0
    property real backgroundSaturation: 0

    spacing: 8
    readonly property int minimumWidth: 360
    width: Math.max(parent ? parent.width : 0, minimumWidth)

    Text {
        text: "Appearance"
        color: "#f2ffffff"
        font.pixelSize: 20
        font.weight: Font.DemiBold
        bottomPadding: 4
    }

    SettingsSelection {
        title: "Media Player Transparency"
        description: "Choose the overlay background style."
        options: ["Acrylic", "Transparent", "Opaque"]
        selectedValue: appearanceSettingsTab.appearanceMode
        onSelectionChanged: function(value) {
            appearanceSettingsTab.appearanceMode = value
        }
    }

    SettingsSlider {
        visible: appearanceSettingsTab.appearanceMode === "Acrylic"
                 || appearanceSettingsTab.appearanceMode === "Transparent"
        title: "Overlay opacity"
        description: "Adjust the overlay background opacity."
        from: 0
        to: 100
        value: appearanceSettingsTab.overlayOpacity
        valueSuffix: "%"
        onValueEdited: function(value) {
            appearanceSettingsTab.overlayOpacity = value
        }
    }

    SettingsSelection {
        title: "Media Player Color Theme"
        description: "Choose the overlay color theme."
        options: ["Album Cover", "Single Color", "Gradient"]
        selectedValue: appearanceSettingsTab.colorTheme
        onSelectionChanged: function(value) {
            appearanceSettingsTab.colorTheme = value
        }
    }

    SettingsToggle {
        visible: appearanceSettingsTab.colorTheme === "Single Color"
                 || appearanceSettingsTab.colorTheme === "Gradient"
        title: "Use song accent colors"
        description: "Use colors extracted from the current song artwork."
        checked: appearanceSettingsTab.useSongAccentColors
        onToggled: function(enabled) {
            appearanceSettingsTab.useSongAccentColors = enabled
        }
    }

    SettingsSlider {
        visible: appearanceSettingsTab.colorTheme === "Album Cover"
        title: "Album cover blur"
        description: "Adjust the background blur applied to the album cover."
        from: 0
        to: 100
        value: appearanceSettingsTab.albumCoverBlur
        valueSuffix: "%"
        onValueEdited: function(value) {
            appearanceSettingsTab.albumCoverBlur = value
        }
    }

    SettingsColorPicker {
        visible: (appearanceSettingsTab.colorTheme === "Single Color"
                  || appearanceSettingsTab.colorTheme === "Gradient")
                 && !appearanceSettingsTab.useSongAccentColors
        title: "Custom palette"
        description: appearanceSettingsTab.colorTheme === "Gradient"
                     ? "Choose the two colors used by the gradient."
                     : "Choose the color used by the overlay."
        colors: appearanceSettingsTab.colorTheme === "Gradient"
                ? appearanceSettingsTab.customColors.slice(0, 2)
                : [appearanceSettingsTab.customColors[0]]
        onSelectionChanged: function(selectedColors) {
            const updatedColors = appearanceSettingsTab.customColors.slice()
            for (let i = 0; i < selectedColors.length; ++i)
                updatedColors[i] = selectedColors[i]
            appearanceSettingsTab.customColors = updatedColors
        }
    }

    SettingsSlider {
        title: "Background brightness"
        description: "Brighten or darken the background without changing opacity."
        from: -100
        to: 100
        value: appearanceSettingsTab.backgroundBrightness
        valueSuffix: "%"
        onValueEdited: function(value) {
            appearanceSettingsTab.backgroundBrightness = value
        }
    }

    SettingsSlider {
        title: "Background saturation"
        description: "Reduce or increase the background color intensity."
        from: -100
        to: 100
        value: appearanceSettingsTab.backgroundSaturation
        valueSuffix: "%"
        onValueEdited: function(value) {
            appearanceSettingsTab.backgroundSaturation = value
        }
    }

    SettingsToggle {
        title: "Use song accent colors for controls"
        description: "Use the song colors for the playbar and buttons."
        checked: appearanceSettingsTab.useAccentColorsForControls
        onToggled: function(enabled) {
            appearanceSettingsTab.useAccentColorsForControls = enabled
        }
    }

    SettingsColorPicker {
        visible: !appearanceSettingsTab.useAccentColorsForControls
        title: "Playbar and button colors"
        description: "Choose the two colors for the playbar and button hover."
        colors: appearanceSettingsTab.customControlColors
        onSelectionChanged: function(selectedColors) {
            appearanceSettingsTab.customControlColors = selectedColors
        }
    }
}