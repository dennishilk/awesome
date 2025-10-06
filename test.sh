#!/bin/bash
# =============================================================
# 🧠 Debian 13 (Trixie) Setup Script
# Btrfs + GRUB + Timeshift Autosnap + Zen Kernel + DWM + Wallpaper
# with automatic repository fix
# Author: Dennis Hilk
# License: MIT
# =============================================================

set -e

echo "=== 🧩 1. Setze Debian-Repositories ==="
# Erkenne Debian-Version (Bookworm oder Trixie)
CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)

if [ -z "$CODENAME" ]; then
  echo "❌ Konnte Debian-Version nicht bestimmen."
  exit 1
fi

sudo bash -c "cat > /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian ${CODENAME} main contrib non-free non-free-firmware
deb http://deb.debian.org/debian ${CODENAME}-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${CODENAME}-security main contrib non-free non-free-firmware
deb http://deb.debian.org/debian ${CODENAME}-backports main contrib non-free non-free-firmware
EOF"

echo "✅ Repositories aktualisiert für Debian '$CODENAME'"

echo "=== 🧠 2. System aktualisieren ==="
sudo apt update && sudo apt full-upgrade -y

echo "=== ⚙️ 3. Installiere Basis-Tools ==="
sudo apt install -y build-essential git curl wget nano unzip btrfs-progs \
  grub-btrfs timeshift software-properties-common xorg dwm suckless-tools stterm feh picom slstatus

# --- Timeshift Autosnap manuell installieren, falls im Repo nicht vorhanden ---
if ! apt-cache show timeshift-autosnap >/dev/null 2>&1; then
  echo "⚙️  Installiere timeshift-autosnap aus GitHub ..."
  cd /tmp
  git clone https://github.com/wmutschl/timeshift-autosnap-apt.git
  cd timeshift-autosnap-apt
  sudo ./install.sh
  cd
else
  sudo apt install -y timeshift-autosnap
fi

echo "=== 🧱 4. Prüfe Btrfs-Root-Dateisystem ==="
ROOT_FS=$(findmnt -n -o FSTYPE /)
if [ "$ROOT_FS" != "btrfs" ]; then
  echo "❌ Root ist kein Btrfs! Bitte Debian auf Btrfs installieren."
  exit 1
fi

echo "=== 📁 5. Erstelle Subvolumes falls nötig ==="
sudo btrfs subvolume list / | grep -q '@' || {
  sudo btrfs subvolume create /@ || true
  sudo btrfs subvolume create /@home || true
  sudo btrfs subvolume create /@snapshots || true
}

echo "=== 🧠 6. Aktiviere grub-btrfsd & Timeshift Autosnap ==="
sudo systemctl enable --now grub-btrfsd.service || true
sudo update-grub

echo "=== 💻 7. Installiere Zen-Kernel (Liquorix) ==="
if ! apt-cache search linux-image-liquorix-amd64 | grep -q liquorix; then
  echo "→ Zen-Kernel-Repository (Liquorix) hinzufügen ..."
  sudo add-apt-repository -y ppa:damentz/liquorix || true
  sudo apt update
fi
sudo apt install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64 || {
  echo "⚠️  Liquorix-Pakete nicht gefunden. Überspringe Kernel."
}

echo "=== 🖼️ 8. Installiere Wallpaper ==="
if [ -f "./coding-2.png" ]; then
  sudo mkdir
