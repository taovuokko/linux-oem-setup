import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import OemSetup
import "pages"

ApplicationWindow {
    id: window
    width: 980
    height: 680
    minimumWidth: 720
    minimumHeight: 520
    visible: true
    title: qsTr("OEM Setup")
    color: "#f5f2ec"

    property int pageIndex: 0

    function goNext() {
        if (pageIndex === 1 && !oemSetup.validateNamePage())
            return
        if (pageIndex === 2 && !oemSetup.validateLanguagePage())
            return
        if (pageIndex === 3 && !oemSetup.validatePasswordPage())
            return
        pageIndex = Math.min(pageIndex + 1, stack.count - 1)
    }

    function goBack() {
        oemSetup.clearError()
        pageIndex = Math.max(pageIndex - 1, 0)
    }

    Connections {
        target: oemSetup
        function onApplySucceeded() {
            pageIndex = 6
        }
        function onApplyFailed() {
            pageIndex = 7
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#f7f4ef" }
            GradientStop { position: 1.0; color: "#e8edf0" }
        }
    }

    StackLayout {
        id: stack
        anchors.fill: parent
        currentIndex: window.pageIndex

        WelcomePage {
            onNext: window.goNext()
        }
        NamePage {
            onBack: window.goBack()
            onNext: window.goNext()
        }
        LanguagePage {
            onBack: window.goBack()
            onNext: window.goNext()
        }
        PasswordPage {
            onBack: window.goBack()
            onNext: window.goNext()
        }
        ConfirmPage {
            onBack: window.goBack()
            onApply: {
                pageIndex = 5
                oemSetup.apply()
            }
        }
        ProgressPage {}
        DonePage {}
        ErrorPage {
            onBack: {
                oemSetup.clearError()
                pageIndex = 4
            }
        }
    }
}
