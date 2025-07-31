BITS 16
ORG 0x7C00

jmp start

MSG_REAL db "16-bit: Loading Kernel...", 13, 10, 0
DISK_ERROR_MSG db "Disk Error!", 0
KERNEL_LOAD_ADDRESS equ 0x1000
STAGE2_LOAD_ADDRESS equ 0x0500
start:
    ; --- Setup Segments & Stack ---
    cli
    mov ax, 0x0000
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000
    sti

    ; --- Print loading message ---
    mov si, MSG_REAL
    call print

    ; --- Load Kernel from disk (4 sectors from LBA 2) ---
    mov ax, KERNEL_LOAD_ADDRESS / 16 ; Calculate segment for 0x1000
    mov es, ax                       ; Set ES to destination segment
    mov bx, 0                        ; Load at offset 0 (ES:BX = 1000:0)
    
    mov ah, 0x02    ; BIOS Read Sectors function
    mov al, 4       ; Read 4 sectors (2KB)
    mov ch, 0       ; Cylinder 0
    mov cl, 2       ; Start at Sector 2 (kernel location)
    mov dh, 0       ; Head 0
    mov dl, 0       ; Drive A:
    int 0x13
    jc disk_error   ; If error, hang

    ; --- Switch to Protected Mode and jump to kernel ---
    call switch_to_pm

disk_error:
    mov si, DISK_ERROR_MSG
    call print
    hlt

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print
.done:
    ret

; --- Includes for GDT and P-Mode Switch ---
%include "boot/switch_32.asm"

; --- Padding and Boot Signature ---
times 510 - ($ - $$) db 0
dw 0xAA55