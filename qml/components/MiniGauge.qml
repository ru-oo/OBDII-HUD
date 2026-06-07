// MiniGauge.qml – Compact labeled progress bar for side panels
import QtQuick

Item {
    id: root
    height: 22

    property string label  : "LABEL"
    property string unit   : "%"
    property real   value  : 0
    property real   minVal : 0
    property real   maxVal : 100
    property color  barColor : theme.accent

    readonly property real _ratio: Math.max(0, Math.min(1, (value - minVal) / Math.max(1, maxVal - minVal)))

    // Label
    Text {
        id: lbl
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: theme.dimText
        font.pixelSize: 8
        font.family: "Segoe UI"
        font.letterSpacing: 1.2
        width: 30
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    // Track
    Rectangle {
        id: track
        anchors.left: lbl.right
        anchors.leftMargin: 6
        anchors.right: valueText.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        height: 3
        radius: 2
        color: theme.gaugeTrack
        Behavior on color { ColorAnimation { duration: 300 } }

        // Fill
        Rectangle {
            width: parent.width * root._ratio
            height: parent.height
            radius: parent.radius
            color: root.barColor
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }

    // Value text
    Text {
        id: valueText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.value.toFixed(root.maxVal < 10 ? 1 : 0) + root.unit
        color: root.barColor
        font.pixelSize: 10
        font.family: "Segoe UI"
        width: 46
        horizontalAlignment: Text.AlignRight
        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
