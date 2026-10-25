#!/usr/bin/env bash
# =============================================================================
# restore-ubuntu.sh — Roll back the "Ubuntu -> macOS" customization
#
#   ~/ubuntu-macos-customization/scripts/restore-ubuntu.sh [--full] [--backup DIR]
#
# What it restores (default):
#   * every GNOME/dconf setting changed by the customization (from the dump)
#   * the two GNOME extensions that were installed by this project
#   * the Inter font, WhiteSur cursors, generated wallpapers
#   * ~/.config/gtk-3.0 and ~/.config/gtk-4.0 (WhiteSur libadwaita override)
#   * the gnome-theme-switcher helper and the light/dark watcher service
#
# --full additionally puts ~/.themes and ~/.local/share/icons back exactly as
# they were in the snapshot (removes anything added there by this project).
#
# It never touches: packages, system files, GDM/display manager, projects,
# repositories, shell profiles, SSH keys, JDK/SDK/Node/Python installs.
#
# RESTORE_ROOT=<dir>  → apply all file operations under <dir> instead of $HOME
#                      (used to test the script in a sandbox)
# RESTORE_SKIP_DCONF=1 → skip the settings part (used with RESTORE_ROOT)
#
# The script ends with a VALIDATION section: it compares the live settings
# against the backup and prints PASS/FAIL. It exits non-zero on any failure.
# =============================================================================
set -uo pipefail

BASE="$HOME/ubuntu-macos-customization"
ROOT="${RESTORE_ROOT:-$HOME}"
if [ "$ROOT" = "$HOME" ] && [ "${ALLOW_REAL_RESTORE:-0}" != "1" ]; then
  echo "SAFETY STOP: this script removes themes/extensions and resets GNOME settings." >&2
  echo "To explicitly authorize a real rollback, rerun with ALLOW_REAL_RESTORE=1." >&2
  exit 2
fi
SKIP_DCONF="${RESTORE_SKIP_DCONF:-0}"
FULL=0
BACKUP_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --full)    FULL=1; shift ;;
    --backup)  BACKUP_DIR="${2:-}"; shift 2 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BACKUP_DIR" ] || BACKUP_DIR="$BASE/backups/latest"
if [ ! -d "$BACKUP_DIR" ]; then
  echo "ERROR: backup not found: $BACKUP_DIR" >&2
  echo "Available backups:" >&2
  ls -1 "$BASE/backups" >&2 2>&1
  exit 1
fi
BACKUP_DIR="$(readlink -f "$BACKUP_DIR")"

FAIL=0
step() { echo; echo "--- $*"; }
ok()   { echo "  OK   $*"; }
err()  { echo "  FAIL $*"; FAIL=1; }

echo "=============================================================="
echo " restore-ubuntu.sh"
echo " backup : $BACKUP_DIR"
echo " target : $ROOT"
echo " mode   : $([ "$FULL" = 1 ] && echo 'full (themes+icons too)' || echo 'settings + added components')"
echo "=============================================================="

# -----------------------------------------------------------------------------
step "1/7  Restore GNOME settings from the dconf dump"
# -----------------------------------------------------------------------------
if [ "$SKIP_DCONF" = 1 ]; then
  echo "  SKIP (RESTORE_SKIP_DCONF=1)"
