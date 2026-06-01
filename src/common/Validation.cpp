#include "Validation.h"

#include <QRegularExpression>
#include <QStringList>

namespace OemSetup {
namespace {

QString trimName(const QString& value)
{
    return QString(value).trimmed();
}

QString stripCombiningMarks(const QString& value)
{
    QString output;
    const QString normalized = value.normalized(QString::NormalizationForm_D);
    output.reserve(normalized.size());

    for (const QChar ch : normalized) {
        const auto category = ch.category();
        if (category != QChar::Mark_NonSpacing &&
            category != QChar::Mark_SpacingCombining &&
            category != QChar::Mark_Enclosing) {
            output.append(ch);
        }
    }

    return output;
}

} // namespace

QString deriveUsername(const QString& displayName)
{
    const QString firstWord = trimName(displayName).section(QRegularExpression("\\s+"), 0, 0);
    QString ascii = stripCombiningMarks(firstWord).toLower();

    ascii.replace(u'ä', "a");
    ascii.replace(u'å', "a");
    ascii.replace(u'ö', "o");
    ascii.replace(u'æ', "ae");
    ascii.replace(u'ø', "o");
    ascii.replace(u'ß', "ss");

    QString username;
    username.reserve(ascii.size());
    for (const QChar ch : ascii) {
        if ((ch >= u'a' && ch <= u'z') ||
            (ch >= u'0' && ch <= u'9') ||
            ch == u'_' ||
            ch == u'-') {
            username.append(ch);
        }
    }

    return username.left(32);
}

ValidationResult validateDisplayName(const QString& displayName)
{
    const QString trimmed = trimName(displayName);
    if (trimmed.isEmpty()) {
        return {false, QStringLiteral("Kirjoita nimi.")};
    }
    if (trimmed.contains(u':')) {
        return {false, QStringLiteral("Nimessä ei voi olla kaksoispistettä.")};
    }

    for (const QChar ch : trimmed) {
        const auto category = ch.category();
        if (ch.isNull() ||
            category == QChar::Other_Control ||
            category == QChar::Other_Format ||
            category == QChar::Separator_Line ||
            category == QChar::Separator_Paragraph) {
            return {false, QStringLiteral("Nimi sisältää näkymättömiä tai ohjausmerkkejä.")};
        }
    }

    return {true, {}};
}

ValidationResult validateUsername(const QString& username)
{
    static const QRegularExpression pattern(QStringLiteral("^[a-z][a-z0-9_-]{0,31}$"));
    if (!pattern.match(username).hasMatch()) {
        return {false, QStringLiteral("Käyttäjätunnuksen täytyy alkaa kirjaimella ja olla enintään 32 merkkiä.")};
    }
    return {true, {}};
}

ValidationResult validateLocale(const QString& locale)
{
    static const QStringList allowed = {
        QStringLiteral("fi_FI.UTF-8"),
        QStringLiteral("sv_SE.UTF-8"),
        QStringLiteral("en_GB.UTF-8"),
        QStringLiteral("en_US.UTF-8"),
    };

    if (!allowed.contains(locale)) {
        return {false, QStringLiteral("Tuntematon kielivalinta.")};
    }
    return {true, {}};
}

} // namespace OemSetup
