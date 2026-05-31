#include "OemSetupController.h"

#include "Validation.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QMap>
#include <QProcess>

OemSetupController::OemSetupController(QObject* parent)
    : QObject(parent)
{
}

QString OemSetupController::displayName() const { return m_displayName; }

void OemSetupController::setDisplayName(const QString& value)
{
    const QString trimmed = value.trimmed();
    if (m_displayName == trimmed) {
        return;
    }

    m_displayName = trimmed;
    const QString nextUsername = OemSetup::deriveUsername(m_displayName);
    const bool usernameChangedNow = nextUsername != m_username;
    m_username = nextUsername;

    emit displayNameChanged();
    if (usernameChangedNow) {
        emit usernameChanged();
    }
}

QString OemSetupController::username() const { return m_username; }

QString OemSetupController::locale() const { return m_locale; }

void OemSetupController::setLocale(const QString& value)
{
    if (m_locale == value) {
        return;
    }
    m_locale = value;
    emit localeChanged();
}

QString OemSetupController::localeLabel() const
{
    static const QMap<QString, QString> labels = {
        {QStringLiteral("fi_FI.UTF-8"), QStringLiteral("Suomi")},
        {QStringLiteral("sv_SE.UTF-8"), QStringLiteral("Svenska")},
        {QStringLiteral("en_GB.UTF-8"), QStringLiteral("English (UK)")},
        {QStringLiteral("en_US.UTF-8"), QStringLiteral("English (US)")},
    };
    return labels.value(m_locale, m_locale);
}

QString OemSetupController::password() const { return m_password; }

void OemSetupController::setPassword(const QString& value)
{
    if (m_password == value) {
        return;
    }
    m_password = value;
    emit passwordChanged();
}

QString OemSetupController::passwordConfirmation() const { return m_passwordConfirmation; }

void OemSetupController::setPasswordConfirmation(const QString& value)
{
    if (m_passwordConfirmation == value) {
        return;
    }
    m_passwordConfirmation = value;
    emit passwordConfirmationChanged();
}

QString OemSetupController::errorTitle() const { return m_errorTitle; }
QString OemSetupController::errorMessage() const { return m_errorMessage; }
bool OemSetupController::busy() const { return m_busy; }
bool OemSetupController::mockMode() const { return m_mockMode; }

void OemSetupController::setMockMode(bool value)
{
    if (m_mockMode == value) {
        return;
    }
    m_mockMode = value;
    emit mockModeChanged();
}

bool OemSetupController::validateNamePage()
{
    const auto nameResult = OemSetup::validateDisplayName(m_displayName);
    if (!nameResult.ok) {
        setError(QStringLiteral("Tarkista nimi"), nameResult.message);
        return false;
    }

    const auto usernameResult = OemSetup::validateUsername(m_username);
    if (!usernameResult.ok) {
        setError(QStringLiteral("Tunnusta ei voi muodostaa"), usernameResult.message);
        return false;
    }

    clearError();
    return true;
}

bool OemSetupController::validateLanguagePage()
{
    const auto localeResult = OemSetup::validateLocale(m_locale);
    if (!localeResult.ok) {
        setError(QStringLiteral("Tarkista kieli"), localeResult.message);
        return false;
    }
    clearError();
    return true;
}

bool OemSetupController::validatePasswordPage()
{
    if (m_password.isEmpty()) {
        setError(QStringLiteral("Kirjoita salasana"), QStringLiteral("Salasana voi olla lyhyt, mutta se ei voi olla tyhjä."));
        return false;
    }

    if (m_password != m_passwordConfirmation) {
        setError(QStringLiteral("Salasanat eivät täsmää"), QStringLiteral("Kirjoita sama salasana molempiin kenttiin."));
        return false;
    }

    clearError();
    return true;
}

bool OemSetupController::validateAll()
{
    return validateNamePage() && validateLanguagePage() && validatePasswordPage();
}

void OemSetupController::apply()
{
    if (m_busy || !validateAll()) {
        emit applyFailed();
        return;
    }

    setBusy(true);

    if (m_mockMode) {
        QTimer::singleShot(1400, this, [this]() {
            setBusy(false);
            clearError();
            emit applySucceeded();
        });
        return;
    }

    QJsonObject payload;
    payload[QStringLiteral("displayName")] = m_displayName;
    payload[QStringLiteral("username")]    = m_username;
    payload[QStringLiteral("locale")]      = m_locale;
    payload[QStringLiteral("password")]    = m_password;
    const QByteArray json = QJsonDocument(payload).toJson(QJsonDocument::Compact);

    m_helperProcess = new QProcess(this);

    connect(m_helperProcess, &QProcess::finished, this,
            [this](int exitCode, QProcess::ExitStatus exitStatus) {
        m_helperProcess->deleteLater();
        m_helperProcess = nullptr;

        // Best-effort: clear password from memory after use
        m_password.clear();
        emit passwordChanged();

        setBusy(false);

        if (exitStatus == QProcess::NormalExit && exitCode == 0) {
            clearError();
            emit applySucceeded();
        } else {
            setError(QStringLiteral("Käyttöönotto epäonnistui"),
                     QStringLiteral("Tilin luominen ei onnistunut. "
                                    "Tarkista, että sinulla on riittävät oikeudet."));
            emit applyFailed();
        }
    });

    m_helperProcess->start(QStringLiteral("pkexec"), {
        QStringLiteral("/usr/libexec/oem-setup/oem-setup-helper")});

    if (!m_helperProcess->waitForStarted(5000)) {
        m_helperProcess->deleteLater();
        m_helperProcess = nullptr;
        setBusy(false);
        setError(QStringLiteral("Käyttöönotto epäonnistui"),
                 QStringLiteral("Helper-prosessin käynnistys epäonnistui."));
        emit applyFailed();
        return;
    }

    m_helperProcess->write(json);
    m_helperProcess->closeWriteChannel();
}

void OemSetupController::clearError()
{
    if (m_errorTitle.isEmpty() && m_errorMessage.isEmpty()) {
        return;
    }
    m_errorTitle.clear();
    m_errorMessage.clear();
    emit errorChanged();
}

void OemSetupController::setError(const QString& title, const QString& message)
{
    m_errorTitle = title;
    m_errorMessage = message;
    emit errorChanged();
}

void OemSetupController::setBusy(bool value)
{
    if (m_busy == value) {
        return;
    }
    m_busy = value;
    emit busyChanged();
}
