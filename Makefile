# Directories
SRC_DIR      	:= boot
BIN_DIR      	:= bin
INCLUDE		 	:= include
BOOT_SRC     	:= boot_sect.asm
KERNEL_SRC   	:= kernel.asm
BOOT_BIN     	:= $(BIN_DIR)/boot_sect.bin
KERNEL_BIN   	:= $(BIN_DIR)/kernel.bin
OS_IMAGE     	:= $(BIN_DIR)/rastos.img

all: $(OS_IMAGE)

run: all
	qemu-system-i386 -fda $(OS_IMAGE)

# This rule now creates a simple image with the kernel at sector 2
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	dd if=/dev/zero of=$(OS_IMAGE) bs=512 count=2880
	dd if=$(BOOT_BIN) of=$(OS_IMAGE) conv=notrunc
	dd if=$(KERNEL_BIN) of=$(OS_IMAGE) seek=1 conv=notrunc

# Rule to build the monolithic bootloader
$(BOOT_BIN): $(SRC_DIR)/$(BOOT_SRC) $(INCLUDE)/boot/gdt_32.asm $(INCLUDE)/boot/switch_32.asm
	mkdir -p $(BIN_DIR)
	nasm -f bin -I$(INCLUDE) $< -o $@

# Rule to build the kernel
$(KERNEL_BIN): $(SRC_DIR)/$(KERNEL_SRC) $(INCLUDE)/boot/print_32.asm
	mkdir -p $(BIN_DIR)
	nasm -f bin -I$(INCLUDE) $< -o $@

clean:
	rm -rf $(BIN_DIR)

.PHONY: all run clean