#!/usr/bin/env bash
# ============================================================
#  Ubuntu -> macOS (Big Sur / Ventura / Tahoe) Installer
#
#  Jalankan sebagai user desktop biasa:
#      chmod +x install.sh
#      ./install.sh
#
#  Script akan meminta password sudo sendiri saat dibutuhkan.
#  JANGAN dijalankan dengan "sudo ./install.sh".
# ============================================================

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/macos-theme.conf"

# ------------------------------------------------------------
# Nilai default (bisa ditimpa macos-theme.conf / argumen CLI)
# ------------------------------------------------------------
THEME_FAMILY="tahoe"          # tahoe | bigsur
THEME_MODE="light"            # light | dark
GTK_ACCENT="grey"
ICON_ACCENT="blue"

DOCK_ICON_SIZE=56
DOCK_BG_OPACITY=0.22
DOCK_BG_COLOR="#eeeeec"
DOCK_POSITION="BOTTOM"
DOCK_AUTOHIDE="true"
DOCK_INTELLIHIDE="true"

WALLPAPER_PRESET="tahoe-night"
WALLPAPER_FILE=""

HIDE_TOP_BAR=0
INSTALL_LIBADWAITA_THEME=1
INSTALL_TERMINAL_PROFILE=1
APPLY_MACOS_KEYBINDINGS=1
ENABLE_EXTENSIONS=1
SET_NAUTILUS_PREFS=1
SET_DESKTOP_ICONS=1

if [ -r "$CONF_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CONF_FILE"
fi

# ------------------------------------------------------------
# Warna output
# ------------------------------------------------------------
if [ -t 1 ]; then
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  RED=$'\033[31m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  BLUE=$'\033[34m'
  CYAN=$'\033[36m'
  RESET=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; RESET=""
fi

info()  { printf '%s==>%s %s\n' "${BLUE}${BOLD}" "$RESET" "$*"; }
step()  { printf '\n%s%s%s\n' "${CYAN}${BOLD}" "$*" "$RESET"; }
ok()    { printf '%s  OK%s %s\n' "$GREEN" "$RESET" "$*"; }
warn()  { printf '%s  ! %s%s\n' "$YELLOW" "$*" "$RESET" >&2; }
die()   { printf '%sERROR:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Penggunaan: ./install.sh [OPSI]

OPSI:
  --family tahoe|bigsur   Gaya tema (default: tahoe)
  --light                 Mode terang (default)
  --dark                  Mode gelap
  --accent WARNA          Aksen GTK: default|blue|purple|pink|red|orange|
                          yellow|green|grey (default: grey)
  --icon-accent WARNA     Aksen ikon (default: blue)
  --icon-size PX          Ukuran ikon dock (default: 56)
  --dock-opacity 0.22     Opasitas latar dock 0.0-1.0 (default: 0.22)
  --no-autohide           Dock selalu tampil
  --hide-topbar           Sembunyikan menu bar atas otomatis
  --show-topbar           Menu bar atas selalu tampil (default)
  --wallpaper NAMA        tahoe-night|tahoe-day|bigsur|bigsur-dark|
                          ventura-dark|ventura-light|custom
  --wallpaper-file PATH   Wallpaper custom (bersama --wallpaper custom)
  --no-libadwaita         Jangan pasang tema GTK4/libadwaita
  --no-terminal           Jangan buat profil terminal macOS
  --no-keybindings        Jangan ubah shortcut keyboard
  --help, -h              Tampilkan bantuan ini

Contoh:
  ./install.sh --family bigsur --dark --icon-size 56
  ./install.sh --family tahoe --wallpaper tahoe-night
EOF
}

# ------------------------------------------------------------
# Argumen CLI
# ------------------------------------------------------------
while [ "$#" -gt 0 ]; do
  case "$1" in
    --family)
      [ "$#" -ge 2 ] || die "Opsi --family butuh nilai."
      THEME_FAMILY="$2"; shift 2 ;;
    --light)
      THEME_MODE="light"; shift ;;
    --dark)
      THEME_MODE="dark"; shift ;;
    --accent)
      [ "$#" -ge 2 ] || die "Opsi --accent butuh nilai."
      GTK_ACCENT="$2"; shift 2 ;;
    --icon-accent)
      [ "$#" -ge 2 ] || die "Opsi --icon-accent butuh nilai."
      ICON_ACCENT="$2"; shift 2 ;;
    --icon-size)
      [ "$#" -ge 2 ] || die "Opsi --icon-size butuh nilai."
      DOCK_ICON_SIZE="$2"; shift 2 ;;
    --dock-opacity)
      [ "$#" -ge 2 ] || die "Opsi --dock-opacity butuh nilai."
      DOCK_BG_OPACITY="$2"; shift 2 ;;
    --no-autohide)
      DOCK_AUTOHIDE="false"; shift ;;
    --hide-topbar)
      HIDE_TOP_BAR=1; shift ;;
    --show-topbar)
      HIDE_TOP_BAR=0; shift ;;
    --wallpaper)
      [ "$#" -ge 2 ] || die "Opsi --wallpaper butuh nilai."
      WALLPAPER_PRESET="$2"; shift 2 ;;
    --wallpaper-file)
      [ "$#" -ge 2 ] || die "Opsi --wallpaper-file butuh nilai."
      WALLPAPER_FILE="$2"; shift 2 ;;
    --no-libadwaita)
      INSTALL_LIBADWAITA_THEME=0; shift ;;
    --no-terminal)
      INSTALL_TERMINAL_PROFILE=0; shift ;;
    --no-keybindings)
      APPLY_MACOS_KEYBINDINGS=0; shift ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      die "Opsi tidak dikenal: $1 (gunakan --help)" ;;
  esac
done

# ------------------------------------------------------------
# Validasi
# ------------------------------------------------------------
case "$THEME_FAMILY" in
  tahoe|bigsur) ;;
  *) die "THEME_FAMILY harus 'tahoe' atau 'bigsur'." ;;
esac

