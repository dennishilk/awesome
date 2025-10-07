#!/usr/bin/env bash
# ==========================================================
# Dennis Hilk - AwesomeWM Interactive Installer
# Works on: Debian 13 (Trixie) & Arch Linux
# Features: Interactive menu, GPU auto-detect (NVIDIA/AMD/Intel/VM),
#           no display manager (optional TTY1 autologin + startx),
#           sane defaults (rofi, dunst, thunar, picom, pipewire)
# License: MIT — © 2025 Dennis Hilk
# GitHub: https://github.com/dennishilk
# ==========================================================

set -Eeuo pipefail

LOG_FILE="$HOME/dennishilk-awesome-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1


banner() {
  clear
  cat <<'EOF'

        AwesomeWM Setup — By Dennis Hilk
EOF
  echo
}

# -------- Helpers --------
die(){ echo "ERROR: $*" >&2; exit 1; }
confirm(){ read -rp "$1 [y/N]: " _c; [[ "${_c:-}" =~ ^[Yy]$ ]]; }
command_exists(){ command -v "$1" &>/dev/null; }

DISTRO=""
detect_distro(){
  if [[ -f /etc/debian_version ]]; then
    DISTRO="debian"
  elif [[ -f /etc/arch-release ]]; then
    DISTRO="arch"
  else
    die "Unsupported distro. Only Debian 13 and Arch Linux are supported."
  fi
}

GPU_KIND="unknown"
detect_gpu(){
  local lspci_out
  lspci_out="$(lspci -nnk 2>/dev/null || true)"
  if grep -qi 'NVIDIA' <<<"$lspci_out"; then GPU_KIND="nvidia"
  elif grep -Eqi 'AMD|Radeon' <<<"$lspci_out"; then GPU_KIND="amd"
  elif grep -qi 'Intel' <<<"$lspci_out"; then GPU_KIND="intel"
  elif grep -Eqi 'VirtualBox|VMware|QEMU|Virtio|Microsoft Hyper-V' <<<"$lspci_out"; then GPU_KIND="vm"
  else GPU_KIND="unknown"; fi
}

# -------- Package Sets --------
base_pkgs_debian=(
  xorg xserver-xorg xinit x11-xserver-utils x11-xkb-utils xinput
  awesome awesome-extra
  rofi dunst feh lxappearance
  thunar thunar-archive-plugin thunar-volman gvfs-backends unzip
  picom
  pipewire-audio pipewire-pulse pavucontrol pamixer
  xdg-user-dirs-gtk fonts-font-awesome fonts-terminus fonts-dejavu-core
  flameshot xclip curl wget git micro
)

base_pkgs_arch=(
  xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xinput
  awesome
  rofi dunst feh lxappearance
  thunar thunar-archive-plugin thunar-volman gvfs unzip
  picom
  pipewire pipewire-pulse wireplumber pavucontrol pamixer
  xdg-user-dirs ttf-dejavu ttf-font-awesome terminus-font
  flameshot xclip curl wget git micro
)

extra_terms_debian=( xterm alacritty )
extra_terms_arch=( xterm alacritty )

vm_tools_debian=( spice-vdagent qemu-guest-agent )
vm_tools_arch=( spice-vdagent qemu-guest-agent )

# GPU driver sets (keep conservative / stable)
gpu_debian_nvidia=( nvidia-driver firmware-misc-nonfree )
gpu_debian_amd=( firmware-amd-graphics mesa-vulkan-drivers )
gpu_debian_intel=( mesa-vulkan-drivers intel-media-va-driver-non-free || true )
gpu_arch_nvidia=( nvidia nvidia-utils )
gpu_arch_amd=( mesa vulkan-radeon )
gpu_arch_intel=( mesa vulkan-intel )

# -------- Install Routines --------
apt_update(){ sudo apt-get update; }
apt_install(){ sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"; }
pac_install(){ sudo pacman -Syu --noconfirm "$@"; }

install_base(){
  if [[ "$DISTRO" == "debian" ]]; then
    apt_update
    apt_install "${base_pkgs_debian[@]}"
    apt_install "${extra_terms_debian[@]}"
  else
    pac_install "${base_pkgs_arch[@]}"
    pac_install "${extra_terms_arch[@]}"
  fi
}

install_vm_tools(){
  if [[ "$GPU_KIND" != "vm" ]]; then return; fi
  echo "Installing VM guest tools…"
  if [[ "$DISTRO" == "debian" ]]; then
    apt_install "${vm_tools_debian[@]}"
    sudo systemctl enable --now qemu-guest-agent || true
  else
    pac_install "${vm_tools_arch[@]}"
    sudo systemctl enable --now qemu-guest-agent || true
  fi
}

install_gpu(){
  case "$GPU_KIND" in
    nvidia)
      echo "Detected GPU: NVIDIA"
      if [[ "$DISTRO" == "debian" ]]; then
        # Ensure non-free-firmware is available
        if ! grep -Eq 'non-free-firmware' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
          echo "Enabling non-free-firmware for Debian 13…"
          sudo sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
          apt_update
        fi
        apt_install "${gpu_debian_nvidia[@]}"
      else
        pac_install "${gpu_arch_nvidia[@]}"
      fi
      ;;
    amd)
      echo "Detected GPU: AMD"
      if [[ "$DISTRO" == "debian" ]]; then
        apt_install "${gpu_debian_amd[@]}"
      else
        pac_install "${gpu_arch_amd[@]}"
      fi
      ;;
    intel)
      echo "Detected GPU: Intel"
      if [[ "$DISTRO" == "debian" ]]; then
        apt_install mesa-va-drivers || true
        apt_install "${gpu_debian_intel[@]//|| true/}"
      else
        pac_install "${gpu_arch_intel[@]}"
      fi
      ;;
    vm)
      echo "Detected virtual GPU — skipping native GPU drivers."
      ;;
    *)
      echo "GPU not detected — skipping driver installation."
      ;;
  esac
}

