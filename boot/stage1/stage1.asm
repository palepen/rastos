bits 	16								; 16 bit mode
org		0x7C00							; BIOS loads us here.

start:	jmp main

; ###########################################
;   OEM Parameter Block (BIOS Parameter Block)
; ###########################################
bpbOEM					db "RastOS "
bpbBytesPerSector 		dw 512
bpbSectorPerCluster 	db 1
bpbReservedSectors		dw 1
bpbNumberOfFATs 		db 2
bpbRootEntries 			dw 224
bpbTotalSectors 		dw 2880
bpbMedia 				db 0xF0
bpbSectorsPerFAT 		dw 9
bpbSectorsPerTrack 		dw 18
bpbHeadsPerCylinder 	dw 2
bpbHiddenSectors 		dd 0
bpbTotalSectorsBig 		dd 0
bsDriveNumber 			db 0
bsUnused 				db 0
bsExtBootSignature 		db 0x29
bsSerialNumber			dd 0xa0a1a2a3
bsVolumeLabel 			db "RASTOS FLP "
bsFileSystem 			db "FAT12   "


print: 							; Simple print string function
		lodsb
		or		al,		al
		jz		.done
		mov		ah,		0x0e
		int		0x10
		jmp 	print
.done:
		ret

; ###########################################
;   Sector Reader (LBA)
; ###########################################
read_sector:
.read_next_sector:
		mov		di,		5		; 5 retries for error
.sector_retry_loop:
		push	ax
		push	bx
		push	cx
		push	dx

		call	lba_chs								; Convert LBA (in ax) to CHS
		mov		ah, 	0x02						; BIOS read sector function
		mov		al,		0x01						; Read one sector
		mov		ch,		BYTE [absoluteTrack]		; Track
		mov 	cl,		BYTE [absoluteSector]		; Sector
		mov		dh,		BYTE [absoluteHead]			; Head
		mov		dl,		BYTE [bsDriveNumber]		; Drive from BPB
		int		0x13								; Invoke BIOS interrupt
		jnc 	.success							; Success if carry flag is not set

		; --- Read failed, try again ---
		xor		ax,		ax							; BIOS reset disk function
		int		0x13								; Invoke BIOS interrupt
		dec		di
		
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		jnz		.sector_retry_loop
		jmp 	read_failure						; All retries failed

.success:
		pop		dx
		pop		cx
		pop		bx
		pop		ax
		add		bx,		WORD [bpbBytesPerSector]	; Queue next buffer
		inc		ax									; Queue next sector (LBA)
		loop	.read_next_sector					; Read next sector if loop counter is not zero
		ret

; ###########################################
; 		Cluster to LBA
; ###########################################
cluster_lba:
		sub 	ax,		2							; Zero base cluster number
		xor		cx,		cx
		mov		cl,		BYTE [bpbSectorPerCluster]	; Sectors per cluster
		mul		cx									; ax = (cluster - 2) * sectors per cluster
		add		ax,		WORD [datasector]			; Add data sector offset
		ret

; ###########################################
;   LBA to CHS
; ###########################################
lba_chs:
		xor 	dx,		dx
		div		WORD [bpbSectorsPerTrack]			; ax = LBA / SectorsPerTrack, dx = LBA % SectorsPerTrack
		inc 	dl										; Sector = (LBA % SectorsPerTrack) + 1
		mov		BYTE [absoluteSector], 	dl
		
		xor		dx,		dx
		div 	WORD [bpbHeadsPerCylinder]			; ax = Quotient / Heads, dx = Quotient % Heads
		mov		BYTE [absoluteHead], 	dl			; Head = (LBA / SectorsPerTrack) % Heads
		mov		BYTE [absoluteTrack],	al			; Track = LBA / (SectorsPerTrack * Heads)
		ret

; ###########################################
;   Bootloader Entry Point
; ###########################################
main:
		; --- Setup Segments and Stack ---
		cli
		mov		ax,		0x07C0
		mov		ds,		ax
		mov		es,		ax
		
		mov 	ax, 	0x0000
		mov		ss, 	ax
		mov		sp,		0xFFFF
		sti

load_root:
		; --- Compute size of root directory in sectors (store in cx) ---
		xor		cx,		cx
		xor		dx,		dx
		mov		ax,		32							; 32 byte directory entry
		mul		WORD [bpbRootEntries]
		div		WORD [bpbBytesPerSector]
		xchg	ax,		cx

		; --- Compute location of root directory (LBA) ---
		mov 	al, 	BYTE [bpbNumberOfFATs]
		mul		WORD [bpbSectorsPerFAT]
		add		ax,		WORD [bpbReservedSectors]
		
		mov 	si, 	ax							; Save root directory LBA
		
		mov 	WORD [datasector], ax 				; First data sector starts after root dir
		add		WORD [datasector], cx

		; --- Read root directory into memory ---
		mov		ax, 	si							; Restore root directory LBA for the read
		mov		bx,		0x2000						; Load root directory to 0x07C0:0x2000
		call 	read_sector

