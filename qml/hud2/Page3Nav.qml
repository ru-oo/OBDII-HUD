import QtQuick
import QtPositioning
import QtLocation
import QtQuick.Layouts

Item {
    id: root
    width: 2388
    height: 1668

    component P3Card: Rectangle {
        color: Hud2Theme.card
        border.color: Hud2Theme.cardBorder
        border.width: 1.5
        radius: 16
        implicitWidth: 0
        implicitHeight: 0
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: 80
        anchors.bottomMargin: 150
        anchors.leftMargin: 40
        anchors.rightMargin: 40

        Item {
            anchors.fill: parent

            // LEFT: MAP AREA
            P3Card {
                id: mapCard
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: rightCol.left
                anchors.rightMargin: 30
                clip: true

                Plugin {
                    id: mapPlugin
                    name: "osm"
                    PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: "true" }
                    PluginParameter { name: "osm.mapping.highdpi_tiles"; value: "true" }
                }

                Map {
                    id: navMap
                    anchors.fill: parent
                    plugin: mapPlugin
                    zoomLevel: 15.5
                    
                    property bool followMode: true
                    
                    Connections {
                        target: vehicleData
                        function onGpsChanged() {
                            if (navMap.followMode) {
                                navMap.center = QtPositioning.coordinate(vehicleData.lat, vehicleData.lon)
                            }
                        }
                    }

                    PinchHandler {
                        id: pinch
                        target: null
                        onActiveChanged: {
                            if (active) navMap.followMode = false
                        }
                        onScaleChanged: (delta) => {
                            navMap.zoomLevel += Math.log2(delta)
                        }
                        onTranslationChanged: (delta) => {
                            navMap.pan(-delta.x, -delta.y)
                        }
                    }

                    DragHandler {
                        id: drag
                        target: null
                        onActiveChanged: {
                            if (active) navMap.followMode = false
                        }
                        onTranslationChanged: (delta) => {
                            navMap.pan(-delta.x, -delta.y)
                        }
                    }

                    MapQuickItem {
                        coordinate: QtPositioning.coordinate(vehicleData.lat, vehicleData.lon)
                        anchorPoint.x: 30
                        anchorPoint.y: 30
                        sourceItem: Item {
                            width: 60; height: 60
                            Canvas {
                                id: mapCanvas
                                anchors.fill: parent
                                rotation: vehicleData.heading
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0,0,width,height);
                                    
                                    ctx.fillStyle = Hud2Theme.accentSoft;
                                    ctx.beginPath(); ctx.arc(30, 30, 28, 0, 2*Math.PI); ctx.fill();
                                    
                                    ctx.fillStyle = Hud2Theme.accent;
                                    ctx.globalAlpha = 0.5;
                                    ctx.beginPath(); ctx.arc(30, 30, 16, 0, 2*Math.PI); ctx.fill();
                                    ctx.globalAlpha = 1.0;
                                    
                                    ctx.beginPath();
                                    ctx.moveTo(30, 10);
                                    ctx.lineTo(20, 36);
                                    ctx.lineTo(40, 36);
                                    ctx.closePath();
                                    ctx.fillStyle = Hud2Theme.accent;
                                    ctx.fill();
                                }
                                Connections {
                                    target: vehicleData
                                    function onHeadingChanged() { mapCanvas.requestPaint(); }
                                }
                            }
                        }
                    }
                }

                // Map Floating Controls
                Column {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 20
                    spacing: 16
                    z: 10

                    // Recenter Button
                    Rectangle {
                        width: 52; height: 52; radius: 26
                        color: navMap.followMode ? Hud2Theme.accent : Qt.rgba(0,0,0,0.65)
                        border.color: Hud2Theme.cardBorder
                        border.width: 1.5
                        opacity: navMap.followMode ? 0.0 : 1.0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        
                        Text { anchors.centerIn: parent; text: "📍"; font.pixelSize: 22 }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                navMap.followMode = true
                                navMap.center = QtPositioning.coordinate(vehicleData.lat, vehicleData.lon)
                            }
                        }
                    }

                    // Zoom In
                    Rectangle {
                        width: 52; height: 52; radius: 26
                        color: Qt.rgba(0,0,0,0.65)
                        border.color: Hud2Theme.cardBorder
                        border.width: 1.5
                        Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 32; font.weight: Font.Medium; anchors.verticalCenterOffset: -2 }
                        MouseArea { 
                            anchors.fill: parent
                            onClicked: {
                                navMap.followMode = false
                                navMap.zoomLevel += 0.8
                            }
                        }
                    }
                    
                    // Zoom Out
                    Rectangle {
                        width: 52; height: 52; radius: 26
                        color: Qt.rgba(0,0,0,0.65)
                        border.color: Hud2Theme.cardBorder
                        border.width: 1.5
                        Text { anchors.centerIn: parent; text: "−"; color: "white"; font.pixelSize: 32; font.weight: Font.Medium; anchors.verticalCenterOffset: -2 }
                        MouseArea { 
                            anchors.fill: parent
                            onClicked: {
                                navMap.followMode = false
                                navMap.zoomLevel -= 0.8
                            }
                        }
                    }
                }

                Rectangle {
                    x: 24; y: 24
                    width: coordsCol.width + 36; height: coordsCol.height + 28
                    radius: 14
                    color: Qt.rgba(0,0,0,0.45)
                    border.color: Hud2Theme.cardBorder
                    Column {
                        id: coordsCol
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "SPEED OVER GROUND"; color: Qt.rgba(1,1,1,0.55); font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.6; font.family: "sans-serif" }
                        Text { 
                            text: Math.round(vehicleData.speed) + " km/h"
                            color: "#ffffff"
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            font.family: "sans-serif"
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    anchors.margins: 24
                    height: 90
                    radius: 18
                    color: Qt.rgba(0,0,0,0.55)
                    border.color: Hud2Theme.cardBorderStrong

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 24

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Row {
                                spacing: 10
                                Text { text: "CURRENT LOCATION"; color: Qt.rgba(1,1,1,0.55); font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 2; font.family: "sans-serif" }
                            }
                            Text {
                                text: vehicleData.lat.toFixed(5) + "° N · " + vehicleData.lon.toFixed(5) + "° E"
                                color: "#fff"
                                font.pixelSize: 22
                                font.weight: Font.Medium
                                font.letterSpacing: 0.5
                                font.family: "sans-serif"
                            }
                        }

                        Column {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2
                            Text { anchors.right: parent.right; text: "HEADING"; color: Qt.rgba(1,1,1,0.5); font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 1.4; font.family: "sans-serif" }
                            Text {
                                anchors.right: parent.right
                                text: { var dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]; return dirs[Math.round(vehicleData.heading / 45) % 8] + " · " + Math.round(vehicleData.heading) + "°" }
                                color: "#fff"
                                font.pixelSize: 26
                                font.weight: 300
                                font.letterSpacing: -0.3
                                font.family: "sans-serif"
                            }
                        }
                    }
                }
            }

            // RIGHT COLUMN
            ColumnLayout {
                id: rightCol
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * 0.28
                spacing: 24

                // Compass & Alt
                P3Card {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.height * 0.20
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 24
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 100
                            Layout.fillHeight: true
                            CompassRose {
                                anchors.centerIn: parent
                                heading: vehicleData.heading
                                size: Math.max(50, Math.min(parent.width*0.8, parent.height))
                            }
                        }
                        Column {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 100
                            spacing: 16
                            Column {
                                spacing: 4
                                Text { text: "HEADING"; color: Hud2Theme.textQuaternary; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.6; font.family: "sans-serif" }
                                Text { text: { var dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]; return dirs[Math.round(vehicleData.heading / 45) % 8]; } color: Hud2Theme.text; font.pixelSize: 26; font.weight: 300; font.family: "sans-serif" }
                                Text { text: Math.round(vehicleData.heading) + "°"; color: Hud2Theme.textTertiary; font.pixelSize: 13; font.weight: Font.Medium; font.family: "sans-serif" }
                            }
                            Column {
                                spacing: 4
                                Text { text: "ALTITUDE"; color: Hud2Theme.textQuaternary; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.6; font.family: "sans-serif" }
                                Row {
                                    spacing: 6
                                    Text { text: Math.round(vehicleData.altM); color: Hud2Theme.text; font.pixelSize: 26; font.weight: 300; font.family: "sans-serif" }
                                    Text { text: "m"; color: Hud2Theme.textTertiary; font.pixelSize: 14; anchors.baseline: parent.bottom; font.family: "sans-serif" }
                                }
                            }
                        }
                    }
                }

                // TPMS (Responsive car shape)
                Item {
                    id: tpmsWrapper
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.height * 0.38

                    // TPMS는 아직 실제 데이터 소스가 없다(README 알려진 한계 참고).
                    // 값이 모두 0이면 미연동으로 보고 상시 빨간 경보가 뜨지 않게 가드한다.
                    property bool tpmsAvailable: (vehicleData.tpmsFl > 0) || (vehicleData.tpmsFr > 0) || (vehicleData.tpmsRl > 0) || (vehicleData.tpmsRr > 0)
                    property bool hasLowTire: tpmsAvailable && ((vehicleData.tpmsFl < 28) || (vehicleData.tpmsFr < 28) || (vehicleData.tpmsRl < 28) || (vehicleData.tpmsRr < 28))

                    // Pulsing Red Glow
                    Rectangle {
                        anchors.fill: tpmsCard
                        anchors.margins: -16
                        radius: 36
                        color: Hud2Theme.crit
                        visible: tpmsWrapper.hasLowTire
                        SequentialAnimation on opacity {
                            running: tpmsWrapper.hasLowTire
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.05; duration: 800; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                        }
                    }

                    P3Card {
                        id: tpmsCard
                        anchors.fill: parent
                        border.color: tpmsWrapper.hasLowTire ? Hud2Theme.crit : Hud2Theme.cardBorder
                        border.width: tpmsWrapper.hasLowTire ? 3 : 1.5

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            opacity: tpmsWrapper.tpmsAvailable ? 1.0 : 0.4
                        Text { text: tpmsWrapper.tpmsAvailable ? "TIRE PRESSURE · TPMS" : "TIRE PRESSURE · TPMS · N/A"; color: Hud2Theme.textTertiary; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 1.4; font.family: "sans-serif" }
                        
                        Item {
                            width: parent.width
                            height: parent.height - 30
                            
                            // Car Image (User will provide 'images/car_outline.png')
                            Image {
                                id: carCanvas
                                anchors.centerIn: parent
                                width: parent.width * 0.45
                                height: parent.height * 0.8
                                source: "qrc:/qt/qml/HudProject/images/car_outline.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                antialiasing: true
                            }
                            
                            // Fl
                            Column { anchors.right: carCanvas.left; anchors.rightMargin: 10; anchors.top: carCanvas.top; anchors.topMargin: carCanvas.height*0.1; Text { text: tpmsWrapper.tpmsAvailable ? vehicleData.tpmsFl.toFixed(1) : "—"; color: !tpmsWrapper.tpmsAvailable ? Hud2Theme.textTertiary : ((vehicleData.tpmsFl < 28) ? Hud2Theme.crit : Hud2Theme.ok); font.pixelSize: 22; font.weight: 300; font.family: "sans-serif" } Text { text: !tpmsWrapper.tpmsAvailable ? "PSI · N/A" : ((vehicleData.tpmsFl < 28) ? "PSI · LOW" : "PSI · OK"); color: Hud2Theme.textTertiary; font.pixelSize: 10; font.weight: Font.Bold; font.family: "sans-serif" } }
                            // Fr
                            Column { anchors.left: carCanvas.right; anchors.leftMargin: 10; anchors.top: carCanvas.top; anchors.topMargin: carCanvas.height*0.1; Text { text: tpmsWrapper.tpmsAvailable ? vehicleData.tpmsFr.toFixed(1) : "—"; color: !tpmsWrapper.tpmsAvailable ? Hud2Theme.textTertiary : ((vehicleData.tpmsFr < 28) ? Hud2Theme.crit : Hud2Theme.ok); font.pixelSize: 22; font.weight: 300; font.family: "sans-serif" } Text { text: !tpmsWrapper.tpmsAvailable ? "PSI · N/A" : ((vehicleData.tpmsFr < 28) ? "PSI · LOW" : "PSI · OK"); color: Hud2Theme.textTertiary; font.pixelSize: 10; font.weight: Font.Bold; font.family: "sans-serif" } }
                            // Rl
                            Column { anchors.right: carCanvas.left; anchors.rightMargin: 10; anchors.bottom: carCanvas.bottom; anchors.bottomMargin: carCanvas.height*0.1; Text { text: tpmsWrapper.tpmsAvailable ? vehicleData.tpmsRl.toFixed(1) : "—"; color: !tpmsWrapper.tpmsAvailable ? Hud2Theme.textTertiary : ((vehicleData.tpmsRl < 28) ? Hud2Theme.crit : Hud2Theme.ok); font.pixelSize: 22; font.weight: 300; font.family: "sans-serif" } Text { text: !tpmsWrapper.tpmsAvailable ? "PSI · N/A" : ((vehicleData.tpmsRl < 28) ? "PSI · LOW" : "PSI · OK"); color: Hud2Theme.textTertiary; font.pixelSize: 10; font.weight: Font.Bold; font.family: "sans-serif" } }
                            // Rr
                            Column { anchors.left: carCanvas.right; anchors.leftMargin: 10; anchors.bottom: carCanvas.bottom; anchors.bottomMargin: carCanvas.height*0.1; Text { text: tpmsWrapper.tpmsAvailable ? vehicleData.tpmsRr.toFixed(1) : "—"; color: !tpmsWrapper.tpmsAvailable ? Hud2Theme.textTertiary : ((vehicleData.tpmsRr < 28) ? Hud2Theme.crit : Hud2Theme.ok); font.pixelSize: 22; font.weight: 300; font.family: "sans-serif" } Text { text: !tpmsWrapper.tpmsAvailable ? "PSI · N/A" : ((vehicleData.tpmsRr < 28) ? "PSI · LOW" : "PSI · OK"); color: Hud2Theme.textTertiary; font.pixelSize: 10; font.weight: Font.Bold; font.family: "sans-serif" } }
                        }
                        }
                    }
                }

                // Trip Stats
                P3Card {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 2
                            rowSpacing: 10
                            columnSpacing: 10
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                opacity: vehicleData.tripKm > 0 ? 1.0 : 0.4   // 트립 거리 소스 미연동 → dim + N/A
                                Text { text: "DISTANCE"; color: Hud2Theme.textTertiary; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.6; font.family: "sans-serif" }
                                RowLayout { 
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { 
                                        Layout.fillWidth: true
                                        text: vehicleData.tripKm > 0 ? vehicleData.tripKm.toFixed(1) : "N/A"
                                        color: Hud2Theme.text; font.pixelSize: 22; font.weight: Font.Light; font.family: "sans-serif" 
                                        fontSizeMode: Text.Fit; minimumPixelSize: 10
                                    } 
                                    Text { Layout.alignment: Qt.AlignBottom; text: "km"; color: Hud2Theme.textSecondary; font.pixelSize: 14; font.family: "sans-serif"; bottomPadding: 2 } 
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                opacity: (vehicleData.runTimeSec > 0 && vehicleData.tripKm > 0) ? 1.0 : 0.4   // 트립 거리 미연동 → dim + N/A
                                Text { text: "AVG SPEED"; color: Hud2Theme.textTertiary; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.6; font.family: "sans-serif" }
                                RowLayout { 
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { 
                                        Layout.fillWidth: true
                                        text: {
                                            var rts = vehicleData.runTimeSec;
                                            var km = vehicleData.tripKm;
                                            if (rts > 0 && km > 0) return (km / (rts / 3600)).toFixed(1);
                                            return "N/A";
                                        }
                                        color: Hud2Theme.text; font.pixelSize: 22; font.weight: Font.Light; font.family: "sans-serif" 
                                        fontSizeMode: Text.Fit; minimumPixelSize: 10
                                    } 
                                    Text { Layout.alignment: Qt.AlignBottom; text: "km/h"; color: Hud2Theme.textSecondary; font.pixelSize: 14; font.family: "sans-serif"; bottomPadding: 2 } 
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                opacity: vehicleData.odoKm > 0 ? 1.0 : 0.4   // 주행거리 소스 미연동 → dim + N/A
                                Text { text: "ODOMETER"; color: Hud2Theme.textTertiary; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.6; font.family: "sans-serif" }
                                RowLayout { 
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text { 
                                        Layout.fillWidth: true
                                        text: vehicleData.odoKm > 0 ? Math.round(vehicleData.odoKm) : "N/A"
                                        color: Hud2Theme.text; font.pixelSize: 20; font.weight: Font.Light; font.family: "sans-serif" 
                                        fontSizeMode: Text.Fit; minimumPixelSize: 10
                                    } 
                                    Text { Layout.alignment: Qt.AlignBottom; text: "km"; color: Hud2Theme.textSecondary; font.pixelSize: 14; font.family: "sans-serif"; bottomPadding: 2 } 
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text { text: "DRIVE TIME"; color: Hud2Theme.textTertiary; font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.6; font.family: "sans-serif" }
                                Text { 
                                    Layout.fillWidth: true
                                    text: {
                                        var secs = vehicleData.runTimeSec;
                                        var h = Math.floor(secs / 3600);
                                        var m = Math.floor((secs % 3600) / 60);
                                        return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m);
                                    }
                                    color: Hud2Theme.text; font.pixelSize: 20; font.weight: Font.Light; font.family: "sans-serif" 
                                    fontSizeMode: Text.Fit; minimumPixelSize: 10
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
