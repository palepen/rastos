# Explaination For Code


## Power-On to Bootloader Execution

When you turn on an x86 PC, the **CPU** starts executing code from a hard-coded address in **ROM** (the BIOS). The **BIOS** runs the **Power-On Self-Test (POST)**, initializes hardware, sets up the **Interrupt Vector Table (IVT)**, and searches for a bootable device (floppy, HDD, CD, USB). The **first sector** (512 bytes) of the boot device is read into memory at **0x7C00** **if** the last two bytes are **0xAA55** (the boot signature). Execution then jumps to **0x7C00**.

### Why 0x7C00?

This address is a **historical convention**, chosen to leave space for the BIOS below and a growing stack above. **Deviation risks incompatibility** with real BIOSes and emulators.

### The Boot Signature

The **boot signature** (`0xAA55`) **must** occupy bytes 511–512 of the sector. If missing, the BIOS **will not** recognize the sector as bootable.

---

## Real Mode: Segmentation, Addressing, and BIOS

### The Real Mode Environment

- **16-bit mode**: Registers are 16 bits wide; all code must be 16-bit.
- **1 MB address space**: Addresses from `0x00000` to `0xFFFFF`.
- **No memory protection**: Any code can access any memory.
- **Segmentation**: Memory is accessed via **segment:offset** pairs.

### Segment:Offset Addressing

- **Physical address = (segment << 4) + offset**
- **Segment registers**: **CS** (Code), **DS** (Data), **ES** (Extra), **SS** (Stack).
- **Example**: `07C0:0000` = `0x07C0 << 4 + 0x0000` = `0x7C00` (bootloader location).
- **Limitations**: **16-bit segments** limit you to **64KB** per segment; addressing more requires changing segment registers.

### BIOS Services in Real Mode

- **Interrupts**: BIOS provides services via **software interrupts** (`int`).
- **Examples**:
  - `INT 0x10`: Video services (print character, set cursor).
  - `INT 0x13`: Disk services (read/write sectors).
  - `INT 0x16`: Keyboard input.
- **No BIOS in Protected Mode**: BIOS calls **do not work** once you leave real mode; all hardware must be accessed directly.

#### Interrupt Vector Table (IVT)

- **IVT Location**: Starts at **0x00000**.
- **Structure**: 256 entries, each 4 bytes (**segment:offset** of handler).
- **Usage**: When an interrupt occurs, the CPU looks up the handler in the IVT.

---

## Bootloader Internals: Minimal NASM Example

A **minimal NASM bootloader** is ≤512 bytes. Its primary jobs:
1. **Initialize CPU, segments, stack**.
2. **Load the next stage** (kernel or stage 2) from disk.
3. **Switch to protected mode**.
4. **Pass control** to the next stage.


```
halt_loop:
hlt
jmp halt_loop

print_string:
lodsb ; Load byte at DS:SI into AL, increment SI
or al, al ; Is AL zero?
jz print_done ; If so, done
mov ah, 0x0E ; BIOS teletype function
int 0x10 ; Print character
jmp print_string

print_done:
ret

message: db 'Booting rastos...', 0

; Pad to 510 bytes and add boot signature
times 510 - ($-$$) db 0
dw 0xAA55 ; Boot signature
```

#### **Line-by-Line Explanation**

- **`[bits 16]`**: Ensures 16-bit code generation; required for real mode.
- **`[org 0x7C00]`**: Directs the assembler to adjust address references for `0x7C00`.
- **Segment Registers**: `DS` and `ES` are set to `0x07C0` (shifted left, equals `0x7C00`).
- **Stack Setup**: Stack is placed at `0x9000`, above the bootloader.
- **Printing**: Uses BIOS interrupt `0x10` to print a string. This only works in **real mode**.
- **Infinite Halt**: Prevents CPU from executing garbage after bootloader.

---

## Multi-Stage Bootloaders and Disk I/O

### Single-Stage vs. Multi-Stage

