#!/usr/bin/env bash
# =============================================================================
# set-mode.sh <light|dark>   —  one command to switch the whole desktop theme
#
#   ~/ubuntu-macos-customization/scripts/set-mode.sh dark
#
# Sets GNOME's color-scheme first (so Settings > Appearance, libadwaita apps
# and the wallpaper switch too), then applies GTK/icon/shell theme values.
# =============================================================================
set -euo pipefail

MODE="${1:-}"
case "$MODE" in
  light|dark) ;;
  *) echo "usage: $0 light|dark" >&2; exit 2 ;;
esac

DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$MODE" = dark ]; then
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
else
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
fi

"$DIR/apply-mode.sh" "$MODE"
echo "Desktop switched to $MODE mode."
