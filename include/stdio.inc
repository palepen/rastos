; ###########################################
;   stdio.inc
; ###########################################

%ifndef __STDIO_INC_RASTOS_INCLUDED__
%define __STDIO_INC_RASTOS_INCLUDED__

; ###########################################
;   puts16 () - prints a null terminated string
; ###########################################

bits    16
puts16:
        pusha
.loop1:
        lodsb
        or      al, al
        jz      puts16_done
        mov     ah, 0eh
        int     0x10
        jmp     .loop1
puts16_done:
        popa
        ret

%endif