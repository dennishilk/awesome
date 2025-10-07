#!/usr/bin/env bash
# ==========================================================
# AwesomeWM Interactive Installer v3.6 — Dennis Hilk
# Debian 13 (Trixie) & Arch Linux
# Features:
#  - GPU auto-detect (NVIDIA/AMD/Intel/VM)
#  - No display manager (optional autologin + startx)
#  - Wallpaper from script folder (wallpaper.png)
#  - Nerd Fonts, Fish + Fastfetch + Fish Dashboard
#  - Nerd Pack, Browser & Utility Picker, Gaming Suite
#  - Performance Tweaks: ZRAM + Zen (Arch)/Liquorix (Debian) kernel + GRUB Auto
# Log: ~/awesomewm-install.log
# ==========================================================

set -Eeuo pipefail
LOG_FILE="$HOME/awesomewm-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

die(){ echo "ERROR: $*" >&2; exit 1; }
confirm(){ read -rp "$1 [y/N]: " _c; [[ "${_c:-}" =~ ^[Yy]$ ]]; }
ask_yn(){ read -rp "$1 [y/N]: " _a; [[ "${_a:-}" =~ ^[Yy]$ ]]; }
command_exists(){ command -v "$1" &>/dev/null; }

DISTRO=""
detect_distro(){
  if [[ -f /etc/debian_version ]]; then DISTRO="debian"
  elif [[ -f /etc/arch-release ]]; then DISTRO="arch"
  else die "Unsupported distro (only Debian 13 & Arch Linux)."; fi
}

GPU_KIND="unknown"
detect_gpu(){
  local out; out="$(lspci -nnk 2>/dev/null || true)"
  if   grep -qi 'NVIDIA' <<<"$out"; then GPU_KIND="nvidia"
  elif grep -Eqi 'AMD|Radeon' <<<"$out"; then GPU_KIND="amd"
  elif grep -qi 'Intel'  <<<"$out"; then GPU_KIND="intel"
  elif grep -Eqi 'VirtualBox|VMware|QEMU|Virtio|Microsoft Hyper-V' <<<"$out"; then GPU_KIND="vm"
  else GPU_KIND="unknown"; fi
}

# ---------------- Packages ----------------
base_pkgs_debian=(
  xorg xserver-xorg xinit x11-xserver-utils x11-xkb-utils xinput
  awesome awesome-extra
  rofi dunst feh lxappearance
  thunar thunar-archive-plugin thunar-volman gvfs-backends unzip
  picom pipewire-audio pipewire-pulse wireplumber pavucontrol pamixer
  xdg-user-dirs-gtk fonts-font-awesome fonts-terminus fonts-dejavu-core
  flameshot xclip curl wget git micro pciutils imagemagick
)

base_pkgs_arch=(
  xorg-server xorg-xinit xorg-xrandr xorg-xset xorg-xinput
  awesome rofi dunst feh lxappearance
  thunar thunar-archive-plugin thunar-volman gvfs unzip
  picom pipewire pipewire-pulse wireplumber pavucontrol pamixer
  xdg-user-dirs ttf-dejavu ttf-font-awesome terminus-font
  flameshot xclip curl wget git micro pciutils imagemagick
)

extra_terms=( xterm alacritty )
extra_fonts_debian=( fonts-jetbrains-mono fonts-firacode fonts-hack-ttf )
extra_fonts_arch=( ttf-jetbrains-mono ttf-firacode ttf-hack-nerd )
extra_shell=( fish )
extra_tools=( fastfetch )

vm_tools_debian=( spice-vdagent qemu-guest-agent )
vm_tools_arch( ){ echo "spice-vdagent qemu-guest-agent"; } # function to avoid array expansion issues in shells

gpu_debian_nvidia=( nvidia-driver firmware-misc-nonfree )
gpu_debian_amd=( firmware-amd-graphics mesa-vulkan-drivers )
gpu_debian_intel=( mesa-vulkan-drivers intel-media-va-driver-non-free )

gpu_arch_nvidia=( nvidia nvidia-utils )
gpu_arch_amd=( mesa vulkan-radeon )
gpu_arch_intel=( mesa vulkan-intel )

nerd_pack=( btop cmatrix neovim htop lolcat cava )
media_pack_arch=( ffmpeg yt-dlp mpv jq p7zip )
media_pack_debian=( ffmpeg yt-dlp mpv jq p7zip-full )

