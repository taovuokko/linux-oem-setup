# Development

This project is developed with a project-local Nix shell.

```bash
nix develop
just build
just run
just check
```

Do not rely on host C++ headers or libraries. Add C++ and Qt dependencies to
`flake.nix` and link them in CMake.

The first GUI milestone uses a mock backend. Production root behavior belongs in
`src/helper`, not in QML or GUI controller code.

Coding and formatting rules are documented in `docs/coding-style.md`.
