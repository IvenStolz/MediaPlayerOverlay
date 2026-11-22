import QtQuick
import QtQuick.Controls

Window {
    id: settingsWindow

    property string selectedTab: "General"
    property string dockEdge: "right"
    property real edgeHoldDurationMs: 500
    property real peekAutoHideMs: 1000
    property real expandedAutoHideMs: 800
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
    property real overlayScalePercent: 100
    property bool bubbleColumnCollapsedByDefault: true
    property bool autostartEnabled: false
    property string globalShortcut: ""
    property bool proximityGlowEnabled: true
    property real proximityGlowStrength: 0.85
    property int proximityGlowDistancePx: 140
    property bool fullscreenEnabled: true
    property string fullscreenHoldKey: ""
    property var appRules: []

    function pageForSelectedTab() {
        switch (selectedTab) {
        case "Appearance":
            return appearanceSettingsPage
        case "Playback":
            return playbackSettingsPage
        case "Lyrics":
            return lyricsSettingsPage
        case "About":
            return aboutSettingsPage
        case "Behavior":
            return behaviorSettingsPage
        default:
            return generalSettingsPage
        }
    }

    Component {
        id: generalSettingsPage

        GeneralSettingsTab {
            dockEdge: settingsWindow.dockEdge
            edgeHoldDurationMs: settingsWindow.edgeHoldDurationMs
            peekAutoHideMs: settingsWindow.peekAutoHideMs
            expandedAutoHideMs: settingsWindow.expandedAutoHideMs
            autostartEnabled: settingsWindow.autostartEnabled
            globalShortcut: settingsWindow.globalShortcut
            globalShortcutError: globalShortcutManager.error

            onDockEdgeEdited: function(edge) {
                settingsWindow.dockEdge = edge
            }
            onEdgeHoldDurationEdited: function(durationMs) {
                settingsWindow.edgeHoldDurationMs = durationMs
            }
            onPeekAutoHideEdited: function(durationMs) {
                settingsWindow.peekAutoHideMs = durationMs
            }
            onExpandedAutoHideEdited: function(durationMs) {
                settingsWindow.expandedAutoHideMs = durationMs
            }
            onAutostartEdited: function(enabled) {
                settingsWindow.autostartEnabled = enabled
            }
            onGlobalShortcutEdited: function(sequence) {
                settingsWindow.globalShortcut = sequence
            }
        }
    }

    Component {
        id: behaviorSettingsPage

        BehaviorSettingsTab {
            fullscreenEnabled: settingsWindow.fullscreenEnabled
            fullscreenHoldKey: settingsWindow.fullscreenHoldKey
            appRules: settingsWindow.appRules

            onFullscreenEnabledEdited: function(enabled) { settingsWindow.fullscreenEnabled = enabled }
            onFullscreenHoldKeyEdited: function(key) { settingsWindow.fullscreenHoldKey = key }
            onAppRulesEdited: function(rules) { settingsWindow.appRules = rules }
        }
    }

    Component {
        id: appearanceSettingsPage

        AppearanceSettingsTab {
            appearanceMode: settingsWindow.appearanceMode
            colorTheme: settingsWindow.colorTheme
            useSongAccentColors: settingsWindow.useSongAccentColors
            customColors: settingsWindow.customColors
            useAccentColorsForControls: settingsWindow.useAccentColorsForControls
            customControlColors: settingsWindow.customControlColors
            overlayOpacity: settingsWindow.overlayOpacity
            albumCoverBlur: settingsWindow.albumCoverBlur
            backgroundBrightness: settingsWindow.backgroundBrightness
            backgroundSaturation: settingsWindow.backgroundSaturation
            overlayScalePercent: settingsWindow.overlayScalePercent
            bubbleColumnCollapsedByDefault: settingsWindow.bubbleColumnCollapsedByDefault
            proximityGlowEnabled: settingsWindow.proximityGlowEnabled
            proximityGlowStrength: settingsWindow.proximityGlowStrength
            proximityGlowDistancePx: settingsWindow.proximityGlowDistancePx

            onAppearanceModeChanged: settingsWindow.appearanceMode = appearanceMode
            onColorThemeChanged: settingsWindow.colorTheme = colorTheme
            onUseSongAccentColorsChanged:
                settingsWindow.useSongAccentColors = useSongAccentColors
            onCustomColorsChanged: settingsWindow.customColors = customColors
            onUseAccentColorsForControlsChanged:
                settingsWindow.useAccentColorsForControls = useAccentColorsForControls
            onCustomControlColorsChanged:
                settingsWindow.customControlColors = customControlColors
            onOverlayOpacityChanged: settingsWindow.overlayOpacity = overlayOpacity
            onAlbumCoverBlurChanged: settingsWindow.albumCoverBlur = albumCoverBlur
            onBackgroundBrightnessChanged:
                settingsWindow.backgroundBrightness = backgroundBrightness
            onBackgroundSaturationChanged:
                settingsWindow.backgroundSaturation = backgroundSaturation
            onOverlayScalePercentChanged:
                settingsWindow.overlayScalePercent = overlayScalePercent
            onBubbleColumnCollapsedByDefaultChanged:
                settingsWindow.bubbleColumnCollapsedByDefault = bubbleColumnCollapsedByDefault
            onProximityGlowEnabledChanged:
                settingsWindow.proximityGlowEnabled = proximityGlowEnabled
            onProximityGlowStrengthChanged:
                settingsWindow.proximityGlowStrength = proximityGlowStrength
            onProximityGlowDistancePxChanged:
                settingsWindow.proximityGlowDistancePx = proximityGlowDistancePx
        }
    }

    Component {
        id: playbackSettingsPage

        SettingsPlaceholderTab {
            heading: "Playback"
            description: "Playback behavior and media controls will be configurable here."
        }
    }

    Component {
        id: lyricsSettingsPage

        SettingsPlaceholderTab {
            heading: "Lyrics"
            description: "Lyrics lookup, display, and synchronization options will be available here."
        }
    }

    Component {
        id: aboutSettingsPage

        SettingsPlaceholderTab {
            heading: "About"
            description: "Application information and version details will be shown here."
        }
    }

    title: "Settings"
    objectName: "settingsWindow"
    width: 720
    height: 480
    minimumWidth: 640
    minimumHeight: 360
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint
    visible: false

    Component.onCompleted: windowBlurController.configureSettingsWindow(settingsWindow)

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(function() {
                windowBlurController.applySettingsWindowBlur(settingsWindow)
            })
        }
    }

    Rectangle {
        id: windowBackground
        anchors.fill: parent
        /* color: "#1E92B38F" */
        color: "#1E386345"
        border.color: "#3992B38F"
        border.width: 1
        radius: 8
        clip: true

        Rectangle {
            id: titleBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 42
            color: "#2A92B38F"

            MouseArea {
                anchors.left: parent.left
                anchors.right: windowControls.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                onPressed: settingsWindow.startSystemMove()

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: settingsWindow.title
                    color: "#f2ffffff"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }
            }

            Row {
                id: windowControls
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                z: 1
                spacing: 2
                anchors.margins: 0

                Repeater {
                    model: [
                        { icon: "minimize.svg", action: "minimize" },
                        {
                            icon: settingsWindow.visibility === Window.FullScreen
                                   ? "fullscreen_exit.svg" : "fullscreen.svg",
                            action: "fullscreen"
                        },
                        { icon: "close.svg", action: "close" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        width: 38
                        radius: 4
                        height: titleBar.height
                        color: controlArea.containsMouse
                               ? (modelData.action === "close" ? "#cc3b3b" : "#44ffffff")
                               : "transparent"

                        Image {
                            anchors.centerIn: parent
                            width: 18
                            height: 18
                            source: "qrc:/MediaPlayerOverlay/assets/icons/" + modelData.icon
                            sourceSize.width: 24
                            sourceSize.height: 24
                        }

                        MouseArea {
                            id: controlArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (modelData.action === "minimize") {
                                    settingsWindow.showMinimized()
                                } else if (modelData.action === "fullscreen") {
                                    if (settingsWindow.visibility === Window.FullScreen) {
                                        settingsWindow.showNormal()
                                    } else {
                                        settingsWindow.showFullScreen()
                                    }
                                } else {
                                    settingsWindow.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: settingsContent
            anchors.top: titleBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: settingsBottomBar.top

            SplitView {
                id: settingsSplitView
                anchors.fill: parent
                anchors.margins: 6
                orientation: Qt.Horizontal

                Rectangle {
                    id: settingsSidebar
                    SplitView.preferredWidth: 190
                    SplitView.minimumWidth: 150
                    SplitView.maximumWidth: 280
                    color: "#1E92B38F"
                    radius: 10

                    Column {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 6

                        Repeater {
                            model: ["General", "Behavior", "Appearance", "Playback", "Lyrics", "About"]

                            delegate: Rectangle {
                                required property string modelData
                                width: settingsSidebar.width - 8
                                height: 40
                                radius: 6
                                color: settingsWindow.selectedTab === modelData
                                       ? "#5592B38F"
                                       : (tabMouseArea.containsMouse
                                          ? "#3392B38F" : "#11ffffff")
                                border.color: settingsWindow.selectedTab === modelData
                                              ? "#6692B38F" : "#11ffffff"
                                border.width: 1

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    text: modelData
                                    color: "#f2ffffff"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: tabMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: settingsWindow.selectedTab = modelData
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: settingsOptions
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 360
                    color: "transparent"

                    Rectangle {
                        id: customScrollTrack
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 12
                        width: 8
                        radius: width / 2
                        color: "#1affffff"
                        visible: settingsPageFlickable.contentHeight
                                 > settingsPageFlickable.height + 1

                        MouseArea {
                            anchors.fill: parent
                            onClicked: function(mouse) {
                                const availableTrack = customScrollTrack.height
                                                       - customScrollThumb.height
                                const maxContentY = settingsPageFlickable.contentHeight
                                                    - settingsPageFlickable.height
                                if (availableTrack > 0) {
                                    settingsPageFlickable.contentY = Math.max(
                                        0, Math.min(maxContentY,
                                        (mouse.y - customScrollThumb.height / 2)
                                        / availableTrack * maxContentY))
                                }
                            }
                        }

                            Rectangle {
                                id: customScrollThumb
                            z: 1
                            x: 2
                            width: parent.width - 4
                            height: Math.min(parent.height, Math.max(
                                28, parent.height * parent.height
                                / settingsPageFlickable.contentHeight))
                            y: {
                                const maxContentY = settingsPageFlickable.contentHeight
                                                    - settingsPageFlickable.height
                                return maxContentY > 0
                                       ? settingsPageFlickable.contentY / maxContentY
                                         * (parent.height - height)
                                       : 0
                            }
                            radius: width / 2
                            color: scrollThumbArea.pressed
                                   ? "#bb92B38F"
                                       : (scrollThumbArea.containsMouse
                                          ? "#8892B38F" : "#6692B38F")

                                MouseArea {
                                    id: scrollThumbArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.SizeVerCursor
                                    property real dragOffset: 0

                                    onPressed: function(mouse) {
                                        dragOffset = mouse.y
                                    }

                                    onPositionChanged: function(mouse) {
                                        if (!pressed)
                                            return

                                        const trackPosition = mapToItem(
                                            customScrollTrack, mouse.x, mouse.y).y
                                        const availableTrack = customScrollTrack.height
                                                               - customScrollThumb.height
                                        const maxContentY = settingsPageFlickable.contentHeight
                                                            - settingsPageFlickable.height
                                        if (availableTrack > 0) {
                                            settingsPageFlickable.contentY = Math.max(
                                                0, Math.min(maxContentY,
                                                (trackPosition - dragOffset)
                                                / availableTrack * maxContentY))
                                        }
                                    }
                                }
                            }
                        }

                        Flickable {
                            id: settingsPageFlickable
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 12
                            anchors.topMargin: 12
                            anchors.bottomMargin: 12
                            anchors.right: customScrollTrack.left
                            anchors.rightMargin: 6
                            clip: true
                            contentWidth: width
                            contentHeight: settingsPageLoader.height
                            boundsBehavior: Flickable.StopAtBounds
                            flickableDirection: Flickable.VerticalFlick

                            Loader {
                                id: settingsPageLoader
                                width: settingsPageFlickable.width
                                height: Math.max(settingsPageFlickable.height, implicitHeight)
                                sourceComponent: settingsWindow.pageForSelectedTab()
                            }
                        }
                    }

                handle: Rectangle {
                    implicitWidth: 6
                    color: SplitHandle.pressed
                           ? "#8892B38F"
                           : (SplitHandle.hovered ? "#6692B38F" : "transparent")
                    radius: 3
                }
            }
        }

        SettingsBottomBar {
            id: settingsBottomBar

            onQuitRequested: Qt.quit()
            onDiscardRequested: settingsWindow.close()
            onSaveRequested: settingsWindow.close()
        }
    }

    MouseArea {
        width: 8
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeHorCursor
        onPressed: settingsWindow.startSystemResize(Qt.LeftEdge)
    }

    MouseArea {
        width: 8
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeHorCursor
        onPressed: settingsWindow.startSystemResize(Qt.RightEdge)
    }

    MouseArea {
        height: 8
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        cursorShape: Qt.SizeVerCursor
        onPressed: settingsWindow.startSystemResize(Qt.TopEdge)
    }

    MouseArea {
        height: 8
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        cursorShape: Qt.SizeVerCursor
        onPressed: settingsWindow.startSystemResize(Qt.BottomEdge)
    }

    MouseArea {
        width: 12
        height: 12
        anchors.top: parent.top
        anchors.left: parent.left
        cursorShape: Qt.SizeFDiagCursor
        onPressed: settingsWindow.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
    }

    MouseArea {
        width: 12
        height: 12
        anchors.top: parent.top
        anchors.right: parent.right
        cursorShape: Qt.SizeBDiagCursor
        onPressed: settingsWindow.startSystemResize(Qt.TopEdge | Qt.RightEdge)
    }

    MouseArea {
        width: 12
        height: 12
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        cursorShape: Qt.SizeBDiagCursor
        onPressed: settingsWindow.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
    }

    MouseArea {
        width: 12
        height: 12
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        cursorShape: Qt.SizeFDiagCursor
        onPressed: settingsWindow.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
    }
}
