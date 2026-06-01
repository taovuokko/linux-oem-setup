import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

WizardFrame {
    eyebrow: qsTr("Valmis")
    title: qsTr("Tietokone on valmis")
    subtitle: qsTr("Seuraavaksi tietokone käynnistyy uudelleen.")
    illustration: "../assets/done.svg"

    ColumnLayout {
        anchors.fill: parent
        spacing: 22

        Label {
            Layout.fillWidth: true
            text: qsTr("Kun kone käynnistyy uudelleen, kirjaudu sisään juuri luomallasi käyttäjällä.")
            wrapMode: Text.WordWrap
            color: "#34403f"
            font.pixelSize: 19
            lineHeight: 1.18
        }

        Item { Layout.fillHeight: true }
    }
}
