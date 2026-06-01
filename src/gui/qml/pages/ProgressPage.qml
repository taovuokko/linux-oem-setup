import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

WizardFrame {
    eyebrow: qsTr("Viimeistellään")
    title: qsTr("Hetki vielä")
    subtitle: qsTr("Luodaan käyttäjätiliä ja valmistellaan seuraavaa käynnistystä.")
    illustration: "../assets/welcome.svg"

    ColumnLayout {
        anchors.fill: parent
        spacing: 22

        Item { Layout.fillHeight: true }

        BusyIndicator {
            running: true
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Tämä kestää yleensä alle minuutin.")
            color: "#34403f"
            font.pixelSize: 17
        }

        Item { Layout.fillHeight: true }
    }
}