# ---------------- Package helpers ----------------
apt_update(){ sudo apt-get update; }
apt_install(){ sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"; }
pac_install(){ sudo pacman -Syu --noconfirm "$@"; }

enable_nonfree_debian(){
  if ! grep -Eq 'non-free-firmware' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    echo "Enabling contrib non-free non-free-firmware..."
    sudo sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
    apt_update
  fi
}
enable_multilib_arch(){
  if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib for pacman..."
    sudo sed -i '/#\[multilib\]/,/#Include = \/etc\/pacman.d\/mirrorlist/ s/^#//' /etc/pacman.conf
    sudo pacman -Sy
  fi
}
ensure_flatpak(){
  if [[ "$DISTRO" == "debian" ]]; then
    command_exists flatpak || apt_install flatpak
  else
    command_exists flatpak || pac_install flatpak
  fi
}

# ---------------- Base install ----------------
install_base(){
  echo "Installing base packages..."
  if [[ "$DISTRO" == "debian" ]]; then
    apt_update
    apt_install "${base_pkgs_debian[@]}" "${extra_terms[@]}"
  else
    pac_install "${base_pkgs_arch[@]}" "${extra_terms[@]}"
  fi
}

install_extras(){
  echo "Installing Nerd Fonts, Fish, Fastfetch..."
  if [[ "$DISTRO" == "debian" ]]; then
    apt_install "${extra_fonts_debian[@]}" "${extra_shell[@]}" "${extra_tools[@]}"
  else
    pac_install "${extra_fonts_arch[@]}" "${extra_shell[@]}" "${extra_tools[@]}"
  fi
}

install_vm_tools(){
  [[ "$GPU_KIND" != "vm" ]] && { echo "VM not detected — skipping guest tools."; return; }
  echo "Installing VM guest tools..."
  if [[ "$DISTRO" == "debian" ]]; then
    apt_install "${vm_tools_debian[@]}"
    sudo systemctl enable --now qemu-guest-agent || true
  else
    pac_install spice-vdagent qemu-guest-agent
    sudo systemctl enable --now qemu-guest-agent || true
  fi
}

install_gpu(){
  echo "Detected GPU: $GPU_KIND"
  case "$GPU_KIND" in
    nvidia)
      if [[ "$DISTRO" == "debian" ]]; then
        enable_nonfree_debian
        apt_install "${gpu_debian_nvidia[@]}"
      else
        pac_install "${gpu_arch_nvidia[@]}"
      fi ;;
    amd)
      [[ "$DISTRO" == "debian" ]] && apt_install "${gpu_debian_amd[@]}" || pac_install "${gpu_arch_amd[@]}" ;;
    intel)
      [[ "$DISTRO" == "debian" ]] && apt_install mesa-va-drivers "${gpu_debian_intel[@]}" || pac_install "${gpu_arch_intel[@]}" ;;
    vm) echo "VM GPU detected — skipping native drivers." ;;
    *)  echo "Unknown GPU — skipping driver installation." ;;
  esac
}

# ---------------- Awesome config + wallpaper ----------------
CONFIG_DIR="$HOME/.config/awesome"

backup_existing(){
  if [[ -d "$CONFIG_DIR" ]]; then
    local bkp="$HOME/.config/awesome_backup_$(date +%F_%H-%M-%S)"
    mv "$CONFIG_DIR" "$bkp"
    echo "Existing Awesome config moved to: $bkp"
  fi
}

ensure_config(){
  mkdir -p "$CONFIG_DIR"
  if [[ ! -f "$CONFIG_DIR/rc.lua" ]]; then
    echo "Creating default rc.lua..."
    if [[ -f /etc/xdg/awesome/rc.lua ]]; then
      cp /etc/xdg/awesome/rc.lua "$CONFIG_DIR/rc.lua"
    else
      cat >"$CONFIG_DIR/rc.lua" <<'LUA'
-- Minimal rc.lua fallback
pcall(require, "luarocks.loader")
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local beautiful = require("beautiful")
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
awful.layout.layouts = { awful.layout.suit.tile, awful.layout.suit.floating }
awful.spawn.with_shell("picom --daemon")
awful.spawn.with_shell("nm-applet || true")
awful.spawn.with_shell("dunst || true")
awful.spawn.with_shell("flameshot || true")
local modkey = "Mod4"
awful.key({ modkey }, "Return", function() awful.spawn(os.getenv("TERMINAL") or "alacritty" or "xterm") end,
          {description = "open terminal", group = "launcher"})
root.keys(awful.util.table.join(root.keys()))
LUA
    fi
  fi
  if ! grep -q 'export TERMINAL=' "$HOME/.profile" 2>/dev/null; then
    echo 'export TERMINAL=alacritty' >> "$HOME/.profile"
  fi
}

