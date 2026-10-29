#!/usr/bin/env bash
# ============================================================
#  Cek cepat hasil Ubuntu -> macOS
#  Jalankan setelah logout/login:
#      ./verify.sh
# ============================================================

set -Eeuo pipefail

if [ -t 1 ]; then
  BOLD=$'\033[1m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  RED=$'\033[31m'
  RESET=$'\033[0m'
else
  BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

ok()   { printf '%s  OK%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s  ! %s%s\n' "$YELLOW" "$*" "$RESET"; }
bad()  { printf '%s  X %s%s\n' "$RED" "$*" "$RESET"; }

get() {
  gsettings get "$1" "$2" 2>/dev/null | tr -d "'" || printf '?'
}

printf '%sTema dan dekorasi:%s\n' "${BOLD}" "$RESET"
GTK="$(get org.gnome.desktop.interface gtk-theme)"
ICON="$(get org.gnome.desktop.interface icon-theme)"
CURSOR="$(get org.gnome.desktop.interface cursor-theme)"
BUTTONS="$(get org.gnome.desktop.wm.preferences button-layout)"
FONT="$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'" || printf '?')"

printf '  GTK theme      : %s\n' "$GTK"
printf '  Icon theme     : %s\n' "$ICON"
printf '  Cursor theme   : %s\n' "$CURSOR"
printf '  Font UI        : %s\n' "$FONT"
printf '  Button layout  : %s\n' "$BUTTONS"

[ -d "$HOME/.themes/$GTK" ] && ok "Folder tema GTK ada." || warn "Folder tema GTK ~/.themes/$GTK tidak ditemukan."
[ -d "$HOME/.local/share/icons/$ICON" ] && ok "Folder ikon ada." || warn "Folder ikon tidak ditemukan."
[ -d "$HOME/.local/share/icons/$CURSOR" ] && ok "Folder kursor ada." || warn "Folder kursor tidak ditemukan."

case "$BUTTONS" in
  *minimize*maximize*close*) ok "Tombol jendela ada di kanan." ;;
  *) warn "Button layout belum sesuai (harus minimize,maximize,close di kanan)." ;;
esac

printf '\n%sDock:%s\n' "${BOLD}" "$RESET"
SCHEMAS="$(gsettings list-schemas 2>/dev/null || true)"
if [ -n "$SCHEMAS" ] && grep -qx -- "org.gnome.shell.extensions.dash-to-dock" <<<"$SCHEMAS"; then
  DOCK_POS="$(get org.gnome.shell.extensions.dash-to-dock dock-position)"
  DOCK_SIZE="$(get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size)"
  DOCK_OPACITY="$(get org.gnome.shell.extensions.dash-to-dock background-opacity)"
  DOCK_AUTOHIDE="$(get org.gnome.shell.extensions.dash-to-dock autohide)"
  SHOW_APPS="$(get org.gnome.shell.extensions.dash-to-dock show-show-apps-button)"
  printf '  Posisi         : %s\n' "$DOCK_POS"
  printf '  Ukuran ikon    : %s px\n' "$DOCK_SIZE"
  printf '  Opasitas       : %s\n' "$DOCK_OPACITY"
  printf '  Auto-hide      : %s\n' "$DOCK_AUTOHIDE"
  printf '  Tombol app grid: %s\n' "$SHOW_APPS"
  if [ "$SHOW_APPS" = "true" ]; then
    ok "Tombol Show Applications (menu semua aplikasi) tampil."
  else
    warn "Tombol Show Applications disembunyikan. Tampilkan dengan:"
    printf '                 gsettings set org.gnome.shell.extensions.dash-to-dock show-show-apps-button true\n'
    printf '                 (atau jalankan ./install.sh --show-apps)\n'
  fi
else
  bad "Skema Ubuntu Dock tidak ditemukan."
fi

printf '\n%sEkstensi aktif:%s\n' "${BOLD}" "$RESET"
if command -v gnome-extensions >/dev/null 2>&1; then
  ENABLED_EXTS="$(gnome-extensions list --enabled 2>/dev/null || true)"
  if [ -n "$ENABLED_EXTS" ]; then
    printf '%s\n' "$ENABLED_EXTS" | sed 's/^/  /'
  fi
  for ext in "user-theme@gnome-shell-extensions.gcampax.github.com" "ubuntu-dock@ubuntu.com"; do
    if [ -n "$ENABLED_EXTS" ] && grep -Fxq -- "$ext" <<<"$ENABLED_EXTS"; then
      ok "Aktif: $ext"
    else
      warn "Belum aktif: $ext"
    fi
  done
else
  bad "Perintah gnome-extensions tidak ditemukan."
fi

printf '\n%sWallpaper:%s\n' "${BOLD}" "$RESET"
gsettings get org.gnome.desktop.background picture-uri 2>/dev/null || true

printf '\n%sShell theme:%s\n' "${BOLD}" "$RESET"
get org.gnome.shell.extensions.user-theme name

printf '\nSelesai. Kalau ada yang belum aktif, logout/login sekali lagi.\n'
