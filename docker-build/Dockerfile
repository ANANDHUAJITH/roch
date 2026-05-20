# Roch OS Builder Container
# Usage: docker build -t roch-builder . && docker run --privileged -v $(pwd)/output:/output roch-builder

FROM archlinux:latest

# Install base dependencies
RUN pacman -Syu --noconfirm &&     pacman -S --noconfirm         base-devel         git         python         python-pip         python-virtualenv         systemd         systemd-sysvcompat         linux-zen         linux-zen-headers         linux-firmware         btrfs-progs         dosfstools         mtools         qemu-full         arch-install-scripts         reflector         sbctl         tpm2-tools         && rm -rf /var/cache/pacman/pkg/*

# Install mkosi from git (latest version)
RUN git clone --depth 1 https://github.com/systemd/mkosi.git /tmp/mkosi &&     cd /tmp/mkosi &&     pip install . &&     rm -rf /tmp/mkosi

# Verify mkosi installation
RUN mkosi --version

# Set up build environment
WORKDIR /build
VOLUME /build
VOLUME /output

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Required for mkosi (loop devices, mounts)
--security-opt seccomp=unconfined --cap-add SYS_ADMIN --device /dev/loop-control --device /dev/loop0 --device /dev/loop1 --device /dev/loop2 --device /dev/loop3 --device /dev/loop4 --device /dev/loop5 --device /dev/loop6 --device /dev/loop7

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["build"]