- **Single-Stage**: Fits entirely in the 512-byte boot sector (very limited).
- **Multi-Stage**: Boot sector loads a **larger stage 2** from disk, enabling **file system parsing, memory detection, graphics, etc.**

### BIOS Disk Access

- **INT 0x13**: BIOS disk service interrupt.
- **AH=0x02**: Read sector(s).
- **Parameters**: **CH** (cylinder), **DH** (head), **CL** (sector), **ES:BX** (destination buffer), **AL** (number of sectors).
- **Example: Read One Sector**

- **Error Handling**: Always check the **carry flag**.

### CHS vs. LBA Addressing

- **CHS** (Cylinder-Head-Sector): Traditional BIOS addressing.
- **LBA** (Logical Block Addressing): Linear sector numbers; easier to use.
- **Conversion**:  
`LBA = (Cylinder × HeadsPerCylinder + Head) × SectorsPerTrack + (Sector - 1)`

---

## FAT12 Filesystem: Structure and File Loading

### FAT12 Overview

- **FAT12** is a simple filesystem (common on floppies).
- **Structure**:  
- **Boot Sector**: Contains BPB (BIOS Parameter Block).
- **FAT (File Allocation Table)**: Tracks cluster usage.
- **Root Directory**: Contains 32-byte entries for files and directories.
- **Data Area**: Where file contents are stored.

### Loading a File Step-by-Step

1. **Read Boot Sector**: Extract BPB values (sectors per cluster, FAT count, root directory size).
2. **Calculate Root Directory Location**:  
 `RootDirStart = ReservedSectors + (NumberOfFATs * SectorsPerFAT)`
3. **Read Root Directory**: Load it into memory.
4. **Find File**: Search directory entries for the target filename.
5. **Load FAT**: Read FAT into memory.
6. **Load File**: Follow cluster chain in FAT, read each cluster into memory.
7. **Jump to Loaded Code**: Transfer control to stage 2/kernel.

#### Technical Detail: Root Directory Entry

Each **32-byte** entry contains:
- **Filename** (8 bytes), **Extension** (3 bytes)
- **Attributes**
- **Reserved** (10 bytes)
- **Time**, **Date**
- **Starting Cluster**
- **File Size**

---

## Hardware Architecture: CPU, Memory, I/O

### Von Neumann Model

- **CPU**: Executes instructions.
- **Memory**: Stores code/data.
- **I/O Devices**: Communicate via ports or memory-mapped registers.
- **System Bus**: Connects all components.

### x86 Registers

| **Type**         | **Example Registers**         | **Purpose**                          |
|------------------|-------------------------------|---------------------------------------|
| **General**      | EAX, EBX, ECX, EDX, ESP, EBP  | Data manipulation, addressing        |
| **Segment**      | CS, DS, ES, SS, FS, GS        | Segmentation, memory access          |
| **Control**      | CR0, CR2, CR3, CR4            | Mode control, paging, protection     |
| **Debug**        | DR0–DR7                       | Breakpoints, debugging               |
| **Model-Specific**| MSRs                         | Advanced CPU features                |

### Control Registers (CR0, CR3)

- **CR0**:  
**PE bit (bit 0)** — Enable protected mode.  
**PG bit (bit 31)** — Enable paging (set later, by kernel).
- **CR3**:  
**Page Directory Base Register**. Points to the page directory when paging is enabled.

---

## Global Descriptor Table (GDT): Structure and Setup

### x86 Segment Descriptor (GDT Entry Format)

Each **GDT entry** (segment descriptor) is 8 bytes (64 bits):


---

#### **Detailed Bit Breakdown**

