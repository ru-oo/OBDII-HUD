import QtQuick
import QtQuick.Layouts

Item {
    id: root
    width: 2388
    height: 1668

    component P2Card: Rectangle {
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

        ColumnLayout {
            anchors.fill: parent
            spacing: 24

            // TOP - 4 radial gauges
            GridLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.height * 0.20
                columns: 4
                columnSpacing: 24

                P2Card {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    RadialGauge {
                        anchors.centerIn: parent
                        size: Math.min(parent.width, parent.height) * 0.85
                        value: vehicleData.engineLoad
                        min: 0; max: 100
                        label: "Engine Load"
                        unit: "%"
                        showZones: true
                        zones: [0.65, 0.88]
                        warning: value > 75
                    }
                }
                P2Card {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    RadialGauge {
                        anchors.centerIn: parent
                        size: Math.min(parent.width, parent.height) * 0.85
                        value: vehicleData.manifoldPres
                        min: 0; max: 250
                        label: "MAP"
                        unit: "kPa"
                    }
                }
                P2Card {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    RadialGauge {
                        anchors.centerIn: parent
                        size: Math.min(parent.width, parent.height) * 0.85
                        value: vehicleData.mafRate
                        min: 0; max: 50
                        label: "MAF"
                        unit: "g/s"
                        decimals: 1
                    }
                }
                P2Card {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    property bool hasCat: true
                    RadialGauge {
                        anchors.centerIn: parent
                        size: Math.min(parent.width, parent.height) * 0.85
                        value: vehicleData.catalystTemp
                        min: 200; max: 900
                        label: "Catalyst"
                        unit: "°C"
                        showZones: true
                        zones: [0.6, 0.85]
                        warning: parent.hasCat && value > 750
                        critical: parent.hasCat && value > 850
                        opacity: parent.hasCat ? 1.0 : 0.2
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: !parent.hasCat
                        color: Qt.rgba(0,0,0,0.45)
                        radius: 16
                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            Rectangle {
                                width: txt1.implicitWidth + 24
                                height: txt1.implicitHeight + 12
                                radius: height/2
                                color: Hud2Theme.hairline
                                border.color: Hud2Theme.cardBorder
                                Text {
                                    id: txt1
                                    anchors.centerIn: parent
                                    text: "NOT EQUIPPED"
                                    color: Hud2Theme.textTertiary
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 2.2
                                    font.family: "sans-serif"
                                }
                            }
                        }
                    }
                }
            }

            // MIDDLE - O2, Trims, Ignition
            GridLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.height * 0.28
                columns: 3
                columnSpacing: 24

                P2Card {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Column {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: parent.height * 0.05
                        Text { text: "O₂ SENSOR VOLTAGE"; color: Hud2Theme.textTertiary; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 1.4; font.family: "sans-serif" }
                        
                        O2Trace {
                            width: parent.width; height: parent.height * 0.35
                            label: "Bank 1"
                            value: vehicleData.cmdAFR
                        }
                        O2Trace {
                            width: parent.width; height: parent.height * 0.35
                            label: "Bank 2"
                            value: 0
                        }
                    }
                }

                P2Card {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Column {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: Math.min(16, parent.height * 0.05)
                        Text { text: "FUEL TRIM · %"; color: Hud2Theme.textTertiary; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 1.4; bottomPadding: 2; font.family: "sans-serif" }
                        
                        BarGauge {
                            width: parent.width; height: parent.height * 0.15
                            value: vehicleData.shortFuelTrim1
                            min: -25; max: 25; centerZero: true; label: "STFT · Bank 1"; unit: "%"; decimals: 1
                        }
                        BarGauge {
                            width: parent.width; height: parent.height * 0.15
                            value: vehicleData.longFuelTrim1
                            min: -25; max: 25; centerZero: true; label: "LTFT · Bank 1"; unit: "%"; decimals: 1
                        }
                        BarGauge {
                            width: parent.width; height: parent.height * 0.15
                            value: 0
                            min: -25; max: 25; centerZero: true; label: "STFT · Bank 2"; unit: "%"; decimals: 1
                            opacity: 0.3
                        }
                        BarGauge {
                            width: parent.width; height: parent.height * 0.15
                            value: 0
                            min: -25; max: 25; centerZero: true; label: "LTFT · Bank 2"; unit: "%"; decimals: 1
                            opacity: 0.3
                        }
                    }
                }

                P2Card {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Column {
                        anchors.fill: parent
                        anchors.margins: 24
                        Text { text: "IGNITION TIMING"; color: Hud2Theme.textTertiary; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 1.4; font.family: "sans-serif" }
                        
                        Item {
                            width: parent.width
                            height: parent.height - 60
                            RadialGauge {
                                anchors.centerIn: parent
                                size: Math.min(parent.width, parent.height) * 0.95
                                value: vehicleData.timingAdv
                                min: -10; max: 50
                                label: "BTDC"
                                unit: "°"
                                decimals: 1
                            }
                        }
                    }
                }
            }

            // BOTTOM - DTC List
            P2Card {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true

                        property int critCount: vehicleData.dtcList.filter(function(d) { return d.sev === 0; }).length
                        property int warnCount: vehicleData.dtcList.filter(function(d) { return d.sev === 1; }).length
                        property int storedCount: vehicleData.dtcList.filter(function(d) { return d.sev === 2; }).length

                        Text { Layout.alignment: Qt.AlignLeft; text: "DIAGNOSTIC TROUBLE CODES"; color: Hud2Theme.textTertiary; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 1.4; font.family: "sans-serif" }
                        Item { Layout.fillWidth: true }
                        Row {
                            spacing: 14
                            visible: vehicleData.dtcList.length > 0
                            Rectangle { width: 100; height: 22; radius: 11; color: Qt.rgba(1,0.2,0.2,0.16); visible: parent.parent.critCount > 0; Text { anchors.centerIn: parent; text: parent.parent.parent.critCount + " Critical"; color: Hud2Theme.crit; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1; font.family: "sans-serif" } }
                            Rectangle { width: 100; height: 22; radius: 11; color: Qt.rgba(1,0.7,0.2,0.16); visible: parent.parent.warnCount > 0; Text { anchors.centerIn: parent; text: parent.parent.parent.warnCount + " Pending"; color: Hud2Theme.warn; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1; font.family: "sans-serif" } }
                            Rectangle { width: 100; height: 22; radius: 11; color: Hud2Theme.accentSoft; visible: parent.parent.storedCount > 0; Text { anchors.centerIn: parent; text: parent.parent.parent.storedCount + " Stored"; color: Hud2Theme.accent; font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1; font.family: "sans-serif" } }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // Empty state
                        Column {
                            anchors.centerIn: parent
                            width: parent.width
                            spacing: 8
                            visible: vehicleData.dtcList.length === 0

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: "NO ACTIVE CODES"
                                color: Hud2Theme.ok
                                font.pixelSize: 14; font.weight: Font.Bold; font.letterSpacing: 2; font.family: "sans-serif"
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: "System nominal"
                                color: Hud2Theme.textTertiary
                                font.pixelSize: 12; font.family: "sans-serif"
                            }
                        }

                        ListView {
                            anchors.fill: parent
                            visible: vehicleData.dtcList.length > 0
                            clip: true
                            spacing: 8
                            model: vehicleData.dtcList
                            delegate: Rectangle {
                            width: ListView.view.width
                            height: 38
                            radius: 8
                            color: Qt.rgba(Hud2Theme.text.r, Hud2Theme.text.g, Hud2Theme.text.b, 0.04)
                            border.color: Hud2Theme.cardBorder
                            border.width: 1

                            Rectangle {
                                width: 4
                                height: parent.height
                                radius: 2
                                anchors.left: parent.left
                                color: modelData.sev === 0 ? Hud2Theme.crit : (modelData.sev === 1 ? Hud2Theme.warn : Hud2Theme.textQuaternary)
                            }

                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.code
                                color: modelData.sev === 0 ? Hud2Theme.crit : (modelData.sev === 1 ? Hud2Theme.warn : Hud2Theme.textSecondary)
                                font.pixelSize: 14; font.weight: Font.DemiBold; font.family: "sans-serif"; font.letterSpacing: 1
                            }
                            Text {
                                anchors.left: parent.left; anchors.leftMargin: 90
                                anchors.right: parent.right; anchors.rightMargin: 220
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.desc
                                color: Hud2Theme.text
                                font.pixelSize: 13; font.weight: Font.Medium; font.family: "sans-serif"
                                elide: Text.ElideRight
                            }
                            Text {
                                anchors.right: parent.right; anchors.rightMargin: 120
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.ecu
                                color: Hud2Theme.textQuaternary
                                font.pixelSize: 11; font.weight: Font.DemiBold; font.family: "sans-serif"; font.letterSpacing: 1
                            }
                            Text {
                                anchors.right: parent.right; anchors.rightMargin: 20
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.status
                                color: modelData.sev === 0 ? Hud2Theme.crit : (modelData.sev === 1 ? Hud2Theme.warn : Hud2Theme.textQuaternary)
                                font.pixelSize: 11; font.weight: Font.Bold; font.family: "sans-serif"; font.letterSpacing: 1
                            }
                        }
                    }
                }
            }
        }
    }
}
}
