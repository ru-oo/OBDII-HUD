pragma Singleton
import QtQuick

QtObject {
    id: t

    // Connect this to your C++ ThemeManager if you want to reuse it, 
    // or just toggle it here for the new hud2 UI.
    property string name: "dark" // "dark", "light", "night"

    property color bg: name === "light" ? "#eef1f4" : "#000000"
    property color bgElevated: name === "light" ? "#f6f8fa" : (name === "night" ? "#050000" : "#0b0d10")
    
    // Using string hex for rgba to pass to Canvas easily, or Qt.rgba
    property color card: name === "light" ? Qt.rgba(1,1,1,0.78) : (name === "night" ? Qt.rgba(25/255,12/255,0,0.55) : Qt.rgba(20/255,24/255,30/255,0.62))
    property color cardSolid: name === "light" ? "#ffffff" : (name === "night" ? "#1a0c00" : "#14181e")
    property color cardBorder: name === "light" ? Qt.rgba(15/255,20/255,28/255,0.12) : (name === "night" ? Qt.rgba(1,160/255,0,0.18) : Qt.rgba(1,1,1,0.15))
    property color cardBorderStrong: name === "light" ? Qt.rgba(15/255,20/255,28/255,0.20) : (name === "night" ? Qt.rgba(1,160/255,0,0.28) : Qt.rgba(1,1,1,0.22))
    property color hairline: name === "light" ? Qt.rgba(15/255,20/255,28/255,0.08) : (name === "night" ? Qt.rgba(1,160/255,0,0.12) : Qt.rgba(1,1,1,0.08))

    property color text: name === "light" ? "#0b0f14" : (name === "night" ? "#ffcc80" : "#f5f7fa")
    property color textSecondary: name === "light" ? Qt.rgba(11/255,15/255,20/255,0.75) : (name === "night" ? Qt.rgba(1,204/255,128/255,0.80) : Qt.rgba(245/255,247/255,250/255,0.75))
    property color textTertiary: name === "light" ? Qt.rgba(11/255,15/255,20/255,0.55) : (name === "night" ? Qt.rgba(1,204/255,128/255,0.55) : Qt.rgba(245/255,247/255,250/255,0.55))
    property color textQuaternary: name === "light" ? Qt.rgba(11/255,15/255,20/255,0.40) : (name === "night" ? Qt.rgba(1,204/255,128/255,0.40) : Qt.rgba(245/255,247/255,250/255,0.40))

    property color accent: name === "light" ? "#0a84ff" : (name === "night" ? "#ff9800" : "#22e6ff")
    property color accentSoft: name === "light" ? Qt.rgba(10/255,132/255,1,0.16) : (name === "night" ? Qt.rgba(1,152/255,0,0.20) : Qt.rgba(34/255,230/255,1,0.18))
    
    property color warn: name === "light" ? "#ff9500" : (name === "night" ? "#ffb74d" : "#ffb340")
    property color crit: name === "light" ? "#ff3b30" : (name === "night" ? "#ff5252" : "#ff3b30")
    property color ok: name === "light" ? "#34c759" : (name === "night" ? "#81c784" : "#30d158")

    property color gaugeTrack: name === "light" ? Qt.rgba(15/255,20/255,28/255,0.10) : (name === "night" ? Qt.rgba(1,160/255,0,0.12) : Qt.rgba(1,1,1,0.10))
    property color gaugeFill1: name === "light" ? "#0a84ff" : (name === "night" ? "#ff9800" : "#22e6ff")
    property color gaugeFill2: name === "light" ? "#34c759" : (name === "night" ? "#ffb74d" : "#4cd964")
    property color gaugeFill3: name === "light" ? "#ff9500" : (name === "night" ? "#ffcc80" : "#ffcc00")
    property color gaugeFill4: name === "light" ? "#ff3b30" : (name === "night" ? "#ff5252" : "#ff3b30")
}