| **Bits**    | **Field**                     | **Description**                                  |
|-------------|------------------------------|---------------------------------------------------|
| 0–15        | Segment Limit 0:15            | Lower 16 bits of segment size (limit)             |
| 16–39       | Base Address 0:23             | Lower 24 bits of base address                     |
| 40          | Accessed                      | Set by CPU on access                              |
| 41          | Readable (Code)/Writable (Data)| Code: readable; Data: writable                   |
| 42          | Direction/Conforming          | Data: expand-down; Code: conforming               |
| 43          | Executable                    | 1 = Code segment, 0 = Data segment                |
| 44          | Descriptor Type               | 1 = Code/Data, 0 = System segment                 |
| 45–46       | Descriptor Privilege Level    | 0 = Ring 0, 3 = Ring 3                            |
| 47          | Present                       | Must be 1 if used                                 |
| 48–51       | Segment Limit 16:19           | Upper 4 bits of segment size                      |
| 52          | AVL                           | OS/reserved, can be set as needed                 |
| 53          | Reserved                      | Must be 0                                         |
| 54          | Default Op Size (D/B)         | 0 = 16-bit, 1 = 32-bit segment                    |
| 55          | Granularity (G)               | 0 = byte, 1 = 4 KB units                          |
| 56–63       | Base Address 24:31            | Upper 8 bits of base address                      |

---

#### **Notes**

- **Base**: Full 32-bit base = Base 0–23 + Base 24–31.
- **Limit**: Full 20-bit limit = Limit 0–15 + Limit 16–19.  
  If **Granularity = 1**, the limit is multiplied by 4 KB (shifted left by 12 bits).
- **Descriptor Type**: Must be set to `1` for code/data segments; set to `0` for system segments (TSS, LDT).
- **DPL**: Determines what privilege level the segment can be accessed from.
- **G, D, AVL** bits control behavior; always set **Reserved** to 0.

---

#### **Example NASM GDT Definition**
```
; Code descriptor (offset 0x8)
dw 0xFFFF         ; Limit 0:15
dw 0              ; Base 0:15
db 0              ; Base 16:23
db 0b10011010     ; Access: P=1, DPL=00, S=1, Type=1010 (code, readable)
db 0b11001111     ; Flags: G=1, D/B=1, L=0, AVL=0, Limit 16:19=0xF
db 0              ; Base 24:31

; Data descriptor (offset 0x10)
dw 0xFFFF         ; Limit 0:15
dw 0              ; Base 0:15
db 0              ; Base 16:23
db 0b10010010     ; Access: P=1, DPL=00, S=1, Type=0010 (data, writable)
db 0b11001111     ; Flags: same as above
db 0              ; Base 24:31
```
---


### **GDT Setup and Loading**

After defining the GDT, you must **load** it into the **GDTR register** using `lgdt`.  
This is done in **assembly**:
```
install_gdt:
cli ; Disable interrupts
pusha ; Save registers
lgdt [gdt_ptr] ; Load GDT pointer into GDTR
sti ; Re-enable interrupts
popa ; Restore registers
ret
```
**GDT pointer structure**:
```
gdt_ptr:
dw gdt_end - gdt_start - 1 ; Limit
dd gdt_start ; Base
```

---

### **Bit-Level Analysis: Example GDT Descriptor**

Given a **code descriptor**:
```
dw 0xFFFF ; Limit 0:15
dw 0 ; Base 0:15
db 0 ; Base 16:23
db 0x9A ; Access byte (10011010b)
db 0xCF ; Flags (11001111b)
db 0 ; Base 24:31
```


