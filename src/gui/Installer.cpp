#include "Installer.h"

#include "Validation.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QTextStream>

namespace {

static int fail(const QString& msg)
{
    QTextStream(stderr) << "oem-setup --install: " << msg << Qt::endl;
    return 1;
}

static QString appBaseDir()
{
    // nix-appimage stores files at Nix store paths, not under $APPDIR/usr/.
    // applicationDirPath() resolves to PREFIX/bin/ in both a CMake install
    // tree and inside a nix-appimage (extracted or FUSE-mounted).
    return QCoreApplication::applicationDirPath() + "/..";
}

static bool copyFile(const QString& src, const QString& dst, QFile::Permissions perms)
{
    if (!QFile::exists(src))
        return fail("source not found: " + src) == 0; // returns false

    QDir().mkpath(QFileInfo(dst).absolutePath());
    QFile::remove(dst);

    if (!QFile::copy(src, dst)) {
        fail("cannot copy " + src + " -> " + dst);
        return false;
    }
    QFile::setPermissions(dst, perms);
    return true;
}

static bool writeFile(const QString& dst, const QString& content, QFile::Permissions perms)
{
    QDir().mkpath(QFileInfo(dst).absolutePath());
    QFile f(dst);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) {
        fail("cannot write " + dst);
        return false;
    }
    QTextStream(&f) << content;
    f.close();
    QFile::setPermissions(dst, perms);
    return true;
}

} // namespace

namespace Installer {

bool isInstalled()
{
    return QFile::exists(QStringLiteral("/usr/libexec/oem-setup/oem-apply.sh"));
}

int install(const QString& setupUser)
{
    if (::getuid() != 0)
        return fail("täytyy ajaa rootina (sudo)");

    if (!OemSetup::validateUsername(setupUser).ok)
        return fail("virheellinen setup-käyttäjänimi: " + setupUser);

    if (!QDir("/home/" + setupUser).exists())
        return fail("kotihakemistoa ei löydy: /home/" + setupUser);

    const QString base = appBaseDir();

    // Install GUI binary (self) to /usr/bin/
    const QString appImagePath = QString::fromLocal8Bit(qgetenv("APPIMAGE"));
    const QString selfPath = appImagePath.isEmpty()
        ? QCoreApplication::applicationFilePath()
        : appImagePath;
    constexpr auto execPerms =
        QFile::ReadOwner | QFile::WriteOwner | QFile::ExeOwner |
        QFile::ReadGroup | QFile::ExeGroup |
        QFile::ReadOther | QFile::ExeOther;
    if (!copyFile(selfPath, "/usr/bin/oem-setup-gui", execPerms))
        return 1;

    // Install scripts
    if (!copyFile(base + "/libexec/oem-setup/oem-apply.sh",
                  "/usr/libexec/oem-setup/oem-apply.sh", execPerms))
        return 1;
    if (!copyFile(base + "/libexec/oem-setup/oem-cleanup.sh",
                  "/usr/libexec/oem-setup/oem-cleanup.sh", execPerms))
        return 1;

    // Polkit policy
    constexpr auto dataPerms =
        QFile::ReadOwner | QFile::WriteOwner |
        QFile::ReadGroup | QFile::ReadOther;
    if (!copyFile(base + "/share/polkit-1/actions/fi.local.oem-setup.policy",
                  "/etc/polkit-1/actions/fi.local.oem-setup.policy", dataPerms))
        return 1;

    // Systemd cleanup service
    if (!copyFile(base + "/lib/systemd/system/oem-cleanup.service",
                  "/usr/lib/systemd/system/oem-cleanup.service", dataPerms))
        return 1;

    // Config
    if (!writeFile("/etc/oem-setup/oem-setup.conf",
                   "setup_user=" + setupUser + "\n"
                   "allowed_locales=fi_FI.UTF-8;sv_SE.UTF-8;en_GB.UTF-8;en_US.UTF-8\n",
                   dataPerms))
        return 1;

    // Autostart for setup user
    // AppImages need --appimage-extract-and-run on systems without FUSE.
    const QString execLine = appImagePath.isEmpty()
        ? QStringLiteral("Exec=/usr/bin/oem-setup-gui")
        : QStringLiteral("Exec=/usr/bin/oem-setup-gui --appimage-extract-and-run");
    const QString autostartDir = "/home/" + setupUser + "/.config/autostart";
    if (!writeFile(autostartDir + "/oem-setup.desktop",
                   "[Desktop Entry]\n"
                   "Type=Application\n"
                   "Name=OEM Setup\n"
                   + execLine + "\n"
                   "X-GNOME-Autostart-enabled=true\n"
                   "NoDisplay=true\n",
                   QFile::ReadOwner | QFile::WriteOwner |
                   QFile::ReadGroup | QFile::ReadOther))
        return 1;

    QProcess::execute("chown", {"-R",
        setupUser + ":" + setupUser,
        "/home/" + setupUser + "/.config"});

    QProcess::execute("systemctl", {"daemon-reload"});

    QTextStream(stdout)
        << "oem-setup: asennus valmis — käynnistä järjestelmä uudelleen." << Qt::endl;
    return 0;
}

} // namespace Installer
