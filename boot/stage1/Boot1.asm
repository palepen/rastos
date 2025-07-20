bits 	16								; 16 bit mode
org		0						;start at this mem adress



start:	jmp main

; ###########################################
;   OEM Parameter Block
; ###########################################
bpbOE					db "RastOS "
bpbBytesPerSector: 		dw 512
bpbSectorPerCluster: 	db 1
bpbReservedSectors:		dw 1
bpbNumberOfFATs: 	    db 2
bpbRootEntries: 	    dw 224
bpbTotalSectors: 	    dw 2880
bpbMedia: 	            db 0xF0
bpbSectorsPerFAT: 	    dw 9
bpbSectorsPerTrack: 	dw 18
bpbHeadsPerCylinder: 	dw 2
bpbHiddenSectors: 	    dd 0
bpbTotalSectorsBig:     dd 0
bsDriveNumber: 	        db 0
bsUnused: 	            db 0
bsExtBootSignature: 	db 0x29
bsSerialNumber:	        dd 0xa0a1a2a3
bsVolumeLabel: 	        db "MOS FLOPPY "
bsFileSystem: 	        db "FAT12   "

msg 	db	"Welcome to Rast OS!", 0 	; to print a string

print: 							; loads the character one by one and outputs them in the video stream till it encounters 0
		lodsb
		or		al,		al
		jz		print_done
		mov		ah,		0x0e
		int		0x10
		jmp 	print

print_done:
		ret

; ###########################################
;   Sector Reader
; ###########################################

read_sector:
	.main:
		mov		di,		0x0005		; 5 retries for error
	.sector_loop:
		push	ax
		push	dx
		push	cx
		call	lba_chs								; convert lba(starting sector) to chs
		mov		ah, 	0x02						; Bios read sector
		mov		al,		0x01						; read one sector		
		mov		ch,		BYTE [absoluteTrack]		; track
		mov 	cl,		BYTE [absoluteSector]		; sector
		mov		dh,		BYTE [absoluteHead]			; head
		mov		dl,		BYTE [bsDriveNumber]		; drive
		int		0x13								; invoke Bios
		jnc 	.success								; test for read error
		xor		ax,		ax							; Bios rest disk
		int		0x13								; invoke bios
		dec		di
		pop		cx
		pop		bx
		pop		ax
		jnz		.sector_loop
	.success:
		mov		si,		msg_progress
		call 	print
		pop		cx
		pop		bx
		pop		ax
		add		bx,		WORD [bpbBytesPerSector]	; queue next buffer
		inc		ax									; queue next sector
		loop    .main								; read next sector
		ret


; ###########################################
; 		Convert CHS to LBA
;		LBA = (cluster - 2) * sectors per cluster
; ###########################################

cluster_lba:
		sub 	ax,		0x0002						; zero base cluster number
		xor		cx,		cx
		mov		cl,		BYTE [bpbSectorPerCluster]	; convert byte to word
		mul		cx
		add		ax,		WORD [datasector]			; base data sector
		ret

; ###########################################
;   LBA to CHS
;	AX => LBA address to convert
;	
;	absolute sector = (logical sector / sectors per track) + 1
;	absolute head = (logivcal sector / sector per track) % number of heads
;	absolute track = logical sector / (sectors per track * number of heads)	
; ###########################################

lba_chs:
		xor 	dx,		dx				
		div  	WORD [bpbSectorsPerTrack]
		inc 	dl										; for sector 0
		mov		BYTE [absoluteSector], 	dl
		xor		dx,		dx
		div 	WORD [bpbHeadsPerCylinder]	
		mov		BYTE [absoluteHead], 	dl
		mov		BYTE [absoluteTrack],	dl
		ret

; ###########################################
;   Bootloader Entry Point
; ###########################################

main:
		cli
		mov		ax,		0x07C0						; registers that point to our segment
		mov		ds,		ax
		mov		es,		ax
		mov		fs,		ax
		mov		gs,		ax		

		mov		ax, 	0x0000						; set the stack
		mov 	ss, 	ax
		mov		sp,		0xFFFF
		sti											; restore interrupt

