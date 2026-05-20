# Roch OS — Build Index

## Quick Start (Choose Your Method)

### 🔥 FASTEST: GitHub Actions (Zero Setup)
1. Push this folder to a GitHub repository
2. Go to **Actions** tab → **Build Roch OS** → **Run workflow**
3. Select profile (optional) → **Run**
4. Download `roch-os.raw` from artifacts (≈5 min build time)
5. Flash to USB: `sudo dd if=roch-os.raw of=/dev/sdX bs=4M status=progress`

### 🐧 NATIVE: Arch Linux + mkosi (Recommended for Development)
```bash
# Prerequisites
sudo pacman -S mkosi systemd-ukify bubblewrap qemu-full

# Build
make build          # Full build
make qemu           # Build + test in QEMU
make clean          # Clean artifacts
```

### 🐳 DOCKER: Any Linux with Docker (No Host Dependencies)
```bash
make docker-build   # Build in privileged container
make docker-qemu    # Build + run in QEMU
```

### 🔧 MANUAL: Standard Arch Tools (No mkosi Required)
```bash
sudo ./build-manual.sh    # Uses pacstrap + arch-chroot
```

---

## File Reference

| File | Purpose |
|------|---------|
| `mkosi.conf` | Main build configuration (packages, kernel, output format) |
| `mkosi.repart/` | GPT partition definitions (ESP, /usr, / with dm-verity) |
| `mkosi.extra/` | Files overlaid into the final image |
| `build.sh` | Wrapper script for mkosi |
| `build-manual.sh` | Standalone build using pacstrap (no mkosi) |
| `Makefile` | All build targets (native, docker, manual, qemu) |
| `quickstart.sh` | Interactive setup wizard |
| `docker-build/` | Docker container definition for isolated builds |
| `.github/workflows/build.yml` | CI/CD pipeline for GitHub Actions |
| `README.md` | Full documentation |
| `SYSTEM.md` | Technical architecture deep-dive |
| `BUILD.md` | Detailed build guide with troubleshooting |
| `CHEATSHEET.md` | Quick reference for daily use |

---

## System Requirements

### To Build
- **Arch Linux** (or Docker with privileged mode)
- **8GB RAM** minimum (16GB recommended)
- **64GB free disk space**
- **Root access** (for loop devices, mounts, chroot)

### To Run
- **64-bit UEFI** system
- **4GB RAM** minimum
- **20GB storage** (expands to full disk on first boot)
- **GPU with Wayland support** (Intel/AMD/NVIDIA with nouveau)

---

## Default Credentials

| User | Password | Groups |
|------|----------|--------|
| `roch` | `roch` | wheel, docker, video, audio, input |

Root access via `sudo` (no password required for wheel group).

---

## First Boot

1. **Login** via tuigreet (terminal greeter)
2. **Hyprland** starts automatically
3. **Waybar** shows profile indicator in center
4. **Click** profile name or press `Super+Shift+P` to switch profiles
5. **Type** `roch-profile list` in terminal to see all options

---

## Support

- **Issues**: Check `BUILD.md` troubleshooting section
- **Profiles**: Edit `mkosi.extra/usr/lib/roch/profiles/profiles.json`
- **UI**: Modify files in `mkosi.extra/usr/lib/roch/ui/`
- **Security**: Adjust `mkosi.extra/etc/apparmor.d/` and `mkosi.extra/etc/nftables.conf`

---

*Roch OS v1.0.0 — Immutable by design, flexible by profile.*
