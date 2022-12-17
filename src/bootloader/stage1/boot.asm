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
	; setup the code segment register properly
	;======================
	push es
	push word .after
	retf
	
.after:
	;======================
	; read from floppy disk
	;======================
	mov [ebr_drive_number], dl		; dl shoud be drive number upon startup (set by BIOS)
	
	;======================
	; show loading message
	;======================
	mov si, msg_loading
	call puts
	
	;======================
	; read drive parameters
	;======================
	push es
	mov ah, 08h
	int 13h
	jc floppy_error
	pop es
	
	and cl, 0x3F						; remove top 2 bits
	xor ch, ch
	mov [bpb_sectors_per_track], cx		; save to memory (sectors_per_track)
	
	inc dh
	mov [bpb_number_of_heads], dx		; save to memory (number_of_heads)
	
	;======================
	; calculate LBA of root directory
	; LBA (root directory) = reserved + fat_count * sectors_per_fat	
	;======================
	mov ax, [bpb_sectors_per_fat]
	mov bl, [bpb_fat_count]
	xor bh, bh
	mul bx								; ax = (fat_count * sectors_per_fat)
	add ax, [bpb_reserved_sectors]		; ax = reserved + (fat_count * sectors_per_fat)
	push ax
	
	;======================
	; calculate size of root directory
	; SIZE (root directory) = entry_size * entry_count
	;======================
	mov ax, [bpb_dir_entries_count]
	shl ax, 5						; ax *= 32
	xor dx, dx						; dx = 0
	div word [bpb_bytes_per_sec]	;
	
	test dx, dx						; if dx != 0 add 1
	jz .root_dir_after				; if dx == 0 skip
	inc ax							; add 1

.root_dir_after:
	;======================
	; read root directory
	;======================
	mov cl, al
	pop ax
	mov dl, [ebr_drive_number]
	mov bx, buffer
	call disk_read
	
	;======================
	; search for kernel.bin
	;======================
	xor bx, bx
	mov di, buffer

.search_kernel:
	mov si, file_kernel_bin			; file to search for
	mov cx, 11						; max file length
	push di
	repe cmpsb						; continue comparing string bytes (research further)
	pop di
	je .found_kernel
	
	add di, 32
	inc bx
	cmp bx, [bpb_dir_entries_count]
	jl .search_kernel
	
	;kernel not found
	jmp kernel_not_found_error

.found_kernel:
	mov ax, [di + 26]			;first cluster number (offset 26 bytes)
	mov [kernel_cluster], ax
	
	; load FAT from disk into memory
	mov ax, [bpb_reserved_sectors]
	mov bx, buffer
	mov cl, [bpb_sectors_per_fat]
	mov dl, [ebr_drive_number]
	call disk_read
	
	; read kernel and process fat chain
	mov bx, KERNEL_LOAD_SEGMENT
	mov es, bx
	mov bx, KERNEL_LOAD_OFFSET

.load_kernel_loop:
	; Read next cluster
	mov ax, [kernel_cluster]
	
	; NOTE: hardcoded value, we should change this sometime
	;  represents an offset into memory
	add ax, 31					; first cluster = (kernel_cluster - 2) * sectors_per_cluster + start_sector
								; start_sector = reserved + fats + root_dir_size = 1 + 18 + 134
	mov cl, 1
	mov dl, [ebr_drive_number]
	call disk_read
	
	; this may cause overflow if the kernel is over 64kb
	add bx, [bpb_bytes_per_sec]
	
	; compute location of next cluster
	mov ax, [kernel_cluster]
	mov cx, 3
	mul cx
	mov cx, 2
	div cx						; ax = index of entry in FAT, dx = cluster % 2
	mov si, buffer
	add si, ax
	mov ax, [ds:si]
	
	or dx, dx
	jz .even

.odd:
	shr ax, 4
	jmp .next_cluster_after
	
.even:
	and ax, 0x0fff

.next_cluster_after:
	cmp ax, 0x0FF8
	jae .read_finish			; jmp if above or equal (unsigned?)

	mov [kernel_cluster], ax
	jmp .load_kernel_loop

.read_finish:
	mov dl, [ebr_drive_number]
	mov ax, KERNEL_LOAD_SEGMENT
	mov ds, ax
	mov es, ax
	jmp KERNEL_LOAD_SEGMENT:KERNEL_LOAD_OFFSET
	
	; if this happens something is wrong
	jmp wait_key_and_reboot
	
	cli
	hlt

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
; When there is an error with search the FATs for the "KERNEL  BIN" file, this is called
;=============================
kernel_not_found_error:
	mov si, msg_kernel_not_found
	call puts
	jmp wait_key_and_reboot
	
;=============================
; This is called when we wanted to reboot the OS but wait for user input first
;=============================
wait_key_and_reboot:
	mov ah, 0			; wait for user keypress
	int 16h				; kernel call
	jmp 0FFFFh:0		; jump up to the start of BIOS (effectively rebooting)

;=============================
; Halt the CPU
;=============================
.halt:					; backup infinite loop
	cli					; disable interupts
    hlt

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

	mov ah, 0eh 		; enter teletype mode
	mov bh, 0h			; set page number
	int 10h				; invoke system interrupt (print char to screen)
	
	jmp .loop			; continue looping over the "string"
.done:
    pop bx
	pop ax				; restore used registers
	pop si				; restore used registers
	ret

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

	push cx
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
msg_loading:			db 'Loading...', 0dh, 0ah, 0
msg_read_fail: 			db 'Disk read failed!', 0dh, 0ah, 0
msg_kernel_not_found	db 'STAGE2.BIN not found', 0dh, 0ah, 0
file_kernel_bin: 		db 'STAGE2  BIN'
kernel_cluster:			dw 0

; Used for loading the kernel into memory
KERNEL_LOAD_SEGMENT		equ 0x2000
KERNEL_LOAD_OFFSET		equ 0


;======================
; program padding (BIOS expects 55aa at the end of the first 512 bytes)
;======================
times 510-($-$$) db 0 	; fill up, up to the last two bytes, with 0s
dw 0aa55h				; magic constant for bios

;======================
; buffer to read kernel into
;======================
buffer:

; NOTE: At this point if anything else is added, we go over the boot sector's 512 byte maximum
