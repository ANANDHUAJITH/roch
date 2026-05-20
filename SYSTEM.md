# Roch OS Technical Architecture

## Overview

Roch OS is an immutable, profile-based Arch Linux distribution built with **mkosi** and **systemd-repart**. It combines the best practices from immutable distributions, security-focused OSes, and modern Linux desktop environments.

## Core Technologies

| Component | Technology | Purpose |
|-----------|-----------|---------|
| Build System | mkosi 26+ | Image building and packaging |
| Partitioning | systemd-repart | Declarative disk layout |
| Boot | UKI (Unified Kernel Image) | Single-file signed boot |
| Kernel | linux-zen | Low-latency desktop kernel |
| Init | systemd | System and service management |
| FS | Btrfs | Snapshots, compression, subvolumes |
| Integrity | dm-verity | Read-only /usr verification |
| Compositor | Hyprland | Wayland-based window manager |
| Security | AppArmor + nftables + auditd | Defense in depth |

## Boot Flow

```
UEFI Firmware
    ↓
TPM PCR Measurement
    ↓
UKI (roch-os.efi)
    ├── systemd-stub
    ├── linux-zen kernel
    ├── initramfs (systemd-based)
    └── cmdline: roch.profile=home
    ↓
systemd in initramfs
    ├── dm-verity setup for /usr
    ├── btrfs mount with subvolumes
    └── switch-root
    ↓
systemd in real root
    ├── roch-profile-setup.service
    ├── /ui symlink setup
    └── greetd (tuigreet login)
    ↓
Hyprland session
    └── Waybar with profile indicator
```

## Partition Layout (systemd-repart)

```
Disk Layout:
┌─────────────┬──────────────────┬─────────────────┐
│  ESP (vfat) │  /usr (btrfs)    │  / (btrfs)      │
│  512M-1G    │  8-16G           │  4-8G           │
│             │  dm-verity data  │  dm-verity hash │
│             │  subvols:        │  subvols:       │
│             │    /var          │    /var         │
│             │    /home         │    /home        │
│             │    /snapshots    │    /snapshots   │
└─────────────┴──────────────────┴─────────────────┘
```

## The /ui Folder

All user interface configuration is centralized in `/ui`:

```
/ui
├── hypr/
│   └── hyprland.conf          # Base config (sources /ui/hypr/hyprland.conf.d/*.conf)
├── waybar/
│   ├── config.jsonc           # Waybar modules including profile switcher
│   └── style.css              # Imports /ui/theme.css
├── fuzzel/
│   └── fuzzel.ini             # Launcher config
├── foot/
│   └── foot.ini               # Terminal config
├── mako/
│   └── config                 # Notification daemon
├── theme.css                  # CSS variables (symlinked by profile)
└── scripts/
    └── autostart.sh           # Session startup
```

**Why one folder?**
- Easy backup: `tar czf ui-backup.tar.gz /ui`
- Easy sync: `rsync -av /ui other-machine:/`
- Easy versioning: Track in git
- Profile isolation: Each profile has its own theme and overrides

## Profile System

### Profile Definition (profiles.json)

Each profile contains:
- **name**: Display name
- **icon**: Emoji/icon for Waybar
- **description**: Human-readable purpose
- **packages**: Pacman packages to install (official + AUR)
- **services**: systemd services to enable
- **ui_theme**: CSS theme file name
- **hypr_config**: Hyprland override file
- **security_level**: standard | elevated | maximum
- **kernel_params**: Optional kernel command line additions

### Profile Activation Flow