- **Bytes 0–1**: `0xFFFF` (Segment limit 0–15)
- **Bytes 2–4**: `0x00`, `0x00`, `0x00` (Base 0–23 = 0)
- **Byte 5**: `0x9A` (**P=1**, **DPL=00**, **S=1**, **Type=1010** = code, readable)
- **Byte 6**: `0xCF` (**G=1** [4K units], **D/B=1** [32-bit], **L=0**, **AVL=0**, **Limit 16–19=1100**
- **Byte 7**: `0x00` (Base 24–31 = 0)

**This is a ring 0, readable, 32-bit, 4 GB code segment starting at address 0.**

---

## Protected Mode: Theory and Entry

The **Global Descriptor Table (GDT)** defines memory segments for **protected mode**.  
After setting up the GDT and loading it into the **GDTR**, you must **enable protected mode** by setting the **PE bit** in **CR0**.

---

### **CR0 Register (Control Register 0)**

The **CR0** register controls fundamental CPU features such as **protected mode** and **paging**.

#### **Bit Layout (Relevant Lower Bits)**



---

#### **CR0 Bit Descriptions**

| **Bit** | **Name** | **Description**                                      |
|---------|----------|-------------------------------------------------------|
| 0       | PE (Protection Enable) | **Enables protected mode**. Set to 1 to switch CPU from real mode. |
| 1       | MP (Monitor Coprocessor) | Controls `WAIT`/`FWAIT` instruction behavior.         |
| 2       | EM (Emulation) | If 1, floating-point instructions cause exceptions.   |
| 3       | TS (Task Switched) | Used for FPU state management.                        |
| 4       | ET (Extension Type) | Indicates math coprocessor type (80287/80387).        |
| 5       | —        | Reserved, must be 0.                                  |
| 6       | PG (Paging) | **Enables paging** (for virtual memory).              |

---

### **Entering Protected Mode**

After setting up the **GDT**, **disable interrupts**, **set the PE bit** in **CR0**, and **flush the pipeline** with a **far jump**:

```
cli                   ; Disable interrupts
lgdt [gdt_ptr]        ; Load GDT
mov eax, cr0
or  eax, 0x1          ; Set PE (bit 0)
mov cr0, eax
jmp 0x08:pm_entry     ; Far jump to 32-bit code

```

```
; Set up stack
mov esp, 0x90000      ; Stack grows down from here

; ... your 32-bit code ...

```


**⚠️ Important:**
- **A far jump** is required to flush the CPU’s instruction queue and reload CS with the new segment selector.
- **Never enable paging** (`PG` bit) without first setting up page tables.
- **After this, all code must be 32-bit** and **all hardware must be accessed directly** (no more BIOS calls).

---

## Summary Table: Key Milestones

| **Stage**         | **CPU Mode**   | **Addressing**      | **BIOS Services** | **Memory Protection** | **Privilege** |
|--------------------|---------------|---------------------|-------------------|-----------------------|---------------|
| **Power-On**       | Real (16-bit) | Segment:Offset      | Yes               | No                    | Real Mode     |
| **Bootloader**     | Real (16-bit) | Segment:Offset      | Yes               | No                    | Real Mode     |
| **Protected Mode** | Protected (32-bit) | Linear/Flat         | No               | Yes                   | Ring 0 (Kernel) |

---

**Continue? Reply with “continue” for the rest:  
Real-world FAT12 parsing, hardware (CPU, memory, I/O), practical tips, troubleshooting, and references.**

# Enabling the A20 Address Line (x86 OS Development)

**A practical, code-centric guide for enabling A20 in x86 bootloaders—especially for QEMU environments—with fallbacks for maximum hardware compatibility.**

---

## Why Enable A20?

- **Real mode** (16-bit) only supports addressing up to **1MB** (`0xFFFFF`).
- **Without A20**, attempts to access memory above 1MB “wrap around”—a legacy of the original 8086/8088 hardware.
- **Enabling A20** unlocks linear (non-wrap-around) access to memory above 1MB, which is **essential for protected mode, kernel loading, and modern OS features**.
- **Failure** to enable A20 before accessing high memory causes a **triple fault** (CPU reset).

---

## Historical Context

- **IBM PC AT (80286)**: Introduced 24-bit addressing, but retained the wrap-around for compatibility.
- **Legacy**: Some old software depended on the wrap-around; modern OSes do not.
- **Default State**: Modern BIOS**es** and emulators (like QEMU) **disable A20 after POST**, so **bootloader code must re-enable A20** before using protected mode or loading code/data above 1MB.

---

## Methods to Enable A20

### **1. Fast A20 Gate (Port 0x92) — Recommended for QEMU**

**This is the simplest, fastest, and most reliable method for emulators and most modern hardware.**

```
enable_a20_sys_control_a:
push eax
mov al, 2 ; Set bit 1: enable A20
out 0x92, al ; System Control Port A
pop eax
ret
```
- **Port 0x92**: System Control Port A.
- **Bit 1 (A20 Enable):** `0` (disable), `1` (enable).
- **Unchanged bits**: Safe to leave alone; do not inadvertently change other features (HDD LED, fast reset, etc.).
- **QEMU always works** with this method.
- **Best Practice**: **Use this by default** for QEMU and most modern systems.

---

### **2. Keyboard Controller (8042) — Fallback Methods**

#### **A. Direct Enable Command (0xDD) — Some Chipsets Only**

```
enable_a20_kkbrd:
cli
push ax
mov al, 0xDD ; Enable A20
out 0x64, al ; Keyboard Controller Command Port
pop ax
ret
```

- **Not all hardware supports this**; use as a **fallback**.
- **QEMU supports** this method.

#### **B. Output Port Manipulation — Most Portable, Most Complex**
This is the **most robust, most hardware-portable** method.
This method **directly manipulates the 8042 keyboard controller**—a legacy system chip that is responsible not only for keyboard input, but also for certain system hardware functions, including control of the **A20 gate**.  

It **works even on systems where the Fast A20 Gate (port 0x92) and BIOS are not supported**, making it the most portable, hardware-agnostic approach.

---

### **Method Overview**

The process involves **sequencing several commands** to the 8042 controller, always waiting for hardware readiness at each step:

1. **Disable the keyboard** to prevent interference during the sensitive port manipulation.
2. **Read the controller’s output port** (which includes the A20 gate control bit among other system flags).
3. **Set the A20-enable bit** in this retrieved value.
4. **Write the modified value** back to the controller’s output port.
5. **Re-enable the keyboard** to restore normal operation.

---

### **Step-by-Step Explanation**

1. **Disable Keyboard**  
   The keyboard is temporarily disabled to ensure no key presses or controller interactions interfere with the process.

2. **Read Output Port**  
   The output port’s current value is read. This port typically controls system hardware features, including the A20 line.

3. **Set A20-Enable Bit**  
   The bit corresponding to the A20 gate is set in the read value.

4. **Write Output Port**  
   The updated value is written back to the controller’s output port, thus enabling the A20 line.

5. **Re-enable Keyboard**  
   The keyboard is re-enabled, returning the system to its normal state.

---

### **Why This Method?**
- **Portable**: Works on virtually all x86 PCs, including vintage and embedded systems.
- **Reliable**: Not dependent on BIOS or standard Fast A20 Gate support.
- **Robust**: Ensures A20 is enabled even on “unusual” or legacy hardware.
- **Slower**: Involves more steps and hardware synchronization than the Fast A20 Gate.

---

### **When to Use This Method**
Use this method **when the Fast A20 Gate fails** (e.g., on some real hardware, embedded controllers, or legacy systems), or **when you want your bootloader to be maximally portable**.

--- 

```
enable_a20_kkbrd_out:
cli
pusha
call    wait_input
mov     al,     0xAD    ; Disable Keyboard
out     0x64,   al
call    wait_input

mov     al,     0xD0    ; Read Output Port
out     0x64,   al
call    wait_output

in      al,     0x60    ; Read Output Port Data
push    eax             ; Save
call    wait_input

mov     al,     0xD1    ; Write Output Port
out     0x64,   al
call    wait_input

pop     eax
or      al,     2       ; Set A20 bit (bit 1: enable)
out     0x60,   al
call    wait_input

mov     al,     0xAE    ; Enable Keyboard
out     0x64,   al
call    wait_input

popa
sti
ret

; --- Helpers ---
wait_input:
in al, 0x64 ; Read Status Register
test al, 2 ; Input Buffer Full?
jnz wait_input ; Wait until clear
ret

wait_output:
in al, 0x64 ; Read Status Register
test al, 1 ; Output Buffer Empty?
jz wait_output ; Wait until full
ret


```
- **Works only in real mode.**
- **Not guaranteed** on all hardware/emulators.
- **Not available** after switching to protected mode.
- **Best Practice**: **Avoid** in production bootloaders; provided for completeness.

---

## **Summary Table: A20 Enable Methods**

| **Method**                | **QEMU** | **Speed** | **Portability** | **Recommendation**           |
|----------------------------|----------|-----------|-----------------|------------------------------|
| **Fast A20 (0x92)**        | Yes      | Fast      | Good            | **Default for QEMU.**        |
| **Keyboard (0xDD)**        | Yes      | Moderate  | Excellent       | **Fallback if needed.**      |
| **Keyboard (output port)** | Yes      | Slow      | Best            | **Use for real hardware.**   |
| **BIOS INT 0x15**          | Yes      | Fast      | Poor            | **Avoid in bootloaders.**    |

---

## **Best Practices**

- **Default to port 0x92** for QEMU/dev emulation.
- **Test A20** after enabling: Write/read above 1MB (`0x100000`); verify no wrap-around.
- **Triple Fault?** Check for premature access to high memory.
- **Debug**: Use Bochs/QEMU’s debugger (`b 0x7C00`, `dump_cpu`, etc.) for real-time inspection.
- **Document**: Always note your chosen method and rationale in your project docs.

---

## **When to Enable A20**

- **Critical**: **Before** entering protected mode or loading code/data above 1MB.
- **Placement**: Typically done **early in stage2 bootloader**, before GDT/IDT setup.

---

## **Code Usage Example**

Call your chosen A20 method at the start of your bootloader’s second stage:
```
call enable_a20_sys_control_a ; Or enable_a20_kkbrd, enable_a20_kkbrd_out
```

# Operating Systems Development: Prepare for the Kernel (Part 1) - VGA Programming Guide


## VGA Theory and Architecture

### Video Graphics Array (VGA) Overview

The **VGA** is an analog display standard introduced by IBM in 1987. It replaced multiple logic chips with a single ISA board containing:

- **Video Buffer**: Memory-mapped display data storage
- **Video DAC**: Digital-to-analog converter for color output
- **CRT Controller**: Generates sync signals and cursor timing
- **Sequencer**: Controls memory timing and character clocks
- **Graphics Controller**: Interface between video memory and display
- **Attribute Controller**: Manages color palettes and attributes

### Memory Mapping

VGA uses **memory-mapped I/O** at specific address ranges:

| **Address Range** | **Purpose** |
|-------------------|-------------|
| `0xA0000-0xBFFFF` | Graphics modes |
| `0xB0000-0xB7777` | Monochrome text mode |
| `0xB8000-0xBFFFF` | **Color text mode** (Mode 7) |

**Key Point**: Writing to these memory addresses directly changes what appears on screen.

### Text Mode 7 Specifications

- **Resolution**: 80 columns × 25 rows
- **Memory Start**: `0xB8000`
- **Character Format**: 2 bytes per character (character + attribute)
- **Total Memory**: 80 × 25 × 2 = 4,000 bytes

## Character Display Fundamentals

### Memory Layout and Addressing

Each character cell uses **2 bytes**:
1. **Byte 0**: ASCII character code
2. **Byte 1**: Attribute byte (color/formatting)

**Position Formula**: `address = base + (y × COLS + x) × 2`

Where:
- `base` = `0xB8000` (start of video memory)
- `COLS` = 80 (characters per row)
- `x`, `y` = column, row positions (0-based)

### Attribute Byte Format

```
Bit: 7 6 5 4 3 2 1 0
| | | | | | | |
B R G B I R G B
| || | ||
| BG | | FG |
| | |____|
BLINK INTENSITY
```

- **Bits 0-2**: Foreground color (RGB)
- **Bit 3**: Foreground intensity
- **Bits 4-6**: Background color (RGB)
- **Bit 7**: Blink or background intensity

**Color Values**:
```
0=Black, 1=Blue, 2=Green, 3=Cyan, 4=Red, 5=Magenta, 6=Brown, 7=Light Gray
8=Dark Gray, 9=Light Blue, 10=Light Green, 11=Light Cyan
12=Light Red, 13=Light Magenta, 14=Yellow, 15=White
```
