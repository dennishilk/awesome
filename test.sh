#!/bin/bash
# =============================================================
# 🧠 Debian 13 (Trixie) Setup Script
# Btrfs + GRUB + Timeshift Autosnap + Zen Kernel + DWM + Wallpaper
# Author: Dennis Hilk
# License: MIT
# =============================================================

set -e

echo "=== 🧩 System aktualisieren ==="
sudo apt update && sudo apt full-upgrade -y

echo "=== ⚙️ Installiere Basiswerkzeuge ==="
sudo apt install -y build-essential git curl wget nano unzip \
  btrfs-progs grub-btrfs timeshift timeshift-autosnap software-properties-common

echo "=== 🧱 Prüfe Btrfs-Dateisystem ==="
ROOT_FS=$(findmnt -n -o FSTYPE /)
if [ "$ROOT_FS" != "btrfs" ]; then
  echo "❌ Root ist kein Btrfs! Bitte Debian mit Btrfs installieren."
  exit 1
fi

echo "=== 📁 Erstelle Subvolumes falls nötig ==="
sudo btrfs subvolume list / | grep -q '@' || {
  sudo btrfs subvolume create /@ || true
  sudo btrfs subvolume create /@home || true
  sudo btrfs subvolume create /@snapshots || true
}

echo "=== 🧠 Aktiviere grub-btrfsd für Timeshift Autosnap ==="
sudo systemctl enable --now grub-btrfsd.service

echo "=== 💻 Installiere DWM + Xorg + Tools ==="
sudo apt install -y xorg dwm suckless-tools stterm feh picom slstatus

echo "=== ⚙️ Installiere den Zen-Kernel ==="
# Debian nennt ihn linux-image-zen oder linux-image-liquorix je nach Repo
if ! apt-cache search linux-image-liquorix-amd64 | grep -q liquorix; then
  echo "→ Zen-Kernel Repo hinzufügen (Liquorix)"
  sudo add-apt-repository -y ppa:damentz/liquorix
  sudo apt update
fi
sudo apt install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64

echo "=== 🖼️ Installiere Wallpaper ==="
if [ -f "./coding-2.png" ]; then
  sudo mkdir -p /usr/share/backgrounds
  sudo cp ./coding-2.png /usr/share/backgrounds/wallpaper.png
  echo "✅ Wallpaper installiert unter /usr/share/backgrounds/wallpaper.png"
else
  echo "⚠️  Kein coding-2.png im Skriptordner gefunden – bitte manuell kopieren."
fi

echo "=== 🧠 Autostart und Xinitrc anlegen ==="
mkdir -p ~/.dwm
cat > ~/.dwm/autostart.sh <<'EOF'
#!/bin/bash
feh --bg-scale /usr/share/backgrounds/wallpaper.png &
picom --experimental-backends &
slstatus &
EOF
chmod +x ~/.dwm/autostart.sh

cat > ~/.xinitrc <<'EOF'
#!/bin/bash
~/.dwm/autostart.sh &
exec dwm
EOF
chmod +x ~/.xinitrc

echo "=== 🔧 Auto-Login in DWM (tty1) ==="
PROFILE=/home/$USER/.bash_profile
grep -q startx "$PROFILE" || echo '[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx' >> "$PROFILE"

echo "=== 🧰 Optional: NVIDIA + CUDA ==="
echo "Um GPU-Treiber zu installieren, führe später aus:"
echo "  sudo apt install nvidia-driver nvidia-cuda-toolkit"

echo
echo "✅ Alles fertig!"
echo "System läuft mit Btrfs, Timeshift Autosnap, DWM und Zen-Kernel."
echo "Bitte neu starten mit:  sudo reboot"