case "$THEME_MODE" in
  light|dark) ;;
  *) die "THEME_MODE harus 'light' atau 'dark'." ;;
esac

[[ "$DOCK_ICON_SIZE" =~ ^[0-9]+$ ]] || die "DOCK_ICON_SIZE harus angka (contoh: 56)."
[ "$DOCK_ICON_SIZE" -ge 16 ] && [ "$DOCK_ICON_SIZE" -le 128 ] \
  || die "DOCK_ICON_SIZE harus antara 16 dan 128."

[[ "$DOCK_BG_OPACITY" =~ ^[0-9]*\.?[0-9]+$ ]] \
  || die "DOCK_BG_OPACITY harus angka (contoh: 0.22)."
awk -v v="$DOCK_BG_OPACITY" 'BEGIN { exit !(v + 0 >= 0 && v + 0 <= 1) }' \
  || die "DOCK_BG_OPACITY harus antara 0.0 dan 1.0 (contoh: 0.22)."

case "$WALLPAPER_PRESET" in
  tahoe-night|tahoe-day|bigsur|bigsur-dark|ventura-dark|ventura-light|custom) ;;
  *) die "WALLPAPER_PRESET tidak dikenal: $WALLPAPER_PRESET" ;;
esac

case "$DOCK_POSITION" in
  BOTTOM|LEFT|RIGHT) ;;
  *) die "DOCK_POSITION harus BOTTOM, LEFT, atau RIGHT." ;;
esac

case "$DOCK_AUTOHIDE" in true|false) ;; *) die "DOCK_AUTOHIDE harus true/false." ;; esac
case "$DOCK_INTELLIHIDE" in true|false) ;; *) die "DOCK_INTELLIHIDE harus true/false." ;; esac

# Kalau auto-hide dimatikan, intellihide juga dimatikan agar dock benar-benar
# selalu tampil.
if [ "$DOCK_AUTOHIDE" = "false" ]; then
  DOCK_INTELLIHIDE="false"
fi

case "$GTK_ACCENT" in
  default|blue|purple|pink|red|orange|yellow|green|grey) ;;
  *) die "GTK_ACCENT tidak dikenal: $GTK_ACCENT" ;;
esac

case "$ICON_ACCENT" in
  default|blue|purple|pink|red|orange|yellow|green|grey) ;;
  *) die "ICON_ACCENT tidak dikenal: $ICON_ACCENT" ;;
esac

# Tema ikon tidak punya semua aksen yang sama seperti tema GTK.
if [ "$THEME_FAMILY" = "tahoe" ]; then
  if [ "$ICON_ACCENT" = "pink" ]; then
    warn "Ikon MacTahoe tidak punya aksen pink; memakai purple."
    ICON_ACCENT="purple"
  fi
else
  if [ "$ICON_ACCENT" = "blue" ]; then
    warn "Ikon WhiteSur tidak punya aksen blue; memakai default."
    ICON_ACCENT="default"
  fi
fi

if [[ "$WALLPAPER_FILE" == "~/"* ]]; then
  WALLPAPER_FILE="$HOME/${WALLPAPER_FILE#\~/}"
fi

# ------------------------------------------------------------
# Nama tema
# ------------------------------------------------------------
if [ "$THEME_FAMILY" = "tahoe" ]; then
  THEME_BASE="MacTahoe"
  # MacTahoe bawaan sudah bernuansa biru seperti referensi.
  if [ "$ICON_ACCENT" = "default" ] || [ "$ICON_ACCENT" = "blue" ]; then
    ICON_THEME_NAME="MacTahoe"
  else
    ICON_THEME_NAME="MacTahoe-${ICON_ACCENT}"
  fi
  if [ "$THEME_MODE" = "dark" ]; then
    CURSOR_THEME_NAME="MacTahoe-dark"
  else
    CURSOR_THEME_NAME="MacTahoe-light"
  fi
else
  THEME_BASE="WhiteSur"
  if [ "$ICON_ACCENT" = "default" ]; then
    ICON_THEME_NAME="WhiteSur"
  else
    ICON_THEME_NAME="WhiteSur-${ICON_ACCENT}"
  fi
  CURSOR_THEME_NAME="WhiteSur-cursors"
fi

if [ "$THEME_MODE" = "dark" ]; then
  MODE_CAP="Dark"
else
  MODE_CAP="Light"
fi

if [ "$GTK_ACCENT" = "default" ]; then
  GTK_THEME_NAME="${THEME_BASE}-${MODE_CAP}"
else
  GTK_THEME_NAME="${THEME_BASE}-${MODE_CAP}-${GTK_ACCENT}"
fi

# ------------------------------------------------------------
# Preflight
# ------------------------------------------------------------
step "1/10  Pemeriksaan awal"

[ "${EUID}" -ne 0 ] || die "Jangan jalankan dengan sudo/root. Jalankan ./install.sh sebagai user desktop; script akan memakai sudo sendiri."

[ -n "${HOME:-}" ] || die "HOME tidak ditemukan."
[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || die "Tidak ada sesi D-Bus. Jalankan script dari terminal di desktop Ubuntu (bukan SSH/TTY)."

command -v sudo >/dev/null 2>&1 || die "sudo tidak ditemukan."
command -v gsettings >/dev/null 2>&1 || die "gsettings tidak ditemukan. Pastikan GNOME terpasang."

if [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [ "${ID:-}" != "ubuntu" ] && [ "${FORCE:-0}" != "1" ]; then
    die "Script ini ditujukan untuk Ubuntu. Set FORCE=1 jika tetap ingin melanjutkan."
  fi
  info "Sistem: ${PRETTY_NAME:-unknown}"
fi

case "${XDG_CURRENT_DESKTOP:-}" in
  *GNOME*|*gnome*|*ubuntu*|*Ubuntu*) ;;
  *)
    if [ "${FORCE:-0}" != "1" ]; then
      die "Sesi desktop bukan GNOME (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-kosong}). Set FORCE=1 untuk memaksa."
    fi
    warn "Sesi desktop bukan GNOME; melanjutkan karena FORCE=1."
    ;;