elif [ -f "$BACKUP_DIR/dconf-gnome.dump" ]; then
  DUMP="$BACKUP_DIR/dconf-gnome.dump"

  # Verify that a handful of representative keys really match the snapshot.
  verify_dump() {
    local path key want got bad=0
    for path in \
      /org/gnome/desktop/interface/gtk-theme \
      /org/gnome/desktop/interface/icon-theme \
      /org/gnome/desktop/interface/cursor-theme \
      /org/gnome/desktop/interface/color-scheme \
      /org/gnome/desktop/background/picture-uri \
      /org/gnome/shell/enabled-extensions \
      /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size
    do
      key="$(basename "$path")"
      want="$(grep -m1 "^$key=" "$DUMP" | cut -d= -f2-)"
      [ -n "$want" ] || continue
      got="$(dconf read "$path" 2>/dev/null)"
      if [ "$got" != "$want" ]; then
        echo "     mismatch $path: want '$want', got '$got'"
        bad=1
      fi
    done
    return $bad
  }

  # IMPORTANT: clear every tree this project wrote to *before* loading the
  # snapshot. dconf only dumps keys that carry a user value, so a key we
  # changed whose original value came from Ubuntu's system defaults would
  # otherwise keep OUR value. Resetting first lets the system/GNOME defaults
  # (or the snapshot) decide, exactly as before the customization.
  #
  # The reset/load pair is retried if the verification shows the write did not
  # land (observed once: dconf's writer can process a reset right after a load).
  ATTEMPT=0
  while [ "$ATTEMPT" -lt 3 ]; do
    ATTEMPT=$((ATTEMPT + 1))
    for tree in \
      /org/gnome/desktop/interface/ \
      /org/gnome/desktop/background/ \
      /org/gnome/desktop/wm/preferences/ \
      /org/gnome/shell/ \
      /org/gnome/shell/extensions/blur-my-shell/ \
      /org/gnome/shell/extensions/user-theme/
    do
      dconf reset -f "$tree" 2>/dev/null
    done
    dconf load /org/gnome/ < "$DUMP" || { err "dconf load failed"; break; }
    sleep 1
    if verify_dump; then
      ok "settings match snapshot (attempt $ATTEMPT)"
      break
    else
      [ "$ATTEMPT" = 3 ] && err "settings still do not match after 3 attempts"
    fi
  done
else
  err "missing $BACKUP_DIR/dconf-gnome.dump"
fi

# -----------------------------------------------------------------------------
step "2/7  Remove extensions installed by this project"
# -----------------------------------------------------------------------------
EXT="$ROOT/.local/share/gnome-shell/extensions"
for uuid in 'blur-my-shell@aunetx' 'user-theme@gnome-shell-extensions.gcampax.github.com'; do
  if [ -e "$EXT/$uuid" ]; then
    rm -rf "$EXT/$uuid" && ok "removed $uuid" || err "could not remove $uuid"
  else
    ok "$uuid not present"
  fi
done

# -----------------------------------------------------------------------------
step "3/7  Remove the light/dark watcher service"
# -----------------------------------------------------------------------------
UNIT="$ROOT/.config/systemd/user/macos-mode-watcher.service"
if [ "$ROOT" = "$HOME" ]; then
  systemctl --user disable --now macos-mode-watcher.service >/dev/null 2>&1 \
    && ok "service disabled and stopped" || ok "service was not running"
fi
if [ -f "$UNIT" ]; then
  rm -f "$UNIT" && ok "removed $UNIT"
  [ "$ROOT" = "$HOME" ] && systemctl --user daemon-reload 2>/dev/null
else
  ok "service unit not present"
fi

# -----------------------------------------------------------------------------
step "4/7  Remove assets added by this project"
# -----------------------------------------------------------------------------
for path in \
  ".local/share/fonts/Inter" \
  ".local/share/icons/WhiteSur-cursors" \
  ".local/bin/gnome-theme-switcher" \
  ".local/share/applications/org.gnome.GTK4ThemeSwitcher.desktop" \
  "Pictures/Wallpapers/Sequoia-light.jpg" \
  "Pictures/Wallpapers/Sequoia-dark.jpg"
do
  if [ -e "$ROOT/$path" ]; then
    rm -rf "$ROOT/$path" && ok "removed ~/$path"
  else
    ok "~/$path not present"
  fi
done
fc-cache -f "$ROOT/.local/share/fonts" >/dev/null 2>&1

# -----------------------------------------------------------------------------
step "5/7  Restore GTK 3.0 / GTK 4.0 configuration from the snapshot"
# -----------------------------------------------------------------------------
for d in .config/gtk-3.0 .config/gtk-4.0; do
  if [ -d "$BACKUP_DIR/$d" ]; then
    mkdir -p "$ROOT/$(dirname "$d")"
    rm -rf "$ROOT/$d"
    cp -a "$BACKUP_DIR/$d" "$ROOT/$d" && ok "restored ~/$d" || err "could not restore ~/$d"
  else
    ok "no snapshot for ~/$d (nothing to do)"
  fi
