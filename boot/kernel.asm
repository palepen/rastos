; File: boot/kernel.asm
ORG 0x1000
BITS 32
BEGIN_PM:
    ; This code runs after the switch to protected mode
    call clear_screen_pm
    
    mov ebx, MSG_PROT_MODE
    call print_string_pm

    ; You can now run any other 32-bit code
    mov ebx, HELLO_MSG
    call print_string_pm

    ; Halt the CPU
    cli
    hlt

; --- Includes ---
%include "boot/print_32.asm"

; --- Data ---
MSG_PROT_MODE   db 0x0A, 0x0A, "    Loaded 32-bit protected mode.", 0x0A , 0
HELLO_MSG       db "    Hello from the loaded kernel!", 0x0A , 0