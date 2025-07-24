bits    16
org     0x500
jmp     main

%include "stdio.inc"
%include "Gdt.inc"

LoadingMsg      db      "Preparing to load rast system...",13,10,0

; ###########################################
;   Stage 2 entry point
; ###########################################

main:
        cli
        xor     ax,     ax              ; null segments
        mov     ds,     ax
        mov     es,     ax
        mov     ax,     0x9000          ; stack begins at 0x0 - 0xffff
        mov     ss,     ax
        mov     sp,     0xFFFF
        sti                             ; enable interrupts

        ; ###########################################
        ;   print loading
        ; ###########################################

        mov     si,     LoadingMsg
        call    puts16

        ; ###########################################
        ;   install gdt
        ; ###########################################
        call install_gdt

        ; ###########################################
        ;   go into pm mode
        ; ###########################################    

        cli 
        mov     eax,    cr0
        or      eax,    1
        mov     cr0,    eax

        jmp     0x08:stage3

; ###########################################
;   entry point for stage 3
; ###########################################

bits    32
stage3:
        
        mov     ax,     0x10                            ; set data segments to data selector
        mov     ds,     ax
        mov     ss,     ax
        mov     es,     ax
        mov     esp,    0x90000                          ; stack begins from here

; ###########################################
;   STOP EXECUTION
; ###########################################
STOP:
        cli
        hlt