esac

if command -v gnome-shell >/dev/null 2>&1; then
  GNOME_MAJOR="$(gnome-shell --version 2>/dev/null | grep -oE '[0-9]+' || true)"
  GNOME_MAJOR="${GNOME_MAJOR%%$'\n'*}"
  info "GNOME Shell: $(gnome-shell --version 2>/dev/null || echo 'tidak diketahui')"
  if [ -n "${GNOME_MAJOR:-}" ] && [ "$GNOME_MAJOR" -gt 48 ]; then
    warn "GNOME Shell ${GNOME_MAJOR} lebih baru dari yang umum diuji. Tema/ekstensi mungkin butuh penyesuaian."
  fi
else
  die "gnome-shell tidak ditemukan."
fi

info "Tema GTK  : ${GTK_THEME_NAME}"
info "Ikon      : ${ICON_THEME_NAME}"
info "Kursor    : ${CURSOR_THEME_NAME}"
info "Dock      : ${DOCK_ICON_SIZE}px, opacity ${DOCK_BG_OPACITY}, ${DOCK_POSITION}"

sudo -v || die "Autentikasi sudo gagal."
ok "Hak akses sudo tersedia."

# Jaga agar sudo tidak timeout saat build tema
( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null || true; sleep 50; done ) &
SUDO_KEEPALIVE_PID=$!

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ubuntu-macos.XXXXXX")"

cleanup() {
  local rc=$?
  trap - EXIT INT TERM
  if [ -n "${SUDO_KEEPALIVE_PID:-}" ]; then
    kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true
  fi
  rm -rf -- "$TMP_DIR"
  exit "$rc"
}
trap cleanup EXIT INT TERM

# ------------------------------------------------------------
# Dependensi
# ------------------------------------------------------------
step "2/10  Memasang dependensi"

sudo env DEBIAN_FRONTEND=noninteractive apt-get update -qq \
  || warn "apt-get update gagal; melanjutkan dengan cache paket yang ada."

APT_PKGS=(
  ca-certificates curl wget git tar gzip unzip
  sassc libglib2.0-dev-bin libglib2.0-bin libxml2-utils
  optipng imagemagick dconf-cli uuid-runtime fontconfig python3
  libgtk-3-bin libgtk-4-bin
  gnome-terminal gnome-tweaks gnome-shell-extensions
  gnome-shell-extension-prefs gnome-shell-extension-manager
  gnome-shell-extension-ubuntu-dock gnome-shell-extension-appindicator
  fonts-inter fonts-jetbrains-mono
)

# Desktop Icons NG (Ubuntu 22.04+) atau versi lama
if apt-cache show gnome-shell-extension-desktop-icons-ng >/dev/null 2>&1; then
  APT_PKGS+=(gnome-shell-extension-desktop-icons-ng)
elif apt-cache show gnome-shell-extension-desktop-icons >/dev/null 2>&1; then
  APT_PKGS+=(gnome-shell-extension-desktop-icons)
fi

# Fallback Dock untuk distro/GNOME tanpa Ubuntu Dock
if ! apt-cache show gnome-shell-extension-ubuntu-dock >/dev/null 2>&1; then
  if apt-cache show gnome-shell-extension-dash-to-dock >/dev/null 2>&1; then
    APT_PKGS+=(gnome-shell-extension-dash-to-dock)
  fi
fi

if [ "$HIDE_TOP_BAR" = "1" ]; then
  APT_PKGS+=(gnome-shell-extension-autohidetopbar)
fi

AVAILABLE_PKGS=()
for pkg in "${APT_PKGS[@]}"; do
  if apt-cache show "$pkg" >/dev/null 2>&1; then
    AVAILABLE_PKGS+=("$pkg")
  else
    warn "Paket tidak tersedia, dilewati: $pkg"
  fi
done

if [ "${#AVAILABLE_PKGS[@]}" -gt 0 ]; then
  if ! sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${AVAILABLE_PKGS[@]}"; then
    die "Gagal memasang paket dependensi. Periksa koneksi/repo lalu ulangi."
  fi
fi

for cmd in curl tar gsettings dconf sassc python3 gtk-update-icon-cache; do
  command -v "$cmd" >/dev/null 2>&1 || die "Perintah wajib tidak ditemukan setelah apt: $cmd"
done

ok "Dependensi siap."

# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------
step "3/10  Membuat backup pengaturan"

STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/ubuntu-macos-installer"
BACKUP_DIR="${STATE_ROOT}/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

if ! dconf dump /org/gnome/ > "$BACKUP_DIR/gnome.dconf"; then
  die "Gagal membuat backup dconf. Instalasi dibatalkan agar aman."
fi
if [ ! -s "$BACKUP_DIR/gnome.dconf" ]; then
  warn "Backup dconf kosong. Sebaiknya batalkan dan periksa sesi GNOME."
fi
if [ -d "$HOME/.config/gtk-4.0" ]; then
  cp -a "$HOME/.config/gtk-4.0" "$BACKUP_DIR/gtk-4.0" 2>/dev/null || true
else
  : > "$BACKUP_DIR/gtk-4.0.absent"
fi
if [ -d "$HOME/.config/gtk-3.0" ]; then
  cp -a "$HOME/.config/gtk-3.0" "$BACKUP_DIR/gtk-3.0" 2>/dev/null || true
else
  : > "$BACKUP_DIR/gtk-3.0.absent"
fi

cat > "$BACKUP_DIR/info.txt" <<EOF
Backup dibuat: $(date -Is)
Sistem: ${PRETTY_NAME:-unknown}
GNOME: $(gnome-shell --version 2>/dev/null || echo unknown)
Tema: ${GTK_THEME_NAME}
Ikon: ${ICON_THEME_NAME}
Kursor: ${CURSOR_THEME_NAME}
EOF

ok "Backup: $BACKUP_DIR"
info "Untuk rollback: ${SCRIPT_DIR}/restore.sh \"$BACKUP_DIR\""


# ------------------------------------------------------------
# Download tema
# ------------------------------------------------------------
step "4/10  Mengunduh tema, ikon, dan kursor"

