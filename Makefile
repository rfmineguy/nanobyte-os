# ============================================================
# Variables
# ============================================================
ASM := nasm
CC := gcc
SRC_DIR := src
TOOLS_DIR := tools
BUILD_DIR := build
DATA_DIR := data
BOCHS_CONFIG := bochs_config

# ============================================================
# System Dependency Code
# ============================================================
UNAME_S := $(shell uname -s)
CREATE_FS :=
ifeq ($(UNAME_S), Linux)
	CREATE_FS += mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/main_floppy.img
else ifeq ($(UNAME_S), Darwin)
	CREATE_FS += newfs_msdos -F 12 -f 1440 $(BUILD_DIR)/main_floppy.img
endif

# ============================================================
# Phony target declarations
# ============================================================
.PHONY: qemu_run
.PHONY: make_target_list
.PHONY: all floppy_image kernel bootloader tools_fat clean always


# ============================================================
# Display a list of make targets
# ============================================================
make_target_list:
	@echo "Make target list"
	@echo "================"
	@echo " + qemu_run       : Starts up qemu with the latest kernel image"
	@echo " + floppy_image   : Builds the main image of the OS"
	@echo " + docker_run     : Starts a docker container in this directory"
	@echo " + bochs_debug    : Starts the bochs x86 emulator/debugger (ONLY AVAILABLE ON LINUX SYSTEMS, as of now)"
	@echo " + tools_fat      : Compiles a C99 program that emulates the FAT12 file system"


all: floppy_image tools_fat

# ============================================================
# Build the main image os the OS
# ============================================================
floppy_image: $(BUILD_DIR)/main_floppy.img
$(BUILD_DIR)/main_floppy.img: bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	#newfs_msdos -F 12 -f 1440 $(BUILD_DIR)/main_floppy.img
	$(CREATE_FS)
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -v -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	mcopy -v -i $(BUILD_DIR)/main_floppy.img $(DATA_DIR)/test.txt "::test.txt"
	mcopy -v -i $(BUILD_DIR)/main_floppy.img $(DATA_DIR)/todolist.txt "::todolist.txt"

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
# Tools
# ============================================================
tools_fat: $(BUILD_DIR)/tools/fat
$(BUILD_DIR)/tools/fat: always $(TOOLS_DIR)/fat/fat.c
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -std=c99 -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c

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


bochs_debug:
ifeq ($(UNAME_S), Linux)
	bochs -f $(BOCHS_CONFIG) -q
else
	@echo "'bochs_debug' target only available for linux based systems"
endif
