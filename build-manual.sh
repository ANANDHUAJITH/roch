#!/bin/bash
# Roch OS Manual Build Script
# Builds bootable disk image using standard Linux tools (no mkosi required)
# Usage: sudo ./build-manual.sh [output-file]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${1:-roch-os-manual.raw}"
SIZE="${2:-8G}"
MIRROR="https://geo.mirror.pkgbuild.com/\$repo/os/\$arch"

echo "=========================================="
echo "  Roch OS Manual Builder"
echo "  Output: $OUTPUT"
echo "  Size: $SIZE"
echo "=========================================="

# Check root
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: This script must be run as root (uses loop devices, mounts)"
    echo "Usage: sudo ./build-manual.sh"
    exit 1
fi

# Check dependencies
for cmd in dd parted mkfs.vfat mkfs.btrfs pacstrap arch-chroot; do
    if ! command -v $cmd &> /dev/null; then
        echo "ERROR: Required command '$cmd' not found"
        echo "Install: pacman -S parted dosfstools btrfs-progs arch-install-scripts"
        exit 1
    fi
done

# Clean up on exit
cleanup() {
    echo "[CLEANUP] Unmounting and detaching..."
    umount -R "$MOUNT_DIR" 2>/dev/null || true
    losetup -d "$LOOP_DEV" 2>/dev/null || true
    rm -rf "$MOUNT_DIR"
}
trap cleanup EXIT

# Create raw image
echo "[1/10] Creating disk image ($SIZE)..."
dd if=/dev/zero of="$OUTPUT" bs=1 count=0 seek=$SIZE status=none

# Partition
echo "[2/10] Partitioning (GPT)..."
parted -s "$OUTPUT" mklabel gpt
parted -s "$OUTPUT" mkpart ESP fat32 1MiB 513MiB
parted -s "$OUTPUT" set 1 esp on
parted -s "$OUTPUT" mkpart root btrfs 513MiB 100%

# Setup loop device
echo "[3/10] Attaching loop device..."
LOOP_DEV=$(losetup -f --show -P "$OUTPUT")
ESP_PART="${LOOP_DEV}p1"
ROOT_PART="${LOOP_DEV}p2"

# Wait for partitions
sleep 2
partprobe "$LOOP_DEV" 2>/dev/null || true

# Format partitions
echo "[4/10] Formatting partitions..."
mkfs.vfat -F32 -n ROCH-ESP "$ESP_PART"
mkfs.btrfs -f -L roch-root "$ROOT_PART"

# Create btrfs subvolumes
echo "[5/10] Creating btrfs subvolumes..."
MOUNT_DIR=$(mktemp -d)
mount "$ROOT_PART" "$MOUNT_DIR"
btrfs subvolume create "$MOUNT_DIR/@"
btrfs subvolume create "$MOUNT_DIR/@home"
btrfs subvolume create "$MOUNT_DIR/@var"
btrfs subvolume create "$MOUNT_DIR/@snapshots"
btrfs subvolume create "$MOUNT_DIR/@ui"
umount "$MOUNT_DIR"

# Mount subvolumes
echo "[6/10] Mounting subvolumes..."
mount -o subvol=@,compress=zstd "$ROOT_PART" "$MOUNT_DIR"
mkdir -p "$MOUNT_DIR"/{home,var,snapshots,ui,boot,efi}
mount -o subvol=@home,compress=zstd "$ROOT_PART" "$MOUNT_DIR/home"
mount -o subvol=@var,compress=zstd "$ROOT_PART" "$MOUNT_DIR/var"
mount -o subvol=@snapshots,compress=zstd "$ROOT_PART" "$MOUNT_DIR/snapshots"
mount -o subvol=@ui,compress=zstd "$ROOT_PART" "$MOUNT_DIR/ui"
mount "$ESP_PART" "$MOUNT_DIR/efi"
mkdir -p "$MOUNT_DIR/boot"

# Base installation
echo "[7/10] Installing base system (pacstrap)..."
pacstrap -c "$MOUNT_DIR" base base-devel systemd linux-zen linux-zen-headers     linux-firmware intel-ucode amd-ucode btrfs-progs snapper     sbctl tpm2-tools dm-crypt cryptsetup polkit audit apparmor     apparmor-profiles firejail iwd networkmanager openssh nftables     hyprland waybar fuzzel foot mako libnotify wl-clipboard grim slurp     swappy brightnessctl pamixer playerctl xdg-desktop-portal-hyprland     xdg-desktop-portal-gtk qt5-wayland qt6-wayland     ttf-jetbrains-mono noto-fonts noto-fonts-emoji     git vim nano pacman-contrib reflector man-db     docker podman python python-pip zstd zip unzip     ripgrep fd fzf bat eza zoxide starship btop     greetd tuigreet --mirror "$MIRROR"

