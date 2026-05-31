import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property string eyebrow: ""
    property string title: ""
    property string subtitle: ""
    property url illustration
    default property alias content: body.data
    signal back()
    signal next()

    Rectangle {
        id: card
        width: Math.min(parent.width - 64, 900)
        height: Math.min(parent.height - 64, 560)
        anchors.centerIn: parent
        radius: 8
        color: "#fbfaf7"
        border.color: "#dad6ce"

        RowLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: Math.max(260, card.width * 0.36)
                color: "#263238"
                radius: 8

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 8
                    color: parent.color
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 36
                    spacing: 22

                    Label {
                        text: root.eyebrow
                        color: "#a8d5ba"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Label {
                        text: root.title
                        color: "white"
                        font.pixelSize: 34
                        font.weight: Font.DemiBold
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        text: root.subtitle
                        color: "#dce3e1"
                        font.pixelSize: 16
                        lineHeight: 1.2
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Item { Layout.fillHeight: true }

                    Image {
                        source: root.illustration
                        Layout.preferredWidth: 190
                        Layout.preferredHeight: 150
                        Layout.alignment: Qt.AlignHCenter
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.95
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 44
                spacing: 20

                Item {
                    id: body
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
