; this is for 32 bit adressing where we will not use interrupts to print 
; In this lesson we will write a new print string routine which works in 32-bit mode, where we don't have BIOS interrupts, by directly manipulating the VGA video memory instead of calling int 0x10. The VGA memory starts at address 0xb8000 and it has a text mode which is useful to avoid manipulating direct pixels.
; The formula for accessing a specific character on the 80x25 grid is:
; 0xb8000 + 2 * (row * 80 + col)

BITS 32
; ip at bx
; define constants
VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x8A

print_string_pm:
    pusha
    mov     edx, VIDEO_MEMORY

print_string_pm_loop:
    mov     al, [ebx]
    mov     ah, WHITE_ON_BLACK

    cmp     al, 0
    je      print_string_pm_done
    
    mov     [edx], ax
    add     ebx, 1   ; next character
    add     edx, 2   ; next video memory position

    jmp     print_string_pm_loop

print_string_pm_done:
    popa
    ret

clear_screen_pm:
    pushad
    mov     edi, VIDEO_MEMORY   ; Start of video memory
    mov     ecx, 80 * 25        ; Total number of screen characters (80x25)
    mov     ah, WHITE_ON_BLACK  ; Color attribute
    mov     al, ' '             ; Character to print (a space)

.clear_loop:
    mov     [edi], ax           ; Write space character with color
    add     edi, 2              ; Move to the next character position
    loop    .clear_loop         ; Repeat for the whole screen

    popad
    ret