# Generate fstab
echo "[8/10] Generating fstab..."
genfstab -U "$MOUNT_DIR" >> "$MOUNT_DIR/etc/fstab"

# Copy Roch OS customizations
echo "[9/10] Applying Roch OS configuration..."
cp -r "$SCRIPT_DIR/mkosi.extra/"* "$MOUNT_DIR/"

# Set up initial profile
echo "home" > "$MOUNT_DIR/etc/roch/current_profile"

# Create roch user
arch-chroot "$MOUNT_DIR" useradd -m -G wheel,docker -s /bin/bash roch 2>/dev/null || true
arch-chroot "$MOUNT_DIR" echo "roch:roch" | chpasswd 2>/dev/null || true

# Enable sudo for wheel
if [[ ! -f "$MOUNT_DIR/etc/sudoers.d/wheel" ]]; then
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > "$MOUNT_DIR/etc/sudoers.d/wheel"
    chmod 440 "$MOUNT_DIR/etc/sudoers.d/wheel"
fi

# Install paru (AUR helper) as roch user
arch-chroot "$MOUNT_DIR" bash -c '
    cd /tmp
    sudo -u roch git clone https://aur.archlinux.org/paru.git
    cd paru
    sudo -u roch makepkg -si --noconfirm
    rm -rf /tmp/paru
' 2>/dev/null || echo "WARNING: paru installation failed (AUR may need manual build)"

# Set up kernel and initramfs
echo "[10/10] Configuring boot..."
arch-chroot "$MOUNT_DIR" bash -c '
    # Set locale
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf

    # Set hostname
    echo "roch-os" > /etc/hostname

    # Enable services
    systemctl enable NetworkManager
    systemctl enable auditd
    systemctl enable apparmor
    systemctl enable nftables
    systemctl enable greetd
    systemctl enable roch-profile-setup.service
    systemctl enable roch-snapper-setup.service
    systemctl enable reflector.timer
    systemctl enable fstrim.timer

    # Build initramfs
    mkinitcpio -P

    # Install bootloader (systemd-boot)
    bootctl install --esp-path=/efi

    # Create boot entry
    mkdir -p /efi/loader/entries
    cat > /efi/loader/entries/roch-os.conf << "EOF"
title   Roch OS
linux   /vmlinuz-linux-zen
initrd  /intel-ucode.img
initrd  /amd-ucode.img
initrd  /initramfs-linux-zen.img
options root=UUID=ROOTUUID rw rootflags=subvol=@ quiet splash roch.profile=home roch.ui=/ui
EOF

    # Update loader config
    cat > /efi/loader/loader.conf << "EOF"
default roch-os.conf
timeout 3
console-mode max
EOF
'

# Replace UUID placeholder with actual UUID
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
sed -i "s/ROOTUUID/$ROOT_UUID/g" "$MOUNT_DIR/efi/loader/entries/roch-os.conf"

# Copy kernel and initramfs to ESP
mkdir -p "$MOUNT_DIR/efi/EFI/Linux"
cp "$MOUNT_DIR/boot/vmlinuz-linux-zen" "$MOUNT_DIR/efi/"
cp "$MOUNT_DIR/boot/initramfs-linux-zen.img" "$MOUNT_DIR/efi/"
cp "$MOUNT_DIR/boot/intel-ucode.img" "$MOUNT_DIR/efi/" 2>/dev/null || true
cp "$MOUNT_DIR/boot/amd-ucode.img" "$MOUNT_DIR/efi/" 2>/dev/null || true

# Create UKI if ukify is available
if command -v ukify &> /dev/null; then
    echo "[BONUS] Building UKI..."
    ukify build         --linux="$MOUNT_DIR/boot/vmlinuz-linux-zen"         --initrd="$MOUNT_DIR/boot/initramfs-linux-zen.img"         --cmdline="root=UUID=$ROOT_UUID rw rootflags=subvol=@ quiet splash roch.profile=home roch.ui=/ui"         --os-release="@$MOUNT_DIR/etc/os-release"         --output="$MOUNT_DIR/efi/EFI/Linux/roch-os.efi"
fi

echo ""
echo "=========================================="
echo "  BUILD COMPLETE!"
echo "=========================================="
echo "  Output: $OUTPUT"
echo "  Size: $(du -h "$OUTPUT" | cut -f1)"
echo ""
echo "  Write to USB:"
echo "    sudo dd if=$OUTPUT of=/dev/sdX bs=4M status=progress"
echo ""
echo "  Boot in QEMU:"
echo "    qemu-system-x86_64 -drive file=$OUTPUT,format=raw -m 4G -smp 4"
echo ""
echo "  Default login: roch / roch"
echo "=========================================="
