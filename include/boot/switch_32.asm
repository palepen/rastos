BITS 16
switch_to_pm:
    mov ax, 0x2401
    int 0x15        ; Enable A20 bit
    mov ax, 0x3
    int 0x10        ; Set VGA to text mode

    cli
    lgdt    [gdt_descriptor]
    mov eax, cr0
    or  eax, 0x1    ; Set PE bit to enter protected mode
    mov cr0, eax
    jmp CODE_SEG:init_pm

BITS 32
init_pm:
    mov ax, DATA_SEG ; Update segment registers
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000    ; Setup a new stack high in memory
    mov esp, ebp

    jmp 0x1000 ; **FIX:** Jump to the KERNEL_LOAD_ADDRESS