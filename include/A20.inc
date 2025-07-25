; ###########################################
;   Enable A20 address line 
; ###########################################

%ifndef __A20_INC_RASTOS_INCLUDED__
%define __A20_INC_RASTOS_INCLUDED__

bits 16

; ###########################################
;   From Keyboard Controller
; ###########################################

enable_a20_kkbrd:
        cli  
        push    ax
        mov     al,     0xdd            ; send enable a20 address line
        out     0x64,   al
        pop     ax
        ret

; ###########################################
;   Enable through output port
; ###########################################

enable_a20_kkbrd_out:
        cli
        pusha
        
        call    wait_input
        mov     al,     0xAD
        out     0x64,   al              ; disable Keyboard
        call    wait_input

        mov     al,     0xD0
        out     0x64,   al              ; tell Controller to read output port
        call    wait_output

        in      al,     0x60            
        push    eax                      ; get output port and store it
        call    wait_input

        pop     eax
        or      al,     2                 ; set bit 1 enable a20
        out     0x60,   al                ; write data bakc

        call    wait_input
        mov     al,     0xAE              ; enable Keyboard
        out     0x64,   al

        call    wait_input
        popa
        sti
        ret

; wait for input buffer to be clear
wait_input:
        in      al,     0x64
        test    al,     2
        jnz     wait_input
        ret

; wait for output buffer to be clear
wait_output:
        in      al,     0x64
        test    al,     1
        jz      wait_output
        ret

; ###########################################
;   Enable through bios
; ###########################################

enable_a20_bios:
        pusha
        mov     ax,     0x2401
        int     0x15
        popa
        ret
    
; ###########################################
;   Enable through system Control port A
; ###########################################

enable_a20_sys_control_a:
        push    eax
        mov     al,     2
        out     0x92,   al
        pop     ax
        ret   
%endif
