# Roch OS Quick Reference

## Profiles
sudo roch-profile home          # Home computing
sudo roch-profile developer     # Software dev
sudo roch-profile gaming        # Gaming mode
sudo roch-profile ai            # ML/AI work
sudo roch-profile robotics      # ROS2/CAD
sudo roch-profile hacker        # Security research
roch-profile list               # List all profiles
roch-profile current            # Show active profile

## Snapshots
sudo roch-profile snapshot      # Auto-named snapshot
sudo roch-profile snapshot NAME # Named snapshot
sudo roch-profile restore NAME  # Restore snapshot

## Mouseless Keys
Super+Enter     Terminal
Super+Q         Close window
Super+R         Launcher (Fuzzel)
Super+HJKL      Focus directions
Super+Shift+HJKL Move window
Super+1-9       Workspace
Super+Shift+1-9 Move to workspace
Super+S         Resize mode
Super+Shift+P   Profile switcher
Print           Screenshot
Super+Print     Area screenshot

## UI Locations
/ui/hypr/       Hyprland config
/ui/waybar/     Status bar
/ui/foot/       Terminal
/ui/fuzzel/     Launcher
/ui/mako/       Notifications
/ui/theme.css   Current theme

## Security
sudo aa-status          # AppArmor status
sudo nft list ruleset   # Firewall rules
sudo auditctl -l        # Audit rules
sudo snapper list       # Snapshots

## System
sudo systemctl status   # Check services
journalctl -xe          # Logs
uname -r                # Kernel version

---
Roch OS - /ui is all you need
