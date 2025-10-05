#!/bin/bash
# =========================================
#  AwesomeWM
#  Minimal Nerd Edition
#  MIT License © Dennis Hilk
# =========================================

echo "==> Updating system..."
sudo pacman -Syu --noconfirm

echo "==> Installing dependencies..."
sudo pacman -S --noconfirm awesome rofi alacritty feh picom conky \
    pipewire pipewire-alsa pipewire-pulse wireplumber \
    git curl wget ttf-jetbrains-mono-nerd

echo "==> Setting up configuration directories..."
mkdir -p ~/.config/{awesome,conky,rofi}
mkdir -p ~/Pictures/wallpaper

echo "==> Copying configuration files..."
cp -r rc.lua theme.lua autorun.sh widgets ~/.config/awesome/
cp -r conky/ ~/.config/
cp wallpaper/wallpaper.png ~/Pictures/wallpaper/

echo "==> Creating autorun script link..."
echo "awful.spawn.with_shell(\"~/.config/awesome/autorun.sh\")" >> ~/.config/awesome/rc.lua

echo "==> Creating Conky config..."
cat << 'EOF' > ~/.config/conky/nerd.conf
conky.config = {
    alignment = 'top_right',
    background = true,
    double_buffer = true,
    update_interval = 1,
    own_window = true,
    own_window_transparent = true,
    use_xft = true,
    font = 'JetBrainsMono Nerd Font:size=10',
    default_color = 'white',
};
conky.text = [[
${time %H:%M:%S}
CPU: ${cpu}%
RAM: ${mem} / ${memmax}
GPU: ${exec nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader}%
]];
EOF

echo "==> Installation complete!"
echo "Reboot now and select AwesomeWM in LightDM."

