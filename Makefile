# Roch OS Makefile
# Usage: make build | make qemu | make clean | make docker-build

.PHONY: build qemu clean docker-build docker-qemu shell help

# Default target
all: build

help:
	@echo "Roch OS Build System"
	@echo "===================="
	@echo "make build        - Build the OS image (requires mkosi + root)"
	@echo "make qemu         - Build and boot in QEMU"
	@echo "make clean        - Remove build artifacts"
	@echo "make docker-build - Build using Docker (no host dependencies)"
	@echo "make docker-qemu  - Build and run in Docker+QEMU"
	@echo "make shell        - Enter build shell"
	@echo "make format-usb   - Write to USB (specify DEV=/dev/sdX)"

# Native build (requires mkosi installed, root privileges)
build:
	@echo "[BUILD] Building Roch OS..."
	mkdir -p mkosi.output mkosi.cache mkosi.builddir
	mkosi --force
	@echo "[BUILD] Complete! Output in mkosi.output/"

qemu: build
	@echo "[QEMU] Booting Roch OS..."
	mkosi qemu

shell:
	@echo "[SHELL] Entering mkosi shell..."
	mkosi shell

clean:
	@echo "[CLEAN] Removing build artifacts..."
	rm -rf mkosi.output/* mkosi.cache/* mkosi.builddir/*
	@echo "[CLEAN] Done"

# Docker-based build (no host dependencies required)
docker-build:
	@echo "[DOCKER] Building Roch OS in container..."
	cd docker-build && docker build -t roch-builder .
	docker run --rm --privileged \
		-v $(PWD):/build \
		-v $(PWD)/output:/output \
		--device /dev/loop-control \
		--device /dev/loop0 \
		--device /dev/loop1 \
		--device /dev/loop2 \
		--device /dev/loop3 \
		--device /dev/loop4 \
		--device /dev/loop5 \
		--device /dev/loop6 \
		--device /dev/loop7 \
		--security-opt seccomp=unconfined \
		--cap-add SYS_ADMIN \
		roch-builder build

docker-qemu:
	@echo "[DOCKER] Building and running in QEMU..."
	cd docker-build && docker build -t roch-builder .
	docker run --rm --privileged \
		-v $(PWD):/build \
		-v $(PWD)/output:/output \
		--device /dev/loop-control \
		--device /dev/kvm \
		--security-opt seccomp=unconfined \
		--cap-add SYS_ADMIN \
		roch-builder qemu

# USB writing (DANGEROUS - be sure about DEV=)
format-usb:
	ifndef DEV
		$(error DEV is not set. Use: make format-usb DEV=/dev/sdX)
	endif
	@echo "[USB] Writing Roch OS to $(DEV)..."
	@echo "WARNING: This will destroy all data on $(DEV)!"
	@read -p "Are you sure? [y/N] " confirm && [ $$confirm = y ] || exit 1
	sudo dd if=mkosi.output/roch-os.raw of=$(DEV) bs=4M status=progress conv=fsync
	@echo "[USB] Done! Safe to remove $(DEV)"

# Validation
validate:
	@echo "[VALIDATE] Checking configuration..."
	@test -f mkosi.conf || (echo "Missing mkosi.conf!" && exit 1)
	@test -d mkosi.repart || (echo "Missing mkosi.repart/!" && exit 1)
	@test -d mkosi.extra || (echo "Missing mkosi.extra/!" && exit 1)
	@echo "[VALIDATE] All required files present"

# Profile switching (on running system)
profile-home:
	sudo roch-profile home
profile-dev:
	sudo roch-profile developer
profile-gaming:
	sudo roch-profile gaming
profile-ai:
	sudo roch-profile ai
profile-robotics:
	sudo roch-profile robotics
profile-hacker:
	sudo roch-profile hacker

# Manual build (no mkosi required, uses pacstrap)
manual-build:
	@echo "[MANUAL] Building Roch OS with standard tools..."
	sudo ./build-manual.sh

manual-qemu: manual-build
	@echo "[MANUAL-QEMU] Booting..."
	qemu-system-x86_64 -drive file=roch-os-manual.raw,format=raw -m 4G -smp 4
