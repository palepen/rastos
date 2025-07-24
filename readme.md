# DOCS

## Bootloader


### CR0 Register (Control Register 0) — x86 Architecture

The `CR0` register is a 32-bit control register that configures various CPU operating modes in x86 systems.

### Bit Layout (Relevant Lower Bits)

```
Bit:  6   5   4   3   2   1   0
      |   |   |   |   |   |   |
      PG  -  ET  TS  EM  MP  PE
```

### Bit Descriptions

| Bit | Name | Description |
|-----|------|-------------|
| 0   | PE (Protection Enable) | Enables **Protected Mode**. When set to 1, the processor switches from Real Mode to Protected Mode. |
| 1   | MP (Monitor Coprocessor) | Controls how the `WAIT`/`FWAIT` instructions operate with a coprocessor present. |
| 2   | EM (Emulation) | When set, all floating-point operations will cause an exception. Used to emulate an FPU in software. |
| 3   | TS (Task Switched) | Set automatically when switching tasks. Used by the CPU to manage FPU state saving. |
| 4   | ET (Extension Type) | Indicates the type of math coprocessor installed: 0 = 80287, 1 = 80387 or later. |
| 5   | — (Unused) | Reserved or undefined in most architectures. Must be 0. |
| 6   | PG (Paging) | Enables **paging**, which activates virtual memory management. |

## Example: Enabling Protected Mode

To enable Protected Mode by setting the PE bit:

```nasm
mov eax, cr0
or  eax, 0x1        ; Set PE (bit 0)
mov cr0, eax
```

Paging (bit 6) must also be set if you’re entering virtual memory mode, typically after setting up page tables.

## Notes

- After setting PE, you must perform a far jump to flush the instruction queue.
- Setting PG without a valid page table will cause a page fault.
- Bits beyond 6 (like CD, NW, WP, AM, NW, etc.) are used in modern CPUs for cache control, write-protection, etc.