curl_retry() {
  local url="$1"
  local out="$2"
  local attempt rc
  for attempt in 1 2 3 4 5; do
    rc=0
    curl -fsSL --connect-timeout 20 --max-time 900 -o "$out" "$url" || rc=$?
    if [ "$rc" -eq 0 ]; then
      return 0
    fi
    rm -f -- "$out"
    # 22 = HTTP error (mis. 404). Tidak perlu diulang.
    [ "$rc" -eq 22 ] && return 1
    if [ "$attempt" -lt 5 ]; then
      warn "Unduhan gagal (percobaan ${attempt}/5), mencoba lagi..."
      sleep "$attempt"
    fi
  done
  return 1
}

fetch_repo() {
  local repo="$1"
  local dest="$2"
  local branch archive
  for branch in main master; do
    rm -rf -- "$dest"
    mkdir -p "$dest"
    archive="${TMP_DIR}/${repo//\//_}-${branch}.tar.gz"
    if curl_retry "https://github.com/${repo}/archive/refs/heads/${branch}.tar.gz" "$archive"; then
      if tar -xzf "$archive" -C "$dest" --strip-components=1 2>/dev/null; then
        ok "Diunduh: ${repo} (${branch})"
        return 0
      fi
    fi
  done
  return 1
}

if [ "$THEME_FAMILY" = "tahoe" ]; then
  fetch_repo "vinceliuice/MacTahoe-gtk-theme" "$TMP_DIR/gtk" \
    || die "Gagal mengunduh MacTahoe GTK theme."
  fetch_repo "vinceliuice/MacTahoe-icon-theme" "$TMP_DIR/icons" \
    || die "Gagal mengunduh MacTahoe icon theme."
else
  fetch_repo "vinceliuice/WhiteSur-gtk-theme" "$TMP_DIR/gtk" \
    || die "Gagal mengunduh WhiteSur GTK theme."
  fetch_repo "vinceliuice/WhiteSur-icon-theme" "$TMP_DIR/icons" \
    || die "Gagal mengunduh WhiteSur icon theme."
  fetch_repo "vinceliuice/WhiteSur-cursors" "$TMP_DIR/cursors" \
    || die "Gagal mengunduh WhiteSur cursors."
fi

# ------------------------------------------------------------
# Install tema GTK + GNOME Shell
# ------------------------------------------------------------
step "5/10  Membangun dan memasang tema GTK/Shell"

# Pasang varian yang dipilih lebih dulu agar tema libadwaita (gtk4)
# mengikuti mode terang/gelap yang dipilih.
COLOR_ARGS=(-c "$THEME_MODE")
if [ "$THEME_MODE" = "light" ]; then
  COLOR_ARGS+=(-c dark)
else
  COLOR_ARGS+=(-c light)
fi

THEME_EXTRA=()
if [ "$INSTALL_LIBADWAITA_THEME" = "1" ]; then
  THEME_EXTRA+=(-l)
fi

info "Membangun ${THEME_BASE} (light + dark). Ini bisa memakan beberapa menit..."
# Catatan: JANGAN memakai --silent-mode. Opsi itu hanya untuk dijalankan sebagai
# root, sedangkan tema harus dipasang ke ~/.themes milik user desktop.
if ! ( cd "$TMP_DIR/gtk" && \
       ./install.sh -o normal -a normal "${COLOR_ARGS[@]}" \
         -t "$GTK_ACCENT" "${THEME_EXTRA[@]}" \
         --round --shell -i apple -p default ); then
  die "Instalasi tema GTK/Shell gagal."
fi

if [ ! -d "$HOME/.themes/$GTK_THEME_NAME" ]; then
  die "Tema '${GTK_THEME_NAME}' tidak ditemukan di ~/.themes setelah instalasi."
fi
ok "Tema GTK/Shell terpasang: $GTK_THEME_NAME"

if [ "$INSTALL_LIBADWAITA_THEME" = "1" ]; then
  if [ -f "$HOME/.config/gtk-4.0/gtk.css" ]; then
    ok "Tema libadwaita/GTK4 terpasang."
  else
    warn "File tema libadwaita/GTK4 tidak ditemukan; aplikasi GTK4 memakai tema bawaan."
  fi
fi

# ------------------------------------------------------------
# Install ikon + kursor
# ------------------------------------------------------------
step "6/10  Memasang ikon dan kursor"

ICON_ARGS=(-t default)
if [ "$ICON_ACCENT" != "default" ]; then
  ICON_ARGS+=("$ICON_ACCENT")
fi

if ! ( cd "$TMP_DIR/icons" && ./install.sh "${ICON_ARGS[@]}" ); then
  die "Instalasi ikon/kursor gagal."
fi

if [ "$THEME_FAMILY" = "bigsur" ]; then
  if ! ( cd "$TMP_DIR/cursors" && ./install.sh ); then
    die "Instalasi kursor WhiteSur gagal."
  fi
fi

[ -d "$HOME/.local/share/icons/$ICON_THEME_NAME" ] \
  || die "Tema ikon '${ICON_THEME_NAME}' tidak ditemukan setelah instalasi."
[ -d "$HOME/.local/share/icons/$CURSOR_THEME_NAME" ] \
  || warn "Tema kursor '${CURSOR_THEME_NAME}' tidak ditemukan; kursor mungkin tetap memakai tema lama."

ok "Ikon dan kursor terpasang."

# ------------------------------------------------------------
# Font
# ------------------------------------------------------------
step "7/10  Memilih font"

