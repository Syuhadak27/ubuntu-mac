#!/usr/bin/env bash
set -euo pipefail
BASE="$HOME/ubuntu-macos-customization"
[ -f "$BASE/scripts/macos-look.sh" ] || { echo "Copy files to $BASE/scripts first"; exit 1; }
echo "Backing up current GNOME settings..."
"$BASE/scripts/backup-ubuntu.sh"
echo "Applying Aqua + Glass settings (no sudo, no GDM changes)..."
"$BASE/scripts/macos-look.sh"
echo "Done. Change mode with: $BASE/scripts/set-mode.sh dark"
