#!/usr/bin/env bash
# =============================================================================
# setup-deps.sh — PERLENGKAPAN TAMAHAN untuk desktop (FILE BARU, bukan bagian
# dari 11 script asli; tidak ada script yang diubah sedikit pun)
#
# Melengkapi kebutuhan yang TIDAK disediakan install-all.sh agar instalasi di
# desktop Ubuntu/GNOME berjalan mulus:
#
#   1. Paket apt: sassc (wajib untuk build tema GTK WhiteSur — tidak dipasang
#      oleh script mana pun), Pillow (generate wallpaper), fontconfig,
#      git/curl/unzip, libglib2.0-bin, libgtk-3-bin (update cache ikon).
#   2. Bit eksekusi untuk semua file di scripts/.
#   3. Wallpaper hasil generate ditaruh di ~/Pictures/Wallpapers
#      (kalau sudah ada, install-all.sh otomatis melewati langkah wallpaper).
#   4. Ekstensi User Themes (build Ubuntu 22.04 / GNOME 42) dipasang offline
#      dari bundle — install-all.sh lalu mencatat "User Themes already
#      installed" dan tidak perlu menghubungi extensions.gnome.org.
#
# Pakai (sekali jalan, di desktop):
#   bash ~/ubuntu-macos-customization/setup-deps.sh
# =============================================================================
set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"
UUID="user-theme@gnome-shell-extensions.gcampax.github.com"

echo "==> [1/4] Paket sistem (apt, butuh sudo)"
sudo apt-get update
sudo apt-get install -y git curl unzip fontconfig sassc libglib2.0-bin \
  libgtk-3-bin python3 python3-pil

echo "==> [2/4] Bit eksekusi untuk skrip"
chmod +x "$BASE"/scripts/*.sh "$BASE"/scripts/*.py
echo "       OK"

echo "==> [3/4] Wallpaper -> ~/Pictures/Wallpapers"
mkdir -p "$HOME/Pictures/Wallpapers"
for w in Sequoia-light.jpg Sequoia-dark.jpg; do
  if [ -f "$BASE/wallpapers/$w" ] && [ ! -f "$HOME/Pictures/Wallpapers/$w" ]; then
    cp "$BASE/wallpapers/$w" "$HOME/Pictures/Wallpapers/$w"
    echo "       copied $w"
  else
    echo "       $w sudah ada / tidak tersedia, dilewati"
  fi
done

echo "==> [4/4] Ekstensi User Themes -> ~/.local/share/gnome-shell/extensions"
EXT_DST="$HOME/.local/share/gnome-shell/extensions/$UUID"
if [ -d "$EXT_DST" ]; then
  echo "       sudah terpasang, dilewati"
elif [ -d "$BASE/extras/$UUID" ]; then
  mkdir -p "$(dirname "$EXT_DST")"
  cp -a "$BASE/extras/$UUID" "$EXT_DST"
  echo "       terpasang (offline)"
else
  echo "       tidak ada di bundle; install-all.sh akan mengunduh sendiri"
fi

cat <<EOF

Selesai. Langkah berikutnya:
  $BASE/scripts/install-all.sh      # pasang tema / ikon / kursor / ekstensi / font
  $BASE/scripts/setup-safe.sh       # backup + terapkan tampilan macOS
  $BASE/scripts/set-mode.sh dark    # ganti mode terang/gelap kapan saja
EOF
