BITS 16
switch_to_pm:
    cli
    ; load GDT
    lgdt    [gdt_descriptor]
    mov eax, cr0
    or  eax, 0x1    ; set 32 bit mode
    mov cr0, eax
    jmp CODE_SEG:init_pm

BITS 32
init_pm:
    mov ax, DATA_SEG ; update the segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    mov ebp, 0x90000    ; stack at the top of free space
    mov esp, ebp

    call BEGIN_PM