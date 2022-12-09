# ============================================================
# Variables
# ============================================================
ASM := nasm
SRC_DIR := src
BUILD_DIR := build


# ============================================================
# Phony target declarations
# ============================================================
.PHONY: qemu_run
.PHONY: make_target_list
.PHONY: all floppy_image kernel bootloader clean always


# ============================================================
# Display a list of make targets
# ============================================================
make_target_list:
	@echo "Make target list"
	@echo "================"
	@echo " + qemu_run         : Starts up qemu with the latest kernel image"
	@echo " + floppy_image     : Builds the main image of the OS"
	@echo " + docker_run	   : Starts a docker container in this directory"

# ============================================================
# Build the main image os the OS
# ============================================================
floppy_image: $(BUILD_DIR)/main_floppy.img
$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	newfs_msdos -F 12 -f 1440 $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -v -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

# ============================================================
# Bootloader
# ============================================================
bootloader: $(BUILD_DIR)/bootloader.bin
$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

# ============================================================
# Kernel 
# ============================================================
kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

# ============================================================
# Always
# ============================================================
always:
	mkdir -p $(BUILD_DIR)

# ============================================================
# Clean
# ============================================================
clean:
	rm -rf $(BUILD_DIR)/*

# ============================================================
# Start the operating system using qemu 
# ============================================================
qemu_run:
	qemu-system-i386 -fda build/main_floppy.img

docker_run:
	docker run --rm -it -w /root/workspace/ -v ~/Documents/dev/operation-systems/nanobyte-os:/root/workspace ubuntu bash
