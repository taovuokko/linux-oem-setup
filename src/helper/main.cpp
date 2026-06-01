#include "HelperOps.h"
#include "Validation.h"

#include <QCoreApplication>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTextStream>

namespace {

static const QString kConfigPath = QStringLiteral("/etc/oem-setup/oem-setup.conf");

int fail(const QString& message)
{
    QTextStream(stderr) << "oem-setup-helper: " << message << Qt::endl;
    return 1;
}

QString loadSetupUser()
{
    QString setupUser = QStringLiteral("setup");
    QFile file(kConfigPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return setupUser;
    }

    QTextStream stream(&file);
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        if (line.startsWith(u'#') || !line.contains(u'=')) continue;
        const int sep = line.indexOf(u'=');
        if (line.left(sep).trimmed() == QStringLiteral("setup_user")) {
            const QString candidate = line.mid(sep + 1).trimmed();
            if (OemSetup::validateUsername(candidate).ok)
                setupUser = candidate;
            break;
        }
    }
    return setupUser;
}

} // namespace

int main(int argc, char* argv[])
{
    QCoreApplication app(argc, argv);
    const QStringList args = app.arguments();

    if (args.contains(QStringLiteral("cleanup"))) {
        return OemSetup::doCleanup(loadSetupUser(), OemSetup::realSystemOps());
    }

    const bool validateOnly = args.contains(QStringLiteral("--validate-only"));

    QFile input;
    if (!input.open(stdin, QIODevice::ReadOnly)) {
        return fail(QStringLiteral("Stdinin lukeminen epäonnistui."));
    }
    const QByteArray payload = input.readAll();
    if (payload.size() > 4096)
        return fail(QStringLiteral("Pyyntö on liian suuri."));

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(payload, &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        return fail(QStringLiteral("Pyyntö ei ole kelvollista JSON-dataa."));
    }

    if (validateOnly) {
        const int status = OemSetup::validateRequest(document.object());
        if (status == 0) QTextStream(stdout) << "ok" << Qt::endl;
        return status;
    }

    return OemSetup::doApply(document.object(), OemSetup::realSystemOps());
}
