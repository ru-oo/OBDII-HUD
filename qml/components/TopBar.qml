// TopBar.qml – Minimal top status bar
import QtQuick

Item {
    id: root

    // ── Background divider line
    Rectangle {
        anchors.fill: parent
        color: theme.panelBg
        Behavior on color { ColorAnimation { duration: 300 } }

        // Bottom border
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: theme.divider
        }
    }

    // ── Left: Weather info
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            text: weatherData.icon === "clear"  ? "☀"
                : weatherData.icon === "cloud"  ? "☁"
                : weatherData.icon === "rain"   ? "🌧"
                : weatherData.icon === "snow"   ? "❄"
                : "🌤"
            font.pixelSize: 18
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: weatherData.temp.toFixed(0) + "°C"
            color: theme.textColor; font.pixelSize: 13; font.family: "Segoe UI"
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        Text {
            text: weatherData.desc
            color: theme.dimText; font.pixelSize: 11; font.family: "Segoe UI"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Center: Date + OAT
    Row {
        anchors.centerIn: parent
        spacing: 16

        Text {
            text: clock.dateStr
            color: theme.dimText
            font.pixelSize: 11
            font.family: "Segoe UI"
            font.letterSpacing: 0.5
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle { width: 1; height: 14; color: theme.divider; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: "OAT " + vehicleData.ambientTemp.toFixed(0) + "°C"
            color: theme.dimText; font.pixelSize: 11; font.family: "Segoe UI"
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle { width: 1; height: 14; color: theme.divider; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: vehicleData.baroPressure.toFixed(0) + " kPa"
            color: theme.dimText; font.pixelSize: 11; font.family: "Segoe UI"
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Right: Time + theme name
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Text {
            text: theme.themeName
            color: theme.accent; font.pixelSize: 9; font.family: "Segoe UI"; font.letterSpacing: 1.5
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        Rectangle { width: 1; height: 14; color: theme.divider; anchors.verticalCenter: parent.verticalCenter }
        Text {
            text: clock.timeStr
            color: theme.textColor; font.pixelSize: 15; font.family: "Segoe UI"; font.weight: Font.Light
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }
}
