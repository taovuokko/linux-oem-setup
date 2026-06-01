import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property alias text: field.text
    property alias placeholderText: field.placeholderText
    property string label: ""
    property string supportingText: ""
    // When true, shows a show/hide eye button (use instead of echoMode: Password)
    property bool showToggle: false
    property bool _passwordVisible: false
    // echoMode used when showToggle is false; ignored when showToggle is true
    property int echoMode: TextInput.Normal
    signal accepted()

    spacing: 6

    Label {
        visible: root.label.length > 0
        text: root.label
        font.pixelSize: 13
        font.weight: Font.DemiBold
        color: "#4a5568"
    }

    // Wrapper so the eye button can be absolutely positioned over the field
    Item {
        Layout.fillWidth: true
        implicitHeight: field.implicitHeight

        TextField {
            id: field
            anchors.fill: parent
            implicitHeight: 48
            font.pixelSize: 17
            selectByMouse: true
            color: "#1a2327"
            placeholderTextColor: "#94a3a8"
            leftPadding: 12
            rightPadding: root.showToggle ? 44 : 12
            echoMode: root.showToggle
                ? (root._passwordVisible ? TextInput.Normal : TextInput.Password)
                : root.echoMode
            onAccepted: root.accepted()

            background: Rectangle {
                id: fieldBg
                radius: 6
                color: "#ffffff"
                border.color: field.activeFocus ? "#3d7a5f" : "#c8d0cd"
                border.width: field.activeFocus ? 2 : 1

                Behavior on border.color { ColorAnimation { duration: 100 } }
                Behavior on border.width { NumberAnimation { duration: 100 } }

                Rectangle {
                    id: flashOverlay
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: "#d97706"
                    border.width: 2
                    opacity: 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
            }
        }

        // Eye toggle button
        Item {
            visible: root.showToggle
            width: 40; height: parent.height
            anchors.right: parent.right

            Canvas {
                id: eyeCanvas
                width: 22; height: 16
                anchors.centerIn: parent

                readonly property color iconColor: "#94a3a8"
                readonly property bool open: root._passwordVisible
                onOpenChanged: requestPaint()
                Component.onCompleted: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var w = width, h = height
                    ctx.strokeStyle = iconColor
                    ctx.fillStyle = iconColor
                    ctx.lineWidth = 1.5
                    ctx.lineCap = "round"

                    // Lens / eye outline
                    ctx.beginPath()
                    ctx.moveTo(0, h / 2)
                    ctx.quadraticCurveTo(w / 2, 0, w, h / 2)
                    ctx.quadraticCurveTo(w / 2, h, 0, h / 2)
                    ctx.stroke()

                    if (open) {
                        // Pupil — password is visible
                        ctx.beginPath()
                        ctx.arc(w / 2, h / 2, h / 4, 0, Math.PI * 2)
                        ctx.fill()
                    } else {
                        // Slash — password is hidden
                        ctx.beginPath()
                        ctx.moveTo(w * 0.15, h * 0.9)
                        ctx.lineTo(w * 0.85, h * 0.1)
                        ctx.stroke()
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root._passwordVisible = !root._passwordVisible
            }
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

    function flash() {
        flashOverlay.opacity = 1
        flashHideTimer.restart()
    }

    Timer {
        id: flashHideTimer
        interval: 700
        onTriggered: flashOverlay.opacity = 0
    }
}
