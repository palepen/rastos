; ip: si stores the string address
print:
    lodsb           ; Load byte at DS:SI into AL, increment SI
    or      al, al       ; Check if it's the null terminator
    jz      print_done
    mov     ah, 0x0E    ; BIOS teletype output
    int     0x10
    jmp     print

print_done:
    ret

print_newline:
    mov     ah, 0x0E
    mov     al, 0x0D
    int     0x10
    mov     al, 0x0A
    int     0x10
    ret

; dx = input string
print_hex:
    pusha
    mov     cx, 0       ; Index Variable


.hex_loop:
    cmp     cx, 4
    je      .hex_done

    mov     ax, dx
    and     ax, 0x000F

    ; convert ot ascii
    add     al, '0'
    cmp     al, '9'
    jle     .store_digit
    add     al, 7        ; convert to A - F

.store_digit:
    mov     bx, HEX_OUT + 5     ; points to last store_digit
    sub     bx, cx              ; move backward by Index
    mov     [bx], al

    ror     dx, 4
    inc     cx
    jmp     .hex_loop

.hex_done:
    mov     si, HEX_OUT
    call    print
    popa
    ret

HEX_OUT     db '0x0000', 0