import QtQuick

Item {
    id: root
    property string _themeTracker: Hud2Theme.name
    on_ThemeTrackerChanged: { if (root.value !== null) canvas.requestPaint(); }

    property string label: ""
    property var value: null // null if not supported

    Column {
        anchors.fill: parent
        spacing: 6

        Item {
            width: parent.width
            height: 24
            
            Text {
                text: root.label.toUpperCase()
                color: Hud2Theme.textQuaternary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 1.6
                font.family: "sans-serif"
                anchors.left: parent.left
                anchors.bottom: parent.bottom
            }

            Text {
                visible: root.value === null
                text: "NOT EQUIPPED"
                color: Hud2Theme.textTertiary
                font.pixelSize: 13
                font.weight: Font.Bold
                font.letterSpacing: 1.8
                font.family: "sans-serif"
                anchors.right: parent.right
                anchors.bottom: parent.bottom
            }
            
            Row {
                visible: root.value !== null
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 4
                Text {
                    text: root.value !== null ? root.value.toFixed(2) : ""
                    color: Hud2Theme.text
                    font.pixelSize: 24
                    font.weight: 350
                    font.family: "sans-serif"
                    font.letterSpacing: -0.1
                }
                Text {
                    text: "V"
                    color: Hud2Theme.textTertiary
                    font.pixelSize: 13
                    font.family: "sans-serif"
                    anchors.baseline: parent.bottom
                    anchors.baselineOffset: -2
                }
            }
        }

        Rectangle {
            width: parent.width; height: parent.height - 30
            color: Hud2Theme.hairline
            radius: 8
            
            Canvas {
                id: canvas
                anchors.fill: parent
                visible: root.value !== null
                
                property real t: 0
                
                Timer {
                    interval: 33 // ~30fps
                    running: root.value !== null && root.visible
                    repeat: true
                    onTriggered: {
                        canvas.t += 0.033;
                        canvas.requestPaint();
                    }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    // Center line (0.45V = ~55% height since y is inverted)
                    ctx.beginPath();
                    ctx.moveTo(0, height * 0.55);
                    ctx.lineTo(width, height * 0.55);
                    ctx.strokeStyle = Hud2Theme.textQuaternary;
                    ctx.lineWidth = 1;
                    ctx.stroke();

                    // Wave
                    var cur = root.value;
                    if (cur === null) cur = 0.45;
                    ctx.beginPath();
                    for (var x = 0; x <= width; x += 8) {
                        var phase = (x / width) * Math.PI * 6 + t * 4;
                        var wave = Math.sin(phase) * 0.18 + Math.sin(phase * 1.7) * 0.08;
                        var yv = Math.max(0.05, Math.min(0.95, cur + wave));
                        var py = height - yv * height;
                        
                        if (x === 0) ctx.moveTo(x, py);
                        else ctx.lineTo(x, py);
                    }
                    ctx.strokeStyle = Hud2Theme.accent;
                    ctx.lineWidth = 2;
                    ctx.shadowColor = Hud2Theme.accent;
                    ctx.shadowBlur = 6;
                    ctx.stroke();
                    
                    ctx.shadowBlur = 0;
                    ctx.shadowColor = "transparent";
                }
            }
            
            Text {
                visible: root.value === null
                text: "SINGLE-BANK ENGINE"
                color: Hud2Theme.textQuaternary
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 1.8
                font.family: "sans-serif"
                anchors.centerIn: parent
            }
        }
    }
}