```
User clicks profile in Waybar
    ↓
fuzzel dmenu shows profile list
    ↓
roch-profile <profile> (via sudo/polkit)
    ↓
1. Auto-snapshot current state
   ├── btrfs snapshot /usr → /var/lib/roch/snapshots/pre-<profile>-<timestamp>-usr
   └── btrfs snapshot /ui → /var/lib/roch/snapshots/pre-<profile>-<timestamp>-ui
    ↓
2. Install packages
   ├── pacman -S --needed <official_packages>
   └── paru -S --needed <aur_packages> (as user)
    ↓
3. Apply UI theme
   ├── ln -sf /usr/lib/roch/profiles/themes/<theme>.css /ui/theme.css
   └── ln -sf /usr/lib/roch/profiles/hypr/<config>.conf /ui/hypr/hyprland.conf
    ↓
4. Configure services
   └── systemctl enable <services>
    ↓
5. Security configuration
   ├── standard: disable apparmor, disable auditd
   ├── elevated: enable apparmor, disable auditd
   └── maximum: enable apparmor, enable auditd, firecfg, strict nftables
    ↓
6. Save state
   └── echo <profile> > /etc/roch/current_profile
    ↓
7. Notify user
   └── mako notification: "Profile X activated!"
```

## Security Architecture

### Layers

1. **Hardware**: TPM2 PCR measurement, Secure Boot (optional)
2. **Boot**: UKI with signed kernel, dm-verity for /usr
3. **Kernel**: linux-zen with lockdown=confidentiality, module blacklist
4. **Mandatory Access Control**: AppArmor profiles per application
5. **Network**: nftables stateful firewall, strict mode for sensitive profiles
6. **Application**: firejail sandboxing (maximum security)
7. **Audit**: auditd syscall logging (elevated+ profiles)
8. **Recovery**: Btrfs snapshots for instant rollback

### Profile Security Levels

| Level | AppArmor | Auditd | Firejail | Firewall | Description |
|-------|----------|--------|----------|----------|-------------|
| standard | Off | Off | Off | Default | Home/Gaming |
| elevated | On | Off | Off | Default | Developer/AI |
| maximum | On | On | On | Strict | Hacker |

## Mouseless Design

Roch OS is designed for keyboard-only operation:

- **Window Management**: Vim keys (HJKL) for focus and movement
- **Workspaces**: Number keys (1-9)
- **Launcher**: Fuzzel (Super+R)
- **Resize Mode**: Super+S, then HJKL
- **Profile Switch**: Super+Shift+P or click Waybar center
- **No Mouse Required**: All operations have keyboard shortcuts

Mouse support exists but is secondary:
- Super+mouse drag: Move window
- Super+right drag: Resize window

## Snapshot System

### Automatic Snapshots

Every profile switch creates an automatic snapshot:
- Name format: `pre-<profile>-<unix_timestamp>`
- Includes: /usr subvolume, /ui subvolume, profile state JSON

### Manual Snapshots

```bash
sudo roch-profile snapshot          # Auto-named
sudo roch-profile snapshot my-backup  # Custom name
```

### Restoration

```bash
sudo roch-profile restore my-backup
```

This:
1. Deletes current /usr and /ui subvolumes
2. Restores from snapshot subvolumes
3. Restores profile state
4. Requires reboot for full effect

## Build Process

```bash
# mkosi reads mkosi.conf
# ├── Downloads Arch packages
# ├── Applies mkosi.extra/ overlay
# ├── Runs systemd-repart for partition layout
# ├── Creates dm-verity hashes
# ├── Builds UKI with systemd-ukify
# └── Outputs disk image

./build.sh
# or
mkosi --force
```

## Package Management

### Base Image
All packages in `mkosi.conf` [Content] section are pre-installed in the immutable base.

### Profile Packages
Additional packages are installed on-demand when activating a profile:
- Official repos: Installed via `pacman` as root
- AUR: Installed via `paru` as the user

### Updates
Since /usr is read-only (dm-verity), system updates require:
1. Building new image with mkosi
2. Deploying new image
3. Or using A/B partition scheme (future enhancement)

## Future Enhancements

- [ ] A/B partition scheme for seamless updates
- [ ] OSTree or composefs for even more efficient updates
- [ ] Network-bound disk encryption (Clevis/Tang)
- [ ] Remote attestation
- [ ] Container runtime integration (Podman/Docker profiles)
- [ ] GPU passthrough profiles for VFIO gaming
- [ ] declarative home-manager style user config

---

*Roch OS — Immutable by design, flexible by profile.*
