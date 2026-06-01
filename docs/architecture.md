# Architecture

The next-generation OEM setup is split into an unprivileged Qt/QML GUI and a
small privileged helper.

## Components

- `/usr/bin/oem-setup-gui`: first-boot wizard shown in the setup user's session.
- `/usr/libexec/oem-setup/oem-setup-helper`: root-owned helper executed through
  polkit.
- `/etc/oem-setup/config`: installer-written runtime configuration.
- `/usr/lib/systemd/system/oem-cleanup.service`: retryable cleanup unit.

The GUI never performs root operations. It collects the display name, derived
username, locale, and password, validates them early, and asks the helper to
apply the final state. The helper validates every field again before touching
the system.

## Milestones

1. Qt/QML wizard with mock backend.
2. Helper protocol and validation.
3. Port current apply and cleanup behavior into C++.
4. Add distro and display-manager adapters.
5. Package as deb, rpm, and PKGBUILD.
