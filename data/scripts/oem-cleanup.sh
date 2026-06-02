#!/bin/bash
# Runs as root via systemd. Removes autologin config, deletes the OEM setup
# user, and removes remaining OEM files. On autologin removal failure the
# service exits non-zero so systemd retries it on the next boot.
set -euo pipefail

die() { echo "oem-cleanup: $*" >&2; exit 1; }

# Read and validate setup user from config (default: setup)
SETUP_USER="setup"
CONFIG=/etc/oem-setup/oem-setup.conf
if [[ -f "$CONFIG" ]]; then
    val=$(grep '^setup_user=' "$CONFIG" | cut -d= -f2- || true)
    [[ -n "$val" ]] && SETUP_USER="$val"
fi
[[ "$SETUP_USER" =~ ^[a-z][a-z0-9_-]{0,31}$ ]] \
    || die "virheellinen setup-käyttäjänimi config-tiedostossa: '$SETUP_USER'"

# Remove INI keys from a config file (in-place). Tolerates spaces around '='.
# Returns 0 if file doesn't exist. Preserves SELinux context via cat-redirect.
filter_keys() {
    local file="$1"; shift
    [[ -f "$file" ]] || return 0
    local tmp sed_expr=""
    tmp=$(mktemp) || return 1
    for key in "$@"; do
        sed_expr="${sed_expr}/^[[:blank:]]*${key}[[:blank:]]*=/d;"
    done
    if ! sed "$sed_expr" "$file" > "$tmp"; then
        rm -f "$tmp"; return 1
    fi
    cat "$tmp" > "$file"; local rc=$?
    rm -f "$tmp"
    return $rc
}

# Returns 0 if no autologin settings remain in any display-manager config.
# Pattern is anchored (^) so commented-out example lines are not matched.
autologin_gone() {
    local pattern='^[[:blank:]]*(autologin-user|autologin-guest|AutomaticLogin(Enable)?)[[:blank:]]*='
    for f in /etc/lightdm/lightdm.conf /etc/gdm3/custom.conf /etc/gdm/custom.conf; do
        [[ -f "$f" ]] || continue
        grep -qE "$pattern" "$f" && return 1
    done
    # Drop-in files enable autologin by their mere presence
    for f in \
            /etc/lightdm/lightdm.conf.d/50-oem-autologin.conf \
            /etc/sddm.conf.d/oem-autologin.conf \
            /etc/plasmalogin.conf.d/oem-autologin.conf; do
        [[ -f "$f" ]] && return 1
    done
    return 0
}

remove_autologin() {
    filter_keys /etc/lightdm/lightdm.conf \
        autologin-user autologin-user-timeout autologin-session autologin-guest || return 1
    rm -f /etc/lightdm/lightdm.conf.d/50-oem-autologin.conf || return 1
    filter_keys /etc/gdm3/custom.conf AutomaticLoginEnable AutomaticLogin || return 1
    filter_keys /etc/gdm/custom.conf  AutomaticLoginEnable AutomaticLogin || return 1
    rm -f /etc/sddm.conf.d/oem-autologin.conf || return 1
    rm -f /etc/plasmalogin.conf.d/oem-autologin.conf || return 1
}

# Phase 1: Remove autologin first — exit non-zero to trigger systemd retry
# if it fails, rather than risk a login loop to a deleted user.
remove_autologin && autologin_gone \
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
rmdir /etc/oem-setup 2>/dev/null || true
rm -f /etc/polkit-1/actions/fi.local.oem-setup.policy
rm -f "/var/lib/AccountsService/users/$SETUP_USER"
rm -f /usr/bin/oem-setup-gui
rm -f /usr/libexec/oem-setup/oem-apply.sh
# Remove self last — running script keeps the fd open, deletion is safe on Linux
rm -f /usr/libexec/oem-setup/oem-cleanup.sh
rmdir /usr/libexec/oem-setup 2>/dev/null || true

# Phase 4: Disable and remove the cleanup service itself
systemctl disable oem-cleanup.service 2>/dev/null || true
rm -f /usr/lib/systemd/system/oem-cleanup.service
systemctl daemon-reload
