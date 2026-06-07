import QtQuick
import QtQuick.Controls
import QtQuick.Controls

Item {
    id: root
    width: 2388
    height: 1668

    // Background color binding to the selected theme
    Rectangle {
        anchors.fill: parent
        color: Hud2Theme.bg
        Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }

    // Status Bar (Top)
    Item {
        id: statusBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 56
        z: 50

        // Linear gradient background
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Hud2Theme.bg }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width; height: 1
            color: Hud2Theme.hairline
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Date
            Text {
                id: dateText
                text: Qt.formatDate(new Date(), "yyyy.MM.dd ddd")
                color: Hud2Theme.textSecondary
                font.pixelSize: 18
                font.weight: Font.Medium
                font.letterSpacing: 0.8
                font.family: "sans-serif"
                Timer { interval: 60000; running: true; repeat: true; onTriggered: dateText.text = Qt.formatDate(new Date(), "yyyy.MM.dd ddd") }
            }
            Rectangle { width: 1; height: 20; color: Hud2Theme.hairline; anchors.verticalCenter: parent.verticalCenter }
            // OBD
            Text {
                text: "OBD-II"
                color: Hud2Theme.textSecondary
                font.pixelSize: 18
                font.weight: Font.Medium
                font.letterSpacing: 0.8
                font.family: "sans-serif"
            }
            Rectangle { width: 1; height: 20; color: Hud2Theme.hairline; anchors.verticalCenter: parent.verticalCenter }
            
            // Weather
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: weatherData.icon === "clear"  ? "☀"
                        : weatherData.icon === "cloud"  ? "☁"
                        : weatherData.icon === "rain"   ? "🌧"
                        : weatherData.icon === "snow"   ? "❄"
                        : "🌤"
                    font.pixelSize: 18
                    color: Hud2Theme.text
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: weatherData.temp.toFixed(0) + "°C"
                    color: Hud2Theme.textSecondary
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    font.family: "sans-serif"
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: weatherData.desc
                    color: Hud2Theme.textTertiary
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    font.family: "sans-serif"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Clock
        Text {
            id: clockText
            anchors.centerIn: parent
            text: Qt.formatTime(new Date(), "hh:mm")
            color: Hud2Theme.text
            font.pixelSize: 22
            font.weight: Font.Normal
            font.family: "sans-serif"
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm") }
        }

        // Top Right: Theme Switcher (Replaces Battery info)
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 28
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            Text {
                text: "THEME"
                color: Hud2Theme.textTertiary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.letterSpacing: 1.4
                font.family: "sans-serif"
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                // Dark
                Rectangle {
                    width: Hud2Theme.name === "dark" ? 40 : 28
                    height: 28
                    radius: 14
                    color: "#0b0d10"
                    border.color: Hud2Theme.name === "dark" ? "#22e6ff" : Hud2Theme.cardBorder
                    border.width: 1.5
                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                    MouseArea { anchors.fill: parent; onClicked: Hud2Theme.name = "dark" }
                }
                // Light
                Rectangle {
                    width: Hud2Theme.name === "light" ? 40 : 28
                    height: 28
                    radius: 14
                    color: "#eef1f4"
                    border.color: Hud2Theme.name === "light" ? "#0a84ff" : Hud2Theme.cardBorder
                    border.width: 1.5
                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                    MouseArea { anchors.fill: parent; onClicked: Hud2Theme.name = "light" }
                }
                // Night
                Rectangle {
                    width: Hud2Theme.name === "night" ? 40 : 28
                    height: 28
                    radius: 14
                    color: "#050000"
                    border.color: Hud2Theme.name === "night" ? "#ff2a2a" : Hud2Theme.cardBorder
                    border.width: 1.5
                    Behavior on width { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                    MouseArea { anchors.fill: parent; onClicked: Hud2Theme.name = "night" }
                }
            }
        }
    }

    // SwipeView for Pages
    SwipeView {
        id: viewStack
        anchors.fill: parent
        currentIndex: 0
        interactive: true

        Page1Driving {}
        Page2Engine {}
        Page3Nav {}
    }

    // Premium Bottom Nav Bar (Sidebar style)
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        width: 600
        height: 64
        radius: 32
        color: Qt.rgba(Hud2Theme.bgElevated.r, Hud2Theme.bgElevated.g, Hud2Theme.bgElevated.b, 0.85)
        border.color: Hud2Theme.cardBorderStrong
        border.width: 1.5
        z: 50

        Row {
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: ["DRIVING", "ENGINE", "NAVIGATION"]
                Rectangle {
                    width: 180
                    height: 48
                    radius: 24
                    color: viewStack.currentIndex === index ? Hud2Theme.cardBorderStrong : "transparent"
                    Behavior on color { ColorAnimation { duration: 240 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: viewStack.currentIndex === index ? Hud2Theme.text : Hud2Theme.textTertiary
                        font.pixelSize: 14
                        font.weight: viewStack.currentIndex === index ? Font.Bold : Font.DemiBold
                        font.letterSpacing: 2
                        font.family: "sans-serif"
                        Behavior on color { ColorAnimation { duration: 240 } }
                    }

                    // Soft glow when active
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 12
                        height: parent.height + 12
                        radius: 30
                        color: Hud2Theme.accentSoft
                        opacity: viewStack.currentIndex === index ? 0.3 : 0
                        z: -1
                        Behavior on opacity { NumberAnimation { duration: 320 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: viewStack.currentIndex = index
                    }
                }
            }
        }
    }
}
