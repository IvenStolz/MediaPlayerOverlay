import QtQuick
import QtQuick.Controls
import "components/media_player"
import "components/settings"

Window {
    id: root
    objectName: "overlayWindow"
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    readonly property real cardScale: 0.8
    readonly property int bubblePanelWidth: 52
    readonly property int edgeMargin: 12
    readonly property int peekWindowWidth: 68
    readonly property int peekWindowHeight: 52

    /** Overlay visibility state: "hidden" | "peek" | "expanded". */
    property string overlayState: "hidden"
    property bool isPinned: false
    property bool bubblesExpanded: true
    property int selectedBubbleIndex: 0

    /** Settings interface for edge-trigger behavior. */
    property string dockEdge: "right"
    property int edgeHoldDurationMs: 1000
    property int peekAutoHideMs: 2500
    property int expandedAutoHideMs: 800

    /** Cached geometry of the screen where the edge trigger fired. */
    property int activeScreenX: 0
    property int activeScreenY: 0
    property int activeScreenWidth: Screen.width
    property int activeScreenHeight: Screen.height
    property int triggerCursorY: 200

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

    /** Fades out the unpinned overlay before hiding the native window. */
    SequentialAnimation {
        id: fadeOutAnimation

        NumberAnimation {
            target: root
            property: "opacity"
            to: 0.0
            duration: 180
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
            if (root.overlayState === "peek" && !peekHover.hovered) {
                fadeOutAnimation.start()
            }
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
            selectedIndex: root.selectedBubbleIndex
            onSelectedIndexChanged: root.selectedBubbleIndex = selectedIndex
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

        Text {
            anchors.centerIn: parent
            text: root.dockEdge === "right" ? "‹" : "›"
            color: "#f2ffffff"
            font.pixelSize: 26
            font.bold: true
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