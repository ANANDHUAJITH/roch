#!/bin/bash
set -e

COMMAND="${1:-build}"
BUILD_DIR="/build"
OUTPUT_DIR="/output"

echo "=========================================="
echo "  Roch OS Builder Container"
echo "  Command: $COMMAND"
echo "=========================================="

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

cd "$BUILD_DIR"

case "$COMMAND" in
    build)
        echo "[BUILD] Starting Roch OS build..."
        mkosi --force
        echo "[BUILD] Copying artifacts to /output..."
        cp -r mkosi.output/* "$OUTPUT_DIR/" 2>/dev/null || true
        echo "[BUILD] Done! Artifacts in /output"
        ;;
    qemu)
        echo "[QEMU] Booting Roch OS in QEMU..."
        mkosi qemu
        ;;
    shell)
        echo "[SHELL] Entering build environment..."
        exec /bin/bash
        ;;
    *)
        echo "Unknown command: $COMMAND"
        echo "Usage: build | qemu | shell"
        exit 1
        ;;
esac
