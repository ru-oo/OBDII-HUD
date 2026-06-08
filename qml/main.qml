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
    // 활성 hud2 스킨의 테마(Hud2Theme.name)를 순환한다. (상단 우측 테마 버튼과 동일 동작)
    Shortcut { sequence: "T"; onActivated: { var ns = ["dark", "light", "night"]; Hud2Theme.name = ns[(ns.indexOf(Hud2Theme.name) + 1) % ns.length] } }
    Shortcut { sequence: "Shift+T"; onActivated: { var ns = ["dark", "light", "night"]; Hud2Theme.name = ns[(ns.indexOf(Hud2Theme.name) + 2) % ns.length] } }

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

