#pragma once

#include <QJsonObject>
#include <QString>
#include <QStringList>
#include <functional>

namespace OemSetup {

struct SystemOps {
    // General process runner — never passes passwords through args
    std::function<bool(const QString& program, const QStringList& args)> run;
    // Password setter — uses stdin pipe, not args
    std::function<bool(const QString& username, const QString& password)> setPassword;
    // Atomic line filter for ini-style config files
    std::function<bool(const QString& path, const QStringList& prefixesToRemove)> filterLines;
    std::function<bool(const QString& path)> removeFile;
};

[[nodiscard]] SystemOps realSystemOps();
[[nodiscard]] int validateRequest(const QJsonObject& request);
[[nodiscard]] int doApply(const QJsonObject& request, const SystemOps& ops);
[[nodiscard]] int doCleanup(const QString& setupUser, const SystemOps& ops);

} // namespace OemSetup
