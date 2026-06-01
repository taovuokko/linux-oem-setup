import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

WizardFrame {
    eyebrow: qsTr("Vaihe 1 / 4")
    title: qsTr("Kuka käyttää tätä tietokonetta?")
    subtitle: qsTr("Nimi näkyy kirjautumisruudussa ja käyttäjäasetuksissa.")
    illustration: "../assets/welcome.svg"
    step: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        TextFieldCard {
            Layout.fillWidth: true
            label: qsTr("Nimi")
            placeholderText: qsTr("Esimerkiksi Matti Meikäläinen")
            supportingText: qsTr("Voit kirjoittaa koko nimen tai pelkän etunimen.")
            text: oemSetup.displayName
            onTextChanged: oemSetup.displayName = text
            onAccepted: next()
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 76
            radius: 8
            color: "#eef3f1"
            border.color: "#d8e1dd"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                Label {
                    text: qsTr("Käyttäjätunnus")
                    color: "#63706f"
                    font.pixelSize: 13
                }

                Label {
                    text: oemSetup.username.length > 0 ? oemSetup.username : qsTr("muodostetaan nimestä")
                    color: "#263238"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: oemSetup.errorMessage.length > 0
            text: oemSetup.errorMessage
            color: "#9b2c2c"
            wrapMode: Text.WordWrap
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            SecondaryButton { text: qsTr("Takaisin"); onClicked: back() }
            Item { Layout.fillWidth: true }
            PrimaryButton { text: qsTr("Jatka"); onClicked: next() }
        }
    }
}
