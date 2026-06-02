#!/bin/bash
# Runs as root via systemd. Removes autologin config, deletes the OEM setup
# user, and removes remaining OEM files. On autologin removal failure the
# service exits non-zero so systemd retries it on the next boot.
set -euo pipefail

die() { echo "oem-cleanup: $*" >&2; exit 1; }

# Read setup user from config (default: setup)
SETUP_USER="setup"
CONFIG=/etc/oem-setup/oem-setup.conf
if [[ -f "$CONFIG" ]]; then
    val=$(grep '^setup_user=' "$CONFIG" | cut -d= -f2- || true)
    [[ -n "$val" ]] && SETUP_USER="$val"
fi

# Remove lines starting with given prefixes from a config file (in-place).
# Returns 0 if file doesn't exist.
# Uses cat-redirect instead of mv so SELinux context and ownership are preserved.
filter_file() {
    local file="$1"; shift
    [[ -f "$file" ]] || return 0
    local tmp sed_expr=""
    tmp=$(mktemp) || return 1
    for prefix in "$@"; do
        sed_expr="${sed_expr}/^[[:blank:]]*${prefix}/d;"
    done
    if ! sed "$sed_expr" "$file" > "$tmp"; then
        rm -f "$tmp"; return 1
    fi
    cat "$tmp" > "$file"; local rc=$?
    rm -f "$tmp"
    return $rc
}

remove_autologin() {
    filter_file /etc/lightdm/lightdm.conf \
        "autologin-user=" "autologin-user-timeout=" || return 1
    rm -f /etc/lightdm/lightdm.conf.d/50-oem-autologin.conf
    filter_file /etc/gdm3/custom.conf "AutomaticLoginEnable=" "AutomaticLogin=" || return 1
    filter_file /etc/gdm/custom.conf  "AutomaticLoginEnable=" "AutomaticLogin=" || return 1
    rm -f /etc/sddm.conf.d/oem-autologin.conf
}

# Phase 1: Remove autologin first — exit non-zero to trigger systemd retry
# if it fails, rather than risk a login loop to a deleted user.
remove_autologin \
    || die "autologinin poisto epäonnistui — yritetään uudelleen seuraavalla bootilla"

# Phase 2: Remove setup user (flush lingering session first)
loginctl disable-linger  "$SETUP_USER" 2>/dev/null || true
loginctl kill-user        "$SETUP_USER" 2>/dev/null || true
loginctl terminate-user   "$SETUP_USER" 2>/dev/null || true
pkill -9 -u "$SETUP_USER" 2>/dev/null || true
userdel --force -r "$SETUP_USER" 2>/dev/null || true
groupdel "$SETUP_USER" 2>/dev/null || true

if id "$SETUP_USER" &>/dev/null; then
    die "setup-käyttäjän poisto epäonnistui"
fi

# Phase 3: Remove remaining OEM files
rm -f /etc/sudoers.d/oem-setup
rm -f /etc/oem-setup/oem-setup.conf
rm -f /etc/polkit-1/actions/fi.local.oem-setup.policy
rm -f "/var/lib/AccountsService/users/$SETUP_USER"

# Phase 4: Disable and remove the cleanup service itself
systemctl disable oem-cleanup.service 2>/dev/null || true
rm -f /usr/lib/systemd/system/oem-cleanup.service
systemctl daemon-reload
