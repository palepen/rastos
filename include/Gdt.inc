; ###########################################
;   Gdt.inc
; contains the global descriptor table
; ###########################################
%ifndef __GDT_INC_RASTOS_INCLUDED__
%define __GDT_INC_RASTOS_INCLUDED__
; Offset 0 in GDT: Descriptor code=0
 
bits    16

install_gdt:
        cli
        pusha                       ; save registers
        ; brings the info stored at toc to here => [toc]
        lgdt    [toc]               ; load gdt into gdtr
        sti                         ; enable interrupts
        popa
        ret

gdt_data:
        dd  0                       ; null descriptor
        dd  0           

; get code:                         ; code descriptor
        dw  0xFFFF                  ; limit low
        dw  0                       ; base low
        db  0                       ; base middle
        db  10011010b               ; access
        db  11001111b               ; granuality
        db  0                       ; base high

; gdt data:                         ; data descriptor
        dw  0xFFFF                  ; limit low
        dw  0                       ; base low
        db  0
        db  10010010b               ; access
        db  11001111b
        db  0

end_of_gdt:
toc:
    dw  end_of_gdt - gdt_data - 1
    dd  gdt_data

%endif ;__GDT_INC_RASTOS_INCLUDED__ 

