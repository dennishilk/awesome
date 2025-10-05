#!/bin/bash
# =========================================
#  Autostart - AwesomeWM by Dennis Hilk
# =========================================

# Start compositor for transparency
picom --experimental-backends &

# Start Conky overlay
conky -c ~/.config/conky/nerd.conf &

# Set wallpaper (if not handled by Awesome)
feh --bg-scale ~/Pictures/wallpaper/wallpaper.png &

