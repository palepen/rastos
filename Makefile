# Directories
SRC_DIR      	:= boot
BIN_DIR      	:= bin
BOOT_SRC     	:= boot_sect.asm
KERNEL_SRC   	:= kernel.asm
INCLUDE		 	:= include
BOOT_BIN     	:= $(BIN_DIR)/boot_sect.bin
KERNEL_BIN   	:= $(BIN_DIR)/kernel.bin
OS_IMAGE     	:= $(BIN_DIR)/rastos.img

# Default target
all: $(OS_IMAGE)

# Rule to run in QEMU
run: all
	qemu-system-i386 $(OS_IMAGE)

# Rule to create a proper 1.44MB floppy disk image
$(OS_IMAGE): $(BOOT_BIN) $(KERNEL_BIN)
	# 1. Create a blank 1.44MB image file filled with zeros
	dd if=/dev/zero of=$(OS_IMAGE) bs=512 count=2880
	# 2. Write the boot sector to the beginning of the image
	dd if=$(BOOT_BIN) of=$(OS_IMAGE) conv=notrunc
	# 3. Write the kernel starting at the second sector (seek=1)
	dd if=$(KERNEL_BIN) of=$(OS_IMAGE) seek=1 conv=notrunc

# Rule to build the bootloader
$(BOOT_BIN): $(SRC_DIR)/$(BOOT_SRC)
	mkdir -p $(BIN_DIR)
	nasm -f bin -I$(INCLUDE) $< -o $@

# Rule to build the kernel
$(KERNEL_BIN): $(SRC_DIR)/$(KERNEL_SRC)
	mkdir -p $(BIN_DIR)
	nasm -f bin -I$(INCLUDE) $< -o $@

# Rule to clean up build files
clean:
	rm -rf $(BIN_DIR)

.PHONY: all run clean