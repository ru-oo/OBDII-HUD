// SpeedCenter.qml – Tesla-minimal center speed display
import QtQuick

Item {
    id: root
    property string gear: "D"

    // ── Hero: large digital speed
    Text {
        id: speedNum
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter:   parent.verticalCenter
        anchors.verticalCenterOffset: -20

        text: Math.round(vehicleData.speed)
        font.family: "Segoe UI"
        font.weight: Font.Thin
        font.pixelSize: Math.min(parent.height * 0.58, 200)

        color: vehicleData.speed > 160 ? theme.gaugeDanger
             : vehicleData.speed > 120 ? theme.gaugeWarn
             : theme.textColor

        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // ── km/h label
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: speedNum.bottom
        anchors.topMargin: -6
        text: "km/h"
        color: theme.dimText
        font.family: "Segoe UI"
        font.pixelSize: 14
        font.letterSpacing: 3
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    // ── Gear selector row: P  R  N  D
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        spacing: 24

        Repeater {
            model: ["P", "R", "N", "D"]
            delegate: Text {
                readonly property bool active: root.gear === modelData
                text: modelData
                color: active ? theme.accent : theme.dimText
                font.family: "Segoe UI"
                font.pixelSize: active ? 22 : 14
                font.weight: active ? Font.Medium : Font.Light
                Behavior on color     { ColorAnimation { duration: 200 } }
            }
        }
    }

    // ── Speed limit badge (demo: 60 km/h)
    Item {
        anchors.right: parent.right
        anchors.rightMargin: 24
        anchors.verticalCenter: parent.verticalCenter
        width: 52; height: 52

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "transparent"
            border.color: theme.panelBorder
            border.width: 2
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -5
            text: "60"
            color: theme.dimText
            font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.Medium
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: "km/h"; color: theme.dimText
            font.pixelSize: 7; font.family: "Segoe UI"
        }
    }

    // ── Top: OBD status + ADAS warning icons
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 14
        spacing: 12

        // OBD status
        Row {
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                width: 6; height: 6; radius: 3
                color: vehicleData.connected ? "#4CAF50" : "#607080"
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: vehicleData.connected ? "OBD LIVE" : "SIMULATION"
                color: theme.dimText; font.pixelSize: 9; font.family: "Segoe UI"; font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Coolant warn
        Rectangle {
            width: 26; height: 26; radius: 4
            color: Qt.rgba(theme.gaugeDanger.r, theme.gaugeDanger.g, theme.gaugeDanger.b, 0.15)
            border.color: theme.gaugeDanger; border.width: 1
            visible: vehicleData.coolantTemp > 105
            Text { anchors.centerIn: parent; text: "🌡"; font.pixelSize: 14 }
        }

        // Low fuel
        Rectangle {
            width: 26; height: 26; radius: 4
            color: Qt.rgba(theme.gaugeWarn.r, theme.gaugeWarn.g, theme.gaugeWarn.b, 0.15)
            border.color: vehicleData.fuelLevel < 10 ? theme.gaugeDanger : theme.gaugeWarn
            border.width: 1
            visible: vehicleData.fuelLevel < 20
            Text { anchors.centerIn: parent; text: "⛽"; font.pixelSize: 14 }
        }

        // MIL
        Rectangle {
            width: 26; height: 26; radius: 4
            color: Qt.rgba(theme.gaugeWarn.r, theme.gaugeWarn.g, theme.gaugeWarn.b, 0.15)
            border.color: theme.gaugeWarn; border.width: 1
            visible: vehicleData.milOn
            Text { anchors.centerIn: parent; text: "⚙"; font.pixelSize: 14; color: theme.gaugeWarn }
            SequentialAnimation on opacity {
                running: vehicleData.milOn; loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 600 }
                NumberAnimation { to: 1.0; duration: 600 }
            }
        }
    }

    // ── Vertical dividers
    Rectangle { anchors.left: parent.left;  anchors.top: parent.top; anchors.bottom: parent.bottom; width: 1; color: theme.divider; Behavior on color { ColorAnimation { duration: 300 } } }
    Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 1; color: theme.divider; Behavior on color { ColorAnimation { duration: 300 } } }
}
