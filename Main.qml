import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import "components/media_player"
import "components/settings"

Window {
    id: root
    objectName: "overlayWindow"
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    readonly property real cardScale: 0.8 * settingsWindow.overlayScalePercent / 100
    readonly property int bubblePanelWidth: 52
    readonly property int edgeMargin: 12
    readonly property int peekWindowWidth: 68
    readonly property int peekWindowHeight: 52

    /** Overlay visibility state: "hidden" | "peek" | "expanded". */
    property string overlayState: "hidden"
    property bool isPinned: false
    property bool bubblesExpanded: !settingsWindow.bubbleColumnCollapsedByDefault
    property int selectedBubbleIndex: 0

    /** Settings interface for edge-trigger behavior. */
    property string dockEdge: settingsWindow.dockEdge
    property int edgeHoldDurationMs: settingsWindow.edgeHoldDurationMs
    property int peekAutoHideMs: settingsWindow.peekAutoHideMs
    property int expandedAutoHideMs: settingsWindow.expandedAutoHideMs

    /** Cached geometry of the screen where the edge trigger fired. */
    property int activeScreenX: 0
    property int activeScreenY: 0
    property int activeScreenWidth: Screen.width
    property int activeScreenHeight: Screen.height
    property int triggerCursorY: 200

    /** Settings interface for edge proximity glow. */
    property bool proximityGlowEnabled: settingsWindow.proximityGlowEnabled
    property real proximityGlowStrength: settingsWindow.proximityGlowStrength
    property int proximityGlowDistancePx: settingsWindow.proximityGlowDistancePx

    /** True while the cursor is over either the media card or the visible bubble window. */
    readonly property bool anyOverlayHovered: expandedHover.hovered
        || (bubbleWindow.visible && bubbleWindowHover.hovered)

    onAnyOverlayHoveredChanged: {
        if (anyOverlayHovered) {
            expandedHideTimer.stop()
            fadeOutAnimation.stop()
            root.opacity = 1.0
        } else if (!root.isPinned && root.overlayState === "expanded") {
            expandedHideTimer.restart()
        }
    }

    readonly property int cardWidthScaled: Math.round(card.width * cardScale)
    readonly property int cardHeightScaled: Math.round(card.height * cardScale)

    visible: overlayState !== "hidden"
    width: overlayState === "expanded" ? cardWidthScaled : peekWindowWidth
    height: overlayState === "expanded" ? cardHeightScaled : peekWindowHeight

    Binding { target: edgeTrigger; property: "edge"; value: root.dockEdge }
    Binding { target: edgeTrigger; property: "holdDurationMs"; value: root.edgeHoldDurationMs }
    Binding { target: edgeTrigger; property: "enabled"; value: root.overlayState === "hidden" }
    Binding {
        target: globalShortcutManager
        property: "sequence"
        value: settingsWindow.globalShortcut
    }
    Binding { target: edgeTrigger; property: "proximityEnabled"; value: root.proximityGlowEnabled }
    Binding { target: edgeTrigger; property: "proximityDistancePx"; value: root.proximityGlowDistancePx }

    function updateWindowPosition() {
        const targetWidth = overlayState === "expanded" ? cardWidthScaled : peekWindowWidth
        const targetHeight = overlayState === "expanded" ? cardHeightScaled : peekWindowHeight

        const targetX = overlayState === "peek"
            ? (dockEdge === "right"
                ? (activeScreenX + activeScreenWidth - targetWidth)
                : activeScreenX)
            : (dockEdge === "right"
                ? (activeScreenX + activeScreenWidth - targetWidth - edgeMargin)
                : (activeScreenX + edgeMargin))

        const minY = activeScreenY + edgeMargin
        const maxY = activeScreenY + activeScreenHeight - targetHeight - edgeMargin
        const targetY = Math.max(minY, Math.min(maxY, Math.round(triggerCursorY - (targetHeight / 2))))

        windowBlurController.setWindowGeometry(root, targetX, targetY, targetWidth, targetHeight)
    }

    function showFromGlobalShortcut() {
        if (overlayState === "hidden" && !edgeTrigger.triggerAtCursor())
            return

        peekHideTimer.stop()
        fadeOutAnimation.stop()
        opacity = 1.0
        overlayState = "expanded"
        raise()
        requestActivate()
    }

    function updateWindowBlur() {
        const shouldBlur = root.overlayState === "expanded"
            && settingsWindow.appearanceMode === "Acrylic"
        windowBlurController.setOverlayWindowBlur(root, shouldBlur)
    }

    /** Keeps the window growing downwards when lyrics open, clamping only at the bottom screen edge. */
    onHeightChanged: {
        if (overlayState === "expanded" && !isPinned) {
            const maxY = activeScreenY + activeScreenHeight - height - edgeMargin
            if (root.y > maxY) {
                root.y = Math.max(activeScreenY + edgeMargin, maxY)
            }
        }
    }

    onOverlayStateChanged: {
        fadeOutAnimation.stop()
        root.opacity = 1.0

        if (overlayState !== "hidden") {
            updateWindowPosition()
        }
        if (overlayState === "peek") {
            peekSlideInAnimation.restart()
        } else if (overlayState === "expanded" && !isPinned && !anyOverlayHovered) {
            expandedHideTimer.restart()
        }
        Qt.callLater(updateWindowBlur)
    }

    onCardScaleChanged: {
        if (overlayState === "expanded")
            Qt.callLater(updateWindowPosition)
    }

    Component.onCompleted: {
        windowBlurController.configureOverlayWindow(root)
    }

    Connections {
        target: edgeTrigger
        function onTriggered(screenX, screenY, screenWidth, screenHeight, cursorY) {
            if (root.overlayState === "hidden") {
                root.activeScreenX = screenX
                root.activeScreenY = screenY
                root.activeScreenWidth = screenWidth
                root.activeScreenHeight = screenHeight
                root.triggerCursorY = cursorY
                root.bubblesExpanded = !settingsWindow.bubbleColumnCollapsedByDefault
                root.overlayState = "peek"
                peekHideTimer.restart()
            }
        }
    }

    Connections {
        target: settingsWindow
        function onAppearanceModeChanged() {
            root.updateWindowBlur()
        }
    }

    Connections {
        target: globalShortcutManager
        function onActivated() {
            root.showFromGlobalShortcut()
        }
    }

    /** Fades out the unpinned overlay before hiding the native window. */
    SequentialAnimation {
        id: fadeOutAnimation

        NumberAnimation {
            target: root
            property: "opacity"
            to: 0.0
            duration: 1000
            easing.type: Easing.InQuad
        }

        ScriptAction {
            script: {
                root.overlayState = "hidden"
                root.opacity = 1.0
            }
        }
    }

    Timer {
        id: peekHideTimer
        interval: root.peekAutoHideMs
        onTriggered: {
            if (root.overlayState !== "peek" || peekHover.hovered)
                return
            if (edgeTrigger.cursorAtEdge) {
                restart()
                return
            }
            fadeOutAnimation.start()
        }
    }

    Timer {
        id: expandedHideTimer
        interval: root.expandedAutoHideMs
        onTriggered: {
            if (root.overlayState === "expanded" && !root.isPinned && !root.anyOverlayHovered) {
                fadeOutAnimation.start()
            }
        }
    }

    SettingsWindow {
        id: settingsWindow
    }

    /** Companion window for the bubble column so the main card window never resizes horizontally. */
    Window {
        id: bubbleWindow
        color: "transparent"
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool

        visible: root.overlayState === "expanded" && (root.bubblesExpanded || bubblePanel.active)
        x: root.x - width
        y: root.y
        width: root.bubblePanelWidth
        height: root.height
        opacity: root.opacity

        Component.onCompleted: windowBlurController.configureOverlayWindow(bubbleWindow)

        HoverHandler { id: bubbleWindowHover }

        SourceBubblePanel {
            id: bubblePanel
            anchors.fill: parent
            expanded: root.bubblesExpanded
            panelWidth: root.bubblePanelWidth
            selectedAppId: mediaManager.currentSessionAppId
            model: mediaManager.activeSessions
            onSessionSelected: (appId) => mediaManager.selectSession(appId)
        }
    }

    /** Full-height, click-through edge window rendering the Y-stretched radial proximity glow. */
    Window {
        id: glowWindow
        transientParent: null
        color: "transparent"
        flags: Qt.FramelessWindowHint
            | Qt.WindowStaysOnTopHint
            | Qt.Tool
            | Qt.WindowTransparentForInput
            | Qt.WindowDoesNotAcceptFocus

        readonly property int stripWidth: 48
        readonly property real targetOpacity: root.proximityGlowEnabled
            && root.overlayState === "hidden"
            ? Math.max(0.0, Math.min(1.0, edgeTrigger.proximity * root.proximityGlowStrength))
            : 0.0

        visible: root.proximityGlowEnabled
            && root.overlayState !== "expanded"
            && (glowVisual.opacity > 0.005 || targetOpacity > 0.0)

        x: root.dockEdge === "right"
            ? (edgeTrigger.screenX + edgeTrigger.screenWidth - stripWidth)
            : edgeTrigger.screenX
        y: edgeTrigger.screenY
        width: stripWidth
        height: Math.max(1, edgeTrigger.screenHeight)

        Component.onCompleted: windowBlurController.configureOverlayWindow(glowWindow)

        Item {
            id: glowVisual
            readonly property real localCursorY: edgeTrigger.cursorY - edgeTrigger.screenY
            readonly property real edgeCenterX: root.dockEdge === "right" ? width : 0

            width: glowWindow.stripWidth
            height: 260
            x: 0
            y: localCursorY - (height / 2)
            opacity: glowWindow.targetOpacity

            Behavior on opacity {
                NumberAnimation {
                    duration: root.overlayState === "peek" ? 260 : 90
                    easing.type: Easing.OutQuad
                }
            }

            /** Outer blue radial glow stretched along the Y-axis. */
            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.smooth: true

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillGradient: RadialGradient {
                        centerX: glowVisual.edgeCenterX
                        centerY: glowVisual.height / 2
                        focalX: glowVisual.edgeCenterX
                        focalY: glowVisual.height / 2
                        centerRadius: glowVisual.width * 1.1
                        GradientStop { position: 0.0; color: "#cc3b9eff" }
                        GradientStop { position: 0.45; color: "#552878ff" }
                        GradientStop { position: 1.0; color: "#002878ff" }
                    }
                    PathRectangle {
                        x: 0
                        y: 0
                        width: glowVisual.width
                        height: glowVisual.height
                    }
                }

                transform: Scale {
                    origin.x: glowVisual.edgeCenterX
                    origin.y: glowVisual.height / 2
                    yScale: 2.6
                }
            }

            /** Smaller white inner core stretched along the Y-axis. */
            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.smooth: true

                ShapePath {
                    strokeWidth: 0
                    strokeColor: "transparent"
                    fillGradient: RadialGradient {
                        centerX: glowVisual.edgeCenterX
                        centerY: glowVisual.height / 2
                        focalX: glowVisual.edgeCenterX
                        focalY: glowVisual.height / 2
                        centerRadius: glowVisual.width * 0.45
                        GradientStop { position: 0.0; color: "#eeffffff" }
                        GradientStop { position: 0.55; color: "#44ffffff" }
                        GradientStop { position: 1.0; color: "#00ffffff" }
                    }
                    PathRectangle {
                        x: 0
                        y: 0
                        width: glowVisual.width
                        height: glowVisual.height
                    }
                }

                transform: Scale {
                    origin.x: glowVisual.edgeCenterX
                    origin.y: glowVisual.height / 2
                    yScale: 2.0
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: Qt.quit()
    }

    DragHandler {
        target: null
        enabled: root.overlayState === "expanded"
        onActiveChanged: {
            if (active) {
                root.isPinned = true
                root.startSystemMove()
            }
        }
    }

    Rectangle {
        id: peekButton
        visible: root.overlayState === "peek"
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 44
        radius: 22
        color: peekHover.hovered ? "#dd2a2a2a" : "#bb181818"
        border.color: "#44ffffff"
        border.width: 1

        readonly property real restingX: root.dockEdge === "right"
            ? (root.peekWindowWidth - width - 10)
            : 10
        readonly property real hiddenX: root.dockEdge === "right"
            ? root.peekWindowWidth
            : -width

        x: restingX

        /** Slides the peek button out from the screen edge with a slight overshoot. */
        ParallelAnimation {
            id: peekSlideInAnimation

            NumberAnimation {
                target: peekButton
                property: "x"
                from: peekButton.hiddenX
                to: peekButton.restingX
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.5
            }

            NumberAnimation {
                target: peekButton
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 160
                easing.type: Easing.OutQuad
            }
        }

        Image {
            anchors.centerIn: parent
            width: 30
            height: 30
            source: "qrc:/MediaPlayerOverlay/assets/icons/chevron_left.svg"
            sourceSize.width: 40
            sourceSize.height: 40
            rotation: root.dockEdge === "right" ? 0 : 180
        }

        HoverHandler {
            id: peekHover
            onHoveredChanged: {
                if (hovered) {
                    peekHideTimer.stop()
                    fadeOutAnimation.stop()
                    root.opacity = 1.0
                } else if (root.overlayState === "peek") {
                    peekHideTimer.restart()
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                peekHideTimer.stop()
                fadeOutAnimation.stop()
                root.opacity = 1.0
                root.overlayState = "expanded"
            }
        }
    }

    Item {
        id: expandedContainer
        visible: root.overlayState === "expanded"
        anchors.fill: parent

        HoverHandler { id: expandedHover }

        MediaPlayerCard {
            id: card
            anchors.top: parent.top
            anchors.left: parent.left
            transformOrigin: Item.TopLeft
            scale: root.cardScale

            trackTitle: mediaManager.title
            trackArtist: mediaManager.artist
            coverUrl: mediaManager.coverURL
            isPlaying: mediaManager.isPlaying
            songDurationMs: mediaManager.songDurationMs
            songPositionMs: mediaManager.songPositionMs
            accentColors: mediaManager.accentColors
            colorTheme: settingsWindow.colorTheme
            useSongAccentColors: settingsWindow.useSongAccentColors
            customColors: settingsWindow.customColors
            useAccentColorsForControls: settingsWindow.useAccentColorsForControls
            customControlColors: settingsWindow.customControlColors
            overlayOpacity: settingsWindow.overlayOpacity
            albumCoverBlur: settingsWindow.albumCoverBlur
            backgroundBrightness: settingsWindow.backgroundBrightness
            backgroundSaturation: settingsWindow.backgroundSaturation
            appearanceMode: settingsWindow.appearanceMode
            overlayHovered: root.anyOverlayHovered
            pinned: root.isPinned

            onPlayPauseClicked: mediaManager.togglePlayPause()
            onNextClicked: mediaManager.next()
            onPreviousClicked: mediaManager.previous()
            onSkipToTime: (ms) => mediaManager.skipToTime(ms)
            onSettingsClicked: settingsWindow.show()
            onCoverClicked: root.bubblesExpanded = !root.bubblesExpanded
            onPinClicked: {
                root.isPinned = !root.isPinned
                if (!root.isPinned && !root.anyOverlayHovered)
                    expandedHideTimer.restart()
            }
        }
    }
}