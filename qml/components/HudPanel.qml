import QtQuick

Item {
    id: root
    property real cornerRadius: 14

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: theme.panelBg
        border.color: theme.panelBorder
        border.width: 1
        Behavior on color { ColorAnimation { duration: 300 } }
        Behavior on border.color { ColorAnimation { duration: 300 } }

        // Top highlight line
        Rectangle {
            width: parent.width * 0.5
            height: 1
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(theme.accent.r, theme.accent.g, theme.accent.b, 0.25)
            radius: 1
        }
    }
}