copy_wallpaper(){
  local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local src="$script_dir/wallpaper.png"
  local tgt="$CONFIG_DIR/wallpaper"
  mkdir -p "$tgt"
  if [[ -f "$src" ]]; then
    cp "$src" "$tgt/wallpaper.png"
    echo "Wallpaper copied to $tgt/wallpaper.png"
  else
    echo "No wallpaper.png next to script — generating gradient."
    if command_exists convert; then
      convert -size 1920x1080 gradient:#0b0b10-#12121a "$tgt/wallpaper.png" || true
    fi
  fi
}

ensure_xinit(){
  if [[ ! -f "$HOME/.xinitrc" ]]; then
    cat >"$HOME/.xinitrc" <<'EOF'
#!/usr/bin/env bash
export XDG_CURRENT_DESKTOP=awesome
export XDG_SESSION_TYPE=x11
xset r rate 250 40
export LANG=${LANG:-en_US.UTF-8}
exec awesome
EOF
    chmod +x "$HOME/.xinitrc"
  fi
}

enable_tty_autologin(){
  sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
  cat <<EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf >/dev/null
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
Type=idle
EOF
  sudo systemctl daemon-reload
  sudo systemctl enable getty@tty1.service
  echo "Autologin enabled on tty1 for $USER."
  if ! grep -q 'startx' "$HOME/.bash_profile" 2>/dev/null; then
    cat >>"$HOME/.bash_profile" <<'BASH'
if [[ -z "$DISPLAY" ]] && [[ $(tty) == /dev/tty1 ]]; then
  startx
  logout
fi
BASH
  fi
}

# ---------------- Fish shell (Dashboard) ----------------
setup_fish(){
  echo "Setting up Fish shell configuration & dashboard..."
  mkdir -p "$HOME/.config/fish"
  cat >"$HOME/.config/fish/config.fish" <<'FISH'
# ===== Fish shell config — AwesomeWM Nerd Dashboard =====
set -gx EDITOR micro
set -gx TERMINAL alacritty
set -gx BROWSER firefox

function _fmt_bytes
  set -l bytes $argv[1]
  if test -z "$bytes"; echo "0"; return; end
  set -l kib (math "$bytes / 1024")
  set -l mib (math "scale=2; $kib / 1024")
  set -l gib (math "scale=2; $mib / 1024")
  if test (math "$gib >= 1") -eq 1
    echo "$gib GiB"
  else
    echo "$mib MiB"
  end
end

function nerd_dashboard
  set_color cyan
  echo "────────────────────────────────────────────────────"
  set_color normal

  set user (whoami)
  set host (hostname)
  set os "Unknown"
  if test -r /etc/os-release
    set os (string match -r '^PRETTY_NAME=.*' </etc/os-release | sed 's/PRETTY_NAME=//; s/"//g')
  end
  set kernel (uname -r)

  set up_pretty (uptime -p | sed 's/^up //')
  set up_total "0s"
  if test -r /proc/uptime
    set -l secs (awk '{print int($1)}' /proc/uptime)
    set -l d (math "$secs / 86400")
    set -l h (math "($secs % 86400) / 3600")
    set -l m (math "($secs % 3600) / 60")
    set up_total "$d"d" "$h"h" "$m"m
  end

  set cpu (grep -m1 'model name' /proc/cpuinfo | sed 's/.*: //')
  set gpu (lspci | grep -E 'VGA|3D' | head -n1 | sed 's/.*: //')

  set used_bytes (awk '/Mem:/ {print $3*1024}' <(free -b))
  set total_bytes (awk '/Mem:/ {print $2*1024}' <(free -b))
  set used (_fmt_bytes $used_bytes)
  set total (_fmt_bytes $total_bytes)

  # ZRAM (zram0 size if present)
  set zram "inactive"
  if test -e /sys/block/zram0/disksize
    set -l zbytes (cat /sys/block/zram0/disksize)
    set zram "active ("(_fmt_bytes $zbytes)")"
  end

  set_color green
  echo "🐧  User: $user@$host"
  echo "🧩  OS:   $os"
  echo "📦  Kernel: $kernel"
  echo "🕐  Uptime: $up_pretty  |  Total: $up_total"
  echo "💻  CPU: $cpu"
  echo "🎮  GPU: $gpu"
  echo "🧠  RAM: $used / $total"
  echo "🔄  ZRAM: $zram"
  set_color cyan
  echo "────────────────────────────────────────────────────"
  set_color normal
end

nerd_dashboard

if type -q fastfetch
  fastfetch
end
FISH

  echo "Setting fish as login shell..."
  if command -v fish >/dev/null 2>&1; then
    sudo chsh -s "$(command -v fish)" "$USER" || true
  fi
  echo "Fish configured. Logout/Login to apply default shell."
}

