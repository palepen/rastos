%ifndef __GDT_32_RASTOS_INCLUDED__
%define __GDT_32_RASTOS_INCLUDED__

gdt_start:
    ; Null descriptor
    dd  0x0
    dd  0x0

; Code Segment Descriptor
gdt_code:
    dw  0xffff      ; Segment limit (bits 0-15)
    dw  0x0         ; Base address (bits 0-15)
    db  0x0         ; Base address (bits 16-23)
    db  10011010b   ; Access flags
    db  11001111b   ; Granularity and segment limit (bits 16-19)
    db  0x0         ; Base address (bits 24-31)

; Data Segment Descriptor
gdt_data:
    dw  0xffff
    dw  0x0
    db  0x0
    db  10010010b
    db  11001111b
    db  0x0

gdt_end:

; GDT Descriptor pointer
gdt_descriptor:
    dw  gdt_end - gdt_start - 1 ; GDT limit (size)
    dd  gdt_start               ; GDT base address

; Define selectors
CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

%endif ; GDT_32_ASM_INCLUDED