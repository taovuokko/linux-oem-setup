import QtQuick

// Laptop lid opens upward, checkmark fades in on screen.
// Colours: teal palette (#44896a / #7ecba0) on dark bg (#1a2e2e).
Item {
    id: root

    // ── Keyboard base ────────────────────────────────────────────────────
    Rectangle {
        id: base
        width: 96; height: 12; radius: 4
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 20
        color: "#2c4040"

        // Trackpad hint
        Rectangle {
            width: 28; height: 5; radius: 2.5
            anchors.centerIn: parent
            color: "#3a5858"
        }
    }

    // ── Screen — clip container whose height grows from 0 ────────────────
    Item {
        id: screenClip
        width: 84; height: 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: base.top; anchors.bottomMargin: 2
        clip: true

        Rectangle {
            width: parent.width; height: 58
            anchors.bottom: parent.bottom   // grows from hinge upward
            radius: 5
            color: "#1a2e2e"
            border.color: "#44896a"; border.width: 1.5

            Text {
                anchors.centerIn: parent
                text: "✓"
                color: "#7ecba0"
                font.pixelSize: 26
                font.weight: Font.Bold
                opacity: root.checkOpacity
            }
        }
    }

    property real checkOpacity: 0

    SequentialAnimation {
        id: anim
        running: false
        PauseAnimation  { duration: 320 }
        NumberAnimation { target: screenClip; property: "height"; to: 58;  duration: 680; easing.type: Easing.OutCubic }
        PauseAnimation  { duration: 200 }
        NumberAnimation { target: root;       property: "checkOpacity"; to: 1; duration: 380; easing.type: Easing.OutCubic }
    }

    Component.onCompleted: anim.start()
}
