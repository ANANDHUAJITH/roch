#!/bin/bash
# Roch OS Build Script
# Usage: ./build.sh [format]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMAT="${1:-disk}"

echo "=========================================="
echo "  Roch OS Builder"
echo "  Format: $FORMAT"
echo "=========================================="

cd "$SCRIPT_DIR"

# Check dependencies
command -v mkosi >/dev/null 2>&1 || { echo "Error: mkosi not installed. Install with: pacman -S mkosi"; exit 1; }

# Build the image
echo "[BUILD] Starting mkosi build..."
mkosi --format "$FORMAT" --force

echo "[BUILD] Build complete!"
echo "[BUILD] Output: mkosi.output/"
echo ""
echo "To test in QEMU:"
echo "  mkosi qemu"
echo ""
echo "To burn to USB:"
echo "  sudo dd if=mkosi.output/roch-os.raw of=/dev/sdX bs=4M status=progress"
