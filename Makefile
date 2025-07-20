# Directories
BOOT_DIR ?= boot
BIN_DIR ?= bin

# Source files
STAGE1_SRC := stage1/Boot1.asm
STAGE2_SRC := stage2/KRNLDR.asm

# Output binaries
STAGE1_BIN := $(BIN_DIR)/Boot1.bin
STAGE2_BIN := $(BIN_DIR)/KRNLDR.bin

# Default target: build both stage 1 and stage 2
all: $(STAGE1_BIN) $(STAGE2_BIN)

# QEMU run using only stage 1 boot sector (bootable floppy)
run: $(STAGE1_BIN)
	@echo "--- Running bootloader in QEMU ---"
	qemu-system-i386 -drive file=$(STAGE1_BIN),format=raw,index=0,if=floppy

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
	nasm -f bin $< -o $@

.PHONY: all run clean
