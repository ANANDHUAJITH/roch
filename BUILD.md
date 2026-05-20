# Roch OS Build Guide

## Prerequisites

### Host System Requirements
- Arch Linux (or any Linux with mkosi v26+)
- 64GB+ free disk space
- 8GB+ RAM
- UEFI-enabled system for testing (or QEMU)

### Required Packages
```bash
sudo pacman -S mkosi systemd-ukify bubblewrap qemu-full
```

### User Setup (for unprivileged builds)
```bash
# Ensure subuid/subgid mappings exist
cat /etc/subuid
# Should show: youruser:100000:65536

# If not, add them:
sudo usermod --add-subuids 100000-165535 youruser
sudo usermod --add-subgids 100000-165535 youruser
```

## Building Roch OS

### Step 1: Prepare Build Directory
```bash
cd roch-os
mkdir -p mkosi.output mkosi.cache mkosi.builddir
```

### Step 2: Build the Image
```bash
# Full build (first time, downloads packages)
mkosi --force

# Incremental build (faster, uses cache)
mkosi --incremental --force

# Build with specific format
mkosi --format disk --force

# Build UKI only
mkosi --format uki --force
```

### Step 3: Test in QEMU
```bash
# Boot the image in QEMU/KVM
mkosi qemu

# Or with specific resources
mkosi --qemu-smp 4 --qemu-mem 4G qemu
```

### Step 4: Write to USB
```bash
# Find your USB device (BE CAREFUL!)
lsblk

# Write image to USB
sudo dd if=mkosi.output/roch-os.raw of=/dev/sdX bs=4M status=progress conv=fsync

# Or use a safer tool
sudo cp mkosi.output/roch-os.raw /dev/sdX
```

## Build Outputs

After successful build, `mkosi.output/` contains:

| File | Description |
|------|-------------|
| `roch-os.raw` | Full GPT disk image |
| `roch-os.efi` | UKI (Unified Kernel Image) |
| `roch-os.verity` | dm-verity hash tree |
| `roch-os.roothash` | Root hash for verification |

## Troubleshooting

### "No space left on device"
```bash
# Clean caches
rm -rf mkosi.cache/* mkosi.builddir/*

# Build with smaller root size
# Edit mkosi.repart/10-usr.conf: SizeMaxBytes=8G
```

### "Failed to find kernel"
```bash
# Ensure linux-zen is in packages list
# Check mkosi.conf Packages= section
```

### "dm-verity setup failed"
```bash
# Ensure VerityMatchKey matches between partitions
# Check mkosi.repart/*.conf files
```

### "UKI signing failed"
```bash
# Generate keys first
sbctl create-keys
sbctl enroll-keys --microsoft

# Or disable signing for testing
# Remove SignExpectedPcr=yes from mkosi.conf
```

## Development Workflow

### Modifying Profiles
1. Edit `mkosi.extra/usr/lib/roch/profiles/profiles.json`
2. Rebuild: `mkosi --incremental --force`
3. Test: `mkosi qemu`

### Adding UI Themes
1. Create CSS in `mkosi.extra/usr/lib/roch/profiles/themes/`
2. Reference in `profiles.json`
3. Rebuild and test

### Testing Profile Scripts
```bash
# Enter build environment
mkosi shell

# Or chroot into built image
sudo systemd-nspawn --image mkosi.output/roch-os.raw
```

## Advanced: Secure Boot + TPM2

### Generate Keys
```bash
sbctl create-keys
sbctl enroll-keys --microsoft
```

### Build Signed Image
```bash
# Keys automatically used by mkosi if present
mkosi --force

# Verify signature
sbctl verify mkosi.output/roch-os.efi
```

### TPM2 Enrollment
```bash
# On first boot, system enrolls TPM2 automatically
# Check with:
tpm2_pcrread
systemd-cryptenroll --tpm2-device=list
```

## CI/CD Build (GitHub Actions Example)

```yaml
name: Build Roch OS
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install mkosi
        run: |
          sudo apt-get update
          sudo apt-get install -y mkosi qemu-utils

      - name: Build image
        run: mkosi --force

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: roch-os-image
          path: mkosi.output/roch-os.raw
```

## References

- [mkosi Documentation](https://github.com/systemd/mkosi)
- [systemd-repart](https://www.freedesktop.org/software/systemd/man/systemd-repart.html)
- [dm-verity](https://www.kernel.org/doc/html/latest/admin-guide/device-mapper/dm-verity.html)
- [UKI - Unified Kernel Image](https://uapi-group.org/specifications/specs/unified_kernel_image/)
- [Arch Wiki - mkosi](https://wiki.archlinux.org/title/Mkosi)
