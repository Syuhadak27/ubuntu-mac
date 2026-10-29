#!/usr/bin/env bash
# ============================================================
#  Rollback pengaturan Ubuntu -> macOS
#
#  Penggunaan:
#      ./restore.sh
#      ./restore.sh /path/ke/backup-YYYYMMDD-HHMMSS
#
#  Script ini mengembalikan pengaturan GNOME (dconf) dan file
#  konfigurasi GTK4/GTK3 yang di-backup oleh install.sh.
#  Tema/ikon yang sudah terpasang tidak dihapus otomatis.
# ============================================================

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/ubuntu-macos-installer"

if [ -t 1 ]; then
  BOLD=$'\033[1m'
  GREEN=$'\033[32m'
  YELLOW=$'\033[33m'
  RED=$'\033[31m'
  RESET=$'\033[0m'
else
  BOLD=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

die()  { printf '%sERROR:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }
warn() { printf '%s  ! %s%s\n' "$YELLOW" "$*" "$RESET" >&2; }

[ "${EUID}" -ne 0 ] || die "Jangan jalankan dengan sudo/root. Jalankan sebagai user desktop pemilik pengaturan."

# dconf butuh sesi D-Bus. Kalau dijalankan dari TTY, pakai sesi sementara.
dc() {
  if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || ! command -v dbus-run-session >/dev/null 2>&1; then
    dconf "$@"
  else
    dbus-run-session -- dconf "$@"
  fi
}

BACKUP_DIR="${1:-}"
if [ -z "$BACKUP_DIR" ]; then
  BACKUP_DIR="$(ls -dt "${STATE_ROOT}"/backup-* 2>/dev/null | head -n1 || true)"
fi

[ -n "$BACKUP_DIR" ] || die "Tidak ada backup. Jalankan: $0 /path/ke/backup-YYYYMMDD-HHMMSS"
[ -d "$BACKUP_DIR" ] || die "Folder backup tidak ditemukan: $BACKUP_DIR"
[ -s "$BACKUP_DIR/gnome.dconf" ] || die "File gnome.dconf tidak ditemukan/kosong di $BACKUP_DIR"

printf '%sMengembalikan pengaturan GNOME dari:%s\n  %s\n' "${BOLD}" "$RESET" "$BACKUP_DIR"

# Hapus pengaturan GNOME yang dibuat setelah backup, lalu muat backup.
dc reset -f /org/gnome/ || warn "Sebagian pengaturan lama gagal direset."
if ! dc load /org/gnome/ < "$BACKUP_DIR/gnome.dconf"; then
  warn "dconf load tidak sepenuhnya berhasil. Periksa $BACKUP_DIR/gnome.dconf"
fi

# Kembalikan konfigurasi GTK4/GTK3 (kalau ada)
if [ -d "$BACKUP_DIR/gtk-4.0" ]; then
  rm -rf "$HOME/.config/gtk-4.0"
  cp -a "$BACKUP_DIR/gtk-4.0" "$HOME/.config/gtk-4.0"
elif [ -f "$BACKUP_DIR/gtk-4.0.absent" ]; then
  rm -rf "$HOME/.config/gtk-4.0"
fi
if [ -d "$BACKUP_DIR/gtk-3.0" ]; then
  rm -rf "$HOME/.config/gtk-3.0"
  cp -a "$BACKUP_DIR/gtk-3.0" "$HOME/.config/gtk-3.0"
elif [ -f "$BACKUP_DIR/gtk-3.0.absent" ]; then
  rm -rf "$HOME/.config/gtk-3.0"
fi

printf '%s  OK%s Pengaturan GNOME dikembalikan.\n' "$GREEN" "$RESET"
printf '\nLogout/login ulang agar perubahan terlihat.\n'
printf '%sCatatan:%s tema/ikon/kursor yang sudah terpasang tidak dihapus.\n' "$YELLOW" "$RESET"