done

# -----------------------------------------------------------------------------
step "6/7  Restore themes and icons from the snapshot (--full)"
# -----------------------------------------------------------------------------
if [ "$FULL" = 1 ]; then
  for d in .themes .local/share/icons; do
    if [ -d "$BACKUP_DIR/$d" ]; then
      mkdir -p "$ROOT/$(dirname "$d")"
      rm -rf "$ROOT/$d"
      cp -a "$BACKUP_DIR/$d" "$ROOT/$d" && ok "restored ~/$d" || err "could not restore ~/$d"
    fi
  done
else
  echo "  SKIP  (pass --full to also restore ~/.themes and ~/.local/share/icons)"
fi

# -----------------------------------------------------------------------------
step "7/7  Validation — live settings vs. snapshot"
# -----------------------------------------------------------------------------
if [ "$SKIP_DCONF" = 1 ]; then
  echo "  SKIP  (settings were not part of this run)"
else
  check() { # check <gsettings-schema> <key> <expected-from-backup>
    local got
    got="$(gsettings get "$1" "$2" 2>&1)"
    if [ "$got" = "$3" ]; then
      ok "$1 $2 = $3"
    else
      err "$1 $2 expected $3 but is $got"
    fi
  }

  expect() { grep -m1 "^$1=" "$BACKUP_DIR/key-settings.txt" | cut -d= -f2-; }

  check org.gnome.desktop.interface gtk-theme        "$(expect gtk-theme)"
  check org.gnome.desktop.interface icon-theme       "$(expect icon-theme)"
  check org.gnome.desktop.interface cursor-theme     "$(expect cursor-theme)"
  check org.gnome.desktop.interface font-name        "$(expect font-name)"
  check org.gnome.desktop.interface document-font-name "$(expect document-font-name)"
  check org.gnome.desktop.interface monospace-font-name "$(expect monospace-font-name)"
  check org.gnome.desktop.interface color-scheme     "$(expect color-scheme)"
  check org.gnome.desktop.interface enable-animations "$(expect enable-animations)"
  check org.gnome.desktop.interface clock-show-date  "$(expect clock-show-date)"
  check org.gnome.desktop.wm.preferences button-layout "$(expect button-layout)"
  check org.gnome.desktop.background picture-uri     "$(expect picture-uri)"
  check org.gnome.desktop.background picture-uri-dark "$(expect picture-uri-dark)"
  check org.gnome.shell enabled-extensions           "$(expect enabled-extensions)"
  check org.gnome.shell disabled-extensions          "$(expect disabled-extensions)"

  # dock keys we changed
  for kv in dash-max-icon-size intellihide autohide transparency-mode \
            show-trash running-indicator-style apply-custom-theme; do
    exp="$(grep -m1 "dash-to-dock $kv " "$BACKUP_DIR/key-settings.txt" | sed "s/.*dash-to-dock $kv //")"
    [ -n "$exp" ] && check org.gnome.shell.extensions.dash-to-dock "$kv" "$exp"
  done

  # extensions must be gone
  for uuid in 'blur-my-shell@aunetx' 'user-theme@gnome-shell-extensions.gcampax.github.com'; do
    if [ -e "$HOME/.local/share/gnome-shell/extensions/$uuid" ]; then
      err "extension still installed: $uuid"
    else
      ok "extension removed: $uuid"
    fi
  done
fi

echo
echo "=============================================================="
if [ "$SKIP_DCONF" = 1 ]; then
  echo " RESULT: PARTIAL — file operations only; settings were not part of this run."
elif [ "$FAIL" = 0 ]; then
  echo " RESULT: PASS — desktop settings and components match the snapshot."
  echo " Log out and back in (or reboot) for the shell to reload extensions."
else
  echo " RESULT: FAIL — some checks did not match. See 'FAIL' lines above."
fi
echo "=============================================================="
exit "$FAIL"
