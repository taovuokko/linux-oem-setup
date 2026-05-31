import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property string eyebrow: ""
    property string title: ""
    property string subtitle: ""
    property url illustration
    property int step: -1          // -1 = no indicator, 0-3 = active step
    default property alias content: body.data
    signal back()
    signal next()

    // Card shadow
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 6
        width: card.width + 4
        height: card.height + 4
        radius: card.radius + 2
        color: "#18000000"
        z: card.z - 1
    }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 12
        width: card.width - 16
        height: card.height
        radius: card.radius
        color: "#0e000000"
        z: card.z - 2
    }

    Rectangle {
        id: card
        width: Math.min(parent.width - 64, 920)
        height: Math.min(parent.height - 64, 580)
        anchors.centerIn: parent
        radius: 12
        color: "#fbfaf7"
        border.color: "#e0dbd2"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Left panel — dark sidebar
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.max(240, card.width * 0.34)
                radius: 12
                color: "#1e2c32"

                // Mask right-side corners so only left side is rounded
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.radius
                    color: parent.color
                }

                // Subtle top gradient highlight
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: parent.height * 0.45
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#263840" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 36
                    spacing: 0

                    Label {
                        text: root.eyebrow
                        color: "#7ecba0"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.8
                        Layout.bottomMargin: 14
                    }

                    Label {
                        text: root.title
                        color: "#f0f4f2"
                        font.pixelSize: 30
                        font.weight: Font.Bold
                        wrapMode: Text.WordWrap
                        lineHeight: 1.15
                        Layout.fillWidth: true
                        Layout.bottomMargin: 16
                    }

                    Label {
                        text: root.subtitle
                        color: "#9ab8b0"
                        font.pixelSize: 14
                        lineHeight: 1.3
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Item { Layout.fillHeight: true }

                    Image {
                        source: root.illustration
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 130
                        Layout.alignment: Qt.AlignHCenter
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.85
                    }
                }
            }

            // Right panel — content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 44
                Layout.rightMargin: 44
                Layout.topMargin: 32
                Layout.bottomMargin: 36
                spacing: 0

                // Step indicator — only shown on wizard pages
                StepIndicator {
                    visible: root.step >= 0
                    currentStep: root.step
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 28
                }

                // Page content
                Item {
                    id: body
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
