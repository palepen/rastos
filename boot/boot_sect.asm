BITS 16
ORG 0x7C00
start:
    ; ds = es = 0
    xor     ax, ax
    mov     ds, ax
    mov     es, ax

    mov     bp, 0x8000
    mov     sp, bp
    
    mov     bx, 0x9000      ; es:bx = 0x0000:0x9000 = 0x09000
    mov     dh, 2           ; read 2 sectors

    call    disk_load
    
    mov     dx, [0x9000]
    call    print_hex

    call    print_newline

    mov     dx, [0x9000 + 512] 
    call    print_hex
    call    print_newline

    ; This is no longer needed since DS is already 0
    ; xor     ax, ax
    ; mov     ds, ax

    mov     si, intro
    call    print
    call    print_newline

    jmp     $

%include "boot/stdio.asm"
%include "boot/disk_io.asm"



intro   db "Welcome to rastOS", 0x00

; Padding and boot signature
times       510 - ($ - $$) db 0
dw          0xAA55

; boot sector = sector 1 of cyl 0 of head 0 of hdd 0
; from now on = sector 2 ...
times 256 dw 0xdada ; sector 2 = 512 bytes
times 256 dw 0xface ; sector 3 = 512 bytes