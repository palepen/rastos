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

; ###########################################
;   32 bit pm mode routines
; ###########################################

bits    32

%define         VIDMEM          0xB8000         ; video memory
%define         COLS            80              ; width and height
%define         LINES           25
%define         CHAR_ATTRIB     14              ; char attribute white on black background

_CurX db 0
_CurY db 0

; ###########################################
;   putch32 
;      prints the character to screen
;       BL => character to print
; ###########################################

putch32:
        pusha
        mov     edi,    VIDMEM

        xor     eax,    eax
;--------------------------------
; Remember: currentPos = x + y * COLS! x and y are in _CurX and _CurY.
; Because there are two bytes per character, COLS=number of characters in a line.
; We have to multiply this by 2 to get number of bytes per line. This is the screen width,
; so multiply screen with * _CurY to get current line
;--------------------------------

        mov     ecx,    COLS * 2        ; mode 7 has 2 bytes per char
        mov     al,     byte [_CurY]    ; y_pos
        mul     ecx
        push    eax

;--------------------------------
; Now y * screen width is in eax. Now, just add _CurX. But, again remember that _CurX is relative
; to the current character count, not byte count. Because there are two bytes per character, we
; have to multiply _CurX by 2 first, then add it to our screen width * y.
;--------------------------------
        mov     al,     byte [_CurX]
        mov     cl,     2
        mul     cl
        pop     ecx                             ; pop y * COLS
        add     eax,    ecx

;-------------------------------
; Now eax contains the offset address to draw the character at, so just add it to the base address
; of video memory (Stored in edi)
;-------------------------------
        xor     ecx,    ecx
        add     edi,    eax                     ; add it to the base address
; -------------------
; new line
; -------------------

        cmp     bl,     0x0A
        je      .Row

;-----------------
; print a char
;-----------------

        mov     dl,             bl
        mov     dh,             CHAR_ATTRIB
        mov     word [edi],     dx 
;------------------
; update next pos
;---------------
        inc     byte    [_CurX]
        cmp     byte [_CurX], COLS
        je      .Row
        jmp     .done   

.Row:
        mov     byte [_CurX],   0
        inc     byte [_CurY]

.done:
        popa                            ; restore registers
        ret

puts32:

        pusha
        push    ebx                     ; copy the string address
        pop     edi                     ; 


.loop:
        mov     bl,     byte [edi]      ; get next char
        cmp     bl,     0
        je      done

        call    putch32

        inc     edi
        jmp     .loop
done:
        ; ###########################################
        ;   update cursor
        ; ###########################################
        mov     bh,     byte [_CurY]
        mov     bl,     byte [_CurX]
        call    mov_cur

        popa
        ret

; ###########################################
;   mov_cur
;        update cursor pos
;        bh - y
;        bl - x
; ###########################################

bits    32
mov_cur:
    pusha
    xor eax, eax
    mov ecx, COLS
    mov al, bh          ; Y position
    mul ecx             ; Y * COLS  
    add al, bl          ; Add X position
    mov ebx, eax        ; EBX now contains the cursor position

    ; Set low byte
    mov al, 0x0F
    mov dx, 0x03D4
    out dx, al
    mov al, bl          ; Low byte of cursor position
    mov dx, 0x03D5
    out dx, al

    ; Set high byte  
    mov al, 0x0E
    mov dx, 0x03D4
    out dx, al
    mov al, bh          ; High byte of cursor position
    mov dx, 0x03D5
    out dx, al

    popa
    ret

; ###########################################
;   Clear screen
; ###########################################

bits 32

clr_scr32:

        pusha
        cld
        mov     edi,    VIDMEM
        mov     cx,     2000
        mov     ah,     CHAR_ATTRIB
        mov     al,     ' '
        rep     stosw

        mov     byte [_CurX],   0
        mov     byte [_CurY],   0

        popa
        ret

;**************************************************;
;       GotoXY ()
;               - Set current X/Y location
;       AL=X position
;       AH=Y position
;**************************************************;

bits 32

goto_xy:
        pusha
        mov     [_CurX],        al
        mov     [_CurY],        ah
        popa    
        ret
      
        
%endif