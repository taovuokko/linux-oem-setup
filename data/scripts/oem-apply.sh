#!/bin/bash
# Runs as root via pkexec. Creates the real user account, sets locale,
# enables the cleanup service, and removes autologin config.
# Usage: pkexec oem-apply.sh --username X --display-name Y --locale Z
# Password is read from stdin (never on argv).
set -euo pipefail

die() { echo "oem-apply: $*" >&2; exit 1; }

USERNAME=""
DISPLAY_NAME=""
LOCALE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --username)     USERNAME="$2";     shift 2 ;;
        --display-name) DISPLAY_NAME="$2"; shift 2 ;;
        --locale)       LOCALE="$2";       shift 2 ;;
        *) die "tuntematon argumentti: $1" ;;
    esac
done

[[ -n "$USERNAME" ]]     || die "puuttuva --username"
[[ -n "$DISPLAY_NAME" ]] || die "puuttuva --display-name"
[[ -n "$LOCALE" ]]       || die "puuttuva --locale"

IFS= read -r PASSWORD || true
[[ -n "$PASSWORD" ]] || die "salasana puuttuu"

# Remove lines starting with given prefixes from a config file (in-place).
# Returns 0 if file doesn't exist (nothing to filter).
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

rollback() {
    echo "oem-apply: käyttöönotto epäonnistui, poistetaan $USERNAME" >&2
    pkill -u "$USERNAME" 2>/dev/null || true
    loginctl terminate-user "$USERNAME" 2>/dev/null || true
    userdel -r "$USERNAME" 2>/dev/null || true
    groupdel "$USERNAME" 2>/dev/null || true
}

# Reject already-existing user
if id "$USERNAME" &>/dev/null; then
    die "käyttäjä on jo olemassa: $USERNAME"
fi

# Create user — useradd is portable across all distros.
# (Debian's adduser is not used: on Fedora/Arch it is a useradd symlink that
# rejects --gecos and --disabled-password.)
useradd -m -c "$DISPLAY_NAME" -s /bin/bash "$USERNAME" \
    || die "käyttäjän luominen epäonnistui"

# Set password via chpasswd stdin (password never on argv)
if ! printf '%s:%s\n' "$USERNAME" "$PASSWORD" | chpasswd; then
    rollback
    die "salasanan asettaminen epäonnistui"
fi

# Add to sudo/wheel group
GROUP=""
if getent group sudo &>/dev/null; then
    GROUP=sudo
elif getent group wheel &>/dev/null; then
    GROUP=wheel
else
    echo "oem-apply: sudo/wheel-ryhmää ei löydy, ohitetaan" >&2
fi

if [[ -n "$GROUP" ]]; then
    if ! usermod -aG "$GROUP" "$USERNAME"; then
        rollback
        die "käyttäjän lisääminen sudo-ryhmään epäonnistui"
    fi
fi

# Set locale
set_locale() {
    local locale="$1"
    command -v locale-gen &>/dev/null && locale-gen "$locale" || true
    if command -v localectl &>/dev/null; then
        localectl set-locale "LANG=$locale"; return $?
    fi
    if command -v update-locale &>/dev/null; then
        update-locale "LANG=$locale"; return $?
    fi
    echo "oem-apply: localectl/update-locale ei saatavilla" >&2
    return 1
}

if ! set_locale "$LOCALE"; then
    rollback
    die "kielen asettaminen epäonnistui"
fi

# Enable cleanup service before removing autologin so it can retry on next boot
if ! systemctl enable oem-cleanup.service; then
    rollback
    die "cleanup-palvelun aktivointi epäonnistui"
fi

# Remove autologin — non-fatal, cleanup service retries on next boot
remove_autologin \
    || echo "oem-apply: varoitus: autologinin poisto epäonnistui osin, cleanup-palvelu yrittää uudelleen" >&2

echo "ok"