# ---------------- Nerd Pack ----------------
install_nerd_pack(){
  echo "Installing Nerd Pack + media tools..."
  if [[ "$DISTRO" == "debian" ]]; then
    apt_install "${nerd_pack[@]}" "${media_pack_debian[@]}"
  else
    pac_install "${nerd_pack[@]}" "${media_pack_arch[@]}"
  fi
}

# ---------------- Browser & Utility Picker ----------------
install_firefox(){
  echo "Installing Firefox..."
  if [[ "$DISTRO" == "debian" ]]; then
    apt_install firefox-esr || apt_install firefox || true
  else pac_install firefox; fi
}
install_chromium(){
  echo "Installing Chromium..."
  if [[ "$DISTRO" == "debian" ]]; then apt_install chromium
  else pac_install chromium; fi
}
install_google_chrome(){
  echo "Installing Google Chrome..."
  if [[ "$DISTRO" == "debian" ]]; then
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | \
      sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
    apt_update && apt_install google-chrome-stable
  else
    if command_exists yay; then yay -S --noconfirm google-chrome
    else echo "AUR helper not found. Install 'yay' or use Chromium."; fi
  fi
}
install_brave(){
  echo "Installing Brave..."
  if [[ "$DISTRO" == "debian" ]]; then
    curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-core.asc | \
      sudo gpg --dearmor -o /usr/share/keyrings/brave-browser.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
      sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
    apt_update && apt_install brave-browser
  else
    if command_exists yay; then yay -S --noconfirm brave-bin
    else echo "AUR helper not found. Choose Firefox/Chromium or install 'yay'."; fi
  fi
}
install_zen_browser(){
  echo "Installing Zen Browser..."
  if [[ "$DISTRO" == "debian" ]]; then
    # AppImage install to /opt/zen-browser with desktop entry
    local ver url appdir bin
    ver="latest"
    url="https://github.com/zen-browser/desktop/releases/latest/download/zen-browser.AppImage"
    sudo mkdir -p /opt/zen-browser
    sudo curl -L "$url" -o /opt/zen-browser/zen-browser.AppImage
    sudo chmod +x /opt/zen-browser/zen-browser.AppImage
    sudo tee /usr/share/applications/zen-browser.desktop >/dev/null <<'DESK'
[Desktop Entry]
Name=Zen Browser
Exec=/opt/zen-browser/zen-browser.AppImage %U
Terminal=false
Type=Application
Icon=zen-browser
Categories=Network;WebBrowser;
DESK
    # Try to extract icon if supported, else skip
    echo "Zen Browser AppImage installed to /opt/zen-browser"
  else
    if command_exists yay; then
      yay -S --noconfirm zen-browser-bin
    else
      echo "No AUR helper found — using AppImage fallback."
      local url="https://github.com/zen-browser/desktop/releases/latest/download/zen-browser.AppImage"
      sudo mkdir -p /opt/zen-browser
      sudo curl -L "$url" -o /opt/zen-browser/zen-browser.AppImage
      sudo chmod +x /opt/zen-browser/zen-browser.AppImage
      sudo tee /usr/share/applications/zen-browser.desktop >/dev/null <<'DESK'
[Desktop Entry]
Name=Zen Browser
Exec=/opt/zen-browser/zen-browser.AppImage %U
Terminal=false
Type=Application
Icon=zen-browser
Categories=Network;WebBrowser;
DESK
    fi
  fi
}

