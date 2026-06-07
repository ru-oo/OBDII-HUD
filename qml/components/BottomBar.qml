// BottomBar.qml – Status bar: fuel strip, range, diagnostics, warnings
import QtQuick

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        color: theme.panelBg
        Behavior on color { ColorAnimation { duration: 300 } }

        // Top border
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: theme.divider
        }
    }

    // ── Fuel strip (left third)
    Item {
        id: fuelSection
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.30
        height: 28

        Text {
            id: fuelLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "FUEL"
            color: theme.dimText; font.pixelSize: 9; font.family: "Segoe UI"; font.letterSpacing: 1.5
        }

        // Fuel track
        Rectangle {
            anchors.left: fuelLabel.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 5
            radius: 3
            color: theme.gaugeTrack

            Rectangle {
                width: parent.width * (vehicleData.fuelLevel / 100)
                height: parent.height
                radius: parent.radius
                color: vehicleData.fuelLevel < 10 ? theme.gaugeDanger
                     : vehicleData.fuelLevel < 20 ? theme.gaugeWarn
                     : theme.rightAccent
                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ── Fuel % + range estimate
    Row {
        anchors.left: fuelSection.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            text: Math.round(vehicleData.fuelLevel) + "%"
            color: vehicleData.fuelLevel < 20 ? theme.gaugeWarn : theme.textColor
            font.pixelSize: 15; font.family: "Segoe UI"; font.weight: Font.Light
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Text { text: "·"; color: theme.dimText; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }

        Text {
            // Rough range estimate: 50L tank × fuel% at ~8L/100km
            text: "≈" + Math.round(vehicleData.fuelLevel * 4.5) + " km"
            color: theme.dimText; font.pixelSize: 12; font.family: "Segoe UI"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Center: RPM bar
    Item {
        id: rpmBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * 0.22
        height: 28

        Text {
            id: rpmBarLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "RPM"
            color: theme.dimText; font.pixelSize: 9; font.family: "Segoe UI"; font.letterSpacing: 1.5
        }
        Rectangle {
            anchors.left: rpmBarLabel.right
            anchors.leftMargin: 8
            anchors.right: rpmValText.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 5; radius: 3
            color: theme.gaugeTrack
            Rectangle {
                width: parent.width * Math.min(1, vehicleData.rpm / 8000)
                height: parent.height; radius: parent.radius
                color: vehicleData.rpm > 6000 ? theme.gaugeDanger
                     : vehicleData.rpm > 4500 ? theme.gaugeWarn
                     : theme.leftAccent
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }
        Text {
            id: rpmValText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(vehicleData.rpm / 100) / 10 + "k"
            color: theme.dimText; font.pixelSize: 10; font.family: "Segoe UI"
        }
    }

    // ── Right: Timing / Manifold pressure / Voltage diagnostics
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        // Timing advance
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text { text: "ADV"; color: theme.dimText; font.pixelSize: 8; font.family: "Segoe UI"; font.letterSpacing: 1 }
            Text { text: vehicleData.timingAdv.toFixed(1) + "°"; color: theme.textColor; font.pixelSize: 12; font.family: "Segoe UI"; font.weight: Font.Light }
        }
        Rectangle { width: 1; height: 24; color: theme.divider; anchors.verticalCenter: parent.verticalCenter }

        // Manifold pressure
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text { text: "MAP"; color: theme.dimText; font.pixelSize: 8; font.family: "Segoe UI"; font.letterSpacing: 1 }
            Text { text: vehicleData.manifoldPres.toFixed(0) + " kPa"; color: theme.textColor; font.pixelSize: 12; font.family: "Segoe UI"; font.weight: Font.Light }
        }
        Rectangle { width: 1; height: 24; color: theme.divider; anchors.verticalCenter: parent.verticalCenter }

        // Catalyst temp
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Text { text: "CAT"; color: theme.dimText; font.pixelSize: 8; font.family: "Segoe UI"; font.letterSpacing: 1 }
            Text {
                text: vehicleData.catalystTemp.toFixed(0) + "°C"
                color: vehicleData.catalystTemp > 700 ? theme.gaugeDanger : theme.textColor
                font.pixelSize: 12; font.family: "Segoe UI"; font.weight: Font.Light
            }
        }
        Rectangle { width: 1; height: 24; color: theme.divider; anchors.verticalCenter: parent.verticalCenter }

        // Warning icons (always last)
        WarningIcons { anchors.verticalCenter: parent.verticalCenter }
    }
}
