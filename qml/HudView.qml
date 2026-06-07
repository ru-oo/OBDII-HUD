// HudView.qml – Tesla Minimal layout
// ┌──────────────── TopBar ─────────────────────────────────────────┐
// │ Left panel │       Center (SpeedCenter)        │  Right panel   │
// └──────────────── BottomBar ──────────────────────────────────────┘

import QtQuick
import QtQuick.Shapes
import "components"

Item {
    id: root
    anchors.fill: parent

    // ── Background
    Rectangle {
        anchors.fill: parent
        color: theme.bgColor
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    // ── Top bar
    TopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 44
        z: 10
    }

    // ── Main area
    Item {
        id: mainArea
        anchors.top: topBar.bottom
        anchors.bottom: bottomBar.top
        anchors.left: parent.left
        anchors.right: parent.right

        // Left panel – RPM + engine data
        Item {
            id: leftPanel
            width: 230
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.margins: 8

            HudPanel { anchors.fill: parent }

            // RPM arc gauge
            ArcGauge {
                id: rpmGauge
                anchors.top: parent.top
                anchors.topMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 28
                height: width * 0.72

                value     : vehicleData.rpm
                minVal    : 0
                maxVal    : 8000
                warnVal   : 6000
                dangerVal : 7200
                startAngle: 215
                spanAngle : 250
                arcColor  : theme.leftAccent
                label     : "RPM"
                digitalText: (vehicleData.rpm / 1000).toFixed(1) + "k"
            }

            // ── Engine sub-gauges
            Column {
                anchors.top: rpmGauge.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 7

                MiniGauge { label: "LOAD";  value: vehicleData.engineLoad;  maxVal: 100; unit: "%"; barColor: theme.leftAccent }
                MiniGauge { label: "THR";   value: vehicleData.throttle;    maxVal: 100; unit: "%"; barColor: theme.leftAccent }
                MiniGauge { label: "TORQ";  value: vehicleData.engineTorqPct; maxVal: 100; unit: "%"; barColor: theme.leftAccent }
                MiniGauge { label: "MAF";   value: vehicleData.mafRate;     maxVal: 30;  unit: "g/s"; barColor: theme.leftAccent }
            }

            // ── Voltage indicator
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Text {
                    text: vehicleData.ctrlVoltage.toFixed(1) + " V"
                    color: vehicleData.ctrlVoltage < 12.0 ? theme.gaugeDanger : theme.dimText
                    font.pixelSize: 11
                    font.family: "Segoe UI"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: "⬧"
                    color: theme.dimText
                    font.pixelSize: 8
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: vehicleData.runTimeSec < 3600
                        ? (Math.floor(vehicleData.runTimeSec / 60) + "m " + (Math.floor(vehicleData.runTimeSec) % 60) + "s")
                        : (Math.floor(vehicleData.runTimeSec / 3600) + "h " + (Math.floor(vehicleData.runTimeSec / 60) % 60) + "m")
                    color: theme.dimText
                    font.pixelSize: 11
                    font.family: "Segoe UI"
                }
            }
        }

        // ── Center – Speed + status
        SpeedCenter {
            id: center
            anchors.left: leftPanel.right
            anchors.right: rightPanel.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 4
            anchors.rightMargin: 4
        }

        // ── Right panel – Fuel + temp data
        Item {
            id: rightPanel
            width: 230
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 8

            HudPanel { anchors.fill: parent }

            // Fuel arc gauge
            ArcGauge {
                id: fuelGauge
                anchors.top: parent.top
                anchors.topMargin: 14
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 28
                height: width * 0.72

                value     : vehicleData.fuelLevel
                minVal    : 0
                maxVal    : 100
                warnVal   : 20
                dangerVal : 10
                startAngle: 215
                spanAngle : 250
                arcColor  : theme.rightAccent
                label     : "FUEL"
                digitalText: Math.round(vehicleData.fuelLevel) + "%"
            }

            // ── Thermal sub-gauges
            Column {
                anchors.top: fuelGauge.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 7

                MiniGauge {
                    label: "COOL"; unit: "°C"; maxVal: 130
                    value: vehicleData.coolantTemp
                    barColor: vehicleData.coolantTemp > 105 ? theme.gaugeDanger
                            : vehicleData.coolantTemp > 95  ? theme.gaugeWarn
                            : theme.rightAccent
                }
                MiniGauge {
                    label: "OIL";  unit: "°C"; maxVal: 150
                    value: vehicleData.oilTemp
                    barColor: vehicleData.oilTemp > 130 ? theme.gaugeDanger
                            : vehicleData.oilTemp > 115  ? theme.gaugeWarn
                            : theme.rightAccent
                }
                MiniGauge { label: "INT";  value: vehicleData.intakeTemp; maxVal: 80;  unit: "°C"; barColor: theme.rightAccent }
                MiniGauge { label: "F.RT"; value: vehicleData.fuelRate;   maxVal: 20;  unit: "L/h"; barColor: theme.rightAccent }
            }

            // ── AFR indicator
            Row {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Text {
                    text: "λ " + vehicleData.cmdAFR.toFixed(3)
                    color: Math.abs(vehicleData.cmdAFR - 1.0) > 0.05 ? theme.gaugeWarn : theme.dimText
                    font.pixelSize: 11
                    font.family: "Segoe UI"
                }
                Text { text: "⬧"; color: theme.dimText; font.pixelSize: 8; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: "FT " + vehicleData.shortFuelTrim1.toFixed(1) + "%"
                    color: Math.abs(vehicleData.shortFuelTrim1) > 10 ? theme.gaugeWarn : theme.dimText
                    font.pixelSize: 11
                    font.family: "Segoe UI"
                }
            }
        }
    }

    // ── Bottom status bar
    BottomBar {
        id: bottomBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 54
        z: 10
    }
}
