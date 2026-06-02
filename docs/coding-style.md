# Coding Style

This project targets C++20 and Qt 6. Code should be modern, explicit, and
boringly reliable. The style is intentionally a little Rust-like: keep ownership
clear, validate boundaries aggressively, avoid spooky action at a distance, and
make failure states visible in types and names.

## General Principles

- Prefer small, focused types over large utility classes.
- Keep GUI code and privileged system code separate.
- Treat every process, file, distro command, and user input as fallible.
- Validate at trust boundaries even if another layer already validated.
- Prefer simple data flow over clever abstractions.
- Avoid hidden global state. If something is configuration, pass it explicitly.
- Do not make QML responsible for privileged behavior or security decisions.

## C++ Version

Use C++20 as the baseline.

Good default tools:

- `std::optional` for absent values.
- `std::variant` for small closed sets of alternatives.
- `std::span` for borrowed contiguous ranges.
- `std::string_view` where useful in non-Qt-only code.
- `enum class` for all enums.
- designated initializers for simple aggregate config structs.
- structured bindings when they improve readability.
- `[[nodiscard]]` for functions where ignored results are suspicious.

Avoid newer-than-C++20 features unless the project baseline is intentionally
raised.

## Qt Types

Use Qt types at Qt boundaries:

- `QString`, `QStringView`, `QByteArray`
- `QFile`, `QSaveFile`
- `QJsonDocument`, `QJsonObject`
- `QObject` and signals/slots for GUI-facing state

Use standard C++ types in backend logic when Qt does not add value. Do not fight
Qt in GUI code just to look more standard-library-like.

## Naming

- Types: `PascalCase`
- Functions and variables: `camelCase`
- Private members: `m_name`
- Constants: `kName` or local `const`/`constexpr`
- Namespaces: `PascalCase` for project namespaces, for example `OemSetup`
- Files: match the primary type, for example `OemSetupController.cpp`

Names should describe domain meaning, not implementation trivia.

Prefer:

```cpp
const auto validation = validateUsername(username);
```

Avoid:

```cpp
const auto res = check(str);
```

## Ownership

Make ownership obvious.

- Prefer values for small data structures.
- Use references for non-owning required objects.
- Use pointers only when null is meaningful or Qt ownership requires it.
- Use `std::unique_ptr` for exclusive ownership outside QObject trees.
- Avoid `std::shared_ptr` unless shared lifetime is genuinely necessary.
- For `QObject` hierarchies, use Qt parent ownership consistently.

Never store raw pointers whose lifetime is unclear. If a pointer is non-owning,
make that clear in naming or surrounding structure.

## Error Handling

Do not represent meaningful failure as a bare `bool` if callers need to know
why it failed.

Use small result structs for project code:

```cpp
struct ValidationResult {
    bool ok = false;
    QString message;
};
```

For helper/backend code, prefer typed outcomes:

```cpp
enum class ApplyError {
    InvalidRequest,
    UserAlreadyExists,
    UserCreationFailed,
    PasswordUpdateFailed,
    CleanupInstallFailed,
};
```

Rules:

- Include actionable log detail for operators.
- Show calm, consumer-safe messages in the GUI.
- Do not leak passwords, hashes, or raw command payloads to logs.
- Do not continue after a failed critical cleanup step unless retry behavior is
  explicitly designed.

## Validation

Validation happens twice:

1. GUI validation for immediate user feedback.
2. Helper validation for security.

The helper is the source of truth. GUI validation must never be considered a
security boundary.

Keep allowlists small and explicit for first-boot scope:

- supported locales
- supported display managers
- allowed helper commands
- known distro adapter families

## Root Helper Rules

The root helper must stay small and auditable.

- No GUI code.
- No QML dependency.
- No shell command construction with untrusted string interpolation.
- Passwords are never passed as command-line arguments.
- Revalidate every field before changing the system.
- Prefer atomic writes for config files.
- Keep rollback behavior explicit and tested.
- Cleanup must remove autologin before removing the setup user.

When invoking system tools, prefer direct argument arrays via `QProcess` or
equivalent APIs. Avoid shell evaluation.

## QML Rules

QML owns presentation and light interaction flow only.

- Keep page components focused.
- Put shared controls in `qml/components`.
- Put wizard pages in `qml/pages`.
- Do not duplicate security validation in QML expressions.
- Bind to C++ controller properties for app state.
- Avoid complex JavaScript blocks.
- Avoid hidden behavior in animations.

Animations should be subtle and short. The wizard should feel calm and fast, not
performative.

## Formatting

Use the existing formatting style in the repository.

C++ defaults:

- 4 spaces, no tabs.
- Opening braces on the same line for functions, classes, and control blocks.
- Keep lines reasonably short, but do not contort readable code.
- Include order:
  1. matching header
  2. project headers
  3. Qt headers
  4. standard library headers
- Prefer early returns over deep nesting.

Example:

```cpp
ValidationResult validateLocale(const QString& locale)
{
    if (!allowedLocales().contains(locale)) {
        return {false, QStringLiteral("Tuntematon kielivalinta.")};
    }

    return {true, {}};
}
```

QML defaults:

- 4 spaces, no tabs.
- One component per file.
- Keep reusable visual controls in `components`.
- Keep page-level layout in `pages`.
- Prefer named properties over magic repeated literals.

## Comments

Comments should explain why, not narrate what the next line says.

Good:

```cpp
// Autologin must be removed first; otherwise a failed cleanup can leave a login loop.
```

Bad:

```cpp
// Remove autologin.
```

Security-sensitive ordering deserves comments. Ordinary syntax does not.

## Tests And Checks

Every non-trivial backend change should have one of:

- a unit test,
- a script or validation test,
- a VM/manual test note in `docs/test-matrix.md`.

Before handing off changes, run:

```bash
nix develop -c just check
```

For GUI-only changes, build verification is the minimum. When a display-capable
test environment is available, also launch:

```bash
nix develop -c just run
```

## Things To Avoid

- Passing passwords through argv.
- Shelling out through `/bin/sh -c` with user-controlled data.
- Letting GUI code mutate `/etc`, users, groups, systemd, or display-manager
  config directly.
- Adding distro-specific hacks outside adapter classes.
- Swallowing errors with `|| true` in new C++ logic.
- Adding broad abstractions before there are at least two real users for them.
- Making the first-boot flow longer than necessary.
