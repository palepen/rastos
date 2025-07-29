BITS 16
ORG 0x7C00

start:
    ; --- Setup a safe environment ---
    mov bp, 0x9000      ; Set up a stack
    mov sp, bp
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; --- Load the Kernel from Disk ---
    mov si, MSG_REAL_MODE
    call print
    
    ; Load 2 sectors from the disk starting at sector 2 (the one after the bootloader)
    ; to memory address 0x1000.
    mov bx, KERNEL_LOAD_ADDRESS ; ES:BX is the buffer address (0x0000:0x1000)
    mov ah, 0x02                ; Read sectors function
    mov al, 2                   ; Number of sectors to read
    mov ch, 0                   ; Cylinder 0
    mov cl, 2                   ; Start at sector 2
    mov dh, 0                   ; Head 0
    int 0x13
    jc disk_error               ; Jump if carry flag is set (error)

    ; --- Switch to Protected Mode ---
    call switch_to_pm
    jmp $ ; Should not be reached

disk_error:
    mov si, DISK_ERROR_MSG
    call print
    hlt

; --- Includes ---
%include "boot/stdio.asm"
%include "boot/gdt_32.asm"
%include "boot/switch_32.asm"

; --- Data ---
MSG_REAL_MODE       db "16-bit Real Mode: Loading kernel...", 13, 10, 0
DISK_ERROR_MSG      db "Disk read error", 0
KERNEL_LOAD_ADDRESS equ 0x1000

times 510 - ($ - $$) db 0
dw 0xAA55