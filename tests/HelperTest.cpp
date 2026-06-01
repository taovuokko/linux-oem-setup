#include "HelperOps.h"

#include <QJsonObject>
#include <QTest>

// Recording harness — captures every ops call so tests can make assertions
// about call sequence, arguments, and security invariants.
struct RecordedCall {
    QString program;
    QStringList args;
};

struct Recorder {
    QList<RecordedCall> calls;
    QStringList passwordsReceived;
    QMap<QString, bool> failOn; // program name → fail this call
    QSet<QString> failOnRemovePaths; // file path → fail removeFile for this path

    // Default: id("username") returns false (user doesn't exist)
    bool idReturnsUserExists = false;

    OemSetup::SystemOps makeOps()
    {
        return {
            .run = [this](const QString& prog, const QStringList& args) -> bool {
                calls.append({prog, args});
                if (failOn.value(prog, false)) return false;
                // "id" returning false means the user does NOT exist — that's
                // the normal pre-creation state. Override idReturnsUserExists
                // to simulate an already-existing user or a failed removal.
                if (prog == QStringLiteral("id")) return idReturnsUserExists;
                return true;
            },
            .setPassword = [this](const QString& /*username*/, const QString& password) -> bool {
                passwordsReceived.append(password);
                return !failOn.value(QStringLiteral("chpasswd"), false);
            },
            .filterLines = [this](const QString& path, const QStringList& /*prefixes*/) -> bool {
                calls.append({QStringLiteral("filterLines"), {path}});
                return !failOn.value(QStringLiteral("filterLines"), false);
            },
            .removeFile = [this](const QString& path) -> bool {
                calls.append({QStringLiteral("removeFile"), {path}});
                return !failOnRemovePaths.contains(path);
            },
        };
    }

    bool wasCalled(const QString& prog) const
    {
        return std::any_of(calls.cbegin(), calls.cend(),
            [&prog](const RecordedCall& c) { return c.program == prog; });
    }

    bool removedPath(const QString& path) const
    {
        return std::any_of(calls.cbegin(), calls.cend(),
            [&path](const RecordedCall& c) {
                return c.program == QStringLiteral("removeFile") && c.args.contains(path);
            });
    }

    bool passwordWasInAnyArg() const
    {
        if (passwordsReceived.isEmpty()) return false;
        for (const QString& pw : passwordsReceived) {
            for (const RecordedCall& c : calls) {
                if (c.args.contains(pw)) return true;
            }
        }
        return false;
    }
};

static QJsonObject validRequest(const QString& password = QStringLiteral("salainen"))
{
    QJsonObject obj;
    obj[QStringLiteral("displayName")] = QStringLiteral("Matti Meikäläinen");
    obj[QStringLiteral("username")]    = QStringLiteral("matti");
    obj[QStringLiteral("locale")]      = QStringLiteral("fi_FI.UTF-8");
    obj[QStringLiteral("password")]    = password;
    return obj;
}

class HelperTest : public QObject {
    Q_OBJECT

private slots:
    // --- validateRequest ---
    void validateRequest_acceptsValidInput();
    void validateRequest_rejectsEmptyName();
    void validateRequest_rejectsUnknownLocale();

    // --- doApply ---
    void apply_callsUserCreation();
    void apply_callsLocaleAndService();
    void apply_passwordNeverInArgs();
    void apply_rollbackOnPasswordFailure();
    void apply_rollbackOnGroupFailure();
    void apply_rollbackOnLocaleFailure();
    void apply_rollbackOnServiceFailure();
    void apply_noRollbackAfterServiceEnabled();
    void apply_rejectsExistingUser();
    void apply_rejectsEmptyPassword();
    void apply_rejectsPasswordWithNewline();

    // --- doCleanup ---
    void cleanup_removesAutologinBeforeUser();
    void cleanup_failsAndRetainsUserWhenAutologinStuck();
    void cleanup_failsAndRetainsUserWhenDropInRemovalFails();
    void cleanup_disablesServiceAtEnd();
    void cleanup_removesAccountsServiceProfile();
};

