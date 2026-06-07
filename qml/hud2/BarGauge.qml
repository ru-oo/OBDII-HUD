import QtQuick

Item {
    id: root
    width: 400
    height: 40

    property real value: 0
    property real min: 0
    property real max: 100
    property bool centerZero: false
    property string label: ""
    property string unit: ""
    property bool showTrack: true
    property bool warning: false
    property bool critical: false
    property real thickness: height * 0.42
    property int decimals: 0

    // Animation
    property real _animValue: value
    Behavior on _animValue { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    on_AnimValueChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    property string _themeTracker: Hud2Theme.name
    on_ThemeTrackerChanged: canvas.requestPaint()

    // Header label
    Item {
        id: header
        width: parent.width
        height: root.label !== "" ? 28 : 0
        visible: root.label !== ""

        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: root.label.toUpperCase()
            color: Hud2Theme.textTertiary
            font.pixelSize: 14
            font.weight: Font.Bold
            font.letterSpacing: 1.6
            font.family: "sans-serif"
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 4

            Text {
                text: _animValue.toFixed(root.decimals)
                color: root.critical ? Hud2Theme.crit : (root.warning ? Hud2Theme.warn : Hud2Theme.text)
                font.pixelSize: 28
                font.weight: 350
                font.family: "sans-serif"
            }
            Text {
                text: root.unit
                color: Hud2Theme.textTertiary
                font.pixelSize: 16
                font.family: "sans-serif"
                anchors.baseline: parent.bottom
                anchors.baselineOffset: -4
                visible: root.unit !== ""
            }
        }
    }

    Canvas {
        id: canvas
        anchors.top: header.bottom
        anchors.topMargin: root.label !== "" ? 8 : 0
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.thickness + 6 // some padding for centerZero line

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var t = root.thickness;
            var trackY = (height - t) / 2;

            var leftPct, fillW;
            if (centerZero) {
                var half = (max - min) / 2;
                var center = min + half;
                var v = Math.max(min, Math.min(max, _animValue));
                if (v >= center) {
                    leftPct = 0.5;
                    fillW = ((v - center) / half) * width / 2;
                } else {
                    leftPct = (1 - (center - v) / half) * 0.5;
                    fillW = width / 2 - leftPct * width;
                }
            } else {
                leftPct = 0;
                fillW = ((Math.max(min, Math.min(max, _animValue)) - min) / (max - min)) * width;
            }
            var fillX = leftPct * width;

            // Track
            if (showTrack) {
                ctx.beginPath();
                ctx.roundedRect(0, trackY, width, t, t/2, t/2);
                ctx.fillStyle = Hud2Theme.gaugeTrack;
                ctx.fill();
            }

            // Center line
            if (centerZero) {
                ctx.beginPath();
                ctx.moveTo(width/2, trackY - 3);
                ctx.lineTo(width/2, trackY + t + 3);
                ctx.lineWidth = 1;
                ctx.strokeStyle = Hud2Theme.textQuaternary;
                ctx.stroke();
            }

            // Fill
            if (fillW > 0) {
                ctx.beginPath();
                ctx.roundedRect(fillX, trackY, fillW, t, t/2, t/2);
                
                if (critical) {
                    ctx.fillStyle = Hud2Theme.crit;
                } else if (warning) {
                    ctx.fillStyle = Hud2Theme.warn;
                } else {
                    var grad = ctx.createLinearGradient(0, 0, width, 0);
                    grad.addColorStop(0, Hud2Theme.gaugeFill2);
                    grad.addColorStop(0.6, Hud2Theme.gaugeFill1);
                    grad.addColorStop(1, Hud2Theme.gaugeFill3);
                    ctx.fillStyle = grad;
                }
                ctx.fill();
            }
        }
    }
}
