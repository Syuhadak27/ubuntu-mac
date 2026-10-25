#!/usr/bin/env bash
# =============================================================================
# mode-watcher.sh — keeps GTK / icon / shell themes in sync with GNOME's
# `color-scheme` setting, so Settings > Appearance (or any tool) switches the
# whole desktop consistently. Runs as a systemd --user service; cost is
# effectively zero (it sleeps inside `gsettings monitor`).
# =============================================================================
set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$DIR/../logs/mode-watcher.log"

# Make sure we can talk to the user session bus when started by systemd --user
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

log() { echo "[$(date -Is)] $*" >> "$LOG"; }

apply() {
  "$DIR/apply-mode.sh" "$1" >> "$LOG" 2>&1
  log "applied $1 mode"
}

current="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)"
case "$current" in
  *prefer-dark*) apply dark ;;
  *)              apply light ;;
esac
log "watching org.gnome.desktop.interface color-scheme"

gsettings monitor org.gnome.desktop.interface color-scheme | while read -r line; do
  case "$line" in
    *prefer-dark*) apply dark ;;
    *)             apply light ;;
  esac
done
