import QtQuick

// User card draws in: card fades, avatar pops (OutBack), two text lines slide right.
// Tweak lineFullW / lineShortW to adjust placeholder line lengths.
Item {
    id: root

    readonly property real lineFullW:  44   // card(112) − leftPad(14) − avatar(32) − gap(10) − rightPad(12)
    readonly property real lineShortW: 28   // shorter second line

    // ── Card ─────────────────────────────────────────────────────────────
    Rectangle {
        id: card
        width: 112; height: 76
        anchors.centerIn: parent
        radius: 10
        color: "#1a2e2e"
        border.color: "#44896a"; border.width: 1.5
        opacity: 0

        // Avatar circle
        Rectangle {
            id: avatar
            width: 32; height: 32; radius: 16
            anchors.left: parent.left; anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: "#44896a"
            scale: 0

            // Head
            Rectangle {
                width: 14; height: 14; radius: 7
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top; anchors.topMargin: 4
                color: "#7ecba0"
            }
            // Shoulders
            Rectangle {
                width: 20; height: 8; radius: 4
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom; anchors.bottomMargin: 3
                color: "#7ecba0"
            }
        }

        // Text placeholder lines
        Column {
            anchors.left: avatar.right; anchors.leftMargin: 10
            anchors.right: parent.right; anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle { id: line1; width: 0; height: 8; radius: 4; color: "#5aab86" }
            Rectangle { id: line2; width: 0; height: 6; radius: 3; color: "#3a5e4e" }
        }
    }

    SequentialAnimation {
        id: anim
        running: false
        NumberAnimation { target: card;   property: "opacity"; to: 1;              duration: 280; easing.type: Easing.OutCubic }
        PauseAnimation  { duration: 80 }
        NumberAnimation { target: avatar; property: "scale";   to: 1;              duration: 360; easing.type: Easing.OutBack }
        PauseAnimation  { duration: 80 }
        NumberAnimation { target: line1;  property: "width";   to: root.lineFullW;  duration: 280; easing.type: Easing.OutCubic }
        PauseAnimation  { duration: 90 }
        NumberAnimation { target: line2;  property: "width";   to: root.lineShortW; duration: 240; easing.type: Easing.OutCubic }
    }

    Component.onCompleted: anim.start()
}
