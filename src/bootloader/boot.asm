;=======================
; preinit
;=======================
org 0x7c00				; beginning of the OS code (calculate all memory offsets based on address 7c00)
bits 16					; tell the assembler that it should emit 16 bit code (NOT 16 bit mode)

;======================
; bpb fat 12 header
;======================
jmp short start								; EB 3C 90		(just has to be there, i think so it knows where the start of the bootloader code is?)
nop

bpb_oem: 		            db 'MSWIN4.1'	; OEM identifier, 8 bytes
bpb_bytes_per_sec: 	        dw 512	        ; Number of bytes per sector (2 bytes)
bpb_sectors_per_cluster:    db 1		    ;
bpb_reserved_sectors:       db 1
bpb_fat_count:              db 2
bpb_dir_entries_count:      dw 0e0h			; 
bpb_total_sectors:			dw 2880			; 2880 * 512 = 1.44MB
bpb_media_descriptor_type:  db 0f0h			; 3.5" floppy
bpb_sectors_per_fat:		dw 9
bpb_sectors_per_track: 		dw 18
bpb_number_of_heads: 		dw 2
bpb_number_hidden_sectors:	dd 0
bpb_large_sector_count: 	dd 0

ebr_drive_number:			db 0			; 0x0 = floppy, 0x80 = hdd
							db 0			; reserved byte
ebr_signature:				db 29h			; either 28h or 29h
ebr_volume_id:				db 'SERI'		; volume id (serial number, 4 bytes)
ebr_volume_label: 			db 'RFOS       '; 11 byte label padded with spaces
ebr_system_id:				db 'FAT12   '   ; 8 byte system id (always FAT12)
ebr_boot_code:

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
    push bx
.loop:					; loop over each byte starting at si
	lodsb				; load byte at ds:si into eax
	or al, al			; set zf if we encounter the NULL(0x0) byte
	jz .done			; we've found the null byte

	mov ah, 0x0e		; enter teletype mode
	mov bh, 0x0			; set page number
	; mov al, al		; al has the byte to display
	int 10h				; invoke system interrupt (print char to screen)
	
	jmp .loop			; continue looping over the "string"
.done:
    pop bx
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
