# Directories
BOOT_DIR     ?= boot
BIN_DIR      ?= bin
INCLUDE_DIR  ?= include

# Source files
STAGE1_SRC   := stage1/stage1.asm
STAGE2_SRC   := stage2/stage2.asm

# Output binaries
STAGE1_BIN   := $(BIN_DIR)/Boot1.bin
STAGE2_BIN   := $(BIN_DIR)/KRNLDR.BIN
FLOPPY_IMG   := $(BIN_DIR)/floppy.img

# Default target: build floppy image
all: $(FLOPPY_IMG)

# Create bootable floppy image
$(FLOPPY_IMG): $(STAGE1_BIN) $(STAGE2_BIN)
	@echo "--- Creating bootable floppy image ---"
	# Create blank 1.44MB floppy
	dd if=/dev/zero of=$@ bs=512 count=2880
	# Format as FAT12
	mkfs.fat -F 12 -n "RASTOS" $@
	# Copy stage2 to floppy BEFORE installing boot sector
	mcopy -i $@ $(STAGE2_BIN) ::KRNLDR.BIN
	# Install stage1 as boot sector (this must be last!)
	dd if=$(STAGE1_BIN) of=$@ bs=512 count=1 conv=notrunc
	@echo "--- Floppy image created successfully ---"

# QEMU run using the complete floppy image
run: $(FLOPPY_IMG)
	@echo "--- Running bootloader in QEMU ---"
	qemu-system-i386 -drive file=$(FLOPPY_IMG),format=raw,index=0,if=floppy

# Clean all binaries
clean:
	@echo "--- Cleaning up binaries ---"
	rm -rf $(BIN_DIR)

# Rule to build stage 1 (Boot1)
$(STAGE1_BIN): $(BOOT_DIR)/$(STAGE1_SRC)
	@echo "--- Assembling Stage 1: $< -> $@ ---"
	mkdir -p $(BIN_DIR)
	nasm -f bin $< -o $@

# Rule to build stage 2 (KRNLDR)
$(STAGE2_BIN): $(BOOT_DIR)/$(STAGE2_SRC)
	@echo "--- Assembling Stage 2: $< -> $@ ---"
	mkdir -p $(BIN_DIR)
	nasm -f bin -I$(INCLUDE_DIR)/ $< -o $@

.PHONY: all run clean
