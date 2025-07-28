bits    16
org     0x0000      ; FIX: Must be 0x0000 to match the load address from stage 1 (0x1000:0x0000)
jmp     main

%include "stdio.inc"
%include "Gdt.inc"
%include "A20.inc"

LoadingMsg      db      13, 10, "Stage 2 Loaded. Entering Protected Mode...", 13, 10, 0

; ###########################################
;  Stage 2 Entry Point
;       - Setup Stack
;       - Install GDT
;       - Enable A20
;       - Enter Protected Mode
;       - Jump to Stage 3 (32-bit Kernel)
; ###########################################

main:
        ; --- Stack and segment setup ---
        cli
        xor     ax, ax          ; Null segments
        mov     ds, ax
        mov     es, ax
        mov     ax, 0x9000      ; Stack segment at 0x9000
        mov     ss, ax
        mov     sp, 0xFFFF      ; Stack pointer at the top
        sti                     ; Re-enable interrupts for now

        ; --- Print loading message ---
        mov     si, LoadingMsg
        call    puts16

        ; --- Install GDT ---
        call    install_gdt

        ; --- Enable A20 Line ---
        call    enable_a20_sys_control_a

        ; --- Enter Protected Mode ---
        cli                     ; Disable interrupts before mode switch
        mov     eax, cr0
        or      eax, 1
        mov     cr0, eax

        ; --- Far jump to flush CPU pipeline and set CS to our 32-bit code descriptor ---
        jmp     CODE_DESC:stage3

; ###########################################
;  Stage 3: 32-bit Protected Mode Entry
; ###########################################

bits    32
stage3:
        ; --- Set up 32-bit segments and stack ---
        mov     ax, DATA_DESC   ; Set data segments to our data selector
        mov     ds, ax
        mov     ss, ax
        mov     es, ax
        mov     esp, 0x90000    ; New 32-bit stack

        ; --- Clear screen and print success message ---
        call    clr_scr32
        mov     ebx, msg
        call    puts32

        ; --- Halt ---
        cli
        hlt

msg:
    db 0x0A, 0x0A, 0x0A, "         <[ RASTOS ]>", 0x0A, 0x0A
    db "      Welcome to 32-bit Protected Mode!", 0
