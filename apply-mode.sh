#!/usr/bin/env bash
# =============================================================================
# apply-mode.sh <light|dark>
# Applies every visual setting for one colour mode. Does NOT write the
# color-scheme key itself, so a watcher on that key can call it safely.
# =============================================================================
set -uo pipefail

MODE="${1:-light}"
case "$MODE" in light|dark) ;; *) echo "Usage: $0 light|dark" >&2; exit 2 ;; esac
UT_DIR="$HOME/.local/share/gnome-shell/extensions/user-theme@gnome-shell-extensions.gcampax.github.com/schemas"
GTK4_DIR="$HOME/.config/gtk-4.0"

set_user_theme() {
  local name="$1"
  [ -d "$UT_DIR" ] || return 0
  gsettings --schemadir "$UT_DIR" set org.gnome.shell.extensions.user-theme name "$name" 2>/dev/null ||
    gsettings --schemadir "$UT_DIR" set :org.gnome.shell.extensions.user-theme name "$name" 2>/dev/null ||
    true
}

case "$MODE" in
  dark)
    gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Dark'
    gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark'
    set_user_theme 'WhiteSur-Dark'
    [ -f "$GTK4_DIR/gtk-Dark.css" ] && ln -sfn "$GTK4_DIR/gtk-Dark.css" "$GTK4_DIR/gtk.css"
    echo "[mode] dark applied"
    ;;
  light)
    gsettings set org.gnome.desktop.interface gtk-theme 'WhiteSur-Light'
    gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'
    set_user_theme 'WhiteSur-Light'
    [ -e "$GTK4_DIR/gtk-Light.css" ] && ln -sfn "$GTK4_DIR/gtk-Light.css" "$GTK4_DIR/gtk.css"
    echo "[mode] light applied"
    ;;
esac

# Cursors and fonts are mode-independent.
gsettings set org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
