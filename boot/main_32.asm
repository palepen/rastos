ORG 0x7C00

mov bp, 0x9000
mov sp, bp

mov si, MSG_REAL_MODE
call    print
call    switch_to_pm
jmp     $

%include    "boot/stdio.asm"
%include    "boot/gdt_32.asm"
%include    "boot/print_32.asm"
%include    "boot/switch_32.asm"

BITS 32
BEGIN_PM:
    mov     ebx, MSG_PROT_MODE
    call    print_string_pm
    jmp $

MSG_REAL_MODE db "Started in 16-bit real mode", 0
MSG_PROT_MODE db "Loaded 32-bit protected mode", 0

times 510 - ($ - $$) db 0
dw  0xAA55