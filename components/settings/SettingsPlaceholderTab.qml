import QtQuick

Column {
    id: settingsPage

    property string heading: ""
    property string description: ""
    readonly property int minimumWidth: 360

    width: Math.max(parent ? parent.width : 0, minimumWidth)
    spacing: 10

    Text {
        text: settingsPage.heading
        color: "#f2ffffff"
        font.pixelSize: 20
        font.weight: Font.DemiBold
    }

    Rectangle {
        width: parent.width
        height: 72
        radius: 6
        color: "#22ffffff"

        Text {
            anchors.fill: parent
            anchors.margins: 12
            text: settingsPage.description
            color: "#bfffffff"
            font.pixelSize: 14
            wrapMode: Text.Wrap
            verticalAlignment: Text.AlignVCenter
        }
    }
}
