import QtQuick

// Padlock snaps shut: body fades in, shackle slides down with OutBack snap.
// Shackle is painted first so the lock body naturally covers the inserted legs.
Item {
    id: root

    // ── Shackle (U-arch) — declared first so lockBody paints over its legs ──
    Item {
        id: shackle
        width: 38; height: 34
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: lockBody.verticalCenter
        opacity: 0
        transform: Translate { id: shackleSlide; y: -14 }  // open: raised up

        // Top arc
        Rectangle {
            width: parent.width; height: 14; radius: 7
            color: "#5aab86"
        }
        // Left leg
        Rectangle {
            x: 0; y: 7; width: 6; height: parent.height - 7; radius: 3
            color: "#5aab86"
        }
        // Right leg
        Rectangle {
            x: parent.width - 6; y: 7; width: 6; height: parent.height - 7; radius: 3
            color: "#5aab86"
        }
    }

    // ── Lock body — declared after shackle so it covers the inserted legs ──
    Rectangle {
        id: lockBody
        width: 66; height: 52
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 16
        radius: 10
        color: "#1a2e2e"
        border.color: "#44896a"; border.width: 2
        opacity: 0

        // Keyhole circle
        Rectangle {
            width: 10; height: 10; radius: 5
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -4
            color: "#44896a"
        }
        // Keyhole slot
        Rectangle {
            width: 5; height: 10; radius: 2.5
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 8
            color: "#44896a"
        }
    }

    SequentialAnimation {
        id: anim
        running: false
        ParallelAnimation {
            NumberAnimation { target: lockBody; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: shackle;  property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
        }
        PauseAnimation  { duration: 200 }
        NumberAnimation { target: shackleSlide; property: "y"; to: 0; duration: 420; easing.type: Easing.OutBack }
    }

    Component.onCompleted: anim.start()
}
