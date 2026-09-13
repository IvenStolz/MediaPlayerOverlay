import QtQuick

Item {
    id: frameRoot
    anchors.fill: parent
    z: 99

    property int margin: 8

    // --- Corners ---

    MouseArea {
        width: frameRoot.margin; height: frameRoot.margin
        anchors.left: parent.left; anchors.top: parent.top
        cursorShape: Qt.SizeFDiagCursor
        onPressed: root.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
    }

    MouseArea {
        width: frameRoot.margin; height: frameRoot.margin
        anchors.right: parent.right; anchors.top: parent.top
        cursorShape: Qt.SizeBDiagCursor
        onPressed: root.startSystemResize(Qt.TopEdge | Qt.RightEdge)
    }

    MouseArea {
        width: frameRoot.margin; height: frameRoot.margin
        anchors.left: parent.left; anchors.bottom: parent.bottom
        cursorShape: Qt.SizeBDiagCursor
        onPressed: root.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
    }

    MouseArea {
        width: frameRoot.margin; height: frameRoot.margin
        anchors.right: parent.right; anchors.bottom: parent.bottom
        cursorShape: Qt.SizeFDiagCursor
        onPressed: root.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
    }

    // --- Edges ---

    MouseArea {
        height: frameRoot.margin
        anchors.top: parent.top
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: frameRoot.margin; anchors.rightMargin: frameRoot.margin
        cursorShape: Qt.SizeVerCursor
        onPressed: root.startSystemResize(Qt.TopEdge)
    }

    MouseArea {
        height: frameRoot.margin
        anchors.bottom: parent.bottom
        anchors.left: parent.left; anchors.right: parent.right
        anchors.leftMargin: frameRoot.margin; anchors.rightMargin: frameRoot.margin
        cursorShape: Qt.SizeVerCursor
        onPressed: root.startSystemResize(Qt.BottomEdge)
    }

    MouseArea {
        width: frameRoot.margin
        anchors.left: parent.left
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.topMargin: frameRoot.margin; anchors.bottomMargin: frameRoot.margin
        cursorShape: Qt.SizeHorCursor
        onPressed: root.startSystemResize(Qt.LeftEdge)
    }

    MouseArea {
        width: frameRoot.margin
        anchors.right: parent.right
        anchors.top: parent.top; anchors.bottom: parent.bottom
        anchors.topMargin: frameRoot.margin; anchors.bottomMargin: frameRoot.margin
        cursorShape: Qt.SizeHorCursor
        onPressed: root.startSystemResize(Qt.RightEdge)
    }
}