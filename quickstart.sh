#!/bin/bash
# Roch OS Quick Start Script
# This helps you get building immediately

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  Roch OS - Quick Start"
echo "=========================================="

# Check if mkosi is available
if command -v mkosi &> /dev/null; then
    echo "✓ mkosi found: $(mkosi --version)"

    # Check if we have root
    if [ "$EUID" -eq 0 ]; then
        echo "✓ Running as root"
        echo ""
        echo "Building Roch OS now..."
        make build
    else
        echo "⚠ Not running as root"
        echo "  mkosi requires root for loop devices and mounts"
        echo ""
        echo "Options:"
        echo "  1. sudo make build"
        echo "  2. make docker-build (no root needed, needs Docker)"
        echo ""
        read -p "Run with sudo? [Y/n]: " choice
        if [[ ! "$choice" =~ ^[Nn]$ ]]; then
            sudo make build
        fi
    fi
else
    echo "✗ mkosi not found on host system"
    echo ""
    echo "Options to build Roch OS:"
    echo ""
    echo "  1. DOCKER (Recommended - no dependencies)"
    echo "     make docker-build"
    echo ""
    echo "  2. INSTALL mkosi on host"
    echo "     Arch:    sudo pacman -S mkosi"
    echo "     Debian:  sudo apt install mkosi  (or build from git)"
    echo "     Fedora:  sudo dnf install mkosi"
    echo "     Generic: pip install git+https://github.com/systemd/mkosi.git"
    echo ""
    echo "  3. GITHUB ACTIONS (Fully automated)"
    echo "     Push to GitHub with .github/workflows/build.yml"
    echo "     Artifacts will be built automatically"
    echo ""

    read -p "Try Docker build? [Y/n]: " choice
    if [[ ! "$choice" =~ ^[Nn]$ ]]; then
        make docker-build
    fi
fi