apps_menu(){
  echo "Browser & Utility picker — select individually:"
  ask_yn "Install Firefox?"       && install_firefox
  ask_yn "Install Zen Browser?"   && install_zen_browser
  ask_yn "Install Google Chrome?" && install_google_chrome
  ask_yn "Install Brave?"         && install_brave
  ask_yn "Install Chromium?"      && install_chromium
  echo "Browser picker done."
}

# ---------------- Gaming Suite (with selection) ----------------
install_steam(){
  echo "Installing Steam..."
  if [[ "$DISTRO" == "debian" ]]; then
    enable_nonfree_debian
    sudo dpkg --add-architecture i386 || true
    apt_update
    apt_install steam
  else
    enable_multilib_arch
    pac_install steam
  fi
}
install_wine(){
  echo "Installing Wine..."
  if [[ "$DISTRO" == "debian" ]]; then
    sudo dpkg --add-architecture i386 || true
    apt_update
    apt_install wine wine32 wine64 winetricks
  else
    enable_multilib_arch
    pac_install wine winetricks
  fi
}
install_mangohud(){
  echo "Installing MangoHud..."
  if [[ "$DISTRO" == "debian" ]]; then
    apt_install mangohud || echo "MangoHud not in repo — skipping."
  else
    enable_multilib_arch
    pac_install mangohud lib32-mangohud
  fi
}
install_gamemode(){
  echo "Installing GameMode..."
  if [[ "$DISTRO" == "debian" ]]; then apt_install gamemode libgamemode0 libgamemodeauto0
  else pac_install gamemode lib32-gamemode || true; fi
  sudo systemctl enable --now gamemoded || true
}
install_gamescope(){
  echo "Installing Gamescope..."
  if [[ "$DISTRO" == "debian" ]]; then apt_install gamescope || echo "Gamescope not in repo — skipping."
  else pac_install gamescope; fi
}
install_lutris(){
  echo "Installing Lutris..."
  if [[ "$DISTRO" == "debian" ]]; then apt_install lutris || echo "Lutris not in repo — consider Flatpak."
  else pac_install lutris; fi
}
install_heroic(){
  echo "Installing Heroic Games Launcher..."
  if [[ "$DISTRO" == "debian" ]]; then
    ensure_flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    flatpak install -y flathub com.heroicgameslauncher.hgl
  else
    if command_exists yay; then yay -S --noconfirm heroic-games-launcher-bin
    else
      ensure_flatpak
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
      flatpak install -y flathub com.heroicgameslauncher.hgl
    fi
  fi
}
install_protonupqt(){
  echo "Installing ProtonUp-Qt..."
  if [[ "$DISTRO" == "debian" ]]; then
    ensure_flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    flatpak install -y flathub net.davidotek.pupgui2
  else
    if command_exists yay; then yay -S --noconfirm protonup-qt
    else
      ensure_flatpak
      flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
      flatpak install -y flathub net.davidotek.pupgui2
    fi
  fi
}
install_vkbasalt(){
  echo "Installing vkBasalt..."
  if [[ "$DISTRO" == "debian" ]]; then apt_install vkbasalt || echo "vkBasalt not in repo — consider manual install."
  else pac_install vkbasalt lib32-vkbasalt; fi
}
gaming_suite_menu(){
  echo "Gaming Suite — select components:"
  ask_yn "Install Steam?"            && install_steam
  ask_yn "Install Wine?"             && install_wine
  ask_yn "Install MangoHud?"         && install_mangohud
  ask_yn "Install GameMode? (auto-enable service)" && install_gamemode
  ask_yn "Install Gamescope?"        && install_gamescope
  ask_yn "Install Lutris?"           && install_lutris
  ask_yn "Install Heroic Launcher?"  && install_heroic
  ask_yn "Install ProtonUp-Qt?"      && install_protonupqt
  ask_yn "Install vkBasalt?"         && install_vkbasalt
  echo "Gaming Suite complete."
}

# ---------------- Performance Tweaks: ZRAM + Zen/Liquorix ----------------
setup_zram(){
  echo "Configuring ZRAM (50% of RAM)..."
  if [[ "$DISTRO" == "debian" ]]; then
    apt_install zram-tools
    sudo tee /etc/default/zramswap >/dev/null <<'CONF'
# zram-tools config
ALGO=zstd
PERCENT=50
CONF
    sudo systemctl enable --now zramswap.service || sudo systemctl enable --now zram-config.service || true
  else
    pac_install zram-generator
    sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'CONF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
CONF
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service || true
    sudo systemctl enable systemd-zram-setup@zram0.service || true
  fi
}

