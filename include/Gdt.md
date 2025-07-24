## Code

# x86 Segment Descriptor (GDT Entry Format)

Each GDT entry (segment descriptor) is 8 bytes (64 bits) and has the following layout:

```
 Bits 63          56 55   52 51                          32
+------------------+----+----+----------------------------+
| Base 31:24       | G  | D | 0 | AVL | Limit 19:16       |
+------------------+----+----+----+-----+-----------------+
 Bits 31                          16
+----------------------------------+----------------------+
| Base 23:0                                             |
+--------------------------------------------------------+
 Bits 15                          0
+--------------------------------------------------------+
| Limit 15:0                                            |
+--------------------------------------------------------+
```

---

## 🧩 Bit Breakdown (Detailed)

| Bits        | Field                          | Description |
|-------------|--------------------------------|-------------|
|  0–15       | Segment Limit 15:0             | Lower 16 bits of segment size (limit) |
| 16–39       | Base Address 0:23              | Lower 24 bits of base address |
| 40          | Accessed Bit                   | Set by CPU on access (used in paging) |
| 41          | Readable/Writable              | Code: readable; Data: writable |
| 42          | Direction/Conforming           | Data: expand-down; Code: conforming |
| 43          | Executable                     | 1 = Code segment, 0 = Data segment |
| 44          | Descriptor Type                | 1 = Code/Data, 0 = System segment |
| 45–46       | Descriptor Privilege Level     | 0 = Ring 0 (kernel), 3 = Ring 3 (user) |
| 47          | Segment Present                | Must be 1 if used |
| 48–51       | Segment Limit 19:16            | Upper 4 bits of segment size |
| 52          | Available (for OS use)         | Can be used by OS (AVL bit) |
| 53          | Reserved (should be 0)         | Always 0 |
| 54          | Default Operation Size (D/B)   | 0 = 16-bit, 1 = 32-bit segment |
| 55          | Granularity (G)                | 0 = byte, 1 = 4 KB units |
| 56–63       | Base Address 24–31             | Upper 8 bits of base address |

---

## 🔧 Notes

- **Base Address**: Full 32-bit base = Base 0–23 + Base 24–31
- **Limit**: Full 20-bit limit = Limit 0–15 + Limit 16–19  
  If Granularity = 1, the limit is multiplied by 4 KB (i.e., shifted left by 12 bits).
- **Descriptor Type**: Must be set to `1` for code/data segments; set to `0` for system segments like TSS or LDT.
- **DPL**: Determines what privilege level the segment can be accessed from.
- **G, D, AVL** bits control behavior; always set `Reserved` to 0.

---

## ✅ Example Descriptor (Pseudo Fields)

| Field         | Value       | Meaning                        |
|---------------|-------------|--------------------------------|
| Base          | `0x00000000`| Segment starts at 0x0          |
| Limit         | `0x000FFFFF`| 4 GB (with G = 1)              |
| G             | `1`         | Limit is in 4 KB units         |
| D             | `1`         | 32-bit segment                 |
| P             | `1`         | Segment present                |
| DPL           | `00`        | Ring 0                         |
| S             | `1`         | Code/Data descriptor           |
| Type          | `1010`      | Executable, Readable Code      |

---

Let me know if you want this saved as an actual `.md` file or used inside a README with code examples!


```
 ; This is the beginning of the GDT. Because of this, its offset is 0.
 
; null descriptor 
	dd 0 				; null descriptor--just fill 8 bytes with zero
	dd 0 
 
; Notice that each descriptor is exactally 8 bytes in size. THIS IS IMPORTANT.
; Because of this, the code descriptor has offset 0x8.
 
; code descriptor:			; code descriptor. Right after null descriptor
	dw 0FFFFh 			; limit low
	dw 0 				; base low
	db 0 				; base middle
	db 10011010b 			; access
	db 11001111b 			; granularity
	db 0 				; base high
 
; Because each descriptor is 8 bytes in size, the Data descritpor is at offset 0x10 from
; the beginning of the GDT, or 16 (decimal) bytes from start.
 
; data descriptor:			; data descriptor
	dw 0FFFFh 			; limit low (Same as code)
	dw 0 				; base low
	db 0 				; base middle
	db 10010010b 			; access
	db 11001111b 			; granularity
	db 0				; base high
```

# Global Descriptor Table (GDT) Setup

This section explains the `install_gdt` assembly function, used to install the Global Descriptor Table in x86 real/protected mode.

## Assembly Code

```asm
install_gdt:
    cli                 ; Disable interrupts
    pusha               ; Save all general-purpose registers
    lgdt    [toc]       ; Load GDT pointer into GDTR
    sti                 ; Re-enable interrupts
    popa                ; Restore all registers
    ret                 ; Return to caller
```

