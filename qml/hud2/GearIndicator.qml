import QtQuick

Item {
    id: root
    width: 60
    height: 480

    property string gear: "D"

    Column {
        anchors.centerIn: parent
        spacing: 14

        Text {
            text: "GEAR"
            color: Hud2Theme.textQuaternary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 1.6
            font.family: "sans-serif"
            anchors.horizontalCenter: parent.horizontalCenter
            bottomPadding: 4
        }

        Repeater {
            model: ["P", "R", "N", "D", "1", "2", "3", "4", "5", "6"]
            Text {
                property bool active: root.gear === modelData
                
                text: modelData
                color: active ? Hud2Theme.accent : Hud2Theme.textQuaternary
                font.pixelSize: active ? 56 : 22
                font.weight: active ? 300 : 500
                font.family: "sans-serif"
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Shadow glow
                layer.enabled: active
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 2
                    height: parent.height * 1.5
                    radius: width/2
                    color: Hud2Theme.accent
                    opacity: active ? 0.15 : 0
                    z: -1
                    // Quick glow fake
                    transformOrigin: Item.Center
                    scale: active ? 1 : 0.5
                    Behavior on scale { NumberAnimation { duration: 240 } }
                    Behavior on opacity { NumberAnimation { duration: 240 } }
                }

                Behavior on font.pixelSize { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 240 } }
            }
        }
    }
}
