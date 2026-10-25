#!/usr/bin/env bash
# =============================================================================
# backup-ubuntu.sh — Snapshot the pre-customization GNOME/desktop state
# Safe, read-only wrt the system. Writes only inside ~/ubuntu-macos-customization/
# =============================================================================
set -uo pipefail

BASE="$HOME/ubuntu-macos-customization"
STAMP="$(date +%Y%m%d-%H%M%S)"
DEST="$BASE/backups/$STAMP"
LOG="$BASE/logs/backup-$STAMP.log"

mkdir -p "$DEST" "$BASE/logs"

log() { echo "[$(date +%H:%M:%S)] $*" | tee -a "$LOG"; }

log "Backup destination: $DEST"

# 1. Full dconf/GNOME settings dump -----------------------------------------
if dconf dump /org/gnome/ > "$DEST/dconf-gnome.dump" 2>>"$LOG"; then
  log "OK  dconf dump ($(wc -l < "$DEST/dconf-gnome.dump") lines)"
else
  log "ERR dconf dump failed"
fi

# Dump every other tree too (covers non-/org/gnome trees, e.g. apps) ----------
if dconf dump / > "$DEST/dconf-all.dump" 2>>"$LOG"; then
  log "OK  full dconf dump ($(wc -l < "$DEST/dconf-all.dump") lines)"
fi

# 2. Key single settings (fast, human readable) ------------------------------
{
  echo "gtk-theme=$(gsettings get org.gnome.desktop.interface gtk-theme)"
  echo "icon-theme=$(gsettings get org.gnome.desktop.interface icon-theme)"
  echo "cursor-theme=$(gsettings get org.gnome.desktop.interface cursor-theme)"
  echo "font-name=$(gsettings get org.gnome.desktop.interface font-name)"
  echo "document-font-name=$(gsettings get org.gnome.desktop.interface document-font-name)"
  echo "monospace-font-name=$(gsettings get org.gnome.desktop.interface monospace-font-name)"
  echo "color-scheme=$(gsettings get org.gnome.desktop.interface color-scheme)"
  echo "enable-animations=$(gsettings get org.gnome.desktop.interface enable-animations)"
  echo "clock-show-date=$(gsettings get org.gnome.desktop.interface clock-show-date)"
  echo "button-layout=$(gsettings get org.gnome.desktop.wm.preferences button-layout)"
  echo "picture-uri=$(gsettings get org.gnome.desktop.background picture-uri)"
  echo "picture-uri-dark=$(gsettings get org.gnome.desktop.background picture-uri-dark)"
  echo "enabled-extensions=$(gsettings get org.gnome.shell enabled-extensions)"
  echo "disabled-extensions=$(gsettings get org.gnome.shell disabled-extensions)"
  echo "dash-to-dock=$(gsettings list-recursively org.gnome.shell.extensions.dash-to-dock 2>/dev/null)"
  echo "session-type=${XDG_SESSION_TYPE:-unknown}"
  echo "gnome-shell=$(gnome-shell --version 2>/dev/null)"
} > "$DEST/key-settings.txt" 2>&1
log "OK  key-settings.txt"

# 3. Extension inventory ------------------------------------------------------
{
  echo "== gnome-extensions list =="
  gnome-extensions list 2>/dev/null
  echo
  echo "== enabled =="
  gnome-extensions list --enabled 2>/dev/null
  echo
  echo "== disabled =="
  gnome-extensions list --disabled 2>/dev/null
  echo
  echo "== user extensions dir =="
  ls -la "$HOME/.local/share/gnome-shell/extensions" 2>/dev/null
  echo
  echo "== system extensions dir =="
  ls -la /usr/share/gnome-shell/extensions 2>/dev/null
} > "$DEST/extensions.txt" 2>&1
log "OK  extensions.txt"

# 4. Package inventory (dpkg + apt-mark auto, so we can tell what we add) -----
dpkg-query -W -f='${Package}\t${Version}\t${Status}\n' > "$DEST/packages-dpkg.tsv" 2>>"$LOG"
apt-mark showmanual 2>/dev/null > "$DEST/packages-manual.txt"
cp /var/log/apt/history.log "$DEST/apt-history.log" 2>/dev/null || \
  { cat /var/log/apt/history.log* 2>/dev/null > "$DEST/apt-history.log"; }
log "OK  package inventory ($(wc -l < "$DEST/packages-dpkg.tsv") packages)"

# 5. Theme / icon / cursor assets --------------------------------------------
for d in .themes .icons .fonts .local/share/themes .local/share/icons \
         .local/share/fonts .config/gtk-3.0 .config/gtk-4.0; do
  if [ -e "$HOME/$d" ]; then
    mkdir -p "$DEST/$(dirname "$d")"
    cp -a "$HOME/$d" "$DEST/$d" 2>>"$LOG" && log "OK  copy ~/$d"
  fi
done

# 6. Wallpaper reference + current wallpaper file ----------------------------
gsettings get org.gnome.desktop.background picture-uri > "$DEST/wallpaper-uri.txt" 2>&1
gsettings get org.gnome.desktop.background picture-uri-dark >> "$DEST/wallpaper-uri.txt"

# 7. Shell startup files (read-only copies) ----------------------------------
mkdir -p "$DEST/shell"
cp -a "$HOME/.bashrc" "$HOME/.profile" "$DEST/shell/" 2>/dev/null
[ -d "$HOME/.config/environment.d" ] && cp -a "$HOME/.config/environment.d" "$DEST/shell/" 2>/dev/null
log "OK  shell configs"

# 8. Manifest ----------------------------------------------------------------
{
  echo "timestamp=$STAMP"
  echo "host=$(hostname)"
  echo "os=$(lsb_release -ds 2>/dev/null)"
  echo "gnome=$(gnome-shell --version 2>/dev/null)"
  echo "session=${XDG_SESSION_TYPE:-unknown}"
  echo "desktop=${XDG_CURRENT_DESKTOP:-unknown}"
} > "$DEST/MANIFEST.txt"

# 9. Latest pointer ----------------------------------------------------------
ln -sfn "$STAMP" "$BASE/backups/latest"
log "DONE  backup -> $DEST (latest -> $(readlink -f "$BASE/backups/latest"))"
