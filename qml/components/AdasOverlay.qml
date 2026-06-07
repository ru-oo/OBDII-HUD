// AdasOverlay.qml
import QtQuick 2.15
Item {
    anchors.fill: parent
    property real pulse: 0
    SequentialAnimation on pulse {
        loops:Animation.Infinite
        NumberAnimation{to:1;duration:900;easing.type:Easing.InOutSine}
        NumberAnimation{to:0;duration:900;easing.type:Easing.InOutSine}
    }
    readonly property real _a: 0.42 + 0.32*pulse

    Canvas {
        anchors.fill:parent
        property real alpha: parent._a
        onAlphaChanged: requestPaint()
        onPaint:{
            var ctx=getContext("2d"); ctx.clearRect(0,0,width,height)
            var cx=width/2, vy=height*0.47, by=height*0.84
            // 차선 좌
            ctx.beginPath(); ctx.moveTo(cx-width*0.115,by); ctx.lineTo(cx-width*0.020,vy)
            ctx.strokeStyle="rgba(0,230,200,"+alpha+")"; ctx.lineWidth=1.5; ctx.setLineDash([8,6]); ctx.stroke()
            // 차선 우
            ctx.beginPath(); ctx.moveTo(cx+width*0.115,by); ctx.lineTo(cx+width*0.020,vy)
            ctx.strokeStyle="rgba(0,230,200,"+alpha+")"; ctx.lineWidth=1.5; ctx.stroke()
            // 도로면 강조
            ctx.beginPath()
            ctx.moveTo(cx-width*0.115,by); ctx.lineTo(cx+width*0.115,by)
            ctx.lineTo(cx+width*0.020,vy); ctx.lineTo(cx-width*0.020,vy); ctx.closePath()
            ctx.fillStyle="rgba(0,200,220,0.04)"; ctx.fill()
            // 전방 감지 박스 코너
            var bw=width*0.10, bh=height*0.13, bx=cx-bw/2, bby=height*0.34, cs=9
            ctx.strokeStyle="rgba(0,230,200,"+alpha*0.9+")"; ctx.lineWidth=1.2; ctx.setLineDash([])
            var corners=[[bx,bby],[bx+bw-cs,bby],[bx,bby+bh-cs],[bx+bw-cs,bby+bh-cs]]
            for(var i=0;i<corners.length;i++){
                var px=corners[i][0],py=corners[i][1]
                ctx.beginPath(); ctx.moveTo(px,py); ctx.lineTo(px+cs,py); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(px,py); ctx.lineTo(px,py+cs); ctx.stroke()
            }
            // 크로스헤어
            var chx=cx,chy=height*0.472,cs2=13
            ctx.strokeStyle="rgba(0,230,200,"+alpha+")"
            ctx.beginPath(); ctx.moveTo(chx-cs2,chy); ctx.lineTo(chx-5,chy); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(chx+5,chy);   ctx.lineTo(chx+cs2,chy); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(chx,chy-cs2); ctx.lineTo(chx,chy-5); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(chx,chy+5);   ctx.lineTo(chx,chy+cs2); ctx.stroke()
            ctx.beginPath(); ctx.arc(chx,chy,5,0,Math.PI*2); ctx.stroke()
        }
    }
}
