bits 16

section _TEXT class=CODE

global _x86_Video_WriteCharTeletype
_x86_Video_WriteCharTeletype:
	;setup stack frame
	push bp
	mov bp, sp
	
	;save bx
	push bx
	
	; [bp + 0] old call frame
	; [bp + 2] return address
	; [bp + 4] first arg (char to print)
	; [bp + 6] second arg (page)
	; NOTE: bytes are converted to words, as you can only push words to the stack
	mov ah, 0eh
	mov al, [bp + 4]
	mov bh, [bp + 6]
	int 10h
	
	;restore bx
	pop bx
	
	;restore stack frame
	mov sp, bp
	pop bp
	
	;return from routine
	ret