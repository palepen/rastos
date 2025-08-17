%ifndef __A20_INC_INCLUDED__
%define __A20_INC_INCLUDED__

bits 16

EnableA20:
    call CheckA20
    test ax, ax
    jnz .done

    call A20Bios
    call CheckA20
    test ax, ax
    jnz .done

    call A20Keyboard
    call CheckA20
    test ax, ax
    jnz .done

    ; Error if all methods fail
    mov si, A20Error
    call print
    hlt

.done:
    ret

CheckA20:
    ; Implementation to check if A20 is enabled (e.g., memory wrap test)
    ; Return AX=1 if enabled, 0 if not
    ret

A20Bios:
    mov ax, 0x2401
    int 0x15
    ret

A20Keyboard:
    ; Keyboard controller method
    cli
    call a20wait
    mov al,0xAD
    out 0x64,al
    call a20wait
    mov al,0xD0
    out 0x64,al
    call a20wait2
    in al,0x60
    push ax
    call a20wait
    mov al,0xD1
    out 0x64,al
    call a20wait
    pop ax
    or al,2
    out 0x60,al
    call a20wait
    mov al,0xAE
    out 0x64,al
    call a20wait
    sti
    ret

a20wait:
    in al,0x64
    test al,2
    jnz a20wait
    ret

a20wait2:
    in al,0x64
    test al,1
    jz a20wait2
    ret

A20Error db "A20 Gate Error!", 0

%endif
