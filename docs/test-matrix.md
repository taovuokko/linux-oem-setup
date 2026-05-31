# Test Matrix

## Distros

- Debian and Ubuntu family
- Fedora family
- Arch family: Arch, EndeavourOS, CachyOS, Manjaro, Garuda

## Display Managers

- LightDM
- GDM and GDM3
- SDDM

## Failure Cases

- Target username already exists.
- Locale generation fails.
- Cleanup service cannot remove autologin.
- Cleanup service cannot remove setup user.
- Reboot happens after apply but before cleanup succeeds.
