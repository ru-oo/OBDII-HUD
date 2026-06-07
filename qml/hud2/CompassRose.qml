import QtQuick

Item {
    id: root
    property real size: 220
    width: size
    height: size
    property string _themeTracker: Hud2Theme.name
    on_ThemeTrackerChanged: canvas.requestPaint()

    property real heading: 0

    // Animation
    property real _animHeading: heading
    // Shortest path rotation
    Behavior on _animHeading { RotationAnimation { duration: 300; direction: RotationAnimation.Shortest } }

    on_AnimHeadingChanged: canvas.requestPaint()
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
            var r = Math.max(0.1, size / 2 - 14);

            // Outer circle
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.lineWidth = 1;
            ctx.strokeStyle = Hud2Theme.cardBorder;
            ctx.stroke();

            ctx.save();
            // Rotate context
            ctx.translate(cx, cy);
            ctx.rotate(-_animHeading * Math.PI / 180);
            ctx.translate(-cx, -cy);

            // Ticks
            ctx.lineWidth = 1;
            ctx.strokeStyle = Hud2Theme.textQuaternary;
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";

            for (var a = 0; a < 360; a += 15) {
                var isCardinal = (a % 90 === 0);
                if (isCardinal) {
                    var l = "";
                    if (a === 0) l = "N";
                    else if (a === 90) l = "E";
                    else if (a === 180) l = "S";
                    else if (a === 270) l = "W";

                    var radC = (a - 90) * Math.PI / 180;
                    var tx = cx + Math.cos(radC) * (r - 24);
                    var ty = cy + Math.sin(radC) * (r - 24);

                    ctx.save();
                    ctx.translate(tx, ty);
                    ctx.fillStyle = (l === "N") ? Hud2Theme.accent : Hud2Theme.textSecondary;
                    ctx.font = ((l === "N") ? "600 " : "500 ") + Math.max(1, size * 0.13) + "px sans-serif";
                    ctx.fillText(l, 0, 0);
                    ctx.restore();

                } else {
                    var len = (a % 30 === 0) ? 8 : 4;
                    var rad = (a - 90) * Math.PI / 180;
                    
                    ctx.beginPath();
                    ctx.moveTo(cx + Math.cos(rad) * r, cy + Math.sin(rad) * r);
                    ctx.lineTo(cx + Math.cos(rad) * (r - len), cy + Math.sin(rad) * (r - len));
                    ctx.stroke();
                }
            }
            ctx.restore(); // restore rotation

            // Fixed pointer
            ctx.beginPath();
            ctx.moveTo(cx, cy - r - 2);
            ctx.lineTo(cx - 8, cy - r + 14);
            ctx.lineTo(cx + 8, cy - r + 14);
            ctx.closePath();
            ctx.fillStyle = Hud2Theme.accent;
            ctx.shadowColor = Hud2Theme.accent;
            ctx.shadowBlur = 10;
            ctx.fill();
            
            ctx.shadowBlur = 0;
            ctx.shadowColor = "transparent";

            // Center dot
            ctx.beginPath();
            ctx.arc(cx, cy, 4, 0, 2 * Math.PI);
            ctx.fillStyle = Hud2Theme.textSecondary;
            ctx.fill();

            // Text Heading
            ctx.fillStyle = Hud2Theme.text;
            ctx.font = "300 " + Math.max(1, size * 0.16) + "px sans-serif";
            var hStr = Math.round(_animHeading).toString();
            while(hStr.length < 3) hStr = "0" + hStr;
            ctx.fillText(hStr + "°", cx, cy + size * 0.2);
        }
    }
}
