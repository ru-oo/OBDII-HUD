import QtQuick

Item {
    id: root
    width: 140
    height: 240

    property real value: 0
    property int lowThreshold: 15

    property bool _isLow: value <= lowThreshold

    // Animation
    property real _animValue: value
    Behavior on _animValue { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    on_AnimValueChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    property string _themeTracker: Hud2Theme.name
    on_ThemeTrackerChanged: canvas.requestPaint()

    Row {
        anchors.fill: parent
        spacing: 16

        // Canvas for the vertical gauge
        Item {
            width: 88
            height: root.height

            Canvas {
                id: canvas
                anchors.fill: parent
                // The React version has width=60, plus labels on the left at x=-28 to 0.
                // Here we use width 88, gauge at x=28, labels from 0 to 28.

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    var gw = 60; // gauge width
                    var gx = 28; // gauge x offset
                    var pct = Math.max(0, Math.min(100, _animValue)) / 100;
                    var fillH = pct * (height - 8);

                    // Track
                    ctx.beginPath();
                    ctx.roundedRect(gx, 0, gw, height, 14, 14);
                    ctx.fillStyle = Hud2Theme.gaugeTrack;
                    ctx.fill();

                    // Fill
                    ctx.beginPath();
                    ctx.roundedRect(gx + 4, height - 4 - fillH, gw - 8, fillH, 10, 10);
                    
                    if (_isLow) {
                        ctx.fillStyle = Hud2Theme.crit;
                        // Glow
                        ctx.shadowColor = Hud2Theme.crit;
                        ctx.shadowBlur = 18;
                    } else {
                        var grad = ctx.createLinearGradient(0, height, 0, 0);
                        grad.addColorStop(0, Hud2Theme.crit);
                        grad.addColorStop(0.2, Hud2Theme.gaugeFill3);
                        grad.addColorStop(0.5, Hud2Theme.gaugeFill2);
                        grad.addColorStop(1, Hud2Theme.gaugeFill1);
                        ctx.fillStyle = grad;
                        ctx.shadowColor = "transparent";
                        ctx.shadowBlur = 0;
                    }
                    ctx.fill();
                    
                    ctx.shadowBlur = 0;
                    ctx.shadowColor = "transparent";

                    // Marks F, 1/2, E
                    var marks = [
                        { t: 1, l: "F" },
                        { t: 0.5, l: "½" },
                        { t: 0, l: "E" }
                    ];
                    
                    ctx.textAlign = "right";
                    ctx.textBaseline = "middle";
                    ctx.font = "bold 15px sans-serif";
                    
                    for (var i = 0; i < marks.length; i++) {
                        var m = marks[i];
                        // Offset by 14px (radius) so text isn't clipped
                        var my = 14 + (height - 28) * (1 - m.t);
                        
                        // Line
                        ctx.beginPath();
                        ctx.moveTo(gx - 10, my);
                        ctx.lineTo(gx - 2, my);
                        ctx.lineWidth = 1.5;
                        ctx.strokeStyle = Hud2Theme.textSecondary;
                        ctx.stroke();
                        
                        // Text
                        ctx.fillStyle = (m.l === "E" && _isLow) ? Hud2Theme.crit : Hud2Theme.textSecondary;
                        ctx.fillText(m.l, gx - 14, my);
                    }
                }
            }
        }

        // Right side data
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                text: "FUEL"
                color: Hud2Theme.textTertiary
                font.pixelSize: 14
                font.weight: Font.Bold
                font.letterSpacing: 1.6
                font.family: "sans-serif"
            }

            Row {
                Text {
                    text: Math.round(_animValue)
                    color: _isLow ? Hud2Theme.crit : Hud2Theme.text
                    font.pixelSize: 56
                    font.weight: 250
                    font.family: "sans-serif"
                    font.letterSpacing: -1
                }
                Text {
                    text: "%"
                    color: Hud2Theme.textTertiary
                    font.pixelSize: 24
                    font.family: "sans-serif"
                    anchors.baseline: parent.bottom
                    anchors.baselineOffset: -6
                }
            }

            Text {
                text: "⚠ LOW FUEL"
                color: Hud2Theme.crit
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
                visible: _isLow
                // Pulse effect
                SequentialAnimation on opacity {
                    running: _isLow
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 700 }
                    NumberAnimation { to: 1.0; duration: 700 }
                }
            }
        }
    }
}
