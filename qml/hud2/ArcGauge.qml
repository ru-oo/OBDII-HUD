import QtQuick

Item {
    id: root
    property real size: 720
    width: size
    height: size
    property string _themeTracker: Hud2Theme.name
    on_ThemeTrackerChanged: canvas.requestPaint()

    property real value: 0
    property real min: 0
    property real max: 240
    property int ticks: 13
    property int minorTicksPerMajor: 4
    property var redlineFrom: null
    property string label: ""
    property string unit: ""
    property var primaryDigit: null
    property string subDigit: ""
    property bool warning: false
    property real thickness: 18
    property string strokeMode: "gradient"
    property string centerStyle: "speedo"

    // Animation on value changes
    property real _animValue: value
    Behavior on _animValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    on_AnimValueChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var cx = width / 2;
            var cy = height / 2;
            var size = Math.min(width, height);
            var r = size / 2 - thickness * 1.6;

            var startA = 135 * Math.PI / 180; // -225 deg is 135 in standard +y down
            var endA = 45 * Math.PI / 180;
            var sweep = 270 * Math.PI / 180;

            var pct = Math.max(0, Math.min(1, (_animValue - min) / (max - min)));
            var valA = startA + sweep * pct;

            // Track
            ctx.beginPath();
            ctx.arc(cx, cy, r, startA, endA, false);
            ctx.lineWidth = thickness;
            ctx.lineCap = "round";
            ctx.strokeStyle = Hud2Theme.gaugeTrack;
            ctx.stroke();

            // Redline Track
            if (redlineFrom !== null) {
                var rt = (redlineFrom - min) / (max - min);
                var rA = startA + sweep * rt;
                ctx.beginPath();
                ctx.arc(cx, cy, r - thickness * 0.7 - thickness * 0.1, rA, endA, false);
                ctx.lineWidth = thickness * 0.18;
                ctx.strokeStyle = Hud2Theme.crit;
                ctx.globalAlpha = 0.85;
                ctx.stroke();
                ctx.globalAlpha = 1.0;
            }

            // Ticks
            var totalTicks = (ticks - 1) * minorTicksPerMajor + ticks;
            for (var i = 0; i < totalTicks; i++) {
                var t = i / (totalTicks - 1);
                var a = startA + sweep * t;
                var isMajor = (i % (minorTicksPerMajor + 1)) === 0;
                var tickLen = isMajor ? thickness * 1.4 : thickness * 0.5;
                var r1 = r - thickness * 0.7 - tickLen;
                var r2 = r - thickness * 0.7;
                
                var inRedline = (redlineFrom !== null) && (min + (max - min) * t >= redlineFrom);

                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1);
                ctx.lineTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2);
                ctx.lineWidth = isMajor ? 2 : 1.2;
                ctx.lineCap = "round";
                ctx.strokeStyle = inRedline ? Hud2Theme.crit : (isMajor ? Hud2Theme.textSecondary : Hud2Theme.textQuaternary);
                ctx.globalAlpha = isMajor ? 0.95 : 0.7;
                ctx.stroke();
            }
            ctx.globalAlpha = 1.0;

            // Numeric Labels
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.font = "500 " + (size * 0.038) + "px sans-serif";
            
            for (var j = 0; j < ticks; j++) {
                var tj = j / (ticks - 1);
                var aj = startA + sweep * tj;
                var tx = cx + Math.cos(aj) * (r - thickness * 1.4 - thickness * 1.7);
                var ty = cy + Math.sin(aj) * (r - thickness * 1.4 - thickness * 1.7);
                var v = Math.round(min + (max - min) * tj);
                
                var inRL = (redlineFrom !== null) && (v >= redlineFrom);
                ctx.fillStyle = inRL ? Hud2Theme.crit : Hud2Theme.textSecondary;
                
                var txt = v >= 1000 ? (v/1000).toFixed(v % 1000 === 0 ? 0 : 1) : v.toString();
                ctx.fillText(txt, tx, ty);
            }

            // Inner ring
            ctx.beginPath();
            ctx.arc(cx, cy, r - thickness * 1.7, 0, 2 * Math.PI);
            ctx.lineWidth = 1;
            ctx.strokeStyle = Hud2Theme.hairline;
            ctx.stroke();

            // Active Fill
            ctx.beginPath();
            ctx.arc(cx, cy, r, startA, valA, false);
            ctx.lineWidth = thickness;
            ctx.lineCap = "round";
            
            if (strokeMode === "gradient") {
                var grad = ctx.createLinearGradient(0, height, width, 0);
                grad.addColorStop(0, Hud2Theme.gaugeFill2);
                grad.addColorStop(0.55, Hud2Theme.gaugeFill1);
                grad.addColorStop(0.85, Hud2Theme.gaugeFill3);
                grad.addColorStop(1, Hud2Theme.gaugeFill4);
                ctx.strokeStyle = grad;
            } else {
                ctx.strokeStyle = warning ? Hud2Theme.crit : Hud2Theme.accent;
            }
            ctx.stroke();
            
            // Center texts
            var displayVal = primaryDigit !== null ? primaryDigit : Math.round(_animValue);
            if (centerStyle === "speedo") {
                ctx.fillStyle = Hud2Theme.text;
                ctx.font = "200 " + Math.max(1, size * 0.28) + "px sans-serif";
                ctx.fillText(displayVal, cx, cy - size * 0.02);
                
                if (unit) {
                    ctx.fillStyle = Hud2Theme.textSecondary;
                    ctx.font = "bold " + Math.max(12, size * 0.05) + "px sans-serif";
                    // letterSpacing not easily supported in Canvas, standard fillText used
                    ctx.fillText(unit.toUpperCase(), cx, cy + size * 0.15);
                }
                if (label) {
                    ctx.fillStyle = Hud2Theme.textSecondary;
                    ctx.font = "bold " + Math.max(12, size * 0.045) + "px sans-serif";
                    ctx.fillText(label.toUpperCase(), cx, cy - size * 0.22);
                }
                if (subDigit) {
                    ctx.fillStyle = Hud2Theme.textSecondary;
                    ctx.font = "500 " + Math.max(12, size * 0.05) + "px sans-serif";
                    ctx.fillText(subDigit, cx, cy + size * 0.23);
                }
            } else if (centerStyle === "minimal") {
                ctx.fillStyle = Hud2Theme.text;
                ctx.font = "250 " + Math.max(20, size * 0.18) + "px sans-serif";
                ctx.fillText(displayVal, cx, cy + size * 0.01);
                
                if (label) {
                    ctx.fillStyle = Hud2Theme.textSecondary;
                    ctx.font = "bold " + Math.max(12, size * 0.045) + "px sans-serif";
                    var lbl = label.toUpperCase();
                    if (unit) lbl += " · " + unit.toUpperCase();
                    ctx.fillText(lbl, cx, cy + size * 0.16);
                }
            }
        }
    }
}
