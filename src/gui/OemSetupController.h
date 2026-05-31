#pragma once

#include <QObject>
#include <QTimer>

class QProcess;

class OemSetupController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString displayName READ displayName WRITE setDisplayName NOTIFY displayNameChanged)
    Q_PROPERTY(QString username READ username NOTIFY usernameChanged)
    Q_PROPERTY(QString locale READ locale WRITE setLocale NOTIFY localeChanged)
    Q_PROPERTY(QString localeLabel READ localeLabel NOTIFY localeChanged)
    Q_PROPERTY(QString password READ password WRITE setPassword NOTIFY passwordChanged)
    Q_PROPERTY(QString passwordConfirmation READ passwordConfirmation WRITE setPasswordConfirmation NOTIFY passwordConfirmationChanged)
    Q_PROPERTY(QString errorTitle READ errorTitle NOTIFY errorChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool mockMode READ mockMode WRITE setMockMode NOTIFY mockModeChanged)

public:
    explicit OemSetupController(QObject* parent = nullptr);

    QString displayName() const;
    void setDisplayName(const QString& value);

    QString username() const;

    QString locale() const;
    void setLocale(const QString& value);
    QString localeLabel() const;

    QString password() const;
    void setPassword(const QString& value);

    QString passwordConfirmation() const;
    void setPasswordConfirmation(const QString& value);

    QString errorTitle() const;
    QString errorMessage() const;

    bool busy() const;
    bool mockMode() const;
    void setMockMode(bool value);

    Q_INVOKABLE bool validateNamePage();
    Q_INVOKABLE bool validateLanguagePage();
    Q_INVOKABLE bool validatePasswordPage();
    Q_INVOKABLE bool validateAll();
    Q_INVOKABLE void apply();
    Q_INVOKABLE void clearError();

signals:
    void displayNameChanged();
    void usernameChanged();
    void localeChanged();
    void passwordChanged();
    void passwordConfirmationChanged();
    void errorChanged();
    void busyChanged();
    void mockModeChanged();
    void applySucceeded();
    void applyFailed();

private:
    void setError(const QString& title, const QString& message);
    void setBusy(bool value);

    QString m_displayName;
    QString m_username;
    QString m_locale = QStringLiteral("fi_FI.UTF-8");
    QString m_password;
    QString m_passwordConfirmation;
    QString m_errorTitle;
    QString m_errorMessage;
    bool m_busy = false;
    bool m_mockMode = true;
    QProcess* m_helperProcess = nullptr;
};
