org     0x0

bits    16
jmp     main

Print:
			lodsb		            ; load next byte from string from SI to AL
			or	    al,     al	    ; Does AL=0?
			jz	    PrintDone	        ; Yep, null terminator found-bail out
			mov	    ah,	    0eh	    ; Nope-Print the character
			int	    10h
			jmp	    Print	            ; Repeat until null terminator found
PrintDone:
			ret		; we are done, so return
;   second stage
main:
        cli
        push    cs  ; cs = ds
        pop     ds

        mov     si,     msg
        call    Print
    
        cli
        hlt

msg	db	"Preparing to load rast system...",13,10,0