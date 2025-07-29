# Directories
SRC_DIR   	?= boot
BIN_DIR   	?= bin
INC_DIR	  	:= include 
BOOT_SRC  	:= main_32.asm
BOOT_BIN  	:= $(BIN_DIR)/main_32.bin

all: $(BOOT_BIN)

run: $(BOOT_BIN)
	qemu-system-i386 $(BOOT_BIN)

$(BOOT_BIN): $(SRC_DIR)/$(BOOT_SRC)
	mkdir -p $(BIN_DIR)
	nasm -f bin -I$(INC_DIR) $< -o $@

clean:
	@echo "--- Cleaning up binaries ---"
	rm -rf $(BIN_DIR)

.PHONY: all run clean
