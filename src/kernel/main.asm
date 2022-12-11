;=======================
; preinit
;=======================
org 0x0					; beginning of the OS code (calculate all memory offsets based on address 0, bootloader set this up)
bits 16					; tell the assembler that it should emit 16 bit code (NOT 16 bit mode)

;======================
; code
;======================
start:
	jmp main
; =============================
; entry point
; =============================
main:
	mov si, msg_hello
	call puts

.halt:					; backup infinite loop
	cli
	hlt					; halt the processor
	
; =============================
; print a string to the screen
; params:
;	- ds:si : string pointer
; =============================
puts:
	push si				; save used registers
	push ax				;
    push bx
.loop:					; loop over each byte starting at si
	lodsb				; load byte at ds:si into eax
	or al, al			; set zf if we encounter the NULL(0x0) byte
	jz .done			; we've found the null byte

	mov ah, 0x0e			; enter teletype mode
	mov bh, 0x0			; set page number
	mov al, al			; al has the byte to display
	int 10h				; invoke system interrupt (print char to screen)
	
	jmp .loop			; continue looping over the "string"
.done:
    pop bx
	pop ax				; restore used registers
	pop si				; restore used registers
	ret

;======================
; program data
;======================
msg_hello: db 'Hello world from kernel!', 0dh, 0ah, 0

;======================
; program padding
;======================
times 510-($-$$) db 0 	; fill up rest of program with 0s
