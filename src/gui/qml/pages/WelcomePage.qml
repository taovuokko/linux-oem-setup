import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

WizardFrame {
    eyebrow: qsTr("Ensikäyttöönotto")
    title: qsTr("Tervetuloa")
    subtitle: qsTr("Otetaan tietokone käyttöösi muutamassa vaiheessa.")
    illustration: "../assets/welcome.svg"

    ColumnLayout {
        anchors.fill: parent
        spacing: 22

        Label {
            Layout.fillWidth: true
            text: qsTr("Tarvitsen nimesi, kielivalinnan ja salasanan. Sen jälkeen tietokone viimeistelee asetukset ja käynnistyy uudelleen.")
            wrapMode: Text.WordWrap
            color: "#34403f"
            font.pixelSize: 19
            lineHeight: 1.18
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            PrimaryButton {
                text: qsTr("Aloitetaan")
                onClicked: next()
            }
        }
    }
}
