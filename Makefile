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


# ============================================================
# Display a list of make targets
# ============================================================
make_target_list:
	@echo "Make target list"
	@echo "================"
	@echo " + qemu_run         : Starts up qemu with the latest kernel image"


# ============================================================
# Build the main image os the OS
# ============================================================
$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/main.bin
	cp $^ $@
	truncate -s 1440k $@


# ============================================================
# Assembly the binary file for the kernel
# ============================================================
$(BUILD_DIR)/main.bin: $(SRC_DIR)/main.asm
	$(ASM) $^ -f bin -o $@


# ============================================================
# Start the operating system using qemu 
# ============================================================
qemu_run:
	qemu-system-i386 -fda build/main_floppy.img