; ###########################################
;   Find Stage 2 ("KRNLDR.BIN")
; ###########################################
find_image:
		mov		cx,		WORD [bpbRootEntries]
		mov		di,		0x2000						; Start search at memory location of root directory

.loop:
		push	cx
		mov		cx,		11							; Compare 11 characters
		mov 	si,		image_name
		push 	di
		rep 	cmpsb								; Compare our name with the directory entry
		pop		di
		je		load_fat							; Found it!
		pop		cx
		add		di,		32							; Queue the next directory entry
		loop	.loop
		jmp 	failure								; Didn't find it

; ###########################################
;   Load FAT and Stage 2 Image
; ###########################################
load_fat:
		mov		si,		msg_found
		call	print

		mov		dx,		WORD [di + 0x001A]			; File's first cluster from directory entry
		mov		WORD [cluster], dx					; Store the cluster!

		; --- Compute size of FAT in sectors (store in cx) ---
		xor		ax, 	ax
		mov		al, 	BYTE [bpbNumberOfFATs]
		mul		WORD [bpbSectorsPerFAT]
		mov		cx,		ax

		; --- Compute location of FAT (LBA) and read it ---
		mov		ax, 	WORD [bpbReservedSectors]
		mov 	bx, 	0x8000						; Load FAT to a safe place: 0x07C0:0x8000
		call 	read_sector

		; --- Prepare to load the image file ---
		mov		si, 	msg_loading
		call 	print
		
		mov		ax,		0x1000
		mov 	es,	 	ax							; Destination segment for image
		mov 	bx,		0x0000						; Destination offset for image
		push	bx

load_image_loop:
		mov		ax,		WORD [cluster]				; Cluster to read
		pop 	bx									; Buffer offset to read into
		call	cluster_lba							; Convert cluster to LBA
		xor		cx,		cx
		mov		cl,		BYTE [bpbSectorPerCluster]	; Sectors to read
		call	read_sector
		push 	bx

		; --- Compute next cluster from FAT ---
		mov		ax, 	WORD [cluster]
		mov		cx, 	ax
		mov		dx, 	ax
		shr		dx,		1							; dx = ax / 2
		add		cx, 	dx							; cx = ax * 1.5 (index into FAT)
		mov		bx,		0x8000						; Location of FAT in memory
		add		bx,		cx							; Index into FAT
		mov 	dx, 	WORD [bx]					; Read two bytes from FAT

		; --- Isolate the 12-bit cluster number ---
		test 	ax, 	0x0001						; Check for odd cluster
		jnz		.odd_cluster

.even_cluster:
		and 	dx, 	0x0FFF						; For even, take low 12 bits
		jmp 	.done_cluster

.odd_cluster:
		shr 	dx, 	4							; For odd, take high 12 bits

.done_cluster:
		mov 	WORD [cluster],	dx					; Store the new cluster number
		cmp		dx, 	0xFF0						; Check for end-of-file marker
		jb 		load_image_loop						; If not EOF, load the next cluster

done:
		mov 	si, 	msg_success
		call 	print
		jmp 	0x1000:0x0000						; Jump to our loaded kernel!

failure:
		mov 	si, 	msg_failure
		call	print
		mov 	ah, 	0x00
		int 	0x16								; Await key press
		int 	0x19								; Warm boot computer

read_failure:
		mov 	si, 	msg_read_failed
		call	print
		jmp 	failure

; ###########################################
;   Data and Variables
; ###########################################
absoluteSector	db	0x00
absoluteHead	db 	0x00
absoluteTrack	db 	0x00

datasector		dw 	0x0000
cluster			dw 	0x0000
image_name		db	"KRNLDR  BIN" ; 8.3 filename, space padded

; FIX: Shortened all messages to save space.
CRLF			db  0x0D, 0x0A, 0x00
msg_found		db	"Found. ", 0x00
msg_loading		db 	"Loading... ", 0x00
msg_success		db	"OK", 0x0D, 0x0A, 0x00
msg_failure		db	"File not found.", 0x0D, 0x0A, 0x00
msg_read_failed db	"Read fail.", 0x0D, 0x0A, 0x00

times 510 - ($ - $$) db 0
dw		0xAA55
