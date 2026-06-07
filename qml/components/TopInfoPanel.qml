// TopInfoPanel.qml
import QtQuick 2.15
Item {
    id:root; width:218; height:92
    property string gearText   :"D"
    property string timeText   :"--:--"
    property string weatherDesc:"맑음"
    property real   weatherTemp:22

    HudPanel{anchors.fill:parent;cornerRadius:14}
    Text{anchors{top:parent.top;topMargin:10;horizontalCenter:parent.horizontalCenter}
         text:root.gearText;font.family:"Segoe UI";font.weight:Font.Light
         font.pixelSize:28;color:"#DCEBff"}
    Text{anchors{top:parent.top;topMargin:44;horizontalCenter:parent.horizontalCenter}
         text:root.timeText;font.family:"Segoe UI";font.pixelSize:13;color:"#A0B4DC"}
    Text{anchors{bottom:parent.bottom;bottomMargin:10;horizontalCenter:parent.horizontalCenter}
         text:root.weatherDesc+"  "+root.weatherTemp.toFixed(0)+"°C"
         font.family:"Segoe UI";font.pixelSize:10;color:"#8890D0"}
}
