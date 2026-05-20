#!/bin/bash
# Roch OS Autostart
# Everything UI lives in /ui

# Create /ui symlinks if they don't exist (first boot)
if [[ ! -d /ui/hypr ]]; then
    sudo mkdir -p /ui
    sudo ln -sf /usr/lib/roch/ui/hypr /ui/hypr
    sudo ln -sf /usr/lib/roch/ui/waybar /ui/waybar
    sudo ln -sf /usr/lib/roch/ui/fuzzel /ui/fuzzel
    sudo ln -sf /usr/lib/roch/ui/foot /ui/foot
    sudo ln -sf /usr/lib/roch/ui/mako /ui/mako
    sudo ln -sf /usr/lib/roch/ui/theme.css /ui/theme.css
fi

# Start notification daemon
mako --config /ui/mako/config &

# Start waybar
waybar --config /ui/waybar/config.jsonc --style /ui/waybar/style.css &

# Set wallpaper (profile-specific)
if [[ -f /ui/wallpaper.png ]]; then
    hyprctl hyprpaper wallpaper ",/ui/wallpaper.png" 2>/dev/null || true
fi

# Welcome notification
notify-send -i dialog-information "Roch OS" "Welcome! Profile: $(cat /etc/roch/current_profile 2>/dev/null || echo 'home')" &
