import QtQuick

Item {
    id: root
    property real size: 280
    width: size
    height: size
    property string _themeTracker: Hud2Theme.name
    on_ThemeTrackerChanged: canvas.requestPaint()

    property real value: 0
    property real min: 0
    property real max: 100
    property string label: ""
    property string unit: ""
    property bool warning: false
    property bool critical: false
    property real thickness: 14
    property bool showZones: false
    property var zones: [0.6, 0.85]
    property int decimals: 0

    // Animation
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
            var r = size / 2 - thickness * 1.4;

            // -210 deg = 150 deg in Canvas (+y down)
            var startA = 150 * Math.PI / 180;
            var endA = 30 * Math.PI / 180;
            var sweep = 240 * Math.PI / 180;

            var pct = Math.max(0, Math.min(1, (_animValue - min) / (max - min)));
            var valA = startA + sweep * pct;

            // Track or Zoned Track
            ctx.lineWidth = thickness;
            if (!showZones) {
                ctx.beginPath();
                ctx.arc(cx, cy, r, startA, endA, false);
                ctx.lineCap = "round";
                ctx.strokeStyle = Hud2Theme.gaugeTrack;
                ctx.stroke();
            } else {
                ctx.lineCap = "butt";
                
                var z1 = startA + sweep * zones[0];
                var z2 = startA + sweep * zones[1];
                
                ctx.beginPath();
                ctx.arc(cx, cy, r, startA, z1, false);
                ctx.strokeStyle = Hud2Theme.gaugeFill2;
                ctx.globalAlpha = 0.18;
                ctx.stroke();
                
                ctx.beginPath();
                ctx.arc(cx, cy, r, z1, z2, false);
                ctx.strokeStyle = Hud2Theme.gaugeFill3;
                ctx.globalAlpha = 0.20;
                ctx.stroke();
                
                ctx.beginPath();
                ctx.arc(cx, cy, r, z2, endA, false);
                ctx.strokeStyle = Hud2Theme.crit;
                ctx.globalAlpha = 0.24;
                ctx.stroke();
                
                ctx.globalAlpha = 1.0;
            }

            // Active Arc
            ctx.beginPath();
            ctx.arc(cx, cy, r, startA, valA, false);
            ctx.lineCap = "round";
            
            if (critical) {
                ctx.strokeStyle = Hud2Theme.crit;
            } else if (warning) {
                ctx.strokeStyle = Hud2Theme.warn;
            } else {
                var grad = ctx.createLinearGradient(0, height, width, 0);
                grad.addColorStop(0, Hud2Theme.gaugeFill2);
                grad.addColorStop(0.6, Hud2Theme.gaugeFill1);
                grad.addColorStop(1, Hud2Theme.gaugeFill3);
                ctx.strokeStyle = grad;
            }
            
            ctx.stroke();

            // Center value
            ctx.fillStyle = critical ? Hud2Theme.crit : Hud2Theme.text;
            ctx.font = "250 " + Math.max(1, size * 0.26) + "px sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            var formatted = _animValue.toFixed(decimals);
            ctx.fillText(formatted, cx, cy - size * 0.02);

            // Unit
            if (unit) {
                ctx.fillStyle = Hud2Theme.textSecondary;
                ctx.font = "500 " + Math.max(12, size * 0.09) + "px sans-serif";
                ctx.fillText(unit, cx, cy + size * 0.15);
            }

            // Label
            if (label) {
                ctx.fillStyle = Hud2Theme.textSecondary;
                ctx.font = "bold " + Math.max(12, size * 0.08) + "px sans-serif";
                ctx.fillText(label.toUpperCase(), cx, cy + size * 0.32);
            }
        }
    }
}
