# Roch OS

**Roch OS** is an immutable, secure, profile-based Arch Linux distribution built with [mkosi](https://github.com/systemd/mkosi) and systemd-repart. It features Hyprland as the default compositor, a single `/ui` directory for all interface configuration, and six specialized profiles that transform the system on demand.

## Philosophy

- **Immutable Base**: The root filesystem is read-only and integrity-verified (dm-verity)
- **Profile-Based**: Switch between Home, Developer, Gaming, AI, Robotics, and Hacker profiles
- **Single UI Folder**: All interface configuration lives in `/ui` — one place to rule them all
- **Mouseless by Default**: Full keyboard-driven workflow with Hyprland
- **Super Secure**: AppArmor, auditd, nftables, TPM-backed UKI, firejail sandboxing
- **Snapshot Everything**: Btrfs snapshots for instant rollback before any profile switch
- **Linux-Zen Kernel**: Optimized for desktop responsiveness and low latency

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Roch OS                               │
├─────────────────────────────────────────────────────────────┤
│  UKI (Unified Kernel Image)                                  │
│  ├── linux-zen kernel                                        │
│  ├── initramfs (systemd-based, btrfs, dm-verity)            │
│  └── cmdline with profile selector                           │
├─────────────────────────────────────────────────────────────┤
│  dm-verity protected /usr (read-only, signed)                │
│  ├── Hyprland + Waybar + Fuzzel + Foot + Mako               │
│  └── Profile definitions in /usr/lib/roch/profiles/          │
├─────────────────────────────────────────────────────────────┤
│  /ui → The Single UI Folder (symlinked to /usr/lib/roch/ui)  │
│  ├── hypr/      - Hyprland configuration                     │
│  ├── waybar/    - Status bar                                 │
│  ├── fuzzel/    - Application launcher                       │
│  ├── foot/      - Terminal emulator                          │
│  ├── mako/      - Notification daemon                        │
│  ├── theme.css  - Current profile theme variables            │
│  └── scripts/   - Autostart and helper scripts               │
├─────────────────────────────────────────────────────────────┤
│  /var/lib/roch/                                              │
│  ├── profiles/  - Downloaded profile packages cache          │
│  └── snapshots/ - Btrfs snapshots for rollback                │
└─────────────────────────────────────────────────────────────┘
```

## Profiles

| Profile | Icon | Description | Key Features |
|---------|------|-------------|--------------|
| **Home** | 🏠 | Minimal home computing | Firefox, LibreOffice, media apps |
| **Developer** | 💻 | Software development | Neovim, VSCode, Docker, K8s, Rust, Go |
| **Gaming** | 🎮 | High-performance gaming | Steam, Lutris, GameMode, MangoHud |
| **AI** | 🧠 | ML/AI development | PyTorch, TensorFlow, Ollama, Jupyter |
| **Robotics** | 🤖 | ROS2 & CAD | ROS2 Humble, Gazebo, FreeCAD, KiCad |
| **Hacker** | 👾 | Security research | Metasploit, Wireshark, BurpSuite, Tor |

### Switching Profiles

Click the profile indicator in Waybar (center of bar) or use:

```bash
# Switch to developer profile
sudo roch-profile developer

# List all profiles
roch-profile list

# Create manual snapshot
sudo roch-profile snapshot my-backup

# Restore from snapshot
sudo roch-profile restore my-backup
```

Each profile switch:
1. **Auto-snapshots** the current system state
2. **Installs** profile-specific packages (official + AUR)
3. **Applies** profile-specific UI theme and Hyprland config
4. **Configures** security level and services
5. **Updates** the kernel command line if needed

## Security Features

- **UKI with TPM PCR signing**: Boot chain measured and verified
- **dm-verity**: Read-only `/usr` with hash verification
- **AppArmor**: Mandatory access control with profile-specific strictness
- **nftables**: Stateful firewall, strict mode for Hacker profile
- **firejail**: Application sandboxing (enabled in maximum security)
- **auditd**: System call auditing (elevated+ profiles)
- **Btrfs snapshots**: Instant rollback capability
- **No passwords for wheel**: Polkit allows `roch-profile` without password for wheel users

## Mouseless Workflow

Roch OS is designed for keyboard-only operation:

| Key | Action |
|-----|--------|
| `Super + Enter` | Open terminal (Foot) |
| `Super + Q` | Close window |
| `Super + R` | Open launcher (Fuzzel) |
| `Super + H/J/K/L` | Focus left/down/up/right |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move to workspace |
| `Super + S` | Resize mode (H/J/K/L to resize) |
| `Super + Shift + P` | Profile switcher |
| `Super + Print` | Screenshot (area) |
| `Print` | Screenshot (full screen) |

## File Structure

```
roch-os/
├── mkosi.conf                    # Main build configuration
├── mkosi.repart/                 # Partition definitions
│   ├── 00-esp.conf              # EFI System Partition
│   ├── 10-usr.conf              # dm-verity protected /usr
│   └── 20-root.conf             # Root partition with snapshots
├── mkosi.extra/                  # Files to include in image
│   ├── /ui/                     # UI configuration (symlinked)
│   ├── /usr/lib/roch/           # Roch OS system files
│   │   ├── profiles/            # Profile definitions
│   │   │   ├── profiles.json    # Profile metadata & packages
│   │   │   ├── themes/          # CSS themes per profile
│   │   │   └── hypr/            # Hyprland profile configs
│   │   └── ui/                  # UI components
│   │       ├── hypr/
│   │       ├── waybar/
│   │       ├── fuzzel/
│   │       ├── foot/
│   │       ├── mako/
│   │       └── scripts/
│   ├── /usr/local/bin/          # Roch commands
│   │   ├── roch-profile         # Profile manager
│   │   └── roch-profile-setup   # First-boot setup
│   └── /etc/                    # System configs
│       ├── apparmor.d/
│       ├── nftables.conf
│       ├── greetd/
│       └── roch/
└── build.sh                      # Build script
```

## Building

### Prerequisites

- Arch Linux (or container with Arch)
- `mkosi` (version 26+)
- `systemd-ukify`
- Root privileges (for loop devices)

### Build

```bash
# Clone or extract this directory
cd roch-os

# Build the disk image
./build.sh

# Or directly with mkosi
mkosi --force

# Test in QEMU
mkosi qemu

# Build specific format
mkosi --format disk --force    # Raw disk image
mkosi --format directory --force # Directory tree (for chroot)
```

### Installation

```bash
# Write to USB drive
sudo dd if=mkosi.output/roch-os.raw of=/dev/sdX bs=4M status=progress

# Or use a flashing tool
sudo dd if=mkosi.output/roch-os.raw of=/dev/sdX bs=4M conv=fsync status=progress
```

## Post-Installation

1. **Boot** from the USB/installation medium
2. **Login** via greetd (tuigreet)
3. **Select profile** from Waybar or use `roch-profile`
4. **Customize** `/ui/` folder — everything UI is there
5. **Snapshot** before major changes: `sudo roch-profile snapshot before-crazy-experiment`

## Customization

### Editing Profile Packages

Edit `/usr/lib/roch/profiles/profiles.json` (as root):

```json
{
  "developer": {
    "packages": ["neovim", "your-package-here"]
  }
}
```

Then reactivate: `sudo roch-profile developer`

### Custom Themes

Add CSS files to `/usr/lib/roch/profiles/themes/` and reference in `profiles.json`.

### UI Customization

Everything lives in `/ui`:
- `/ui/hypr/hyprland.conf` — Window manager
- `/ui/waybar/config.jsonc` — Status bar
- `/ui/waybar/style.css` — Bar styling
- `/ui/foot/foot.ini` — Terminal
- `/ui/fuzzel/fuzzel.ini` — Launcher
- `/ui/mako/config` — Notifications
- `/ui/theme.css` — Color variables (auto-symlinked by profile)

## Inspired By

- **Arch Linux**: Base distribution and philosophy
- **Omichi**: Profile-based system transformation concept
- **Fedora Silverblue/Kinoite**: Immutable OS ideas
- **NixOS**: Declarative configuration inspiration
- **Qubes OS**: Security compartmentalization
- **EndeavourOS**: Arch accessibility

## License

MIT License — This is a reference distribution configuration.

---

**Roch OS** — *One system, infinite profiles. Built with mkosi. Secured by design.*