## Instruction Breakdown

| Instruction | Meaning |
|-------------|---------|
| `cli`       | Clears the interrupt flag to prevent  interrupts during GDT setup. |
| `pusha`     | Pushes all general-purpose registers onto the stack. |
| `lgdt [toc]`| Loads the GDT pointer into GDTR from memory address `toc`. |
| `sti`       | Sets the interrupt flag, re-enabling interrupts. |
| `popa`      | Pops all general-purpose registers from the stack. |
| `ret`       | Returns from the function. |

## GDT Pointer Structure (`toc`)

```c
struct GDTPointer {
    uint16_t limit;   // Size of GDT - 1
    uint32_t base;    // Base address of GDT
} __attribute__((packed));
```

This pointer is typically declared in C or directly in assembly like:

```asm
toc:
    dw gdt_end - gdt - 1     ; limit
    dd gdt                   ; base
```

## Notes

- Make sure `gdt` is aligned and the segment descriptors are properly defined.
- Always disable interrupts (`cli`) before loading a new GDT to prevent faults.


# GDT Segment Descriptor Breakdown

In assembly language, **each declared byte, word, dword, qword, or instruction** is literally placed **right after each other** in memory.

Given the following 8-byte GDT entry:

```
11111111 11111111 00000000 00000000 00000000 10011010 11001111 00000000
```

Or, as bytes:
```asm
db 0xFF
db 0xFF
db 0x00
db 0x00
db 0x00
db 0x9A    ; access
db 0xCF    ; granularity
db 0x00    ; base high
```

---

## Bit-Level Analysis

### Bytes 0–1: Segment Limit (Bits 0–15)

```
11111111 11111111 → 0xFFFF
```

These two bytes specify the **segment limit**, meaning we cannot access memory beyond address `0xFFFF` within this segment. Attempting to do so would cause a **General Protection Fault (GPF)**.

---

### Bytes 2–4: Base Address (Bits 16–39)

```
00000000 00000000 00000000 → 0x000000
```

This is the lower 24 bits of the **segment base address**, which in this case is `0x0`.

So, with a base of `0x0` and limit `0xFFFF`, this code segment can access every byte from `0x0` to `0xFFFF`.

---

### Byte 5: Access Byte (Bit 40–47)

```asm
db 10011010b   ; 0x9A
```

| Bit | GDT Bit | Meaning                          | Value | Notes                          |
|-----|---------|----------------------------------|-------|--------------------------------|
| 0   | 40      | Accessed                         | 0     | Unused (no virtual memory yet) |
| 1   | 41      | Readable/Writable                | 1     | Read/Execute allowed           |
| 2   | 42      | Expansion Direction / Conforming | 0     | Ignored                        |
| 3   | 43      | Executable                       | 1     | This is a code segment         |
| 4   | 44      | Descriptor Type                  | 1     | Code/Data descriptor           |
| 5–6 | 45–46   | Descriptor Privilege Level (DPL) | 00    | Ring 0                         |
| 7   | 47      | Present                          | 1     | Segment is in memory           |

**Interpretation**:  
This is a **code segment**, **readable**, **ring 0**, and **present in memory**.

---

### Byte 6: Flags and Segment Limit High (Bits 48–55)

```asm
db 11001111b   ; 0xCF
```

| Bit | GDT Bit | Meaning                        | Value | Notes                                |
|-----|---------|--------------------------------|-------|--------------------------------------|
| 0–3 | 48–51   | Segment Limit (Bits 16–19)     | 1111  | Combines with low bits for 0xFFFFF   |
| 4   | 52      | OS-Available                   | 0     | Reserved for OS use                  |
| 5   | 53      | Reserved                       | 0     | Must be 0                            |
| 6   | 54      | Default Operand Size (D/B)     | 1     | 32-bit segment                       |
| 7   | 55      | Granularity (G)                | 1     | 4 KB granularity                     |

So we can access up to `0xFFFFF`, and because **granularity is enabled**, we multiply by `4 KB`, allowing access up to **4 GB**.

---

### Byte 7: Base Address High (Bits 56–63)

```asm
db 00000000b   ; 0x00
```

The final 8 bits of the base address, which is still `0`.

---

## Final Summary

This descriptor defines a **32-bit code segment** that:

- Starts at `0x00000000`
- Has a limit of `0xFFFFF` with 4 KB granularity → total size: **4 GB**
- Is readable and executable
- Has **Ring 0 (kernel)** privilege
- Is marked as **present in memory**

---
