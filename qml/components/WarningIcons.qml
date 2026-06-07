// WarningIcons.qml – Warning indicator lights row
import QtQuick

Row {
    spacing: 8

    // Check engine / MIL
    Rectangle {
        width: 22; height: 22; radius: 4
        color: vehicleData.milOn ? Qt.rgba(1,0.76,0,0.15) : "transparent"
        border.color: vehicleData.milOn ? theme.gaugeWarn : "transparent"
        border.width: 1
        visible: vehicleData.milOn
        Text {
            anchors.centerIn: parent
            text: "⚙"
            font.pixelSize: 12
            color: theme.gaugeWarn
        }
        SequentialAnimation on opacity {
            running: vehicleData.milOn
            loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: 700 }
            NumberAnimation { to: 1.0; duration: 700 }
        }
    }

    // High coolant temp
    Rectangle {
        width: 22; height: 22; radius: 4
        color: vehicleData.coolantTemp > 110 ? Qt.rgba(1,0,0,0.15) : "transparent"
        border.color: vehicleData.coolantTemp > 110 ? theme.gaugeDanger : "transparent"
        border.width: 1
        visible: vehicleData.coolantTemp > 105
        Text {
            anchors.centerIn: parent
            text: "🌡"
            font.pixelSize: 12
        }
    }

    // Low fuel
    Rectangle {
        width: 22; height: 22; radius: 4
        color: vehicleData.fuelLevel < 10 ? Qt.rgba(1,0,0,0.15) : Qt.rgba(1,0.76,0,0.10)
        border.color: vehicleData.fuelLevel < 10 ? theme.gaugeDanger : theme.gaugeWarn
        border.width: 1
        visible: vehicleData.fuelLevel < 20
        Text {
            anchors.centerIn: parent
            text: "⛽"
            font.pixelSize: 12
        }
    }

    // Low battery voltage
    Rectangle {
        width: 22; height: 22; radius: 4
        color: Qt.rgba(1,0.76,0,0.10)
        border.color: theme.gaugeWarn
        border.width: 1
        visible: vehicleData.ctrlVoltage < 12.0
        Text {
            anchors.centerIn: parent
            text: "🔋"
            font.pixelSize: 12
        }
    }

    // OBD connected indicator
    Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter
        Rectangle {
            width: 5; height: 5; radius: 3
            color: vehicleData.connected ? "#4CAF50" : "#F44336"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: vehicleData.connected ? "OBD" : "SIM"
            color: theme.dimText; font.pixelSize: 8; font.family: "Segoe UI"
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
