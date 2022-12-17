#BUILD_DIR ?= build/
BUILD_DIR := build/
ASM ?= nasm
ASMFLAGS ?=-f obj
CC16 ?= /usr/bin/watcom/binl64/wcc
CFLAGS16 := -4 -d3 -s -ms -zl -zq
LD16 ?= /usr/bin/watcom/binl64/wlink

SOURCES_C := $(wildcard *.c)
SOURCES_ASM := $(wildcard *.asm)
OBJECTS_C := $(patsubst %.c, $(BUILD_DIR)/stage2/c/%.obj, $(SOURCES_C))
OBJECTS_ASM := $(patsubst %.asm, $(BUILD_DIR)/stage2/asm/%.obj, $(SOURCES_ASM))

DOCKER_CMD := docker run --rm -it --name nano-container -w /root/workspace/ -v $(realpath --relative-to ./)/:/root/workspace/ nanobyte_build_img_v2
DOCKER_WRKSPC := -w /root/workspace/
DOCKER_VOLUME := -v $(realpath --relative-to ./)/:/root/workspace/
DOCKER_IMAGE := nanobyte_build_img_v2

.PHONY: all stage2 clean

all: stage2

# Why not just run this whole process in the docker container?
stage2: $(BUILD_DIR)/stage2.bin

$(BUILD_DIR)/stage2.bin: $(OBJECTS_ASM) $(OBJECTS_C)
	#$(DOCKER_CMD) $(LD16) NAME $(BUILD_DIR)/stage2.bin FILE \{ $(OBJECTS_ASM) $(OBJECTS_C) \} OPTION MAP=$(BUILD_DIR)/stage2.map @linker.lnk

$(BUILD_DIR)/stage2/c/%.obj: %.c always
	docker run --rm -it --name nano-container $(DOCKER_WRKSPC) $(DOCKER_VOLUME)	$(DOCKER_IMAGE) $(CC16) $(CFLAGS16) -fo=$@ $<
	
$(BUILD_DIR)/stage2/asm/%.obj: %.asm always
	$(ASM) $(ASMFLAGS) -o $@ $<
	
always:
	mkdir -p $(BUILD_DIR)/stage2/c
	mkdir -p $(BUILD_DIR)/stage2/asm

clean:
	rm -f $(BUILD_DIR)/stage2.bin