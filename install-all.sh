#!/usr/bin/env bash
# =============================================================================
# install-all.sh — (Re)install every theme / icon / cursor / extension used by
# the macOS look, from the pinned repositories in ~/ubuntu-macos-customization.
#
# User-level only: nothing here needs sudo, nothing here touches system files,
# packages, the display manager or the development environment.
#
# Safe to re-run at any time (installers replace their own output only).
# =============================================================================
set -uo pipefail

BASE="$HOME/ubuntu-macos-customization"
REPO="$BASE/repositories"
LOG_DIR="$BASE/logs"
mkdir -p "$LOG_DIR"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# --- 0. make sure the repositories are present ------------------------------
fetch() {
  local url="$1" dir="$2" branch="${3:-}"
  if [ -d "$dir/.git" ]; then
    log "repo present: $(basename "$dir")"
  else
    if [ -n "$branch" ]; then
      git clone --depth 1 --branch "$branch" "$url" "$dir" || return 1
    else
      git clone --depth 1 "$url" "$dir" || return 1
    fi
    log "cloned: $url"
  fi
}

fetch https://github.com/vinceliuice/WhiteSur-gtk-theme.git   "$REPO/WhiteSur-gtk-theme"
fetch https://github.com/vinceliuice/WhiteSur-icon-theme.git  "$REPO/WhiteSur-icon-theme"
fetch https://github.com/vinceliuice/WhiteSur-cursors.git     "$REPO/WhiteSur-cursors"
# blur-my-shell v47 = last release supporting GNOME Shell 42 (42/43/44)
fetch https://github.com/aunetx/blur-my-shell.git "$REPO/blur-my-shell-v47" v47

# --- 1. GTK theme (WhiteSur, Monterey style, libadwaita override) -----------
log "installing WhiteSur GTK theme ..."
( cd "$REPO/WhiteSur-gtk-theme" && ./install.sh -d "$HOME/.themes" -m -l ) \
  > "$LOG_DIR/whitesur-gtk-install.log" 2>&1 \
  && log "OK  WhiteSur GTK" || { log "ERR WhiteSur GTK (see logs/whitesur-gtk-install.log)"; exit 1; }

# libadwaita override: gtk.css must follow the *light* stylesheet so that
# libadwaita apps honour light mode (gtk-dark.css covers dark mode).
[ -e "$HOME/.config/gtk-4.0/gtk-Light.css" ] \
  && true  # apply-mode.sh selects the active GTK4 stylesheet

# --- 2. Icons ----------------------------------------------------------------
log "installing WhiteSur icons ..."
( cd "$REPO/WhiteSur-icon-theme" && ./install.sh ) \
  > "$LOG_DIR/whitesur-icons-install.log" 2>&1 \
  && log "OK  WhiteSur icons" || log "ERR icons (see logs/whitesur-icons-install.log)"

# --- 3. Cursors --------------------------------------------------------------
log "installing WhiteSur cursors ..."
( cd "$REPO/WhiteSur-cursors" && ./install.sh ) \
  > "$LOG_DIR/whitesur-cursors-install.log" 2>&1 \
  && log "OK  WhiteSur cursors" || log "ERR cursors (see logs/whitesur-cursors-install.log)"

# --- 4. Blur my Shell (GNOME 42 build) --------------------------------------
# Built without translations because msgfmt/gettext tooling is not installed
# (and we must not install packages without approval).
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
BMS_UUID="blur-my-shell@aunetx"
if [ -f "$REPO/blur-my-shell-v47/metadata.json" ]; then
  log "building Blur my Shell v47 ..."
  ( cd "$REPO/blur-my-shell-v47/src" &&
    gnome-extensions pack -f \
      --extra-source=../metadata.json \
      --extra-source=../resources/icons \
      --extra-source=../resources/ui \
      --extra-source=./components \
      --extra-source=./conveniences \
      --extra-source=./effects \
      --extra-source=./preferences \
      --extra-source=./dbus \
      --schema=../schemas/org.gnome.shell.extensions.blur-my-shell.gschema.xml \
      -o ../build ) > "$LOG_DIR/blur-my-shell-pack.log" 2>&1
  if ls "$REPO/blur-my-shell-v47/build/"*.shell-extension.zip >/dev/null 2>&1; then
    gnome-extensions install -f "$REPO/blur-my-shell-v47/build/"*.shell-extension.zip \
      && log "OK  Blur my Shell installed ($EXT_DIR/$BMS_UUID)" \
      || log "ERR blur-my-shell install"
  else
    log "ERR blur-my-shell pack failed (see logs/blur-my-shell-pack.log)"
  fi
fi

# --- 5. User Themes extension (needed for the WhiteSur GNOME Shell theme) ----
UT_UUID="user-theme@gnome-shell-extensions.gcampax.github.com"
if [ ! -d "$EXT_DIR/$UT_UUID" ]; then
  log "downloading User Themes extension (GNOME 42 build) ..."
  UT_URL=$(curl -s "https://extensions.gnome.org/extension-info/?uuid=$UT_UUID&shell_version=42" \
             | python3 -c "import sys,json;print(json.load(sys.stdin).get('download_url',''))" 2>/dev/null)
  if [ -n "$UT_URL" ] && [ "$UT_URL" != "None" ]; then
    curl -sL "https://extensions.gnome.org${UT_URL}" -o /tmp/user-themes.zip \
      && gnome-extensions install -f /tmp/user-themes.zip \
      && log "OK  User Themes installed" || log "ERR user-themes install"
  else
    log "ERR could not resolve User Themes download URL"
  fi
else
  log "User Themes already installed"
fi

# --- 6. Inter font (open source UI font, OFL) -------------------------------
if [ ! -d "$HOME/.local/share/fonts/Inter" ]; then
  log "installing Inter font ..."
  TMP=$(mktemp -d)
  if curl -sL -o "$TMP/inter.zip" "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip"; then
    mkdir -p "$HOME/.local/share/fonts/Inter"
    unzip -o -j "$TMP/inter.zip" \
      extras/ttf/Inter-Regular.ttf extras/ttf/Inter-Medium.ttf extras/ttf/Inter-SemiBold.ttf \
      extras/ttf/Inter-Bold.ttf extras/ttf/Inter-Light.ttf LICENSE.txt \
      -d "$HOME/.local/share/fonts/Inter" >/dev/null \
      && fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 \
      && log "OK  Inter font"
  fi
  rm -rf "$TMP"
else
  log "Inter font already installed"
fi

# --- 7. Wallpapers ----------------------------------------------------------
if [ ! -f "$HOME/Pictures/Wallpapers/Sequoia-light.jpg" ]; then
  python3 "$BASE/scripts/generate-wallpaper.py" && log "OK  wallpapers"
fi

log "install-all finished. Run scripts/macos-look.sh to (re)apply the settings."
