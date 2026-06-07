// ProgressBar.qml
import QtQuick 2.15
Item {
    id: root; height: 28
    property real   value   : 0
    property string label   : ""
    property string unit    : "%"
    property color  barColor: "#00E6DC"

    Text { id:lbl; anchors{left:parent.left;verticalCenter:parent.verticalCenter}
           text:root.label; font.family:"Segoe UI"; font.pixelSize:10; color:"#506090" }
    Text { anchors{right:parent.right;verticalCenter:parent.verticalCenter}
           text:Math.round(root.value)+root.unit; font.family:"Segoe UI"
           font.pixelSize:10; color:root.barColor }
    Rectangle {
        id:track
        anchors{left:lbl.right;leftMargin:8;right:parent.right;rightMargin:36;verticalCenter:parent.verticalCenter}
        height:5; radius:2; color:"#0A1937"
        Rectangle {
            width:Math.max(0,track.width*root.value/100); height:parent.height; radius:parent.radius
            gradient:Gradient {
                orientation:Gradient.Horizontal
                GradientStop{position:0.0;color:Qt.darker(root.barColor,1.5)}
                GradientStop{position:1.0;color:root.barColor}
            }
            Behavior on width{NumberAnimation{duration:80}}
        }
    }
}
