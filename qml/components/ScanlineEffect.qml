// ScanlineEffect.qml
import QtQuick 2.15
Item {
    anchors.fill:parent
    property real _pos:-60
    NumberAnimation on _pos{from:-60;to:height+60;duration:3400;loops:Animation.Infinite;easing.type:Easing.Linear}
    Rectangle{
        x:0; y:parent._pos-30; width:parent.width; height:60
        gradient:Gradient{
            GradientStop{position:0.0;color:"transparent"}
            GradientStop{position:0.5;color:"#0C00C8DC"}
            GradientStop{position:1.0;color:"transparent"}}}
    Canvas{
        anchors.fill:parent;opacity:0.025
        onPaint:{
            var ctx=getContext("2d");ctx.clearRect(0,0,width,height)
            ctx.strokeStyle="#00C8DC";ctx.lineWidth=0.5
            for(var y=0;y<height;y+=3){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(width,y);ctx.stroke()}}
        Component.onCompleted:requestPaint()}}
