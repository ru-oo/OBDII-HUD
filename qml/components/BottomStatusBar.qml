// BottomStatusBar.qml
import QtQuick 2.15
Item {
    id:root; height:52
    property real   fuel       :65
    property real   throttle   :0
    property real   weatherTemp:22
    readonly property int fuelKm: Math.round(fuel/100*620)

    HudPanel{anchors.fill:parent;cornerRadius:10}

    Column{anchors{left:parent.left;leftMargin:18;verticalCenter:parent.verticalCenter}spacing:2
        Text{text:"주행가능";font.pixelSize:9;font.family:"Segoe UI";color:"#506090"}
        Text{text:root.fuelKm+" km";font.pixelSize:13;font.family:"Segoe UI";font.weight:Font.Medium;color:"#DCEBff"}}

    Column{anchors.centerIn:parent;spacing:4
        Row{anchors.horizontalCenter:parent.horizontalCenter;spacing:0
            Repeater{model:["0","10","20","30"]
                Text{width:46;text:modelData;font.pixelSize:8;font.family:"Segoe UI";color:"#506090"}}}
        Rectangle{id:trk;width:184;height:5;radius:2;color:"#0A1937";anchors.horizontalCenter:parent.horizontalCenter
            Rectangle{width:Math.max(0,trk.width*root.throttle/100);height:parent.height;radius:parent.radius
                gradient:Gradient{orientation:Gradient.Horizontal
                    GradientStop{position:0.0;color:"#501490"}
                    GradientStop{position:0.5;color:"#A03CDC"}
                    GradientStop{position:1.0;color:"#DC50A0"}}
                Behavior on width{NumberAnimation{duration:100}}}}
        Text{anchors.horizontalCenter:parent.horizontalCenter;text:"12.0 km/L";font.pixelSize:10;font.family:"Segoe UI";color:"#B48CDC"}}

    Column{anchors{right:parent.right;rightMargin:18;verticalCenter:parent.verticalCenter}spacing:2
        Text{text:"ODO";font.pixelSize:9;font.family:"Segoe UI";color:"#506090"}
        Text{text:"15000 km";font.pixelSize:13;font.family:"Segoe UI";font.weight:Font.Medium;color:"#DCEBff"}}
}