choose_font() {
  local candidate families=""
  if command -v fc-list >/dev/null 2>&1; then
    families="$(fc-list : family 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  fi
  for candidate in "$@"; do
    if [ -n "$families" ] && [[ "$families" == *"${candidate,,}"* ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  printf '%s\n' "$1"
}

UI_FONT="$(choose_font "Inter" "Cantarell" "Ubuntu" "DejaVu Sans")"
MONO_FONT="$(choose_font "JetBrains Mono" "Fira Code" "Ubuntu Mono" "DejaVu Sans Mono")"
info "Font antarmuka : ${UI_FONT} 11"
info "Font terminal  : ${MONO_FONT} 11"

# ------------------------------------------------------------
# Wallpaper
# ------------------------------------------------------------
step "8/10  Memasang wallpaper"

WALL_DIR="$HOME/.local/share/backgrounds/macos"
mkdir -p "$WALL_DIR"

WALL_URL=""
WALL_NAME=""

case "$WALLPAPER_PRESET" in
  tahoe-night)
    WALL_URL="https://raw.githubusercontent.com/vinceliuice/MacTahoe-gtk-theme/main/wallpaper/MacTahoe-night.jpeg"
    WALL_NAME="macos-tahoe-night.jpeg" ;;
  tahoe-day)
    WALL_URL="https://raw.githubusercontent.com/vinceliuice/MacTahoe-gtk-theme/main/wallpaper/MacTahoe-day.jpeg"
    WALL_NAME="macos-tahoe-day.jpeg" ;;
  bigsur)
    WALL_URL="https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/WhiteSur.jpg"
    WALL_NAME="macos-bigsur.jpg" ;;
  bigsur-dark)
    WALL_URL="https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/WhiteSur-dark.jpg"
    WALL_NAME="macos-bigsur-dark.jpg" ;;
  ventura-dark)
    WALL_URL="https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/Ventura-dark.jpg"
    WALL_NAME="macos-ventura-dark.jpg" ;;
  ventura-light)
    WALL_URL="https://raw.githubusercontent.com/vinceliuice/WhiteSur-wallpapers/main/4k/Ventura-light.jpg"
    WALL_NAME="macos-ventura-light.jpg" ;;
  custom)
    [ -n "$WALLPAPER_FILE" ] || die "WALLPAPER_PRESET=custom butuh WALLPAPER_FILE."
    [ -f "$WALLPAPER_FILE" ] || die "File wallpaper tidak ditemukan: $WALLPAPER_FILE"
    WALL_NAME="$(basename "$WALLPAPER_FILE")"
    if [ ! "$WALLPAPER_FILE" -ef "$WALL_DIR/$WALL_NAME" ]; then
      cp -f -- "$WALLPAPER_FILE" "$WALL_DIR/$WALL_NAME"
    fi ;;
  *)
    die "WALLPAPER_PRESET tidak dikenal: $WALLPAPER_PRESET" ;;
esac

if [ "$WALLPAPER_PRESET" != "custom" ]; then
  if [ ! -s "$WALL_DIR/$WALL_NAME" ]; then
    info "Mengunduh wallpaper ${WALLPAPER_PRESET}..."
    if curl_retry "$WALL_URL" "$WALL_DIR/$WALL_NAME.part"; then
      mv -f "$WALL_DIR/$WALL_NAME.part" "$WALL_DIR/$WALL_NAME"
    else
      rm -f "$WALL_DIR/$WALL_NAME.part"
      warn "Gagal mengunduh wallpaper. Wallpaper lama dipertahankan."
    fi
  fi
fi

WALLPAPER_URI=""
if [ -s "$WALL_DIR/$WALL_NAME" ]; then
  WALLPAPER_URI="$(python3 - "$WALL_DIR/$WALL_NAME" <<'PY'
import pathlib
import sys
print(pathlib.Path(sys.argv[1]).resolve().as_uri())
PY
)"
  ok "Wallpaper: $WALL_DIR/$WALL_NAME"
else
  warn "Wallpaper tidak tersedia; menggunakan wallpaper yang sudah ada."
fi

# ------------------------------------------------------------
# Terapkan pengaturan
# ------------------------------------------------------------
step "9/10  Menerapkan pengaturan macOS"

# Helper: gsettings opsional (jangan gagal kalau key tidak ada)
gs_opt() {
  gsettings set "$1" "$2" "$3" >/dev/null 2>&1 || true
}

# Daftar skema diambil sekali. Menggunakan here-string (bukan pipe) supaya
# "grep -q" tidak memicu SIGPIPE + pipefail.
ALL_SCHEMAS="$(gsettings list-schemas 2>/dev/null || true)"
has_schema() {
  [ -n "$ALL_SCHEMAS" ] && grep -qx -- "$1" <<<"$ALL_SCHEMAS"
}

# gsettings wajib-ish: hanya beri peringatan
gs_set() {
  if ! gsettings set "$1" "$2" "$3" >/dev/null 2>&1; then
    warn "Gagal set ${1} ${2}"
  fi
}

# --- Tema & dekorasi jendela ---
gs_set org.gnome.desktop.interface gtk-theme "$GTK_THEME_NAME"
gs_set org.gnome.desktop.interface icon-theme "$ICON_THEME_NAME"
gs_set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME_NAME"
gs_set org.gnome.desktop.interface cursor-size 24
gs_set org.gnome.desktop.wm.preferences theme "$GTK_THEME_NAME"

# Tombol jendela di KANAN, berwarna (close/minimize/maximize).
# Urutan: minimize, maximize, close -> close paling kanan.
gs_set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"
gs_set org.gnome.desktop.wm.preferences action-double-click-titlebar "toggle-maximize"

if [ "$THEME_MODE" = "dark" ]; then
  gs_opt org.gnome.desktop.interface color-scheme "prefer-dark"
else
  gs_opt org.gnome.desktop.interface color-scheme "prefer-light"
fi

# --- Font ---
gs_set org.gnome.desktop.interface font-name "$UI_FONT 11"
gs_set org.gnome.desktop.interface document-font-name "$UI_FONT 11"
gs_set org.gnome.desktop.interface monospace-font-name "$MONO_FONT 11"
gs_set org.gnome.desktop.wm.preferences titlebar-font "$UI_FONT Bold 11"
gs_opt org.gnome.desktop.interface font-antialiasing "grayscale"
gs_opt org.gnome.desktop.interface font-hinting "slight"
gs_opt org.gnome.desktop.interface text-scaling-factor 1.0

