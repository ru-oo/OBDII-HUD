import QtQuick
import QtQuick.Window
import "hud2"

Window {
    id: root
    width : 1194 // Half of 2388 (iPad Pro 11-inch logical resolution)
    height: 834  // Half of 1668
    visibility: Qt.platform.os === "ios" ? Window.FullScreen : Window.Windowed
    title  : "HMI Cluster – " + theme.themeName
    color  : theme.bgColor

    // ── Fullscreen toggle
    Shortcut { sequence: "F11"; onActivated: root.visibility === Window.FullScreen ? root.showNormal() : root.showFullScreen() }
    Shortcut { sequence: "Escape"; onActivated: root.showNormal() }

    // ── Theme cycle: T key
    Shortcut { sequence: "T"; onActivated: theme.nextTheme() }
    Shortcut { sequence: "Shift+T"; onActivated: theme.prevTheme() }

    // ── OBD port commands (for runtime use from QML console)
    // vehicleData.openUdpPort(35000)

    Hud2App { anchors.fill: parent }

    Component.onCompleted: {
        // Request GPS and other hardware permissions AFTER the UI has loaded
        vehicleData.initHardwarePermissions()
        // Automatically start listening for UDP telemetry
        vehicleData.openUdpPort(35000)
    }
}

