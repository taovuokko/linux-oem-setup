import QtQuick
import QtQuick.Controls
import OemSetup
import "pages"

ApplicationWindow {
    id: window
    width: 980
    height: 680
    minimumWidth: 740
    minimumHeight: 540
    visible: true
    title: qsTr("OEM Setup")

    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#eeeae4" }
            GradientStop { position: 1.0; color: "#e0e7eb" }
        }
    }

    Connections {
        target: oemSetup
        function onApplySucceeded() {
            stack.replace(null, doneComp)
        }
        function onApplyFailed() {
            stack.pop()
            stack.push(errorComp)
        }
    }

    StackView {
        id: stack
        anchors.fill: parent
        clip: true

        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: stack.width * 0.07; to: 0
                    duration: 260; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0; to: 1
                    duration: 220; easing.type: Easing.OutCubic
                }
            }
        }
        pushExit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 0; to: -stack.width * 0.07
                    duration: 260; easing.type: Easing.OutCubic
                }
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 }
            }
        }
        popEnter: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: -stack.width * 0.07; to: 0
                    duration: 260; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0; to: 1
                    duration: 220; easing.type: Easing.OutCubic
                }
            }
        }
        popExit: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: 0; to: stack.width * 0.07
                    duration: 260; easing.type: Easing.OutCubic
                }
                NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 }
            }
        }
        replaceEnter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300; easing.type: Easing.OutCubic }
        }
        replaceExit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 200 }
        }

        initialItem: welcomeComp
    }

    Component {
        id: welcomeComp
        WelcomePage {
            onNext: stack.push(nameComp)
        }
    }

    Component {
        id: nameComp
        NamePage {
            onBack: stack.pop()
            onNext: { if (oemSetup.validateNamePage()) stack.push(languageComp) }
        }
    }

    Component {
        id: languageComp
        LanguagePage {
            onBack: stack.pop()
            onNext: { if (oemSetup.validateLanguagePage()) stack.push(passwordComp) }
        }
    }

    Component {
        id: passwordComp
        PasswordPage {
            onBack: stack.pop()
            onNext: { if (oemSetup.validatePasswordPage()) stack.push(confirmComp) }
        }
    }

    Component {
        id: confirmComp
        ConfirmPage {
            onBack: {
                oemSetup.clearError()
                stack.pop()
            }
            onApply: {
                stack.push(progressComp)
                oemSetup.apply()
            }
        }
    }

    Component {
        id: progressComp
        ProgressPage {}
    }

    Component {
        id: doneComp
        DonePage {}
    }

    Component {
        id: errorComp
        ErrorPage {
            onBack: {
                oemSetup.clearError()
                stack.pop()
            }
        }
    }
}