# --- Jam, baterai, hot corner ---
gs_set org.gnome.desktop.interface clock-show-date true
gs_set org.gnome.desktop.interface clock-show-weekday true
gs_opt org.gnome.desktop.interface clock-show-seconds false
gs_opt org.gnome.desktop.interface show-battery-percentage true
gs_opt org.gnome.desktop.interface enable-hot-corners true

# --- Touchpad ala macOS ---
gs_opt org.gnome.desktop.peripherals.touchpad natural-scroll true
gs_opt org.gnome.desktop.peripherals.touchpad tap-to-click true
gs_opt org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gs_opt org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false
gs_opt org.gnome.desktop.peripherals.touchpad click-method "fingers"

# --- Wallpaper ---
if [ -n "$WALLPAPER_URI" ]; then
  gs_set org.gnome.desktop.background picture-uri "$WALLPAPER_URI"
  gs_opt org.gnome.desktop.background picture-uri-dark "$WALLPAPER_URI"
  gs_opt org.gnome.desktop.screensaver picture-uri "$WALLPAPER_URI"
  gs_opt org.gnome.desktop.background picture-options "zoom"
fi

# --- Nautilus / Files ---
if [ "$SET_NAUTILUS_PREFS" = "1" ]; then
  gs_opt org.gnome.nautilus.preferences click-policy "double"
  gs_opt org.gnome.nautilus.preferences show-image-thumbnails "always"
  gs_opt org.gnome.nautilus.preferences default-folder-viewer "icon-view"
fi

# --- Ikon desktop ---
if [ "$SET_DESKTOP_ICONS" = "1" ]; then
  gs_opt org.gnome.shell.extensions.ding show-home false
  gs_opt org.gnome.shell.extensions.ding show-trash false
  gs_opt org.gnome.shell.extensions.desktop-icons show-home false
  gs_opt org.gnome.shell.extensions.desktop-icons show-trash false
fi

# --- Ekstensi ---
INSTALLED_EXTS="$(gnome-extensions list 2>/dev/null || true)"
has_ext() {
  [ -n "$INSTALLED_EXTS" ] || return 1
  grep -Fx -- "$1" <<<"$INSTALLED_EXTS" >/dev/null 2>&1
}

enable_ext() {
  local id="$1"
  if has_ext "$id"; then
    if gnome-extensions enable "$id" >/dev/null 2>&1; then
      ok "Ekstensi aktif: $id"
    else
      warn "Ekstensi terpasang tetapi gagal diaktifkan: $id"
    fi
  else
    warn "Ekstensi tidak ditemukan: $id"
  fi
}

gs_opt org.gnome.shell disable-user-extensions false

if [ "$ENABLE_EXTENSIONS" = "1" ]; then
  enable_ext "user-theme@gnome-shell-extensions.gcampax.github.com"
  enable_ext "ubuntu-dock@ubuntu.com"
  enable_ext "ubuntu-appindicators@ubuntu.com"
  enable_ext "ding@rastersoft.com"
fi

# Fallback kalau Ubuntu Dock tidak ada
if ! has_schema "org.gnome.shell.extensions.dash-to-dock"; then
  warn "Skema Ubuntu Dock tidak ditemukan."
  if [ "$ENABLE_EXTENSIONS" = "1" ]; then
    enable_ext "dash-to-dock@micxgx.gmail.com"
  fi
fi

# --- Tema GNOME Shell ---
gs_opt org.gnome.shell.extensions.user-theme name "$GTK_THEME_NAME"

# --- Dock ---
info "Mengatur dock..."
gs_opt org.gnome.shell.extensions.dash-to-dock dock-position "$DOCK_POSITION"
gs_opt org.gnome.shell.extensions.dash-to-dock extend-height false
gs_opt org.gnome.shell.extensions.dash-to-dock dock-fixed false
gs_opt org.gnome.shell.extensions.dash-to-dock autohide "$DOCK_AUTOHIDE"
gs_opt org.gnome.shell.extensions.dash-to-dock intellihide "$DOCK_INTELLIHIDE"
gs_opt org.gnome.shell.extensions.dash-to-dock intellihide-mode "MAXIMIZED_WINDOWS"
gs_opt org.gnome.shell.extensions.dash-to-dock autohide-in-fullscreen true
gs_opt org.gnome.shell.extensions.dash-to-dock dash-max-icon-size "$DOCK_ICON_SIZE"
gs_opt org.gnome.shell.extensions.dash-to-dock icon-size-fixed true
gs_opt org.gnome.shell.extensions.dash-to-dock height-fraction 1.0
gs_opt org.gnome.shell.extensions.dash-to-dock preferred-monitor 0
gs_opt org.gnome.shell.extensions.dash-to-dock apply-custom-theme false
gs_opt org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gs_opt org.gnome.shell.extensions.dash-to-dock force-straight-corner false
gs_opt org.gnome.shell.extensions.dash-to-dock isolate-workspaces false
gs_opt org.gnome.shell.extensions.dash-to-dock show-running true
gs_opt org.gnome.shell.extensions.dash-to-dock running-indicator-style "DOTS"
gs_opt org.gnome.shell.extensions.dash-to-dock click-action "minimize-or-previews"
gs_opt org.gnome.shell.extensions.dash-to-dock scroll-action "switch-workspace"
gs_opt org.gnome.shell.extensions.dash-to-dock show-trash false
gs_opt org.gnome.shell.extensions.dash-to-dock show-mounts false
gs_opt org.gnome.shell.extensions.dash-to-dock show-show-apps-button false
gs_opt org.gnome.shell.extensions.dash-to-dock show-apps-at-top false
gs_opt org.gnome.shell.extensions.dash-to-dock animate-show-apps true
gs_opt org.gnome.shell.extensions.dash-to-dock transparency-mode "FIXED"
gs_opt org.gnome.shell.extensions.dash-to-dock custom-background-color true
gs_opt org.gnome.shell.extensions.dash-to-dock background-color "$DOCK_BG_COLOR"
gs_opt org.gnome.shell.extensions.dash-to-dock background-opacity "$DOCK_BG_OPACITY"
ok "Dock: ${DOCK_ICON_SIZE}px, ${DOCK_POSITION}, opacity ${DOCK_BG_OPACITY}"