// --- validateRequest ---

void HelperTest::validateRequest_acceptsValidInput()
{
    QCOMPARE(OemSetup::validateRequest(validRequest()), 0);
}

void HelperTest::validateRequest_rejectsEmptyName()
{
    QJsonObject req = validRequest();
    req[QStringLiteral("displayName")] = QStringLiteral("");
    QVERIFY(OemSetup::validateRequest(req) != 0);
}

void HelperTest::validateRequest_rejectsUnknownLocale()
{
    QJsonObject req = validRequest();
    req[QStringLiteral("locale")] = QStringLiteral("xx_XX.UTF-8");
    QVERIFY(OemSetup::validateRequest(req) != 0);
}

// --- doApply ---

void HelperTest::apply_callsUserCreation()
{
    Recorder rec;
    const int result = OemSetup::doApply(validRequest(), rec.makeOps());
    QCOMPARE(result, 0);
    // Either adduser or useradd must have been invoked
    QVERIFY(rec.wasCalled(QStringLiteral("adduser")) || rec.wasCalled(QStringLiteral("useradd")));
}

void HelperTest::apply_callsLocaleAndService()
{
    Recorder rec;
    QCOMPARE(OemSetup::doApply(validRequest(), rec.makeOps()), 0);
    // Locale tool (localectl or update-locale) must have been invoked
    QVERIFY(rec.wasCalled(QStringLiteral("localectl")) || rec.wasCalled(QStringLiteral("update-locale")));
    // Cleanup service must have been enabled
    QVERIFY(rec.wasCalled(QStringLiteral("systemctl")));
}

void HelperTest::apply_passwordNeverInArgs()
{
    Recorder rec;
    QCOMPARE(OemSetup::doApply(validRequest(QStringLiteral("supersecret")), rec.makeOps()), 0);
    QVERIFY(!rec.passwordWasInAnyArg());
}

void HelperTest::apply_rollbackOnPasswordFailure()
{
    Recorder rec;
    rec.failOn[QStringLiteral("chpasswd")] = true;
    QVERIFY(OemSetup::doApply(validRequest(), rec.makeOps()) != 0);
    QVERIFY(rec.wasCalled(QStringLiteral("userdel")));
}

void HelperTest::apply_rollbackOnGroupFailure()
{
    Recorder rec;
    rec.failOn[QStringLiteral("usermod")] = true;
    QVERIFY(OemSetup::doApply(validRequest(), rec.makeOps()) != 0);
    QVERIFY(rec.wasCalled(QStringLiteral("userdel")));
}

void HelperTest::apply_rollbackOnLocaleFailure()
{
    // Simulate no locale tool available and localectl failing
    Recorder rec;
    rec.failOn[QStringLiteral("localectl")]     = true;
    rec.failOn[QStringLiteral("update-locale")] = true;
    QVERIFY(OemSetup::doApply(validRequest(), rec.makeOps()) != 0);
    QVERIFY(rec.wasCalled(QStringLiteral("userdel")));
}

void HelperTest::apply_rollbackOnServiceFailure()
{
    Recorder rec;
    rec.failOn[QStringLiteral("systemctl")] = true;
    QVERIFY(OemSetup::doApply(validRequest(), rec.makeOps()) != 0);
    QVERIFY(rec.wasCalled(QStringLiteral("userdel")));
}

void HelperTest::apply_noRollbackAfterServiceEnabled()
{
    // After systemctl enable succeeds, autologin removal failing must NOT
    // trigger rollback — cleanup service handles it on next boot.
    Recorder rec;
    rec.failOn[QStringLiteral("filterLines")] = true;
    // systemctl returns true, so service is enabled
    const int result = OemSetup::doApply(validRequest(), rec.makeOps());
    // Apply succeeds (returns 0) despite autologin removal warning
    QCOMPARE(result, 0);
    // No rollback
    QVERIFY(!rec.wasCalled(QStringLiteral("userdel")));
}

