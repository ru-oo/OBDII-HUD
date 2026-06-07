import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Controls
import QtPositioning
import QtLocation

Item {
    id: root
    anchors.fill: parent

    property color bgColor: theme.bgColor
    property color textMain: theme.textColor
    property color dimText: theme.dimText
    property color veryDimText: Qt.rgba(theme.textColor.r, theme.textColor.g, theme.textColor.b, 0.25)
    property color accent: theme.accent
    property color panelBorder: theme.panelBorder
    property string fontMain: "Inter"

    Rectangle {
        anchors.fill: parent
        color: bgColor
    }

    // Top thin status row
    Item {
        id: topRow
        height: 44
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22

            Text {
                id: clockText
                text: Qt.formatTime(new Date(), "hh:mm")
                color: textMain
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: fontMain
                Timer {
                    interval: 1000; running: true; repeat: true
                    onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm")
                }
            }
            Row {
                spacing: 6
                // Weather Glyph
                Canvas {
                    width: 14; height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.strokeStyle = dimText;
                        ctx.lineWidth = 1.4;
                        ctx.beginPath();
                        ctx.arc(5, 6, 2.4, 0, 2*Math.PI);
                        ctx.stroke();
                        ctx.beginPath();
                        ctx.moveTo(4, 10);
                        ctx.lineTo(11, 10);
                        ctx.arc(11, 7.5, 2.5, Math.PI/2, -Math.PI/2, true);
                        ctx.arc(8, 6.5, 3, -Math.PI/4, Math.PI, true);
                        ctx.stroke();
                    }
                }
                Text {
                    text: Math.round(vehicleData.ambientTemp) + "°"
                    color: dimText
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: fontMain
                }
            }
            Text {
                text: {
                    var dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']
                    return dirs[Math.round(vehicleData.heading / 45) % 8]
                }
                color: dimText
                font.pixelSize: 13
                font.weight: Font.Medium
                font.family: fontMain
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22

            Text {
                visible: vehicleData.milOn
                text: "● Service"
                color: "#FFB800"
                font.pixelSize: 13
                font.weight: Font.Medium
                font.family: fontMain
            }
            Text {
                text: "WIFI"
                color: dimText
                font.pixelSize: 13
                font.weight: Font.Medium
                font.family: fontMain
            }
            Row {
                spacing: 6
                // Battery Icon
                Canvas {
                    width: 22; height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.strokeStyle = dimText;
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.roundRect(0.5, 1.5, 18, 9, 1.5);
                        ctx.stroke();
                        
                        ctx.fillStyle = dimText;
                        ctx.fillRect(20, 4, 1.5, 4);
                        ctx.fillRect(2, 3, 15, 6); // 100%
                    }
                }
                Text {
                    text: "100%"
                    color: dimText
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    font.family: fontMain
                }
            }
        }
    }

    // MAIN GRID
    GridLayout {
        anchors.top: topRow.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        columns: 2
        rows: 2
        rowSpacing: 0
        columnSpacing: 0

        // TOP-LEFT: Speed
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: panelBorder }
            Rectangle { anchors.bottom: parent.bottom; height: 1; width: parent.width; color: panelBorder }

            Item {
                anchors.fill: parent
                anchors.leftMargin: 48
                anchors.topMargin: 40
                
                Text {
                    text: "SPEED"
                    color: veryDimText
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    font.weight: Font.Medium
                    font.family: fontMain
                }

                Row {
                    anchors.top: parent.top
                    anchors.topMargin: 28
                    spacing: 12
                    
                    Text {
                        text: Math.round(vehicleData.speed)
                        color: textMain
                        font.pixelSize: 220
                        font.weight: 200
                        font.family: fontMain
                        lineHeight: 0.82
                    }
                    Text {
                        text: "km/h"
                        color: dimText
                        font.pixelSize: 24
                        font.weight: Font.Normal
                        font.family: fontMain
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 40
                    }
                }
                
                Row {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40
                    spacing: 24
                    Text {
                        text: "GPS " + Math.round(vehicleData.speed * 0.98) + " km/h"
                        color: dimText
                        font.pixelSize: 13
                        font.family: fontMain
                    }
                    Text {
                        text: "Limit 80"
                        color: dimText
                        font.pixelSize: 13
                        font.family: fontMain
                    }
                }
            }
        }

        // TOP-RIGHT: Map / G-Force tabs
        Item {
            id: rightTabsPanel
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle { anchors.bottom: parent.bottom; height: 1; width: parent.width; color: panelBorder }

            property string currentTab: "map"

            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 20
                anchors.rightMargin: 24
                spacing: 4
                z: 2
                
                Rectangle {
                    color: Qt.rgba(0,0,0,0.5)
                    border.color: panelBorder
                    border.width: 1
                    radius: 25
                    height: 50
                    width: childrenRect.width + 12
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Rectangle {
                            width: 80; height: 44; radius: 22
                            color: rightTabsPanel.currentTab === "map" ? "#fff" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "Map"
                                color: rightTabsPanel.currentTab === "map" ? "#000" : dimText
                                font.pixelSize: 14; font.weight: Font.Medium; font.family: fontMain
                            }
                            MouseArea { anchors.fill: parent; onClicked: rightTabsPanel.currentTab = "map" }
                        }
                        Rectangle {
                            width: 100; height: 44; radius: 22
                            color: rightTabsPanel.currentTab === "gforce" ? "#fff" : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "G-Force"
                                color: rightTabsPanel.currentTab === "gforce" ? "#000" : dimText
                                font.pixelSize: 14; font.weight: Font.Medium; font.family: fontMain
                            }
                            MouseArea { anchors.fill: parent; onClicked: rightTabsPanel.currentTab = "gforce" }
                        }
                    }
                }
            }

            // Tabs Content
            Item {
                anchors.fill: parent
                visible: rightTabsPanel.currentTab === "map"
                
                Plugin {
                    id: mapPlugin
                    name: "osm"
                }

                Map {
                    id: navMap
                    anchors.fill: parent
                    plugin: mapPlugin
                    center: QtPositioning.coordinate(vehicleData.lat, vehicleData.lon)
                    zoomLevel: 15.5
                    
                    // Vehicle Marker
                    MapQuickItem {
                        coordinate: QtPositioning.coordinate(vehicleData.lat, vehicleData.lon)
                        anchorPoint.x: 20
                        anchorPoint.y: 20
                        sourceItem: Item {
                            width: 40; height: 40
                            Canvas {
                                id: markerCanvas
                                anchors.fill: parent
                                rotation: vehicleData.heading
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0,0,width,height);
                                    
                                    // glow
                                    ctx.fillStyle = Qt.rgba(61/255, 219/255, 255/255, 0.18);
                                    ctx.beginPath(); ctx.arc(20, 20, 14, 0, 2*Math.PI); ctx.fill();
                                    
                                    // dot
                                    ctx.fillStyle = accent;
                                    ctx.beginPath(); ctx.arc(20, 20, 6, 0, 2*Math.PI); ctx.fill();
                                    
                                    // pointer (arrow pointing up)
                                    ctx.beginPath(); ctx.moveTo(20, 8); ctx.lineTo(15, 15); ctx.lineTo(25, 15); ctx.fill();
                                }
                                Connections {
                                    target: vehicleData
                                    function onHeadingChanged() { markerCanvas.requestPaint(); }
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.margins: 24
                    text: vehicleData.lat.toFixed(5) + "°N  " + Math.abs(vehicleData.lon).toFixed(5) + "°W"
                    color: dimText
                    font.pixelSize: 13
                    font.family: fontMain
                }
            }

            Item {
                anchors.fill: parent
                visible: rightTabsPanel.currentTab === "gforce"
                
                Canvas {
                    anchors.centerIn: parent
                    width: 280
                    height: 280
                    onPaint: {
                        var ctx = getContext("2d");
                        var cx = width/2, cy = height/2;
                        
                        // gradient background
                        var grad = ctx.createRadialGradient(cx, cy, 0, cx, cy, cx);
                        grad.addColorStop(0, "#161c28");
                        grad.addColorStop(1, "#0a0d14");
                        ctx.fillStyle = grad;
                        ctx.beginPath(); ctx.arc(cx, cy, cx-4, 0, 2*Math.PI); ctx.fill();
                        
                        ctx.strokeStyle = "rgba(255,255,255,0.12)";
                        ctx.lineWidth = 1;
                        [0.5, 1.0, 1.5].forEach(function(g, i) {
                            ctx.beginPath();
                            if(i !== 1) ctx.setLineDash([3,3]); else ctx.setLineDash([]);
                            ctx.arc(cx, cy, (g/1.5)*(cx-24), 0, 2*Math.PI);
                            ctx.stroke();
                        });
                        ctx.setLineDash([]);
                        
                        ctx.strokeStyle = "rgba(255,255,255,0.18)";
                        ctx.beginPath(); ctx.moveTo(12, cy); ctx.lineTo(width-12, cy); ctx.stroke();
                        ctx.beginPath(); ctx.moveTo(cx, 12); ctx.lineTo(cx, height-12); ctx.stroke();
                        
                        // dot
                        ctx.fillStyle = accent;
                        ctx.beginPath(); ctx.arc(cx, cy, 10, 0, 2*Math.PI); ctx.fill();
                        
                        ctx.fillStyle = "rgba(255,255,255,0.45)";
                        ctx.font = "9px monospace";
                        ctx.textAlign = "center";
                        ctx.fillText("ACCEL", cx, 14);
                        ctx.fillText("BRAKE", cx, height-6);
                        ctx.textAlign = "left";
                        ctx.fillText("L", 10, cy+3);
                        ctx.textAlign = "right";
                        ctx.fillText("R", width-10, cy+3);
                        
                        // Total G text
                        ctx.fillStyle = accent;
                        ctx.font = "bold 14px monospace";
                        ctx.textAlign = "center";
                        ctx.fillText("0.00G", cx, cy - cx + 30);
                    }
                }
            }
        }

        // BOTTOM-LEFT: Engine
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: panelBorder }

            Row {
                anchors.fill: parent
                anchors.margins: 48
                spacing: 32

                // RPM Arc
                Item {
                    width: 200
                    height: parent.height
                    
                    Text {
                        text: "RPM"
                        color: veryDimText
                        font.pixelSize: 11
                        font.letterSpacing: 2
                        font.weight: Font.Medium
                        font.family: fontMain
                    }

                    Item {
                        y: 30
                        width: 200
                        height: 200
                        
                        Shape {
                            anchors.fill: parent
                            rotation: -135
                            
                            ShapePath {
                                strokeColor: Qt.rgba(1, 1, 1, 0.08)
                                strokeWidth: 2
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: 100; centerY: 100
                                    radiusX: 86; radiusY: 86
                                    startAngle: 0; sweepAngle: 270
                                }
                            }
                            
                            ShapePath {
                                strokeColor: accent
                                strokeWidth: 3
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: 100; centerY: 100
                                    radiusX: 86; radiusY: 86
                                    startAngle: 0
                                    sweepAngle: 270 * Math.min(Math.max(vehicleData.rpm / 7000, 0), 1)
                                }
                            }
                        }
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: (vehicleData.rpm / 1000).toFixed(1)
                                color: textMain
                                font.pixelSize: 44
                                font.weight: 200
                                font.family: fontMain
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "×1000 / Gear 1"
                                color: dimText
                                font.pixelSize: 12
                                font.family: fontMain
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // Stats
                Column {
                    width: parent.width - 232
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 24

                    Repeater {
                        model: [
                            { label: "Throttle", value: Math.round(vehicleData.throttle) + "%", pct: vehicleData.throttle, color: accent },
                            { label: "Load", value: Math.round(vehicleData.engineLoad) + "%", pct: vehicleData.engineLoad, color: accent },
                            { label: "Coolant", value: Math.round(vehicleData.coolantTemp) + "°C", pct: (vehicleData.coolantTemp - 60)/60 * 100, color: vehicleData.coolantTemp > 110 ? "#FF5A5A" : accent },
                            { label: "Fuel", value: Math.round(vehicleData.fuelLevel) + "%", pct: vehicleData.fuelLevel, color: vehicleData.fuelLevel < 15 ? "#FFB800" : accent }
                        ]

                        Item {
                            width: parent.width
                            height: 18
                            
                            RowLayout {
                                anchors.top: parent.top
                                width: parent.width
                                Text { Layout.alignment: Qt.AlignLeft; text: modelData.label; color: dimText; font.pixelSize: 13; font.weight: Font.Medium; font.family: fontMain }
                                Item { Layout.fillWidth: true }
                                Text { Layout.alignment: Qt.AlignRight; text: modelData.value; color: "#fff"; font.pixelSize: 13; font.weight: Font.Medium; font.family: fontMain }
                            }
                            
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 2
                                color: Qt.rgba(1,1,1,0.08)
                                radius: 1
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, modelData.pct / 100))
                                    height: parent.height
                                    color: modelData.color
                                    radius: 1
                                    Behavior on width { NumberAnimation { duration: 150 } }
                                }
                            }
                        }
                    }
                }
            }
        }

        // BOTTOM-RIGHT: Trip
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                anchors.fill: parent
                anchors.margins: 48
                columns: 2
                rowSpacing: 32
                columnSpacing: 32

                // Heading
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Column {
                        Text { text: "HEADING"; color: veryDimText; font.pixelSize: 11; font.letterSpacing: 2; font.weight: Font.Medium; font.family: fontMain }
                        Text { text: { var dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW']; return dirs[Math.round(vehicleData.heading / 45) % 8]; } color: textMain; font.pixelSize: 64; font.weight: 200; font.family: fontMain; topPadding: 16 }
                        Text { text: Math.round(vehicleData.heading) + "°"; color: dimText; font.pixelSize: 14; font.family: fontMain; topPadding: 4 }
                    }
                }
                // Altitude
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Column {
                        Text { text: "ALTITUDE"; color: veryDimText; font.pixelSize: 11; font.letterSpacing: 2; font.weight: Font.Medium; font.family: fontMain }
                        Row {
                            topPadding: 16
                            Text { text: Math.round(vehicleData.altM); color: textMain; font.pixelSize: 64; font.weight: 200; font.family: fontMain }
                            Text { text: "m"; color: dimText; font.pixelSize: 22; anchors.baseline: parent.bottom; anchors.baselineOffset: -8; leftPadding: 6 }
                        }
                        Text { text: "↑ " + (Math.round((vehicleData.altM - 38)*10)/10) + "m"; color: dimText; font.pixelSize: 14; font.family: fontMain; topPadding: 4 }
                    }
                }
                // Trip
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Column {
                        Text { text: "TRIP"; color: veryDimText; font.pixelSize: 11; font.letterSpacing: 2; font.weight: Font.Medium; font.family: fontMain }
                        Row {
                            topPadding: 16
                            Text { text: vehicleData.tripKm.toFixed(1); color: textMain; font.pixelSize: 36; font.weight: 300; font.family: fontMain }
                            Text { text: "km"; color: dimText; font.pixelSize: 16; anchors.baseline: parent.bottom; anchors.baselineOffset: -4; leftPadding: 6 }
                        }
                        Text { text: "00:12:34"; color: dimText; font.pixelSize: 13; font.family: fontMain; topPadding: 4 }
                    }
                }
                // Odometer
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Column {
                        Text { text: "ODOMETER"; color: veryDimText; font.pixelSize: 11; font.letterSpacing: 2; font.weight: Font.Medium; font.family: fontMain }
                        Text { text: Math.round(vehicleData.odoKm); color: textMain; font.pixelSize: 36; font.weight: 300; font.family: fontMain; topPadding: 16 }
                        Text { text: "km"; color: dimText; font.pixelSize: 13; font.family: fontMain; topPadding: 4 }
                    }
                }
            }
        }
    }
}
