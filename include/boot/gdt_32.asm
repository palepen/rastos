gdt_start:
    ; starts with null 8 byte
    dd  0x0
    dd  0x0


    ; GDT for code seg.
    ; base = 0x00000, len = 0xfffff
gdt_code:
    dw  0xffff      ; seg len
    dw  0x0         ; seg base, bits 0-15
    db  0x0         ; seg base, bits 16-23
    db  10011010b   ; flags 
    db  11001111b   ; flag 4 + segment lesson
    db  0x0         ; segmentb base, 24-31


gdt_data:
    dw  0xffff
    dw  0x0
    db  0x0
    db  10010010b
    db  11001111b
    db  0x0

gdt_end:
gdt_descriptor:
    dw  gdt_end - gdt_start - 1
    dd  gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start