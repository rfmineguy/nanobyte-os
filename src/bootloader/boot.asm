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
bpb_reserved_sectors:       dw 1
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
	
	;======================
	; read from floppy disk
	;======================
	mov [ebr_drive_number], dl
	mov ax, 1						; Second sector (LBA=1)
	mov cl, 1						; Read one sector
	mov bx, 0x7E00					; Store data after boot sector
	call disk_read
	
	;======================
	; test printing hello world
	;======================
	mov si, msg_hello
	call puts
;======================
; end main
;======================

;=============================
; When there is a floppy error this is called
;=============================
floppy_error:			; used for when attempts to read fail
	mov si, msg_read_fail
	call puts
	jmp wait_key_and_reboot
	
;=============================
; This is called when we wanted to reboot the OS but wait for user input first
;=============================
wait_key_and_reboot:
	mov ah, 0			; wait for user keypress
	int 16h				; kernel call
	jmp 0FFFFh:0		; jump up to the start of BIOS (effectively rebooting)
	
.halt:					; backup infinite loop
	cli					; disable interupts
    hlt
	;jmp .halt			;   just in case hlt doesn't actually halt

;======================
; Disk functions below
;======================

;======================
; Description:
;   - LBA to CHS (Conversion function, more in DiskLayout.md)
; Params:
;	- ax			  : LBA Address
; Returns:
; 	- cx [bits 0-5]   : sector number
;	- cx [bits 6-15]  : cylinder
;	- dh 			  : head
;======================
lba_to_chs:
    push ax
    push dx
										;Calculate Sector #
	xor dx, dx							;  dx = 0
	div word [bpb_sectors_per_track]	;  ax = LBA / SectorsPerTrack
										;  dx = LBA % SectorsPerTrack
	inc dx								;  dx = (LBA % SectorsPerTrack) + 1		(Sector #)
	mov cx, dx							;  cx = dx								Store sector # in proper register
	
	xor dx, dx							;Calculate head and cylinder
	div word [bpb_number_of_heads]		;  ax = (LBA / SPT) / HPC				(Cylinder #)
										;  dx = (LBA / SPT) % HPC				(Head #)
	
	mov dh, dl							; dh = head
	mov ch, al							; ch = cylinder (low 8 bits)
	shl ah, 6
	or cl, ah							; put upper two bits of cylinder in cl
	
	pop ax
	mov dl, al 							; restor dl
	pop ax
	ret

;======================
; Description:
;	- Reads sectors from a disk
;	- Ref: https://en.wikipedia.org/wiki/INT_13H#INT_13h_AH=02h:_Read_Sectors_From_Drive
; Params:
;	- ax   : LBA address
;	- cl   : number of sectors to read (128 max)
; 	- dl   : drive number
;	- es:bx: address to store read data
; Returns:
;	- N/A
;	- Read data will reside at the address specified with es:bs
;======================
disk_read:
	push ax
	push bx
	push cx								; save CL (number of sectors to read), cl is modified in 'lba_to_chs'
	push dx
	push di

	call lba_to_chs						; convert LBA to CHS
	pop ax								; al = # of sectors to read (was in cl)

	mov ah, 02h
	mov di, 3							; retry read count
.retry:
	pusha								; save registers
	stc									; set carry flag intentionally
	int 13h								; interupt 13h	(if the carry flag is still set there was an error)
	jnc .done
	
	; error reading
	popa
	call disk_reset
	
	dec di
	test di, di
	jnz .retry
.fail:									; all 3 attempts to read failed 	
	jmp floppy_error
.done:
	popa

	pop di
	pop dx
	pop cx								; save CL (number of sectors to read), cl is modified in 'lba_to_chs'
	pop bx
	pop ax
	ret

;======================
; Description:
;   - Resets the disk controller
; Params:
;   - dl: drive number
; Returns:
;   - N/A
;======================
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc floppy_error
	popa
	ret

;======================
; program data
;======================
msg_hello: db 'Hello World!', 0dh, 0ah, 0
msg_read_fail: db 'Read from disk failed!', 0dh, 0ah, 0

;======================
; program padding (BIOS expects 55aa at the end of the first 512 bytes)
;======================
times 510-($-$$) db 0 	; fill up to the last two bytes with 0s
dw 0aa55h				; magic constant for bios