# -------- Config: AwesomeWM + xinit --------
CONFIG_DIR="$HOME/.config/awesome"
ensure_config(){
  mkdir -p "$CONFIG_DIR"
  if [[ ! -f "$CONFIG_DIR/rc.lua" ]]; then
    echo "Creating rc.lua from system default…"
    # Prefer packaged default if available
    if [[ -f /etc/xdg/awesome/rc.lua ]]; then
      cp /etc/xdg/awesome/rc.lua "$CONFIG_DIR/rc.lua"
    else
      # Minimal fallback rc.lua
      cat >"$CONFIG_DIR/rc.lua" <<'LUA'
-- Minimal rc.lua fallback — Dennis Hilk
pcall(require, "luarocks.loader")
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
awful.layout.layouts = { awful.layout.suit.tile, awful.layout.suit.floating }
awful.spawn.with_shell("picom --experimental-backends --daemon")
awful.spawn.with_shell("nm-applet || true")
awful.spawn.with_shell("dunst || true")
awful.spawn.with_shell("flameshot || true")
-- Mod+Return to open terminal
local modkey = "Mod4"
awful.key({ modkey }, "Return", function() awful.spawn(os.getenv("TERMINAL") or "xterm") end,
          {description = "open a terminal", group = "launcher"})
root.keys(awful.util.table.join(root.keys()))
LUA
    fi
  fi

  # Set TERMINAL default
  if ! grep -q 'export TERMINAL=' "$HOME/.profile" 2>/dev/null; then
    echo 'export TERMINAL=alacritty' >> "$HOME/.profile"
  fi

  # Wallpaper dir (optional nice default)
  mkdir -p "$CONFIG_DIR/wallpaper"
  if [[ ! -f "$CONFIG_DIR/wallpaper/wallpaper.png" ]]; then
    # simple dark gradient as placeholder
    convert -size 1920x1080 gradient:#0b0b10-#12121a "$CONFIG_DIR/wallpaper/wallpaper.png" 2>/dev/null || true
  fi
}

ensure_xinit(){
  # .xinitrc for startx
  if [[ ! -f "$HOME/.xinitrc" ]]; then
    cat >"$HOME/.xinitrc" <<'EOF'
#!/usr/bin/env bash
# ~/.xinitrc — start AwesomeWM (Dennis Hilk)
export XDG_CURRENT_DESKTOP=awesome
export XDG_SESSION_TYPE=x11
# Keyrate tweak
xset r rate 250 40
# Locale fix (optional)
export LANG=${LANG:-en_US.UTF-8}
# Start Awesome
exec awesome
EOF
    chmod +x "$HOME/.xinitrc"
  fi
}

# -------- Optional: Autologin to TTY1 + auto startx --------
enable_tty_autologin(){
  # Create systemd override for getty@tty1
  sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
  cat <<EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf >/dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
Type=idle
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable getty@tty1.service
  echo "Autologin on tty1 enabled for user $USER."

  # Auto-start X on login to tty1
  if ! grep -q 'startx' "$HOME/.bash_profile" 2>/dev/null; then
    cat >>"$HOME/.bash_profile" <<'BASH'
# Auto-start X on tty1
if [[ -z "$DISPLAY" ]] && [[ $(tty) == /dev/tty1 ]]; then
  startx
  logout
fi
BASH
  fi
}

# -------- Menu --------
main_menu(){
  banner
  echo "Detected distro: $DISTRO"
  echo "Detected GPU:    $GPU_KIND"
  echo
  cat <<'MENU'
[1] Install base packages (AwesomeWM, Xorg, tools)
[2] Install GPU drivers (auto-detected)
[3] Install VM guest tools (if VM)
[4] Setup AwesomeWM config + xinit
[5] Enable TTY1 autologin + auto startx (no display manager)
[6] Do EVERYTHING (1–5)
[0] Exit
MENU
  echo
  read -rp "Choose an option: " choice
  case "${choice:-}" in
    1) install_base ;;
    2) install_gpu ;;
    3) install_vm_tools ;;
    4) ensure_config; ensure_xinit ;;
    5) enable_tty_autologin ;;
    6) install_base; install_gpu; install_vm_tools; ensure_config; ensure_xinit; enable_tty_autologin ;;
    0) exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
  echo
  confirm "Return to menu?" && main_menu || true
}

# -------- Pre-flight --------
banner
echo "This will set up AwesomeWM on Debian 13 or Arch Linux — without a display manager."
echo "A log is saved to: $LOG_FILE"
echo
confirm "Continue?" || die "Aborted."

detect_distro
detect_gpu

# Ensure needed package manager exists
if [[ "$DISTRO" == "debian" ]]; then
  command_exists apt-get || die "apt-get not found."
else
  command_exists pacman || die "pacman not found."
fi

main_menu

echo
echo "✅ Done. You can start AwesomeWM with 'startx' (or reboot if you enabled autologin)."
echo "   Log: $LOG_FILE"
