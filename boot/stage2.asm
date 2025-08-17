BITS 16
ORG 0x0500 ; Must match STAGE2_LOAD_ADDRESS in boot_sect

jmp start ; Jump over the data and included code

; --- Includes, Data, and BPB Definitions ---
%include "boot/bpb.asm"
%include "boot/stdio.asm"
%include "boot/fat12.asm"
%include "boot/gdt_32.asm"
%include "boot/switch_32.asm"

STAGE2_ERROR_MSG    db "Stage 2: Could not find or load kernel.bin", 0
KERNEL_FILE_NAME    db "KERNEL  BIN"
KERNEL_LOAD_ADDRESS equ 0x1000
DEBUG_CHAR          db "DAST", 0

start:
    ; --- DEBUG: Print a character to show Stage 2 has started ---
    mov si, DEBUG_CHAR
    call print
    ; --- END DEBUG ---

    ; Set segment registers to where we are loaded
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; --- Load the Kernel using FAT12 driver ---
    call    LoadRoot        ; Load root directory table

    mov     si, KERNEL_FILE_NAME
    call    FindFile        ; Find kernel.bin
    cmp     ax, -1
    je      error

    mov     ebx, KERNEL_LOAD_ADDRESS
    mov     bp, 0
    mov     si, KERNEL_FILE_NAME
    call    LoadFile        ; Load the file
    cmp     ax, -1
    je      error

    ; --- Switch to Protected Mode ---
    call switch_to_pm
    jmp $ ; Should not be reached

error:
    mov si, STAGE2_ERROR_MSG
    call print
    hlt