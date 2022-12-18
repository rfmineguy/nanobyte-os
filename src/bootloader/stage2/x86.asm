bits 16

section _TEXT class=CODE
global _x86_div64_32
_x86_div64_32:
	push bp
	mov bp, sp
	
	push bx
	
	; divide upper 32 bits
	mov eax, [bp + 8] 	;eax = upper 32 bits
	mov ecx, [bp + 12]	;ecx = divsor
	xor edx, edx
	div ecx				; axe = quot, edx = remainder
	
	; store upper 32 bits of quotient
	mov ebx, [bp + 16]
	mov [bx+4], eax
	
	; divide lower 32 bits
	mov eax, [bp + 4]	; eax = lower 32 bits
						; ecx = divisor
	div ecx
	mov [bx], eax
	mov bx, [bp + 18]
	mov [bx], edx
	
	pop bx 
			
	mov sp, bp
	pop bp
	ret

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