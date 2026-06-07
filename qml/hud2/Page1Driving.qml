import QtQuick
import QtQuick.Layouts

Item {
    id: root
    width: 2388
    height: 1668

    // Background glow removed as requested

    Item {
        anchors.fill: parent
        anchors.topMargin: 80
        anchors.bottomMargin: 110 // Room for bottom nav
        anchors.leftMargin: 40
        anchors.rightMargin: 40

        RowLayout {
            id: mainRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: bottomStrip.top
            anchors.bottomMargin: 30
            spacing: 30

            // ================= HERO SPEEDO (LEFT) =================
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 48
                Layout.fillHeight: true

                // Natural glow behind the speedo
                Rectangle {
                    anchors.centerIn: speedoGauge
                    width: speedoGauge.size * 0.5
                    height: speedoGauge.size * 0.5
                    radius: width / 2
                    color: Hud2Theme.accentSoft
                    opacity: 0.25
                }

                ArcGauge {
                    id: speedoGauge
                    anchors.centerIn: parent
                    size: Math.min(parent.width, parent.height) * 0.95
                    value: vehicleData.speed
                    min: 0; max: 240
                    ticks: 13
                    minorTicksPerMajor: 4
                    unit: "km/h"
                    label: "Speed"
                    thickness: size * 0.025
                }
            }

            // ================= CENTER COLUMN (RPM & LOAD) =================
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 32
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 30

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        ArcGauge {
                            id: rpmGauge
                            anchors.centerIn: parent
                            size: Math.min(parent.width, parent.height) * 0.95
                            value: vehicleData.rpm
                            min: 0; max: 8000
                            ticks: 9
                            minorTicksPerMajor: 4
                            redlineFrom: 6000
                            label: "RPM × 1000"
                            primaryDigit: (vehicleData.rpm / 1000).toFixed(1)
                            thickness: size * 0.025
                            centerStyle: "speedo"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 110
                        color: Hud2Theme.card
                        border.color: Hud2Theme.cardBorder
                        border.width: 1.5
                        radius: 20

                        BarGauge {
                            anchors.centerIn: parent
                            width: parent.width * 0.8
                            height: 32
                            value: vehicleData.engineLoad
                            min: 0; max: 100
                            label: "Engine Load"
                            unit: "%"
                        }
                    }
                }
            }

            // ================= RIGHT COLUMN (INTAKE, COOLANT, FUEL VERTICAL) =================
            Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 20
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    // Intake
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Hud2Theme.card
                        border.color: Hud2Theme.cardBorder
                        border.width: 1.5
                        radius: 20

                        RadialGauge {
                            anchors.centerIn: parent
                            size: Math.min(parent.width, parent.height) * 0.7
                            value: vehicleData.intakeTemp
                            min: -20; max: 80
                            label: "Intake Air"
                            unit: "°C"
                            showZones: true
                            zones: [0.6, 0.85]
                            warning: value > 60
                            critical: value > 70
                        }
                    }

                    // Coolant
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Hud2Theme.card
                        border.color: Hud2Theme.cardBorder
                        border.width: 1.5
                        radius: 20

                        RadialGauge {
                            anchors.centerIn: parent
                            size: Math.min(parent.width, parent.height) * 0.7
                            value: vehicleData.coolantTemp
                            min: 40; max: 130
                            label: "Coolant"
                            unit: "°C"
                            showZones: true
                            zones: [0.55, 0.85]
                            warning: value > 105
                            critical: value > 115
                        }
                    }

                    // Fuel
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Pulsing Red Glow
                        Rectangle {
                            anchors.fill: fuelCard
                            anchors.margins: -16
                            radius: 36
                            color: Hud2Theme.crit
                            visible: vehicleData.fuelLevel <= 15
                            SequentialAnimation on opacity {
                                running: vehicleData.fuelLevel <= 15
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.05; duration: 800; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                            }
                        }

                        Rectangle {
                            id: fuelCard
                            anchors.fill: parent
                            color: Hud2Theme.card
                            border.color: (vehicleData.fuelLevel <= 15) ? Hud2Theme.crit : Hud2Theme.cardBorder
                            border.width: (vehicleData.fuelLevel <= 15) ? 3 : 1.5
                            radius: 20

                            FuelGauge {
                                anchors.centerIn: parent
                                height: parent.height * 0.65
                                value: vehicleData.fuelLevel
                                lowThreshold: 15
                            }
                        }
                    }
                }
            }
        }

        // ================= BOTTOM STRIP =================
        RowLayout {
            id: bottomStrip
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 130
            spacing: 30

            // Throttle
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 40
                Layout.fillHeight: true
                color: Hud2Theme.card
                border.color: Hud2Theme.cardBorder
                border.width: 1.5
                radius: 20

                Column {
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    spacing: 12
                    BarGauge {
                        width: parent.width; height: 36
                        value: vehicleData.throttle
                        min: 0; max: 100
                        label: "Throttle Position"
                        unit: "%"
                    }
                    Item {
                        width: parent.width
                        height: 24
                        Text { text: "0"; anchors.left: parent.left; color: Hud2Theme.textTertiary; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2; font.family: "sans-serif" }
                        Text { text: "25"; anchors.left: parent.left; anchors.leftMargin: parent.width * 0.25; color: Hud2Theme.textTertiary; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2; font.family: "sans-serif" }
                        Text { text: "50"; anchors.horizontalCenter: parent.horizontalCenter; color: Hud2Theme.textTertiary; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2; font.family: "sans-serif" }
                        Text { text: "75"; anchors.right: parent.right; anchors.rightMargin: parent.width * 0.25; color: Hud2Theme.textTertiary; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2; font.family: "sans-serif" }
                        Text { text: "WOT"; anchors.right: parent.right; color: Hud2Theme.textTertiary; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2; font.family: "sans-serif" }
                    }
                }
            }

            // Battery
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 30
                Layout.fillHeight: true
                color: Hud2Theme.card
                border.color: Hud2Theme.cardBorder
                border.width: 1.5
                radius: 20

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text { text: "BATTERY"; color: Hud2Theme.textTertiary; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2; font.family: "sans-serif" }
                    
                    Row {
                        spacing: 12
                        Text { text: vehicleData.ctrlVoltage.toFixed(1); color: Hud2Theme.text; font.pixelSize: 56; font.weight: 250; font.letterSpacing: -1.2; font.family: "sans-serif" }
                        Text { text: "V"; color: Hud2Theme.textSecondary; font.pixelSize: 26; font.weight: Font.Medium; font.family: "sans-serif"; anchors.baseline: parent.bottom; anchors.baselineOffset: -8 }
                        
                        Item { width: 10 } 
                        
                        Rectangle {
                            width: 60; height: 28; radius: 14
                            anchors.verticalCenter: parent.verticalCenter
                            color: (vehicleData.ctrlVoltage > 15) ? Qt.rgba(1, 0, 0, 0.16) :
                                   ((vehicleData.ctrlVoltage < 12.4) ? Qt.rgba(1, 0.7, 0, 0.16) : Qt.rgba(0.2, 0.8, 0.3, 0.16))
                            Text {
                                anchors.centerIn: parent
                                text: (vehicleData.ctrlVoltage > 15) ? "HIGH" : ((vehicleData.ctrlVoltage < 12.4) ? "LOW" : "OK")
                                color: (vehicleData.ctrlVoltage > 15) ? Hud2Theme.crit : ((vehicleData.ctrlVoltage < 12.4) ? Hud2Theme.warn : Hud2Theme.ok)
                                font.pixelSize: 13; font.weight: Font.Bold; font.letterSpacing: 1.5; font.family: "sans-serif"
                            }
                        }
                    }
                }
            }

            // Ambient
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 30
                Layout.fillHeight: true
                color: Hud2Theme.card
                border.color: Hud2Theme.cardBorder
                border.width: 1.5
                radius: 20

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text { text: "AMBIENT AIR"; color: Hud2Theme.textTertiary; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2; font.family: "sans-serif" }
                    Row {
                        spacing: 12
                        Text { text: vehicleData.ambientTemp.toFixed(1); color: Hud2Theme.text; font.pixelSize: 56; font.weight: 250; font.letterSpacing: -1.2; font.family: "sans-serif" }
                        Text { text: "°C"; color: Hud2Theme.textSecondary; font.pixelSize: 26; font.weight: Font.Medium; font.family: "sans-serif"; anchors.baseline: parent.bottom; anchors.baselineOffset: -8 }
                    }
                }
            }
        }
    }
}
