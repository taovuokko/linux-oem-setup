import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property alias text: field.text
    property alias placeholderText: field.placeholderText
    property alias echoMode: field.echoMode
    property string label: ""
    property string supportingText: ""
    signal accepted()

    spacing: 6

    Label {
        text: root.label
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: "#4a5568"
    }

    TextField {
        id: field
        Layout.fillWidth: true
        implicitHeight: 48
        font.pixelSize: 17
        selectByMouse: true
        color: "#1a2327"
        placeholderTextColor: "#94a3a8"
        leftPadding: 12
        rightPadding: 12
        onAccepted: root.accepted()

        background: Rectangle {
            radius: 6
            color: "#ffffff"
            border.color: field.activeFocus ? "#3d7a5f" : "#c8d0cd"
            border.width: field.activeFocus ? 2 : 1

            Behavior on border.color { ColorAnimation { duration: 100 } }
            Behavior on border.width { NumberAnimation { duration: 100 } }
        }
    }

    Label {
        text: root.supportingText
        visible: text.length > 0
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
        color: "#7a8f8e"
        font.pixelSize: 13
    }
}
