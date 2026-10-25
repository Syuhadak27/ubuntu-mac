Ubuntu macOS Customization

Transform your Ubuntu GNOME desktop into a macOS-inspired environment with WhiteSur themes, macOS-style icons, cursors, wallpapers, and desktop visual effects.

This project automates desktop appearance customization while keeping the original Ubuntu system and development environment intact.

«Project status: Personal desktop customization project. Compatibility depends on your Ubuntu version, GNOME Shell version, installed extensions, and session type.»

Features

macOS-inspired appearance

- WhiteSur GTK theme — macOS-inspired application windows and interface styling.
- WhiteSur icon theme — consistent macOS-style application and system icons.
- WhiteSur cursor theme — matching pointer appearance.
- Light and dark modes — switch between "WhiteSur-Light" and "WhiteSur-Dark".
- Inter font — a modern, readable interface font.
- macOS-style wallpapers — generated or installed Sequoia-inspired light and dark wallpapers.
- GNOME Shell theming — applies the matching shell theme when the required extension is available.
- Blur effects — integrates Blur My Shell for compatible GNOME environments.

Automation and configuration

- Automated installation of themes, icons, cursors, fonts, and selected GNOME extensions.
- Light/dark mode scripts for applying appearance settings.
- Mode watcher service for automating appearance changes when configured and enabled.
- Configuration backup before applying desktop changes.
- Installation logs to help diagnose errors.
- Ubuntu restoration scripts to help recover the original desktop configuration.

Requirements

- Ubuntu Linux with the GNOME desktop environment.
- An internet connection to download repositories and dependencies.
- Git, Bash, Python 3, and the required build utilities.
- "sudo" access when installing system dependencies.
- A compatible GNOME Shell version for the selected extensions.

Important: GNOME extensions are version-sensitive. Check compatibility before installing them on a different Ubuntu or GNOME release.

Installation

1. Clone the repository

git clone git@github.com:Syuhadak27/ubuntu-mac.git
cd ubuntu-mac

If SSH authentication is not configured, use HTTPS instead:

git clone https://github.com/Syuhadak27/ubuntu-mac.git
cd ubuntu-mac

2. Review the scripts

Before executing scripts that change your desktop, inspect their contents:

ls -la

Review the installation and restoration scripts:

less setup-deps.sh
less install-all.sh
less macos-look.sh
less backup-ubuntu.sh
less restore-ubuntu.sh

3. Prepare dependencies

The dependency setup installs required packages and prepares supporting files.

bash setup-deps.sh

This step may request your password through "sudo" to install system packages.

4. Install themes and visual assets

bash install-all.sh

This script installs the WhiteSur GTK theme, icons, cursors, compatible GNOME extensions, Inter font, and wallpaper assets.

5. Back up and apply the macOS appearance

bash backup-ubuntu.sh
bash macos-look.sh

The backup script records GNOME settings and relevant desktop configuration before customization. Review the backup logs to confirm which components were saved.

Note: The current scripts contain references to a "scripts/" subdirectory. Ensure the repository's actual directory layout matches those references before running the commands above.

Usage

Switch to dark mode

bash set-mode.sh dark

Switch to light mode

bash set-mode.sh light

The mode scripts apply the corresponding GTK theme, icon theme, shell theme when available, GTK 4 stylesheet, and cursor configuration.

Reinstall the visual components

bash install-all.sh

Use this when a theme or visual component needs to be reinstalled. Review the logs if any step fails.

Inspect installation logs

ls -lah logs/

Read a specific log, for example:

less logs/whitesur-gtk-install.log

Available log files depend on which installation steps have run.

Restore the Ubuntu desktop

If you want to undo the customization, first inspect the available backups:

ls -lah ~/ubuntu-macos-customization/backups/

Then review the restoration script:

less restore-ubuntu.sh

Follow its documented usage to select the appropriate backup and restore the original configuration.

Do not assume that restoring settings removes every installed theme, extension, font, or package. Review the restoration script to understand exactly what it restores and what it leaves installed.

Project structure

The repository includes the following scripts:

File| Purpose
"setup-deps.sh"| Installs supporting system dependencies and prepares assets.
"install-all.sh"| Installs themes, icons, cursors, fonts, and selected extensions.
"macos-look.sh"| Applies the macOS-inspired GNOME appearance.
"apply-mode.sh"| Applies light or dark appearance settings.
"set-mode.sh"| Changes the selected appearance mode.
"mode-watcher.sh"| Supports automatic appearance-mode handling.
"macos-mode-watcher.service"| Service definition for the mode watcher.
"backup-ubuntu.sh"| Saves desktop settings and related configuration.
"restore-ubuntu.sh"| Restores configuration using the project's restoration procedure.
"generate-wallpaper.py"| Generates wallpaper assets.
"portal-shot.py"| Supporting portal/screenshot utility.

Other directories, such as "repositories/", "wallpapers/", "logs/", "backups/", and "scripts/", contain downloaded repositories, visual assets, diagnostic logs, saved configurations, or supporting scripts when present.

Troubleshooting

Theme does not apply completely

- Confirm that the theme is installed.
- Check the GNOME Shell version and extension compatibility.
- Log out and log back in if required.
- Review the installation logs.

Light/dark mode does not change all applications

Some applications use their own theme settings or GTK 4/libadwaita styling. Verify the active GTK stylesheet and GNOME color-scheme configuration.

GNOME extension fails to load

Check the extension's supported GNOME Shell versions. An extension built for GNOME 42 may not work correctly on newer releases.

Symbolic-link errors on Android shared storage

Keep the working repository in a Linux filesystem, such as your Ubuntu home directory. Android shared storage at "/storage/emulated/0/" does not support normal Linux symbolic-link behavior.

For backup, create an archive instead:

tar -czf ubuntu-macos-customization.tar.gz ubuntu-macos-customization/

This preserves symbolic-link metadata inside the archive.

Safety notes

- Review shell scripts before executing them.
- Do not run the entire customization process as root unless a particular operation explicitly requires elevated privileges.
- Back up important data before making significant desktop changes.
- Keep a copy of your original GNOME configuration.
- Third-party themes and extensions may break after system upgrades.

Credits

This project uses or integrates work from:

- "WhiteSur GTK Theme" (https://github.com/vinceliuice/WhiteSur-gtk-theme)
- "WhiteSur Icon Theme" (https://github.com/vinceliuice/WhiteSur-icon-theme)
- "WhiteSur Cursors" (https://github.com/vinceliuice/WhiteSur-cursors)
- "Blur My Shell" (https://github.com/aunetx/blur-my-shell)
- "Inter Font" (https://github.com/rsms/inter)

All third-party components remain subject to their respective licenses.

License

Check the repository and the licenses of the bundled or downloaded components before redistributing this project or its assets.

---

Repository: "Syuhadak27/ubuntu-mac" (https://github.com/Syuhadak27/ubuntu-mac)

Made for Ubuntu users who want a macOS-inspired desktop experience without replacing Linux.