# --- Menu bar atas ---
if [ "$HIDE_TOP_BAR" = "1" ]; then
  enable_ext "hidetopbar@mathieu.bidon.ca"
  gs_opt org.gnome.shell.extensions.hidetopbar enable-intellihide true
  gs_opt org.gnome.shell.extensions.hidetopbar animation-time-autohide 0.2
  gs_opt org.gnome.shell.extensions.hidetopbar mouse-sensitive true
  gs_opt org.gnome.shell.extensions.hidetopbar mouse-sensitive-fullscreen-window true
  gs_opt org.gnome.shell.extensions.hidetopbar mouse-triggers-overview false
  gs_opt org.gnome.shell.extensions.hidetopbar pressure-threshold 200
  gs_opt org.gnome.shell.extensions.hidetopbar pressure-timeout 1000
else
  if has_ext "hidetopbar@mathieu.bidon.ca"; then
    gnome-extensions disable "hidetopbar@mathieu.bidon.ca" >/dev/null 2>&1 || true
  fi
fi

# --- Favorite dock ---
desktop_exists() {
  local desktop="$1" base
  for base in \
    "$HOME/.local/share/applications" \
    "/usr/local/share/applications" \
    "/usr/share/applications" \
    "/var/lib/snapd/desktop/applications" \
    "$HOME/.local/share/flatpak/exports/share/applications" \
    "/var/lib/flatpak/exports/share/applications"; do
    [ -f "${base}/${desktop}" ] && return 0
  done
  return 1
}

FAVORITES=()
add_favorite() {
  local d="$1" x
  desktop_exists "$d" || return 0
  if [ "${#FAVORITES[@]}" -gt 0 ]; then
    for x in "${FAVORITES[@]}"; do
      [ "$x" = "$d" ] && return 0
    done
  fi
  FAVORITES+=("$d")
}

add_favorite "org.gnome.Nautilus.desktop"
add_favorite "org.gnome.Terminal.desktop"
add_favorite "firefox_firefox.desktop"
add_favorite "firefox.desktop"
add_favorite "google-chrome.desktop"
add_favorite "chromium_chromium.desktop"
add_favorite "chromium-browser.desktop"
add_favorite "org.gnome.Software.desktop"
add_favorite "snap-store.desktop"
add_favorite "org.gnome.TextEditor.desktop"
add_favorite "gedit.desktop"
add_favorite "org.gnome.Calendar.desktop"
add_favorite "gnome-system-monitor.desktop"
add_favorite "org.gnome.Calculator.desktop"
add_favorite "org.gnome.Music.desktop"
add_favorite "org.gnome.Photos.desktop"
add_favorite "gnome-control-center.desktop"

if [ "${#FAVORITES[@]}" -gt 0 ]; then
  FAV_LITERAL="["
  FAV_SEP=""
  for d in "${FAVORITES[@]}"; do
    FAV_LITERAL+="${FAV_SEP}'${d}'"
    FAV_SEP=", "
  done
  FAV_LITERAL+="]"
  gs_set org.gnome.shell favorite-apps "$FAV_LITERAL"
  ok "Dock favorites: ${#FAVORITES[@]} aplikasi"
fi

# --- Terminal ---
if [ "$INSTALL_TERMINAL_PROFILE" = "1" ]; then
  info "Membuat profil terminal macOS..."
  if ! command -v gnome-terminal >/dev/null 2>&1; then
    warn "gnome-terminal tidak ditemukan; profil terminal dilewati."
  elif ! has_schema "org.gnome.Terminal.ProfilesList"; then
    warn "Skema GNOME Terminal tidak ditemukan; profil terminal dilewati."
  else
    PROFILE_LIST="$(gsettings get org.gnome.Terminal.ProfilesList list 2>/dev/null || printf '[]')"
    case "$PROFILE_LIST" in
      "@as []"|"[]"|"")
        PROFILE_IDS="" ;;
      *)
        PROFILE_IDS="$(
          printf '%s\n' "$PROFILE_LIST" \
            | sed "s/[][]//g; s/'//g; s/,/ /g"
        )" ;;
    esac

    PROFILE_ARR=()
    if [ -n "$PROFILE_IDS" ]; then
      while IFS= read -r pid; do
        [ -n "$pid" ] && PROFILE_ARR+=("$pid")
      done < <(printf '%s\n' "$PROFILE_IDS" | tr ' ' '\n')
    fi

    PROFILE_ID=""
    for pid in "${PROFILE_ARR[@]}"; do
      pname="$(gsettings get "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${pid}/" visible-name 2>/dev/null | tr -d "'" || true)"
      if [ "$pname" = "macOS" ]; then
        PROFILE_ID="$pid"
        break
      fi
    done

    if [ -z "$PROFILE_ID" ]; then
      PROFILE_ID="$(cat /proc/sys/kernel/random/uuid)"

      NEW_LIST="["
      LIST_SEP=""
      for pid in "${PROFILE_ARR[@]}"; do
        NEW_LIST+="${LIST_SEP}'${pid}'"
        LIST_SEP=", "
      done
      [ -n "$LIST_SEP" ] && NEW_LIST+=", "
      NEW_LIST+="'${PROFILE_ID}']"

      gs_set org.gnome.Terminal.ProfilesList list "$NEW_LIST"
    fi

    gs_set org.gnome.Terminal.ProfilesList default "$PROFILE_ID"

    PBASE="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${PROFILE_ID}/"
    term_set() {
      gsettings set "$PBASE" "$1" "$2" >/dev/null 2>&1 || true
    }

    term_set visible-name "macOS"
    term_set use-theme-colors false
    term_set background-color "#1e1e1e"
    term_set foreground-color "#f8f8f2"
    term_set bold-color "#ffffff"
    term_set bold-color-same-as-fg false
    term_set bold-is-bright true
    term_set use-transparent-background true
    term_set background-transparency-percent 10
    term_set palette "['#000000', '#ff6b6b', '#a8e6a1', '#ffd93d', '#6ba4ff', '#d8a0ff', '#5ce1e6', '#e6e6e6', '#666666', '#ff8e8e', '#b8f0b2', '#ffe66d', '#8dbfff', '#e5b8ff', '#7fedf0', '#ffffff']"
    term_set use-system-font false
    term_set font "$MONO_FONT 11"
    term_set cursor-shape "block"
    term_set cursor-blink-mode "on"
    term_set scrollback-lines 10000
    term_set scroll-on-output false
    term_set scroll-on-keystroke true
    term_set audible-bell false
    term_set default-size-columns 110
    term_set default-size-rows 30
    term_set login-shell false

    gs_opt org.gnome.Terminal.Legacy.Settings theme-variant "dark"
    gs_opt org.gnome.desktop.default-applications.terminal exec "gnome-terminal"

    if command -v update-alternatives >/dev/null 2>&1 && \
       [ -x /usr/bin/gnome-terminal.wrapper ]; then
      sudo update-alternatives --set x-terminal-emulator /usr/bin/gnome-terminal.wrapper \
        >/dev/null 2>&1 || true
    fi

    ok "Profil terminal 'macOS' aktif (background #1e1e1e, font ${MONO_FONT} 11)."
  fi