install_kernel_perf(){
  if [[ "$DISTRO" == "debian" ]]; then
    echo "Installing Liquorix kernel (Debian)..."
    sudo apt-get install -y curl || true
    curl -s 'https://liquorix.net/add-liquorix-repo.sh' | sudo bash - || true
    apt_update
    apt_install linux-image-liquorix-amd64 linux-headers-liquorix-amd64 || echo "Liquorix install attempt finished."
    # Auto-set GRUB default (saved) & try to pick Liquorix
    if command_exists update-grub; then sudo update-grub || true; else sudo grub-mkconfig -o /boot/grub/grub.cfg || true; fi
    sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub || true
    sudo sed -i 's/^#\?GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/' /etc/default/grub || true
    if command_exists update-grub; then sudo update-grub || true; else sudo grub-mkconfig -o /boot/grub/grub.cfg || true; fi
    local entry; entry="$(grep -Po "(?<=menuentry ')[^']*Liquorix[^']*" /boot/grub/grub.cfg | head -n1 || true)"
    [[ -n "${entry:-}" ]] && sudo grub-set-default "$entry" || echo "Liquorix entry not found; GRUB saved default enabled."
  else
    echo "Installing Zen kernel (Arch)..."
    pac_install linux-zen linux-zen-headers
    sudo sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub || true
    sudo sed -i 's/^#\?GRUB_SAVEDEFAULT=.*/GRUB_SAVEDEFAULT=true/' /etc/default/grub || true
    sudo grub-mkconfig -o /boot/grub/grub.cfg || true
    local entry; entry="$(grep -Po "(?<=menuentry ')[^']*Linux zen[^']*" /boot/grub/grub.cfg | head -n1 || true)"
    [[ -z "${entry:-}" ]] && entry="$(grep -Po "(?<=menuentry ')[^']*zen[^']*" /boot/grub/grub.cfg | head -n1 || true)"
    [[ -n "${entry:-}" ]] && sudo grub-set-default "$entry" || echo "Zen entry not found; GRUB saved default enabled."
  fi
}

performance_menu(){
  setup_zram
  install_kernel_perf
  install_gamemode  # ensure gamemoded enabled automatically
  echo
  confirm "Reboot now to activate kernel & ZRAM?" && sudo reboot || true
}

# ---------------- Preset Menus ----------------
preset_gaming(){
  echo "Preset: Gaming Setup — select components:"
  ask_yn "Liquorix/Zen Kernel?"     && install_kernel_perf
  ask_yn "Enable ZRAM?"             && setup_zram
  ask_yn "Enable GameMode?"         && install_gamemode
  ask_yn "Install MangoHud?"        && install_mangohud
  ask_yn "Install Steam?"           && install_steam
  ask_yn "Install Gamescope?"       && install_gamescope
  ask_yn "Install Wine?"            && install_wine
  # Laptop tweaks
  if ask_yn "Install TLP + auto-cpufreq (laptops)?" ; then
    if [[ "$DISTRO" == "debian" ]]; then
      apt_install tlp tlp-rdw auto-cpufreq || true
      sudo systemctl enable --now tlp || true
      sudo systemctl enable --now auto-cpufreq || true
    else
      pac_install tlp auto-cpufreq || true
      sudo systemctl enable --now tlp || true
      sudo systemctl enable --now auto-cpufreq || true
    fi
  fi
  echo "Gaming preset finished."
}
preset_creator(){
  echo "Preset: Creator Setup — select components:"
  if [[ "$DISTRO" == "debian" ]]; then
    ask_yn "Install OBS Studio?" && apt_install obs-studio
    ask_yn "Install Kdenlive?"   && apt_install kdenlive
    ask_yn "Install Audacity?"   && apt_install audacity
  else
    ask_yn "Install OBS Studio?" && pac_install obs-studio
    ask_yn "Install Kdenlive?"   && pac_install kdenlive
    ask_yn "Install Audacity?"   && pac_install audacity
  fi
  ask_yn "Install ffmpeg & yt-dlp?" && { [[ "$DISTRO" == "debian" ]] && apt_install ffmpeg yt-dlp || pac_install ffmpeg yt-dlp; }
  ask_yn "Install Fastfetch?"       && { [[ "$DISTRO" == "debian" ]] && apt_install fastfetch || pac_install fastfetch; }
  ask_yn "Install Nerd Fonts?"      && install_extras
  ask_yn "Enable Fish Dashboard?"   && setup_fish
  echo "Creator preset finished."
}
preset_minimal_nerd(){
  echo "Preset: Minimal Nerd Setup — select components (no GUI):"
  ask_yn "Fish Dashboard?"          && { install_extras; setup_fish; }
  ask_yn "tmux?"                     && { [[ "$DISTRO" == "debian" ]] && apt_install tmux || pac_install tmux; }
  ask_yn "htop?"                     && { [[ "$DISTRO" == "debian" ]] && apt_install htop || pac_install htop; }
  ask_yn "fastfetch?"                && { [[ "$DISTRO" == "debian" ]] && apt_install fastfetch || pac_install fastfetch; }
  ask_yn "git/curl/wget?"            && { [[ "$DISTRO" == "debian" ]] && apt_install git curl wget || pac_install git curl wget; }
  ask_yn "SSH tools (openssh-client, rsync, mtr)?" && {
    if [[ "$DISTRO" == "debian" ]]; then apt_install openssh-client rsync mtr-tiny
    else pac_install openssh rsync mtr; fi
  }
  echo "Minimal Nerd preset finished."
}
presets_menu(){
  cat <<'P'
Preset Menu — choose one:
[1] Gaming Setup (choose components)
[2] Creator Setup (choose components)
[3] Minimal Nerd Setup (choose components, CLI-only)
[0] Back
P
  read -rp "Choose: " p
  case "${p:-}" in
    1) preset_gaming ;;
    2) preset_creator ;;
    3) preset_minimal_nerd ;;
    0) return ;;
    *) echo "Invalid choice."; ;;
  esac
}

