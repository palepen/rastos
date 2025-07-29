; load dh sectors from drive dl into ES:BX
disk_load:
    pusha
    push    dx
    
    mov     ah, 0x02    ; ah = 0x02 for read
    mov     al, dh      ; number of sectors to be read
    mov     cl, 0x02    ; cl = sector 

    mov     ch, 0x00    ; ch = cylinder
    mov     dh, 0x00    ; dh = head number

    ; [es:bx] = pointer to buffer where the data will be stored
    int     0x13        ; BIOS interrrupt
    jc      disk_error  ; if error 

    pop     dx
    cmp     al, dh      ; BIOS sets al to the # of sectors read, compare it.
    jne     sectors_error
    popa
    ret 

disk_error:
    mov     si, DISK_ERROR
    call    print
    call    print_newline
    mov     dh, ah       ; ah = error code and dl = disk drive
    ret
sectors_error:
    mov     si, SECTORS_ERROR
    call    print
    


DISK_ERROR: db "Disk read error", 0
SECTORS_ERROR: db "Incorrect number of sectors read", 0