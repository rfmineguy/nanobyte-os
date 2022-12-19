bits 16

section _TEXT class=CODE
global _x86_div64_32
global _x86_Video_WriteCharTeletype

;
; This function basically performs the normal long division algorithm
; 0x1111 2222 3333 4444 / 0x123 = 0xF 03A2 DDDD DDEC
;   1111 2126
;		   FC 3333 4444 
;		   FC 3333 4344
;					100
;
; 0xF 03A2 DDDD DDEC r 0x100
_x86_div64_32:
    ; make new call frame
    push bp             ; save old call frame
    mov bp, sp          ; initialize new call frame

    push bx				; sp --

    ; divide upper 32 bits
    mov eax, [bp + 8]   ; eax <- upper 32 bits of dividend
    mov ecx, [bp + 12]  ; ecx <- divisor
    xor edx, edx
    div ecx             ; eax - quot, edx - remainder

    ; store upper 32 bits of quotient
    mov bx, [bp + 16]
    mov [bx + 4], eax

    ; divide lower 32 bits
    mov eax, [bp + 4]   ; eax <- lower 32 bits of dividend
                        ; edx <- old remainder
    div ecx

    ; store results
    mov [bx], eax
    mov bx, [bp + 18]
    mov [bx], edx

    pop bx

    ; restore old call frame
    mov sp, bp
    pop bp
    ret

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