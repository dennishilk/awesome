🐧 Dennis Hilk - AwesomeWM Interactive Installer

An interactive, **looped** installer for **AwesomeWM** that works on **Debian 13 (Trixie)** and **Arch Linux**.  
It detects your **GPU** (NVIDIA/AMD/Intel/VM), sets up a complete AwesomeWM environment **without a display manager**, and adds quality-of-life tools for gaming and daily use — including a slick **Fish shell dashboard**, **Nerd Fonts**, **browser picker**, and **performance tweaks** like **ZRAM** and the **Liquorix/Zen kernel**.

> The menu returns after every action — install items in any order, then exit when you’re done.

---

## ✨ Highlights

- 🧠 **Distro-aware**: Debian 13 & Arch Linux
- 🎮 **Gaming Suite** (selective install): Steam, Wine, MangoHud, GameMode (auto-enabled), Gamescope, Lutris, Heroic, ProtonUp-Qt, vkBasalt
- 💻 **GPU auto-detection**: NVIDIA / AMD / Intel / VM
- 🔐 **No Display Manager**: optional TTY1 autologin → `startx`
- 🐚 **Fish shell dashboard**: whoami, OS, kernel, uptime, CPU, GPU, RAM, **ZRAM status**
- 🔤 **Nerd Fonts** + Fastfetch
- 🌐 **Browser picker**: Firefox, **Zen Browser**, Google Chrome, Brave, Chromium
- 🚀 **Performance tweaks**: **ZRAM** + **Liquorix (Debian)** / **Zen (Arch)** kernel, GRUB auto-default, **gamemoded** enabled
- 🖼️ **Wallpaper**: drop `wallpaper.png` next to the script and it’s applied
- ♻️ **Safe**: backs up existing `~/.config/awesome` with timestamp
- 🧰 **Nerd Pack**: btop, cmatrix, neovim, htop, lolcat, cava, ffmpeg, yt-dlp, mpv, jq, p7zip

---

## 🧩 Requirements

- Debian 13 (Trixie) **or** Arch Linux
- Internet connection
- `sudo` privileges

---

## ⚙️ Quick Start

Clone and run:

```bash
git clone https://github.com/dennishilk/awesome.git
cd awesome
chmod +x install.sh
./install.sh
