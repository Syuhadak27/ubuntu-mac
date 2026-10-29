#!/usr/bin/env bash
# =============================================================================
# macos-look.sh — Apply the macOS Aqua + Glass appearance (user-level only)
#
# Safe to re-run (idempotent). Touches only:
#   * gsettings / dconf (user session)
#   * files under $HOME
# It NEVER touches packages, system files, GDM, or the display manager.
# =============================================================================
set -uo pipefail

LOG_DIR="$HOME/ubuntu-macos-customization/logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/apply-macos-look.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== $(date -Is) applying macOS look ==="

# -----------------------------------------------------------------------------
# 1. Fonts  (Inter is the open-source, macOS-like UI font we installed locally)
# -----------------------------------------------------------------------------
if [ -n "$(fc-list 'Inter' family 2>/dev/null)" ]; then
  gsettings set org.gnome.desktop.interface font-name 'Inter 10'
  gsettings set org.gnome.desktop.interface document-font-name 'Inter 10'
  echo "[font] UI font -> Inter 10"
else
  echo "[font] Inter not found, leaving current font untouched"
fi
# Monospace font is deliberately NOT changed (development environment).

# -----------------------------------------------------------------------------
# 2. Window controls on the RIGHT: Minimize | Maximize | Close
# -----------------------------------------------------------------------------
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'

# -----------------------------------------------------------------------------
# 3. Core look: theme / icons / cursors (light values; set-mode.sh flips them)
# -----------------------------------------------------------------------------
# Keep the user's existing Light/Dark preference; apply-mode.sh handles the theme.
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'

# Cursor size (default 24)
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true

# -----------------------------------------------------------------------------
# 4. Animations: keep GNOME's native animations (cheapest, most compatible)
# -----------------------------------------------------------------------------
gsettings set org.gnome.desktop.interface enable-animations true

# -----------------------------------------------------------------------------
# 5. Top bar: minimal, with date shown next to the clock (macOS style)
# -----------------------------------------------------------------------------
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface clock-format '24h'
gsettings set org.gnome.desktop.interface clock-show-weekday false

# Show battery / power status if the hardware provides one
gsettings set org.gnome.desktop.interface show-battery-percentage true

# -----------------------------------------------------------------------------
# 5b. Wallpaper (generated Sequoia-style gradients, free of third-party art)
# -----------------------------------------------------------------------------
WALL="$HOME/Pictures/Wallpapers"
if [ -f "$WALL/Sequoia-light.jpg" ] && [ -f "$WALL/Sequoia-dark.jpg" ]; then
  gsettings set org.gnome.desktop.background picture-uri "file://$WALL/Sequoia-light.jpg"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALL/Sequoia-dark.jpg"
  gsettings set org.gnome.desktop.background picture-options 'zoom'
  echo "[wallpaper] Sequoia light/dark, zoom"
fi

# -----------------------------------------------------------------------------
# 6. macOS-style Dock  (Ubuntu Dock = Dash to Dock, already installed)
# -----------------------------------------------------------------------------
DASH=org.gnome.shell.extensions.dash-to-dock

gsettings set $DASH dock-position 'BOTTOM'
gsettings set $DASH dock-fixed false             # allow intelligent hide
gsettings set $DASH extend-height false          # shrink to content, centered
gsettings set $DASH dash-max-icon-size 46        # 42-48 px requested
gsettings set $DASH icon-size-fixed true
gsettings set $DASH intellihide true             # intelligent hide
gsettings set $DASH intellihide-mode 'ALL_WINDOWS'
gsettings set $DASH autohide true                # hide when overlapping windows
gsettings set $DASH autohide-in-fullscreen false
gsettings set $DASH transparency-mode 'DYNAMIC'  # glass: opaque only near windows
gsettings set $DASH apply-custom-theme false     # let WhiteSur style the dock
gsettings set $DASH custom-theme-shrink true     # tight, floating background
gsettings set $DASH custom-theme-customize-running-dots false
gsettings set $DASH running-indicator-style 'DOTS'   # macOS-like running dots
gsettings set $DASH show-running true
gsettings set $DASH show-show-apps-button true   # Launchpad-like apps button
gsettings set $DASH show-trash true              # macOS dock shows the trash
gsettings set $DASH show-mounts false
gsettings set $DASH show-mounts-network false
gsettings set $DASH isolate-monitors false
gsettings set $DASH isolate-workspaces false
gsettings set $DASH animate-show-apps true
gsettings set $DASH animation-time 0.2
gsettings set $DASH hide-delay 0.2
# Leave optional preview settings at their installed defaults
echo "[dock] bottom, 46px, intellihide, dynamic transparency"

# -----------------------------------------------------------------------------
# 7. Blur My Shell (GNOME 42 build, v47) — frosted glass, performance tuned
#    (only static/cached blur on the panel & dock; NO per-window blur)
# -----------------------------------------------------------------------------
BMS=/org/gnome/shell/extensions/blur-my-shell/

