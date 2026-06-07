// BackgroundScene.qml — 하늘·도로·날씨 배경
import QtQuick 2.15

Canvas {
    id: root
    property int    hour       : 12
    property string weatherIcon: "clear"
    property real   speedKmh   : 0

    // 도로 파선 오프셋
    property real _offset: 0
    NumberAnimation on _offset {
        from: 0; to: 1
        duration: Math.max(200, 2000 - speedKmh * 7)
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }

    onHourChanged        : requestPaint()
    onWeatherIconChanged : requestPaint()
    on_OffsetChanged     : requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        var w = width, h = height
        var isNight = hour < 6 || hour >= 20

        // ── 하늘
        var skyGrd = ctx.createLinearGradient(0, 0, 0, h * 0.65)
        if (weatherIcon === "fog") {
            skyGrd.addColorStop(0, "#949899"); skyGrd.addColorStop(1, "#B8BBBC")
        } else if (weatherIcon === "rain" || weatherIcon === "thunder") {
            skyGrd.addColorStop(0, "#1A2038"); skyGrd.addColorStop(1, "#333D52")
        } else if (isNight) {
            skyGrd.addColorStop(0, "#03040E"); skyGrd.addColorStop(1, "#070A1A")
        } else if ((hour >= 6 && hour < 8) || (hour >= 18 && hour < 20)) {
            skyGrd.addColorStop(0, "#200D3E"); skyGrd.addColorStop(1, "#CC5A28")
        } else {
            skyGrd.addColorStop(0, "#145AC8"); skyGrd.addColorStop(1, "#7ABAE8")
        }
        ctx.fillStyle = skyGrd
        ctx.fillRect(0, 0, w, h * 0.65)

        // ── 태양 (주간)
        if (!isNight && weatherIcon === "clear") {
            var prog = (hour - 6) / 14.0
            var sx = w * (0.15 + prog * 0.70)
            var sy = h * 0.14
            var sr = 22
            var sunGrd = ctx.createRadialGradient(sx, sy, 0, sx, sy, sr * 2.8)
            sunGrd.addColorStop(0, "rgba(255,230,100,0.25)")
            sunGrd.addColorStop(1, "rgba(255,200,80,0)")
            ctx.fillStyle = sunGrd
            ctx.beginPath(); ctx.arc(sx, sy, sr * 2.8, 0, Math.PI * 2); ctx.fill()
            ctx.fillStyle = hour < 17 ? "#FFE864" : "#FF9F3C"
            ctx.beginPath(); ctx.arc(sx, sy, sr, 0, Math.PI * 2); ctx.fill()
        }

        // ── 달 (야간)
        if (isNight && (weatherIcon === "clear" || weatherIcon === "cloudy")) {
            ctx.fillStyle = "#E8E8D0"
            ctx.beginPath(); ctx.arc(w*0.78, h*0.12, 18, 0, Math.PI*2); ctx.fill()
            // 이지러진 부분
            var bgTop = isNight ? "#03040E" : "#145AC8"
            ctx.fillStyle = bgTop
            ctx.beginPath(); ctx.arc(w*0.78+9, h*0.12-5, 18, 0, Math.PI*2); ctx.fill()
        }

        // ── 별 (야간, 맑음)
        if (isNight && weatherIcon === "clear") {
            var starSeeds = [
                [0.12,0.08],[0.28,0.15],[0.38,0.05],[0.52,0.18],[0.61,0.07],
                [0.70,0.14],[0.18,0.22],[0.44,0.25],[0.55,0.10],[0.82,0.20],
                [0.90,0.06],[0.08,0.30],[0.35,0.28],[0.65,0.30],[0.76,0.08],
            ]
            ctx.fillStyle = "rgba(210,215,255,0.75)"
            for (var si = 0; si < starSeeds.length; si++) {
                var stx = starSeeds[si][0]*w, sty = starSeeds[si][1]*h*0.7
                ctx.beginPath(); ctx.arc(stx, sty, 1.2, 0, Math.PI*2); ctx.fill()
            }
        }

        // ── 구름
        if (weatherIcon === "cloudy" || weatherIcon === "rain" || weatherIcon === "thunder") {
            var cc = weatherIcon === "cloudy" ? "rgba(210,215,220,0.65)" : "rgba(90,100,115,0.80)"
            var cloudPos = [[0.15,0.18,45],[0.38,0.12,58],[0.62,0.20,48],[0.85,0.14,40]]
            for (var ci = 0; ci < cloudPos.length; ci++) {
                var clx = cloudPos[ci][0]*w, cly = cloudPos[ci][1]*h, clr = cloudPos[ci][2]
                ctx.fillStyle = cc
                ctx.beginPath(); ctx.ellipse(clx,      cly, clr,    clr*0.55, 0, 0, Math.PI*2); ctx.fill()
                ctx.beginPath(); ctx.ellipse(clx-clr*0.5,cly,clr*0.7,clr*0.5, 0, 0, Math.PI*2); ctx.fill()
                ctx.beginPath(); ctx.ellipse(clx+clr*0.5,cly,clr*0.7,clr*0.5, 0, 0, Math.PI*2); ctx.fill()
            }
        }

        // ── 지면
        var groundGrd = ctx.createLinearGradient(0, h*0.65, 0, h)
        groundGrd.addColorStop(0, weatherIcon === "fog" ? "#A0A59A" : "#1A1E18")
        groundGrd.addColorStop(1, "#0A0D09")
        ctx.fillStyle = groundGrd
        ctx.fillRect(0, h*0.65, w, h*0.35)

        // ── 도로 원근 사다리꼴
        var vx = w/2, vy = h*0.65
        var rNear = w*0.34, rFar = w*0.028
        ctx.fillStyle = isNight ? "#121318" : "#1A1C22"
        ctx.beginPath()
        ctx.moveTo(vx-rFar, vy); ctx.lineTo(vx+rFar, vy)
        ctx.lineTo(vx+rNear, h); ctx.lineTo(vx-rNear, h)
        ctx.closePath(); ctx.fill()

        // 갓길 선
        ctx.strokeStyle = "rgba(160,155,180,0.35)"; ctx.lineWidth = 1.5
        ctx.beginPath(); ctx.moveTo(vx-rFar,vy); ctx.lineTo(vx-rNear,h); ctx.stroke()
        ctx.beginPath(); ctx.moveTo(vx+rFar,vy); ctx.lineTo(vx+rNear,h); ctx.stroke()

        // 중앙 파선
        for (var di = 0; di < 12; di++) {
            var frac  = ((di / 12.0) + _offset) % 1.0
            var dy    = vy + (h - vy) * frac
            var dw    = Math.max(1, 2 * frac)
            var dh    = Math.max(3, 12 * frac)
            var da    = (1.0 - frac) * 0.80
            ctx.fillStyle = "rgba(140,120,200," + da + ")"
            ctx.fillRect(vx - dw/2, dy, dw, dh)
        }

        // 야간 헤드라이트
        if (isNight) {
            var beamGrd = ctx.createLinearGradient(vx, h*0.75, vx, vy)
            beamGrd.addColorStop(0, "rgba(255,240,180,0.06)")
            beamGrd.addColorStop(1, "rgba(255,240,180,0)")
            ctx.fillStyle = beamGrd
            ctx.beginPath()
            ctx.moveTo(vx-30, h*0.75); ctx.lineTo(vx+30, h*0.75)
            ctx.lineTo(vx+rFar*1.5, vy); ctx.lineTo(vx-rFar*1.5, vy)
            ctx.closePath(); ctx.fill()
        }

        // ── 차량 (후방 시점)
        var cx2 = vx, carY = h*0.72
        var cw = w*0.085, cHt = h*0.12

        // 차체
        ctx.fillStyle = "#C5C8D4"
        ctx.roundRect(cx2-cw/2, carY + cHt*0.35, cw, cHt*0.65, 3)
        ctx.fill()
        // 루프
        ctx.fillStyle = "#B8BBC8"
        ctx.beginPath()
        ctx.moveTo(cx2-cw*0.40, carY+cHt*0.35)
        ctx.lineTo(cx2-cw*0.28, carY)
        ctx.lineTo(cx2+cw*0.28, carY)
        ctx.lineTo(cx2+cw*0.40, carY+cHt*0.35)
        ctx.closePath(); ctx.fill()
        // 유리
        ctx.fillStyle = "rgba(80,110,160,0.60)"
        ctx.roundRect(cx2-cw*0.25, carY+cHt*0.03, cw*0.50, cHt*0.28, 2); ctx.fill()
        // 테일라이트
        ctx.fillStyle = isNight ? "#FF1010" : "#CC1010"
        ctx.fillRect(cx2-cw/2,         carY+cHt*0.55, cw*0.18, cHt*0.15)
        ctx.fillRect(cx2+cw/2-cw*0.18, carY+cHt*0.55, cw*0.18, cHt*0.15)
        // 번호판
        ctx.fillStyle = "#DADBE0"
        ctx.fillRect(cx2-cw*0.18, carY+cHt*0.72, cw*0.36, cHt*0.14)
    }
}