load_root:
		; compute size of root directory and then store in cx
		xor		cx,		cx
		xor		dx,		dx
		mov		ax,		0x0020						; 32 byte directory Entry
		mul		WORD [bpbRootEntries]			
		div     WORD [bpbBytesPerSector]
		xchg	ax,		cx

		; compute loc of root directory
		mov 	al, 	BYTE [bpbNumberOfFATs]
		mul		WORD [bpbSectorsPerFAT]
		add		ax,		WORD [bpbReservedSectors]
		mov		WORD [datasector], 	ax
		mov		WORD [datasector], 	cx
		
		;read root directory into memory

		mov		bx,	0x2000							; copy root dir above bootcode
		call 	read_sector

; ###########################################
;   Find Stage 2
; ###########################################

; browse root directory for binary image

		mov		cx,		WORD [bpbRootEntries]		; load loop counter
		mov		di,		0x0200						; locate the first root entry

.loop:
		push	cx
		mov		cx,		0x000B						; eleven character name
		mov 	si,		image_name					; image name to find
		push 	di

		rep cmpsb									; reapeat the cmpsb instruction cx times
		pop		di
		je		load_fat
		pop		cx
		add		di,		0x0020						; queue the next directory entry
		loop	.loop
		jmp 	failure

; ###########################################
;   Load FAT
; ###########################################

load_fat:
		; save starting cluster of boot image

		mov		si,		msgCRLF
		call	print
		mov		dx,		WORD [di + 0x001A]			; file's first cluster

		; compute size of FAT and store in cx
		
		xor		ax, 	ax
		mov		al, 	BYTE [bpbNumberOfFATs]		
		mul		WORD [bpbSectorsPerFAT]
		mov		cx,		ax

		; compute loc of FAT and store in ax

		mov		ax, WORD [bpbReservedSectors]		; adjust for bootsector

		; read FAT into mem
		
		mov 	bx, 	0x0200						; copy FAT above bootcode
		call 	read_sector

		; read image file inot memory

		mov		si, 	msgCRLF
		call 	print
		mov		ax,		0x0050
		mov 	es,	 	ax							; destination for image
		mov 	bx,		0x0000						; destination for image
		push	bx

; ###########################################
;   Load Stage 2
; ###########################################

load_image:
		mov	ax,		WORD [cluster]					; cluster to read
		pop 	bx									; buffer to read into
		call	cluster_lba							; convert cluster to LBA
		xor		cx,		cx
		mov		cl,		BYTE [bpbSectorPerCluster]	; sectors to read
		call	read_sector
		push 	bx

		; compute next cluster

		mov		ax, 	WORD [cluster]
		mov		cx, 	ax
		mov		dx, 	ax
		shr		dx,   	0x0001						; div by 2
		add		cx, 	dx							; sum for 3 / 2
		mov		bx,		0x0200						; location of FAT in mem
		add		bx,		cx							; index into FAT
		mov 	dx, 	WORD [bx]					; read two bytes from FAT
		test 	ax, 	0x0001
		jnz		.odd_cluster

.even_cluster:
		and 	dx, 	0000111111111111b			; take low 12 bits
		jmp  	.done

.odd_cluster:
		shr 	dx, 	0x0004						; take high 12 bits

.done:
		mov 	WORD [cluster],	dx					; start new cluster
		cmp		dx, 	0x0FF0
		jb 		load_image

done:	
		mov 	si, msgCRLF
		call 	print
		push	WORD 0x0050
		push 	WORD 0x0000
		retf 

failure:
		mov 	si, 	msg_failure
		call	print
		mov 	ah, 	0x00
		int 	0x16								; await key press
		int 	0x19								; warm boot computer

absoluteSector 	db 	0x00
absoluteHead	db 	0x00
absoluteTrack	db 	0x00

datasector		dw 	0x0000
cluster			dw 	0x000
image_name		db  "KRNLDR  BIN"
msg_loading		db 	0x0D, 0x0A, "Loading Boot Image ", 0x0D, 0x0A, 0x00
msgCRLF 		db	0x0D, 0x0A, 0x00
msg_progress	db 	"*", 0x00
msg_failure		db	0x0D, 0x0A, "ERROR: Press Any Key to Reboot", 0x0A, 0x00

times 510 - ($ - $$) db 0	;set the unused 512 bytes to 0
dw		0xAA55		; boot signature INT 0x19 will load and execute the boot loader