# ---------------- Menu ----------------
main_menu(){
  echo
  echo "Detected distro: $DISTRO"
  echo "Detected GPU:    $GPU_KIND"
  echo "Log file:        $LOG_FILE"
  echo
  cat <<'MENU'
[1]  Base System (AwesomeWM, Xorg, PipeWire, Tools)
[2]  GPU Drivers (Auto-Detect)
[3]  VM Guest Tools
[4]  Awesome Config + xinit + wallpaper + backup
[5]  TTY Autologin + auto startx
[6]  Nerd Fonts + Fish + Fastfetch (Dashboard + auto-login shell)
[7]  Nerd Pack (btop, cmatrix, neovim, htop, lolcat, cava + media tools)
[8]  Browser & Utility Picker (Firefox, Zen Browser, Google Chrome, Brave, Chromium)
[9]  Gaming Suite (Steam, Wine, MangoHud, GameMode, Gamescope, Lutris, Heroic, ProtonUp-Qt, vkBasalt)
[10] System Performance Tweaks (ZRAM + Zen/Liquorix kernel + GRUB Auto + GameMode)
[11] Preset Menu (Gaming Setup / Creator Setup / Minimal Nerd Setup)
[12] Do EVERYTHING (1–11)
[0]  Exit
MENU
  echo
  read -rp "Choose an option: " choice
  case "${choice:-}" in
    1) install_base ;;
    2) install_gpu ;;
    3) install_vm_tools ;;
    4) backup_existing; ensure_config; ensure_xinit; copy_wallpaper ;;
    5) enable_tty_autologin ;;
    6) install_extras; setup_fish ;;
    7) install_nerd_pack ;;
    8) apps_menu ;;
    9) gaming_suite_menu ;;
    10) performance_menu ;;
    11) presets_menu ;;
    12) install_base; install_gpu; install_vm_tools; backup_existing; ensure_config; ensure_xinit; copy_wallpaper; install_extras; setup_fish; install_nerd_pack; apps_menu; gaming_suite_menu; performance_menu ;;
    0) exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
  echo
  confirm "Return to menu?" && main_menu || true
}

# ---------------- Run ----------------
echo "AwesomeWM Setup (Debian 13 / Arch Linux)"
echo "A log will be saved to: $LOG_FILE"
echo
confirm "Continue?" || die "Aborted."

detect_distro
detect_gpu
main_menu

echo
echo "✅ Done. Start AwesomeWM with 'startx' (or reboot if autologin enabled)."
echo "   Log: $LOG_FILE"