void HelperTest::apply_rejectsExistingUser()
{
    Recorder rec;
    rec.idReturnsUserExists = true;
    QVERIFY(OemSetup::doApply(validRequest(), rec.makeOps()) != 0);
    // No user creation should have been attempted
    QVERIFY(!rec.wasCalled(QStringLiteral("useradd")));
    QVERIFY(!rec.wasCalled(QStringLiteral("adduser")));
}

void HelperTest::apply_rejectsEmptyPassword()
{
    Recorder rec;
    QVERIFY(OemSetup::doApply(validRequest(QStringLiteral("")), rec.makeOps()) != 0);
}

void HelperTest::apply_rejectsPasswordWithNewline()
{
    Recorder rec;
    QVERIFY(OemSetup::doApply(validRequest(QStringLiteral("pass\nword")), rec.makeOps()) != 0);
}

// --- doCleanup ---

void HelperTest::cleanup_removesAutologinBeforeUser()
{
    Recorder rec;
    QCOMPARE(OemSetup::doCleanup(QStringLiteral("setup"), rec.makeOps()), 0);

    // filterLines must appear before userdel in the call sequence
    int filterIdx = -1, userdelIdx = -1;
    for (int i = 0; i < rec.calls.size(); ++i) {
        if (rec.calls[i].program == QStringLiteral("filterLines") && filterIdx == -1)
            filterIdx = i;
        if (rec.calls[i].program == QStringLiteral("userdel"))
            userdelIdx = i;
    }
    QVERIFY(filterIdx != -1);
    QVERIFY(userdelIdx != -1);
    QVERIFY(filterIdx < userdelIdx);
}

void HelperTest::cleanup_failsAndRetainsUserWhenAutologinStuck()
{
    Recorder rec;
    rec.failOn[QStringLiteral("filterLines")] = true;
    QVERIFY(OemSetup::doCleanup(QStringLiteral("setup"), rec.makeOps()) != 0);
    // userdel must NOT have been called — user is retained for safety
    QVERIFY(!rec.wasCalled(QStringLiteral("userdel")));
}

void HelperTest::cleanup_failsAndRetainsUserWhenDropInRemovalFails()
{
    // If the drop-in config file (e.g. SDDM or LightDM) cannot be removed,
    // cleanup must abort before deleting the setup user — otherwise the
    // display manager would autologin to a deleted user on next boot.
    Recorder rec;
    rec.failOnRemovePaths.insert(
        QStringLiteral("/etc/lightdm/lightdm.conf.d/50-oem-autologin.conf"));
    QVERIFY(OemSetup::doCleanup(QStringLiteral("setup"), rec.makeOps()) != 0);
    QVERIFY(!rec.wasCalled(QStringLiteral("userdel")));
}

void HelperTest::cleanup_disablesServiceAtEnd()
{
    Recorder rec;
    QCOMPARE(OemSetup::doCleanup(QStringLiteral("setup"), rec.makeOps()), 0);
    // systemctl disable must appear after userdel
    int userdelIdx = -1, sysctlIdx = -1;
    for (int i = 0; i < rec.calls.size(); ++i) {
        if (rec.calls[i].program == QStringLiteral("userdel"))
            userdelIdx = i;
        if (rec.calls[i].program == QStringLiteral("systemctl") &&
                rec.calls[i].args.contains(QStringLiteral("disable")))
            sysctlIdx = i;
    }
    QVERIFY(userdelIdx != -1);
    QVERIFY(sysctlIdx != -1);
    QVERIFY(userdelIdx < sysctlIdx);
}

void HelperTest::cleanup_removesAccountsServiceProfile()
{
    Recorder rec;
    QCOMPARE(OemSetup::doCleanup(QStringLiteral("setup"), rec.makeOps()), 0);
    QVERIFY(rec.removedPath(
        QStringLiteral("/var/lib/AccountsService/users/setup")));
}

QTEST_MAIN(HelperTest)
#include "HelperTest.moc"
