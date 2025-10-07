DONT USE ! -- in work -- 



# 🐧 Dennis Hilk - AwesomeWM Interactive Installer

An interactive setup script for **AwesomeWM**, created by **Dennis Hilk**.  
It supports **Debian 13 (Trixie)** and **Arch Linux**, automatically detects your **GPU** (NVIDIA, AMD, Intel, or VM), and sets up a complete **AwesomeWM desktop** without any display manager — optionally booting straight into `startx` via autologin.

---

## ✨ Features

- 🧠 **Automatic distro detection** (Debian 13 or Arch Linux)
- 🎮 **GPU auto-detection** (NVIDIA / AMD / Intel / Virtual Machine)
- 🧰 **Interactive menu** — choose what to install
- 🧱 **Full AwesomeWM environment** (Xorg, Rofi, Dunst, Picom, Thunar, PipeWire, etc.)
- 💻 **No display manager required** — optional TTY1 autologin + auto `startx`
- 🎨 **Automatic AwesomeWM config & rc.lua creation**
- 🖼️ **Wallpaper folder with default gradient background**
- 🧩 **Works inside VMs (QEMU, VirtualBox, VMware, etc.)**
- 💾 **Installation log:** `~/dennishilk-awesome-install.log`
- 🧡 **Open Source (MIT)** — by Dennis Hilk

---

## 🧩 Requirements

- Debian 13 (Trixie) or Arch Linux  
- Internet connection  
- Sudo privileges  

---

## ⚙️ Installation

### 1️⃣ Download the script

```bash
wget https://github.com/dennishilk/awesome.git
cd awesome
chmod +x install.sh
./install.sh

📁 Directory Structure
Path	Description
~/.config/awesome/rc.lua	Main AwesomeWM config (auto-created)
~/.config/awesome/wallpaper/	Default wallpaper directory
~/.xinitrc	Startup file for startx
~/.bash_profile	Contains autostart logic for X on TTY1
~/dennishilk-awesome-install.log	Installation log file