fi

# --- Shortcut keyboard ala macOS ---
if [ "$APPLY_MACOS_KEYBINDINGS" = "1" ]; then
  info "Menerapkan shortcut keyboard macOS..."

  gs_set org.gnome.desktop.wm.keybindings close "['<Super>w', '<Alt>F4']"
  gs_set org.gnome.desktop.wm.keybindings minimize "['<Super>m', '<Super>h']"
  gs_set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
  gs_set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down']"
  gs_set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"

  gs_set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
  gs_set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
  gs_set org.gnome.desktop.wm.keybindings switch-group "['<Super>Above_Tab', '<Alt>Above_Tab']"
  gs_set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Super>Above_Tab', '<Shift><Alt>Above_Tab']"

  gs_set org.gnome.desktop.wm.keybindings switch-input-source "['<Control><Super>space', 'XF86Keyboard']"
  gs_set org.gnome.desktop.wm.keybindings switch-input-source-backward "['<Shift><Control><Super>space', '<Shift>XF86Keyboard']"

  gs_set org.gnome.shell.keybindings toggle-overview "['<Super>space', '<Super>s']"
  gs_set org.gnome.shell.keybindings toggle-application-view "['<Super>a']"

  gs_set org.gnome.settings-daemon.plugins.media-keys terminal "['<Super>t', '<Primary><Alt>t']"
  gs_set org.gnome.settings-daemon.plugins.media-keys control-center "['<Super>comma']"
  gs_set org.gnome.settings-daemon.plugins.media-keys screensaver "['<Super>l']"

  gs_set org.gnome.settings-daemon.plugins.media-keys screenshot "['<Shift><Super>3', 'Print']"
  gs_set org.gnome.settings-daemon.plugins.media-keys area-screenshot "['<Shift><Super>4', '<Shift>Print']"
  gs_set org.gnome.settings-daemon.plugins.media-keys screenshot-clip "['<Control><Shift><Super>3', '<Control>Print']"
  gs_set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clip "['<Control><Shift><Super>4', '<Control><Shift>Print']"

  ok "Shortcut macOS diterapkan."
fi

# --- Flatpak theme access (kalau ada) ---
if command -v flatpak >/dev/null 2>&1; then
  sudo flatpak override --filesystem=xdg-config/gtk-3.0 \
                       --filesystem=xdg-config/gtk-4.0 \
                       >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------
# Verifikasi ringkas
# ------------------------------------------------------------
step "10/10  Verifikasi"

CURRENT_GTK="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || true)"
CURRENT_ICON="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || true)"
CURRENT_CURSOR="$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null | tr -d "'" || true)"
CURRENT_BUTTONS="$(gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null || true)"
CURRENT_DOCK_SIZE="$(gsettings get org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 2>/dev/null || true)"
CURRENT_DOCK_OPACITY="$(gsettings get org.gnome.shell.extensions.dash-to-dock background-opacity 2>/dev/null || true)"

printf '\n%sRingkasan:%s\n' "${BOLD}" "$RESET"
printf '  GTK theme      : %s\n' "${CURRENT_GTK:-?}"
printf '  Icon theme     : %s\n' "${CURRENT_ICON:-?}"
printf '  Cursor theme   : %s\n' "${CURRENT_CURSOR:-?}"
printf '  Tombol jendela : %s\n' "${CURRENT_BUTTONS:-?}"
printf '  Dock icon size : %s\n' "${CURRENT_DOCK_SIZE:-?}"
printf '  Dock opacity   : %s\n' "${CURRENT_DOCK_OPACITY:-?}"
printf '  Wallpaper      : %s\n' "${WALLPAPER_URI:-tidak berubah}"
printf '  Backup         : %s\n' "$BACKUP_DIR"

printf '\n%sSelesai!%s\n' "${GREEN}${BOLD}" "$RESET"
cat <<EOF

Langkah terakhir:
  1. Logout sepenuhnya, lalu login kembali.
     (Di Ubuntu 22.04/24.04 bisa juga reboot.)
  2. Kalau dock belum muncul, buka "Extensions" dan aktifkan "Ubuntu Dock".
  3. Kalau tema GNOME Shell belum berubah, pastikan ekstensi
     "User Themes" aktif, lalu logout/login sekali lagi.

Rollback pengaturan:
  ${SCRIPT_DIR}/restore.sh "${BACKUP_DIR}"

Catatan:
  - Angka 22 pada referensi adalah 22% opasitas dock.
    Ukuran ikon dock di script ini default 56 px (seperti referensi).
    Untuk ikon 22 px: ./install.sh --icon-size 22
  - Script ini mengubah pengaturan GNOME user, bukan sistem-wide.
EOF
