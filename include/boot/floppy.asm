;*******************************************************
;
;	Floppy16.inc
;		Floppy drive interface routines
;
;*******************************************************

%ifndef __FLOPPY16_RASTOS_INCLUDED__
%define __FLOPPY16_RASTOS_INCLUDED__

bits	16

; NOTE: The BIOS Parameter Block has been moved to boot_sect.asm
; as it must reside at a specific offset in the boot sector.

datasector  dw 0x0000
cluster     dw 0x0000

absoluteSector db 0x00
absoluteHead   db 0x00
absoluteTrack  db 0x00

;************************************************
; Convert CHS to LBA
; LBA = (cluster - 2) * sectors per cluster
;************************************************
ClusterLBA:
          sub     ax, 0x0002                          ; zero base cluster number
          xor     cx, cx
          mov     cl, BYTE [bpbSectorsPerCluster]     ; convert byte to word
          mul     cx
          add     ax, WORD [datasector]               ; base data sector
          ret

;************************************************
; Convert LBA to CHS
; AX=>LBA Address to convert
;************************************************
LBACHS:
          xor     dx, dx                              ; prepare dx:ax for operation
          div     WORD [bpbSectorsPerTrack]           ; calculate
          inc     dl                                  ; adjust for sector 0
          mov     BYTE [absoluteSector], dl
          xor     dx, dx                              ; prepare dx:ax for operation
          div     WORD [bpbHeadsPerCylinder]          ; calculate
          mov     BYTE [absoluteHead], dl
          mov     BYTE [absoluteTrack], al
          ret


;************************************************
; Reads a series of sectors
; CX=>Number of sectors to read
; AX=>Starting sector
; ES:EBX=>Buffer to read to
;************************************************
ReadSectors:
     .MAIN:
          mov     di, 0x0005                          ; five retries for error
     .SECTORLOOP:
          push    ax
          push    bx
          push    cx
          call    LBACHS                              ; convert starting sector to CHS
          mov     ah, 0x02                            ; BIOS read sector
          mov     al, 0x01                            ; read one sector
          mov     ch, BYTE [absoluteTrack]            ; track
          mov     cl, BYTE [absoluteSector]           ; sector
          mov     dh, BYTE [absoluteHead]             ; head
          mov     dl, BYTE [bsDriveNumber]            ; drive
          int     0x13                                ; invoke BIOS
          jnc     .SUCCESS                            ; test for read error
          xor     ax, ax                              ; BIOS reset disk
          int     0x13                                ; invoke BIOS
          dec     di                                  ; decrement error counter
          pop     cx
          pop     bx
          pop     ax
          jnz     .SECTORLOOP                         ; attempt to read again
          int     0x18
     .SUCCESS:
          pop     cx
          pop     bx
          pop     ax
          add     bx, WORD [bpbBytesPerSector]        ; queue next buffer
          inc     ax                                  ; queue next sector
          loop    .MAIN                               ; read next sector
          ret

%endif		;__FLOPPY16_INC_67343546FDCC56AAB872_INCLUDED__