dconf write $BMS'sigma' 24
dconf write $BMS'brightness' 0.7
dconf write $BMS'noise-amount' 0.0
dconf write $BMS'color-and-noise' false
dconf write $BMS'hacks-level' 1
dconf write $BMS'debug' false

# --- top bar: static (cached) blur, light frosted glass over a light tint ----
dconf write $BMS'panel/blur' true
dconf write $BMS'panel/static-blur' true
dconf write $BMS'panel/customize' true
dconf write $BMS'panel/sigma' 24
dconf write $BMS'panel/brightness' 0.9
dconf write $BMS'panel/override-background' true
dconf write $BMS'panel/style-panel' 1          # light glass (black text stays legible)
dconf write $BMS'panel/override-background-dynamically' false
dconf write $BMS'panel/unblur-in-overview' true

# --- dock: translucent blurred background ----------------------------------
dconf write $BMS'dash-to-dock/blur' true
dconf write $BMS'dash-to-dock/static-blur' true
dconf write $BMS'dash-to-dock/customize' true
dconf write $BMS'dash-to-dock/sigma' 24
dconf write $BMS'dash-to-dock/brightness' 0.7
dconf write $BMS'dash-to-dock/override-background' true
dconf write $BMS'dash-to-dock/style-dash-to-dock' 0   # transparent glass
dconf write $BMS'dash-to-dock/unblur-in-overview' false

# --- overview / app folders: soft blur (only while visible) -----------------
dconf write $BMS'overview/blur' true
dconf write $BMS'overview/sigma' 24
dconf write $BMS'appfolder/blur' true
dconf write $BMS'lockscreen/blur' true

# --- NEVER blur application windows (biggest GPU saver on Intel HD 520) -----
dconf write $BMS'applications/blur' false
dconf write $BMS'applications/enable-all' false
dconf write $BMS'applications/blur-on-overview' false

# --- misc components we do not need ----------------------------------------
dconf write $BMS'screenshot/blur' false

echo "[blur] panel + dock frosted glass, window blur disabled"

# -----------------------------------------------------------------------------
# 8. Shell theme (WhiteSur) — needs the User Themes extension (installed)
#    apply-mode.sh also (re)applies GTK theme, icon theme and cursor theme.
# -----------------------------------------------------------------------------
MODE=light
case "$(gsettings get org.gnome.desktop.interface color-scheme)" in
  *prefer-dark*) MODE=dark ;;
esac
"$HOME/ubuntu-macos-customization/scripts/apply-mode.sh" "$MODE" || true
echo "[shell] apply-mode.sh $MODE executed"

# -----------------------------------------------------------------------------
# 9. Enable the extensions we installed (applies fully on next login)
# -----------------------------------------------------------------------------
CURRENT=$(gsettings get org.gnome.shell enabled-extensions | sed "s/^\[//;s/\]$//;s/'//g")
for UUID in 'blur-my-shell@aunetx' 'user-theme@gnome-shell-extensions.gcampax.github.com'; do
  case ",$CURRENT," in
    *", $UUID,"*|*",$UUID,"*) echo "[ext] $UUID already enabled" ;;
    *)
      NEW=$(gsettings get org.gnome.shell enabled-extensions | sed "s/^\[//;s/\]$//")
      if [ -z "${NEW// /}" ]; then
        gsettings set org.gnome.shell enabled-extensions "['$UUID']"
      else
        gsettings set org.gnome.shell enabled-extensions "[$NEW,'$UUID']"
      fi
      echo "[ext] enabled $UUID"
      ;;
  esac
  CURRENT=$(gsettings get org.gnome.shell enabled-extensions | sed "s/^\[//;s/\]$//;s/'//g")
done

# -----------------------------------------------------------------------------
# 10. Light/dark mode watcher (keeps GTK/icon/shell themes in sync with GNOME's
#     color-scheme, so Settings > Appearance switches everything at once)
# -----------------------------------------------------------------------------
UNIT_SRC="$HOME/ubuntu-macos-customization/scripts/macos-mode-watcher.service"
UNIT_DST="$HOME/.config/systemd/user/macos-mode-watcher.service"
mkdir -p "$HOME/.config/systemd/user"
if [ -f "$UNIT_SRC" ]; then
  sed "s|^ExecStart=.*|ExecStart=$HOME/ubuntu-macos-customization/scripts/mode-watcher.sh|" "$UNIT_SRC" > "$UNIT_DST"
  if systemctl --user daemon-reload 2>/dev/null; then
    systemctl --user enable --now macos-mode-watcher.service 2>/dev/null \
      && echo "[mode] watcher service enabled and started" \
      || echo "[mode] watcher service could not start here (it starts at next login)"
  else
    echo "[mode] systemd --user unavailable; watcher will be started manually"
  fi
fi

# -----------------------------------------------------------------------------
echo "=== done: $(date -Is) ==="
echo "NOTE: newly installed extensions load at the next GNOME login."
