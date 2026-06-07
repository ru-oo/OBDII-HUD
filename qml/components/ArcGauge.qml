// ArcGauge.qml – Tesla-minimal thin arc gauge, theme-aware
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real   value      : 0
    property real   minVal     : 0
    property real   maxVal     : 100
    property real   warnVal    : 0
    property real   dangerVal  : 0
    property real   startAngle : 215
    property real   spanAngle  : 250
    property color  arcColor   : theme.accent
    property string label      : ""
    property string digitalText: "0"

    readonly property real _ratio : Math.max(0, Math.min(1, (value - minVal) / Math.max(1, maxVal - minVal)))
    readonly property real _filled: spanAngle * _ratio
    readonly property color _col  : {
        if (dangerVal > 0 && value >= dangerVal) return theme.gaugeDanger
        if (warnVal   > 0 && value >= warnVal)   return theme.gaugeWarn
        return arcColor
    }
    readonly property real _r  : Math.min(width, height) / 2 - 10
    readonly property real _cx : width  / 2
    readonly property real _cy : height / 2

    // ── Track (background arc)
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: theme.gaugeTrack
            strokeWidth: 4
            fillColor  : "transparent"
            capStyle   : ShapePath.RoundCap
            PathAngleArc {
                centerX: root._cx; centerY: root._cy
                radiusX: root._r;  radiusY: root._r
                startAngle: -root.startAngle
                sweepAngle: -root.spanAngle
            }
        }
    }

    // ── Subtle glow (dark themes only)
    Shape {
        anchors.fill: parent
        visible: root._filled > 0.5 && theme.bgColor.hslLightness < 0.4
        ShapePath {
            strokeColor: Qt.rgba(root._col.r, root._col.g, root._col.b, 0.18)
            strokeWidth: 14
            fillColor  : "transparent"
            capStyle   : ShapePath.RoundCap
            PathAngleArc {
                centerX: root._cx; centerY: root._cy
                radiusX: root._r;  radiusY: root._r
                startAngle: -root.startAngle
                sweepAngle: -root._filled
            }
        }
    }

    // ── Fill arc
    Shape {
        anchors.fill: parent
        visible: root._filled > 0.5
        ShapePath {
            strokeColor: root._col
            strokeWidth: 4
            fillColor  : "transparent"
            capStyle   : ShapePath.RoundCap
            PathAngleArc {
                centerX: root._cx; centerY: root._cy
                radiusX: root._r;  radiusY: root._r
                startAngle: -root.startAngle
                sweepAngle: -root._filled
            }
        }
    }

    // ── Tick marks
    Canvas {
        id: ticks
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var count = 10
            for (var i = 0; i <= count; i++) {
                var f   = i / count
                var ang = (root.startAngle - root.spanAngle * f) * Math.PI / 180
                var maj = (i % 2 === 0)
                var len = maj ? 7 : 4
                var ir  = root._r - len - 2
                var or_ = root._r - 2
                ctx.beginPath()
                ctx.lineWidth   = maj ? 1.5 : 1
                ctx.lineCap     = "round"
                var tc = theme.gaugeTrack
                var fc = root._col
                ctx.strokeStyle = f <= root._ratio
                    ? Qt.rgba(fc.r, fc.g, fc.b, 0.7)
                    : Qt.rgba(tc.r, tc.g, tc.b, 0.8)
                ctx.moveTo(root._cx + ir  * Math.cos(ang), root._cy - ir  * Math.sin(ang))
                ctx.lineTo(root._cx + or_ * Math.cos(ang), root._cy - or_ * Math.sin(ang))
                ctx.stroke()
                if (maj) {
                    var val = root.minVal + (root.maxVal - root.minVal) * f
                    var lx  = root._cx + (root._r - 18) * Math.cos(ang)
                    var ly  = root._cy - (root._r - 18) * Math.sin(ang)
                    ctx.fillStyle = Qt.rgba(tc.r, tc.g, tc.b, 0.9)
                    ctx.font = "bold 7px 'Segoe UI'"
                    ctx.textAlign    = "center"
                    ctx.textBaseline = "middle"
                    var display = root.maxVal > 999
                        ? (val / 1000).toFixed(0) + "k"
                        : Math.round(val).toString()
                    ctx.fillText(display, lx, ly)
                }
            }
        }
        Connections {
            target: root
            function onValueChanged() { ticks.requestPaint() }
        }
        Connections {
            target: theme
            function onThemeChanged() { ticks.requestPaint() }
        }
        Component.onCompleted: requestPaint()
    }

    // ── Digital value
    Text {
        id: digitalValue
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter  : parent.verticalCenter
        anchors.verticalCenterOffset: 6
        text : root.digitalText
        color: root._col
        font.family  : "Segoe UI"
        font.weight  : Font.Light
        font.pixelSize: Math.min(root.width, root.height) * 0.20
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: digitalValue.bottom
        anchors.topMargin: -2
        text : root.label
        color: theme.dimText
        font.family    : "Segoe UI"
        font.pixelSize : 9
        font.letterSpacing: 1.5
        Behavior on color { ColorAnimation { duration: 300 } }
    }
}
