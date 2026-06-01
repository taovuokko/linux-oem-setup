#include "HelperOps.h"

#include "Validation.h"

#include <QFile>
#include <QProcess>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTextStream>

namespace OemSetup {
namespace {

int fail(const QString& message)
{
    QTextStream(stderr) << "oem-setup-helper: " << message << Qt::endl;
    return 1;
}

bool createUser(const QString& username, const QString& displayName, const SystemOps& ops)
{
    if (!QStandardPaths::findExecutable(QStringLiteral("adduser")).isEmpty()) {
        if (ops.run(QStringLiteral("adduser"), {
                QStringLiteral("--gecos"), displayName,
                QStringLiteral("--disabled-password"),
                username})) {
            return true;
        }
    }
    return ops.run(QStringLiteral("useradd"), {
        QStringLiteral("-m"),
        QStringLiteral("-c"), displayName,
        QStringLiteral("-s"), QStringLiteral("/bin/bash"),
        username});
}

bool addToSudoGroup(const QString& username, const SystemOps& ops)
{
    const auto groupExists = [&ops](const QString& group) {
        return ops.run(QStringLiteral("getent"), {QStringLiteral("group"), group});
    };

    QString group;
    if (groupExists(QStringLiteral("sudo"))) {
        group = QStringLiteral("sudo");
    } else if (groupExists(QStringLiteral("wheel"))) {
        group = QStringLiteral("wheel");
    } else {
        QTextStream(stderr) << "oem-setup-helper: sudo/wheel-ryhmää ei löydy, ohitetaan" << Qt::endl;
        return true;
    }
    return ops.run(QStringLiteral("usermod"), {QStringLiteral("-aG"), group, username});
}

bool setLocale(const QString& locale, const SystemOps& ops)
{
    // Generate locale first if available (Debian/Ubuntu, Arch)
    if (!QStandardPaths::findExecutable(QStringLiteral("locale-gen")).isEmpty()) {
        ops.run(QStringLiteral("locale-gen"), {locale}); // non-fatal
    }

    if (!QStandardPaths::findExecutable(QStringLiteral("localectl")).isEmpty()) {
        return ops.run(QStringLiteral("localectl"), {
            QStringLiteral("set-locale"), QStringLiteral("LANG=") + locale});
    }

    if (!QStandardPaths::findExecutable(QStringLiteral("update-locale")).isEmpty()) {
        return ops.run(QStringLiteral("update-locale"), {QStringLiteral("LANG=") + locale});
    }

    QTextStream(stderr) << "oem-setup-helper: localectl/update-locale ei saatavilla" << Qt::endl;
    return false;
}

void rollbackUser(const QString& username, const SystemOps& ops)
{
    QTextStream(stderr) << "oem-setup-helper: käyttöönotto epäonnistui, poistetaan " << username << Qt::endl;
    ops.run(QStringLiteral("pkill"), {QStringLiteral("-u"), username});
    ops.run(QStringLiteral("loginctl"), {QStringLiteral("terminate-user"), username});
    ops.run(QStringLiteral("userdel"), {QStringLiteral("-r"), username});
    ops.run(QStringLiteral("groupdel"), {username});
}

bool removeAutologin(const SystemOps& ops)
{
    bool ok = true;

    ok &= ops.filterLines(QStringLiteral("/etc/lightdm/lightdm.conf"), {
        QStringLiteral("autologin-user="),
        QStringLiteral("autologin-user-timeout="),
    });
    ok &= ops.removeFile(QStringLiteral("/etc/lightdm/lightdm.conf.d/50-oem-autologin.conf"));

    for (const QString& path : {
            QStringLiteral("/etc/gdm3/custom.conf"),
            QStringLiteral("/etc/gdm/custom.conf")}) {
        ok &= ops.filterLines(path, {
            QStringLiteral("AutomaticLoginEnable="),
            QStringLiteral("AutomaticLogin="),
        });
    }

    ok &= ops.removeFile(QStringLiteral("/etc/sddm.conf.d/oem-autologin.conf"));

    return ok;
}

} // namespace

int validateRequest(const QJsonObject& request)
{
    const QString displayName = request.value(QStringLiteral("displayName")).toString();
    const QString username    = request.value(QStringLiteral("username")).toString();
    const QString locale      = request.value(QStringLiteral("locale")).toString();

    const auto nameResult = validateDisplayName(displayName);
    if (!nameResult.ok) return fail(nameResult.message);

    const auto usernameResult = validateUsername(username);
    if (!usernameResult.ok) return fail(usernameResult.message);

    const auto localeResult = validateLocale(locale);
    if (!localeResult.ok) return fail(localeResult.message);

    return 0;
}

SystemOps realSystemOps()
{
    return {
        .run = [](const QString& program, const QStringList& args) -> bool {
            QProcess proc;
            proc.setProcessChannelMode(QProcess::MergedChannels);
            proc.start(program, args);
            proc.waitForFinished(30000);
            return proc.exitStatus() == QProcess::NormalExit && proc.exitCode() == 0;
        },
        .setPassword = [](const QString& username, const QString& password) -> bool {
            QProcess proc;
            proc.start(QStringLiteral("chpasswd"), {});
            if (!proc.waitForStarted(5000)) return false;
            // chpasswd reads "username:password\n" from stdin — password never touches argv
            proc.write((username + u':' + password + u'\n').toUtf8());
            proc.closeWriteChannel();
            proc.waitForFinished(10000);
            return proc.exitStatus() == QProcess::NormalExit && proc.exitCode() == 0;
        },
        .filterLines = [](const QString& path, const QStringList& prefixesToRemove) -> bool {
            QFile file(path);
            if (!file.exists()) return true;
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return false;

            QStringList kept;
            QTextStream in(&file);
            while (!in.atEnd()) {
                const QString line = in.readLine();
                const QString trimmed = line.trimmed();
                bool remove = false;
                for (const QString& prefix : prefixesToRemove) {
                    if (trimmed.startsWith(prefix)) { remove = true; break; }
                }
                if (!remove) kept.append(line);
            }
            file.close();

            QSaveFile out(path);
            if (!out.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
            QTextStream stream(&out);
            for (const QString& line : kept) stream << line << u'\n';
            return out.commit();
        },
        .removeFile = [](const QString& path) -> bool {
            return !QFile::exists(path) || QFile::remove(path);
        },
    };
}

int doApply(const QJsonObject& request, const SystemOps& ops)
{
    if (const int status = validateRequest(request); status != 0) return status;

    const QString displayName = request.value(QStringLiteral("displayName")).toString();
    const QString username    = request.value(QStringLiteral("username")).toString();
    const QString locale      = request.value(QStringLiteral("locale")).toString();
    const QString password    = request.value(QStringLiteral("password")).toString();

    if (password.isEmpty() || password.contains(u'\n') || password.contains(u'\r'))
        return fail(QStringLiteral("Salasana puuttuu tai sisältää virheellisiä merkkejä."));

    // id returns 0 if the user exists
    if (ops.run(QStringLiteral("id"), {username}))
        return fail(QStringLiteral("Käyttäjä on jo olemassa: ") + username);

    if (!createUser(username, displayName, ops))
        return fail(QStringLiteral("Käyttäjän luominen epäonnistui."));

    if (!ops.setPassword(username, password)) {
        rollbackUser(username, ops);
        return fail(QStringLiteral("Salasanan asettaminen epäonnistui."));
    }

    if (!addToSudoGroup(username, ops)) {
        rollbackUser(username, ops);
        return fail(QStringLiteral("Käyttäjän lisääminen sudo-ryhmään epäonnistui."));
    }

    if (!setLocale(locale, ops)) {
        rollbackUser(username, ops);
        return fail(QStringLiteral("Kielen asettaminen epäonnistui."));
    }

    // Enable cleanup service before removing autologin so the cleanup can
    // retry autologin removal on next boot if the step below fails.
    if (!ops.run(QStringLiteral("systemctl"), {QStringLiteral("enable"), QStringLiteral("oem-cleanup.service")})) {
        rollbackUser(username, ops);
        return fail(QStringLiteral("Cleanup-palvelun aktivointi epäonnistui."));
    }

    if (!removeAutologin(ops)) {
        QTextStream(stderr) << "oem-setup-helper: varoitus: autologinin poisto epäonnistui osin, "
                               "cleanup-palvelu yrittää uudelleen seuraavalla bootilla" << Qt::endl;
    }

    QTextStream(stdout) << "ok" << Qt::endl;
    return 0;
}

int doCleanup(const QString& setupUser, const SystemOps& ops)
{
    // Phase 1: Remove autologin first. Exit with failure if it doesn't clear —
    // systemd will retry this unit on the next boot, which is safer than
    // leaving a login loop without a valid user.
    if (!removeAutologin(ops))
        return fail(QStringLiteral("Autologinin poisto epäonnistui — yritetään uudelleen seuraavalla bootilla."));

    // Phase 2: Remove setup user (only after autologin is confirmed gone).
    // kill-user + terminate-user flush any lingering systemd user session.
    // --force on userdel removes the account even if systemd still tracks it.
    ops.run(QStringLiteral("loginctl"), {QStringLiteral("disable-linger"), setupUser});
    ops.run(QStringLiteral("loginctl"), {QStringLiteral("kill-user"), setupUser});
    ops.run(QStringLiteral("loginctl"), {QStringLiteral("terminate-user"), setupUser});
    ops.run(QStringLiteral("pkill"), {QStringLiteral("-9"), QStringLiteral("-u"), setupUser});
    ops.run(QStringLiteral("userdel"), {QStringLiteral("--force"), QStringLiteral("-r"), setupUser});
    ops.run(QStringLiteral("groupdel"), {setupUser});

    if (ops.run(QStringLiteral("id"), {setupUser}))
        return fail(QStringLiteral("Setup-käyttäjän poisto epäonnistui."));

    // Phase 3: Remove remaining OEM files
    ops.removeFile(QStringLiteral("/etc/sudoers.d/oem-setup"));
    ops.removeFile(QStringLiteral("/etc/oem-setup/oem-setup.conf"));
    ops.removeFile(QStringLiteral("/etc/polkit-1/actions/fi.local.oem-setup.policy"));
    ops.removeFile(QStringLiteral("/var/lib/AccountsService/users/") + setupUser);

    // Phase 4: Disable and remove the cleanup service itself
    ops.run(QStringLiteral("systemctl"), {QStringLiteral("disable"), QStringLiteral("oem-cleanup.service")});
    ops.removeFile(QStringLiteral("/usr/lib/systemd/system/oem-cleanup.service"));
    ops.run(QStringLiteral("systemctl"), {QStringLiteral("daemon-reload")});

    return 0;
}

} // namespace OemSetup
