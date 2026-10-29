# Ubuntu → macOS (Big Sur / Ventura / Tahoe)

Installer otomatis untuk mengubah tampilan Ubuntu (GNOME) menjadi semirip mungkin
dengan macOS: ikon, dock, kursor, wallpaper, terminal, font, tombol jendela
berwarna di kanan, dan shortcut keyboard ala macOS.

Referensi tampilan: `referensi.png` (screenshot desktop macOS-like) dan repo
[Chiu-Tat/Ubuntu-to-MacOS-setting](https://github.com/Chiu-Tat/Ubuntu-to-MacOS-setting).
Tema/ikon/kursor/wallpaper memakai proyek **vinceliuice**:

- [MacTahoe GTK Theme](https://github.com/vinceliuice/MacTahoe-gtk-theme)
- [MacTahoe Icon + Cursor Theme](https://github.com/vinceliuice/MacTahoe-icon-theme)
- [WhiteSur GTK Theme](https://github.com/vinceliuice/WhiteSur-gtk-theme)
- [WhiteSur Icon Theme](https://github.com/vinceliuice/WhiteSur-icon-theme)
- [WhiteSur Cursors](https://github.com/vinceliuice/WhiteSur-cursors)
- [WhiteSur Wallpapers](https://github.com/vinceliuice/WhiteSur-wallpapers)

> **Status:** script sudah dicek sintaksnya (`bash -n`) dan alur lengkapnya sudah
> diuji dengan simulasi (perintah `gsettings`/`dconf`/unduhan/theme di-stub),
> tetapi **belum dijalankan di Ubuntu asli** sesuai permintaan. Jalankan di mesin
> Ubuntu yang siap diubah.

---

## Yang akan diubah

| Bagian | Hasil |
|---|---|
| Tema GTK/Shell | MacTahoe (default, paling mirip `referensi.png`) atau WhiteSur (Big Sur) |
| Ikon | MacTahoe / WhiteSur, gaya macOS |
| Kursor | MacTahoe-light (mode gelap: MacTahoe-dark) / WhiteSur cursors |
| Wallpaper | MacTahoe night (default), atau Big Sur / Ventura |
| Dock | Bawah, mengambang, ikon 56 px (bisa diubah), latar 22% opasitas, indikator titik |
| Tombol jendela | Di **kanan**: minimize, maximize, close; warna merah/kuning/hijau dari tema |
| Terminal | Profil GNOME Terminal “macOS”: background gelap, palet warna, font JetBrains Mono, transparan 10% |
| Font UI | Inter 11 (fallback Cantarell/Ubuntu) |
| Top bar | Jam + tanggal, ikon Apple (dari tema Shell), battery percentage; opsi auto-hide |
| Shortcut | `Super+W` close, `Super+M/H` minimize, `Super+Tab` app switcher, `Super+T` terminal, dll. |
| Nautilus | Double-click, thumbnail selalu tampil |
| Desktop | Ikon Home/Trash disembunyikan |

Hal yang **tidak** diubah:

- Tema GDM/login screen (berisiko membuat login gagal).
- GRUB/Plymouth.
- Gesture touchpad kustom (Touchégg, three-finger drag, dll.). Repo referensi
  memakai Ubuntu 20.04 + Rust + extension khusus; tidak dipasang di sini agar
  kompatibel dengan Ubuntu 22.04/24.04+.
- Aplikasi pihak ketiga (Chrome, VS Code, dll.) — hanya ikonnya yang mengikuti
  tema jika aplikasinya terpasang.

---

## Persyaratan

- Ubuntu 20.04/22.04/24.04+ dengan GNOME (default Ubuntu).
- Sesi desktop aktif (bukan SSH/TTY), karena installer memakai `gsettings`/`dconf`.
- Koneksi internet (mengunduh tema + wallpaper).
- Akses `sudo` (script akan meminta password sendiri).
- Ruang disk ± 500 MB untuk tema/ikon.

**Jangan** jalankan dengan `sudo ./install.sh`. Jalankan sebagai user desktop
biasa; script memakai `sudo` hanya untuk apt dan beberapa operasi sistem.

---

## Cara pakai

```bash
cd /path/ke/folder/ini
chmod +x install.sh restore.sh verify.sh
./install.sh
```

Setelah selesai:

1. **Logout sepenuhnya**, lalu login lagi (atau reboot).
2. Jika diminta memilih sesi, pilih **Ubuntu** (Wayland) atau **Ubuntu on Xorg**.
3. Jalankan `./verify.sh` untuk melihat status tema/dock/ekstensi.
4. Jika dock belum muncul: buka **Extensions** → aktifkan **Ubuntu Dock**.
5. Jika tema Shell belum berubah: pastikan **User Themes** aktif, lalu logout/login sekali lagi.

---

## Konfigurasi

Semua opsi ada di `macos-theme.conf`. Ubah sebelum menjalankan installer.

Contoh:

```bash
# Gaya Big Sur klasik, mode gelap, ikon dock 56 px
./install.sh --family bigsur --dark --icon-size 56

# Ikon dock 22 px (kalau memang ingin sekecil itu)
./install.sh --icon-size 22

# Wallpaper Ventura gelap
./install.sh --wallpaper ventura-dark

# Wallpaper sendiri
./install.sh --wallpaper custom --wallpaper-file ~/Pictures/wallpaper.jpg

# Dock selalu tampil (tidak auto-hide)
./install.sh --no-autohide

# Menu bar atas auto-hide
./install.sh --hide-topbar
```

Opsi CLI lengkap: `./install.sh --help`

### Tentang angka “22”

Screenshot referensi memakai:

- ukuran ikon dock **56 px**
- opasitas latar dock **22%** (`0.22`)

Jadi di script ini default-nya `DOCK_ICON_SIZE=56` dan `DOCK_BG_OPACITY=0.22`
agar semirip `referensi.png`. Kalau yang dimaksud memang **ikon 22 px**,
jalankan `./install.sh --icon-size 22` atau ubah `DOCK_ICON_SIZE=22` di
`macos-theme.conf`.

---

## Rollback

Installer otomatis membuat backup di:

```
~/.local/state/ubuntu-macos-installer/backup-YYYYMMDD-HHMMSS/
```

Kembalikan pengaturan GNOME:

```bash
./restore.sh
# atau
./restore.sh ~/.local/state/ubuntu-macos-installer/backup-20261029-180000
```

`restore.sh` mengembalikan dconf GNOME, konfigurasi GTK3/GTK4, dan terminal.
Tema/ikon/kursor yang sudah terpasang **tidak** dihapus otomatis (bisa dihapus
manual dari `~/.themes` dan `~/.local/share/icons`).

---

## Troubleshooting

**Dock tidak muncul / tidak berubah**
- Logout/login, lalu cek `gnome-extensions list --enabled | grep -i dock`.
- Di Ubuntu, ekstensi yang benar adalah `ubuntu-dock@ubuntu.com`.
- Kalau memakai GNOME non-Ubuntu, script mencoba fallback
  `dash-to-dock@micxgx.gmail.com`; ekstensi Dash to Dock harus terpasang.

**Tema GNOME Shell tidak berubah**
- Pastikan ekstensi `user-theme@gnome-shell-extensions.gcampax.github.com` aktif.
- Pastikan `gsettings get org.gnome.shell.extensions.user-theme name`
  menghasilkan nama tema yang benar.
- Logout/login (bukan hanya lock screen).

**Tombol jendela belum berwarna**
- Tema GTK hanya memengaruhi aplikasi GTK. Aplikasi non-GTK (mis. Firefox
  dengan tema bawaan) bisa punya tombol sendiri.
- Cek: `gsettings get org.gnome.desktop.wm.preferences button-layout`
  harus `appmenu:minimize,maximize,close`.

**Kursor belum berubah**
- Logout/login. Beberapa aplikasi (Flatpak/Snap) perlu izin akses tema.
- Cek: `gsettings get org.gnome.desktop.interface cursor-theme`.

**Font tidak berubah**
- Pastikan paket `fonts-inter` dan `fonts-jetbrains-mono` terpasang:
  `fc-list | grep -i inter`.
- Jalankan `fc-cache -f` lalu logout/login.

**Terminal tidak berubah**
- Pastikan paket `gnome-terminal` terpasang dan profil `macOS` ada:
  `gsettings get org.gnome.Terminal.ProfilesList default`.
- Kalau memakai terminal lain (GNOME Console/Ptyxis), profil ini tidak berlaku.

**GNOME 46/47/48+**
- Tema MacTahoe/WhiteSur versi terbaru umumnya mendukung GNOME baru.
- Ekstensi Ubuntu Dock/User Themes mengikuti versi GNOME dari repo Ubuntu.
- Script memberi peringatan, bukan memblokir, jika GNOME lebih baru dari 48.

---

## Struktur file

```
.
├── install.sh          # installer utama
├── restore.sh          # rollback pengaturan GNOME
├── verify.sh           # cek hasil instalasi
├── macos-theme.conf    # konfigurasi
├── referensi.png       # screenshot referensi
└── README.md
```

---

## Lisensi / kredit

Script installer ini bebas dipakai dan diubah. Tema, ikon, kursor, dan wallpaper
mengikuti lisensi masing-masing proyek vinceliuice (GPL-3.0 untuk tema GTK;
lihat repo masing-masing). Wallpaper macOS adalah milik Apple; gunakan hanya
untuk keperluan pribadi.
