# 🍎 Ubuntu → macOS Look

> Ubah desktop **Ubuntu GNOME** menjadi tampilan ala **macOS** — tema WhiteSur, ikon & kursor macOS, font Inter, dock bawah bergaya Launchpad, efek kaca (blur), serta wallpaper Sequoia yang dibuat otomatis dari kode.

[![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20GNOME-E95420?logo=ubuntu&logoColor=white)](#persyaratan)
[![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)](#)
[![Python](https://img.shields.io/badge/python-3.x-3776AB?logo=python&logoColor=white)](#)
[![License](https://img.shields.io/badge/license-cek%20komponen%20pihak%20ketiga-lightgrey)](#lisensi)

Proyek ini **hanya mengubah tampilan level user** (`gsettings`/`dconf` dan file di `$HOME`). Tidak menyentuh paket sistem, GDM/display manager, maupun environment pengembangan. Semua langkah **idempotent** (aman dijalankan berulang) dan menyediakan **backup + restore**.

> ⚠️ Status: proyek kustomisasi desktop pribadi. Kompatibilitas bergantung pada versi Ubuntu, versi GNOME Shell, ekstensi yang terpasang, dan tipe sesi (X11/Wayland).

---

## ✨ Fitur

### Tampilan ala macOS

- 🎨 **WhiteSur GTK Theme** — gaya jendela & antarmuka aplikasi bergaya macOS (Monterey).
- 🖼️ **WhiteSur Icon Theme** — ikon aplikasi dan sistem yang konsisten.
- 🖱️ **WhiteSur Cursors** — kursor dengan tampilan khas macOS.
- 🌗 **Mode Terang & Gelap** — beralih antara `WhiteSur-Light` dan `WhiteSur-Dark`.
- 🔤 **Font Inter** — font antarmuka modern dan mudah dibaca (font monospace tidak diubah, aman untuk development).
- 🏔️ **Wallpaper Sequoia** — gradien terang & gelap yang digenerate sendiri (bebas aset pihak ketiga).
- 🐚 **GNOME Shell Theme** — tema shell diterapkan bila ekstensi *User Themes* tersedia.
- 🧊 **Blur / Frosted Glass** — integrasi *Blur My Shell* yang sudah dioptimalkan untuk performa.

### Dock & top bar

- Dock di **bawah**, ikon 46 px, *intellihide* + autohide.
- Indikator aplikasi berjalan bergaya **titik (dots)** seperti macOS.
- Tombol **Launchpad**, Trash, dan animasi buka aplikasi.
- Top bar menampilkan tanggal, jam 24 jam, dan persentase baterai.

### Otomasi & keamanan

- ⚙️ Instalasi otomatis tema, ikon, kursor, font, dan ekstensi GNOME terpilih.
- 🌓 **Mode watcher** (systemd user service) — tema GTK/ikon/shell otomatis ikut saat kamu mengganti *Settings → Appearance*.
- 💾 **Backup** konfigurasi GNOME sebelum perubahan.
- 📝 **Log instalasi** untuk mempermudah diagnosa error.
- ↩️ **Restore** untuk mengembalikan desktop Ubuntu seperti semula.

---

## 📋 Persyaratan

- Ubuntu Linux dengan desktop **GNOME**.
- Koneksi internet (untuk mengunduh repo tema, font, dan dependensi).
- `git`, `bash`, `python3`, dan utilitas build yang dibutuhkan.
- Akses `sudo` saat memasang dependensi sistem.
- Versi GNOME Shell yang kompatibel dengan ekstensi yang dipakai (proyek ini menargetkan **GNOME 42 / Ubuntu 22.04**, dengan *Blur My Shell v47* dan *User Themes* build GNOME 42).

> 💡 Ekstensi GNOME sangat sensitif terhadap versi. Periksa kompatibilitas sebelum memakainya di rilis Ubuntu/GNOME lain.

---

## 🚀 Instalasi

### 1. Clone repository

```bash
git clone git@github.com:Syuhadak27/ubuntu-mac.git
```

Jika SSH belum dikonfigurasi, gunakan HTTPS:

```bash
git clone https://github.com/Syuhadak27/ubuntu-mac.git
```

### 2. Letakkan file di lokasi yang diharapkan skrip

Skrip mengacu ke `~/ubuntu-macos-customization/scripts/`, jadi susun direktorinya seperti ini:

```bash
mv ubuntu-mac ~/ubuntu-macos-customization
cd ~/ubuntu-macos-customization
mkdir -p scripts
cp -a ./*.sh ./*.py ./scripts/
chmod +x ./scripts/*.sh ./scripts/*.py
```

> 📁 Hasil akhir: `~/ubuntu-macos-customization/scripts/{install-all.sh,macos-look.sh,...}` — lokasi inilah yang dipakai semua skrip.

### 3. Tinjau skrip (disarankan)

```bash
ls -la scripts/
less scripts/setup-deps.sh
less scripts/install-all.sh
less scripts/macos-look.sh
less scripts/backup-ubuntu.sh
less scripts/restore-ubuntu.sh
```

### 4. Pasang dependensi

```bash
bash scripts/setup-deps.sh
```

Langkah ini memasang paket sistem (butuh `sudo`): `git`, `curl`, `unzip`, `fontconfig`, `sassc`, `libglib2.0-bin`, `libgtk-3-bin`, `python3`, `python3-pil`. Sekaligus menyiapkan wallpaper dan (jika tersedia di bundle) ekstensi *User Themes* secara offline.

### 5. Pasang tema & aset visual

```bash
bash scripts/install-all.sh
```

Memasang WhiteSur GTK theme, ikon, kursor, ekstensi GNOME, font Inter, dan wallpaper. Log ada di `~/ubuntu-macos-customization/logs/`.

### 6. Backup lalu terapkan tampilan macOS

```bash
bash scripts/backup-ubuntu.sh   # snapshot konfigurasi GNOME
bash scripts/macos-look.sh      # terapkan tampilan
```

Atau jalankan keduanya sekaligus:

```bash
bash scripts/setup-safe.sh
```

> 🔁 **Logout lalu login kembali** agar ekstensi yang baru dipasang termuat sepenuhnya.

---

## 🎛️ Cara Pakai

### Ganti mode terang/gelap

```bash
bash ~/ubuntu-macos-customization/scripts/set-mode.sh dark
bash ~/ubuntu-macos-customization/scripts/set-mode.sh light
```

Perintah ini mengatur `color-scheme` GNOME lalu menerapkan tema GTK, ikon, shell theme, stylesheet GTK 4, dan kursor yang sesuai.

### Ganti mode lewat Settings

Setelah `macos-look.sh` dijalankan, service **mode watcher** aktif otomatis. Cukup buka **Settings → Appearance** dan pilih Light/Dark — seluruh desktop ikut berubah.

Cek status service:

```bash
systemctl --user status macos-mode-watcher.service
```

### Instal ulang komponen visual

```bash
bash ~/ubuntu-macos-customization/scripts/install-all.sh
```

Aman dijalankan berulang; installer hanya mengganti output miliknya sendiri.

### Lihat log

```bash
ls -lah ~/ubuntu-macos-customization/logs/
less ~/ubuntu-macos-customization/logs/whitesur-gtk-install.log
less ~/ubuntu-macos-customization/logs/apply-macos-look.log
```

### Backup ulang

```bash
bash ~/ubuntu-macos-customization/scripts/backup-ubuntu.sh
```

Backup tersimpan di `~/ubuntu-macos-customization/backups/<timestamp>/` dan `latest` selalu menunjuk ke backup terbaru.

### Kembalikan desktop Ubuntu

```bash
# lihat backup yang ada
ls -lah ~/ubuntu-macos-customization/backups/

# rollback (wajib konfirmasi eksplisit)
ALLOW_REAL_RESTORE=1 bash ~/ubuntu-macos-customization/scripts/restore-ubuntu.sh

# sertakan restore ~/.themes dan ~/.local/share/icons
ALLOW_REAL_RESTORE=1 bash ~/ubuntu-macos-customization/scripts/restore-ubuntu.sh --full

# pilih backup tertentu
ALLOW_REAL_RESTORE=1 bash ~/ubuntu-macos-customization/scripts/restore-ubuntu.sh --backup ~/ubuntu-macos-customization/backups/20260101-120000
```

Skrip restore berakhir dengan validasi **PASS/FAIL** terhadap snapshot. Logout/login lagi agar shell memuat ulang ekstensi.

> ℹ️ Restore **tidak** menghapus paket sistem. Yang dikembalikan: setting GNOME, ekstensi yang dipasang proyek, font Inter, kursor WhiteSur, wallpaper, config GTK 3/4, dan service watcher.

---

## 🗂️ Struktur Proyek

| File | Fungsi |
| --- | --- |
| `setup-deps.sh` | Memasang dependensi sistem & menyiapkan aset (wallpaper, User Themes offline). |
| `install-all.sh` | Memasang tema, ikon, kursor, font, dan ekstensi GNOME. |
| `macos-look.sh` | Menerapkan tampilan macOS (font, dock, blur, wallpaper, shell theme, watcher). |
| `apply-mode.sh` | Menerapkan setting visual untuk satu mode (`light`/`dark`). |
| `set-mode.sh` | Perintah cepat untuk mengganti mode terang/gelap. |
| `mode-watcher.sh` | Menjaga tema tetap sinkron dengan `color-scheme` GNOME. |
| `macos-mode-watcher.service` | Unit systemd user untuk mode watcher. |
| `backup-ubuntu.sh` | Menyimpan snapshot konfigurasi desktop. |
| `restore-ubuntu.sh` | Mengembalikan konfigurasi dari snapshot (dengan validasi). |
| `setup-safe.sh` | Backup + terapkan tampilan dalam satu perintah. |
| `generate-wallpaper.py` | Membuat wallpaper Sequoia terang & gelap (1920×1080) dengan Pillow. |
| `portal-shot.py` | Utilitas screenshot lewat XDG portal (khusus Wayland). |

Direktori yang muncul saat runtime:

- `repositories/` — repo tema & ekstensi hasil clone
- `logs/` — log instalasi & mode watcher
- `backups/` — snapshot konfigurasi
- `wallpapers/`, `extras/` — aset opsional

---

## 🩺 Troubleshooting

<details>
<summary><b>Tema tidak sepenuhnya diterapkan</b></summary>

- Pastikan tema benar-benar terpasang di `~/.themes` / `~/.local/share/themes`.
- Periksa versi GNOME Shell dan kompatibilitas ekstensi.
- Logout lalu login kembali.
- Cek log instalasi di `logs/`.

</details>

<details>
<summary><b>Mode terang/gelap tidak mengubah semua aplikasi</b></summary>

Sebagian aplikasi memakai setting tema sendiri atau styling GTK 4/libadwaita. Periksa stylesheet GTK 4 yang aktif (`~/.config/gtk-4.0/gtk.css`) dan nilai `color-scheme` GNOME.

</details>

<details>
<summary><b>Ekstensi GNOME gagal dimuat</b></summary>

Cocokkan versi Shell yang didukung ekstensi. Ekstensi untuk GNOME 42 belum tentu berjalan di rilis yang lebih baru.

</details>

<details>
<summary><b>Error symbolic link di penyimpanan Android</b></summary>

Simpan repo di filesystem Linux (mis. home Ubuntu), bukan di `/storage/emulated/0/`, karena penyimpanan bersama Android tidak mendukung perilaku symbolic link Linux. Untuk backup, gunakan arsip:

```bash
tar -czf ubuntu-macos-customization.tar.gz ubuntu-macos-customization/
```

</details>

<details>
<summary><b>Skrip bilang "Copy files to .../scripts first"</b></summary>

Ulangi langkah 2 di atas agar semua `.sh`/`.py` berada di `~/ubuntu-macos-customization/scripts/`.

</details>

---

## 🔒 Catatan Keamanan

- Tinjau skrip shell sebelum menjalankannya.
- Jangan jalankan seluruh proses sebagai `root` kecuali operasi tertentu memang butuh privilege.
- Backup data penting sebelum mengubah desktop secara signifikan.
- Simpan salinan konfigurasi GNOME asli.
- Tema/ekstensi pihak ketiga bisa rusak setelah upgrade sistem.

---

## 🙏 Kredit

Proyek ini memakai/mengintegrasikan karya:

- [WhiteSur GTK Theme](https://github.com/vinceliuice/WhiteSur-gtk-theme) — vinceliuice
- [WhiteSur Icon Theme](https://github.com/vinceliuice/WhiteSur-icon-theme) — vinceliuice
- [WhiteSur Cursors](https://github.com/vinceliuice/WhiteSur-cursors) — vinceliuice
- [Blur My Shell](https://github.com/aunetx/blur-my-shell) — aunetx
- [Inter Font](https://github.com/rsms/inter) — Rasmus Andersson

Semua komponen pihak ketiga tetap tunduk pada lisensi masing-masing.

---

## 📄 Lisensi

Periksa lisensi repository dan komponen yang diunduh sebelum mendistribusikan ulang proyek atau asetnya.

---

**Repository:** [Syuhadak27/ubuntu-mac](https://github.com/Syuhadak27/ubuntu-mac)

Dibuat untuk pengguna Ubuntu yang ingin nuansa macOS tanpa meninggalkan Linux.
