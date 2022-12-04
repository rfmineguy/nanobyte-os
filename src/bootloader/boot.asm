;=======================
; preinit
;=======================
org 0x7c00				; beginning of the OS code (calculate all memory offsets based on address 7c00)
bits 16					; tell the assembler that it should emit 16 bit code (NOT 16 bit mode)

;======================
; bpb fat 12 header
;======================
jmp short start				; EB 3C 90		(just has to be there, i think so it knows where the start of the bootloader code is?)
nop
bpb_oem: 		            db "MSWIN4.1	; 8 bytes
bpb_bytes_per_sec: 	        dw 512	;
bpb_sectors_per_cluster:    db 1		;


;======================
; code
;======================
start:
	jmp main

; =============================
; print a string to the screen
; params:
;	- ds:si : string pointer
; =============================
puts:
	push si				; save used registers
	push ax				;
.loop:					; loop over each byte starting at si
	lodsb				; load byte at ds:si into eax
	or al, al			; set zf if we encounter the NULL(0x0) byte
	jz .done			; we've found the null byte

	mov ah, 0x0e		; enter teletype mode
	mov bh, 0x0			; set page number
	mov al, al			; al has the byte to display
	int 10h				; invoke system interrupt (print char to screen)
	
	jmp .loop			; continue looping over the "string"
.done:
	pop ax				; restore used registers
	pop si				; restore used registers
	ret

; =============================
; entry point
; =============================
main:
	;======================
	; setup data segments
	;======================
	mov ax, 0
	mov ds, ax
	mov es, ax
	
	;======================
	; setup stack registers
	;======================
	mov ss, ax
	mov sp, 0x7C00
	
	mov si, msg_hello
	call puts

	hlt					; halt the processor
	
.halt:					; backup infinite loop
	jmp .halt			;   just in case hlt doesn't actually halt

;======================
; program data
;======================
msg_hello: db 'Hello World!', 0dh, 0ah, 0

;======================
; program padding (BIOS expects 55aa at the end of the first 512 bytes)
;======================
times 510-($-$$) db 0 	; fill up to the last two bytes with 0s
dw 0aa55h				; magic constant for bios
