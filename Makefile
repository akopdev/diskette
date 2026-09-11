.EXPORT_ALL_VARIABLES:
.DEFAULT_GOAL := help

# Path to the aarch64 UEFI firmware.
# This path is specific to MacOS with, Qemu installed with Homebrew.
# Change this variable if you're on a different OS.
QEMU_BIOS_PATH ?= /opt/homebrew/share/qemu/edk2-aarch64-code.fd

# Path to system images
IMAGE_FILE := debian-13-generic-arm64.qcow2
SEED_IMAGE := seed.iso

$(IMAGE_FILE):
	@if [ ! -f "$(IMAGE_FILE)" ]; then \
		curl -fL -o $(IMAGE_FILE) https://cloud.debian.org/images/cloud/trixie/latest/$(IMAGE_FILE); \
		qemu-img resize $(IMAGE_FILE) 16G; \
	fi

$(SEED_IMAGE): cloud-init/meta-data cloud-init/user-data
	hdiutil makehybrid -iso -joliet -iso-volume-name cidata -joliet-volume-name cidata -o $@ cloud-init

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-16s\033[0m %s\n", $$1, $$2}'

.PHONY: run
run: $(IMAGE_FILE) $(SEED_IMAGE)  ## Run local test environment.
	qemu-system-aarch64 \
				-machine virt \
				-cpu cortex-a72 \
				-m 2048 \
				-nographic \
				-bios $(QEMU_BIOS_PATH) \
				-drive if=virtio,file=$(IMAGE_FILE),format=qcow2 \
				-drive if=virtio,format=raw,file=$(SEED_IMAGE) \
				-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8096-:8096,hostfwd=tcp::8384-:8384,hostfwd=tcp::5432-:5432,hostfwd=tcp::4445-:4455 \
				-device virtio-net-pci,netdev=net0 \
				-fsdev local,id=fsdev0,path=.,security_model=mapped-xattr \
				-device virtio-9p-pci,fsdev=fsdev0,mount_tag=diskette

.PHONY: clean
clean: ## Clean up temp files.
	@rm -f $(IMAGE_FILE) $(SEED_IMAGE)
	@rm -rf systemd/*.wants/
