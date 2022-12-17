;
; this file sets up the bootloader stage 2
;
bits 16

section _ENTRY class=CODE

extern _cstart_
global entry

entry:
    cli
    ; setup stack (stack and data segment in small memory model should be the same)
    mov ax, ds
    mov ss, ax
    mov sp, 0
    mov bp, sp
    sti

    ; expect boot drive in dl, send it as argument to cstart function
    xor dh, dh
    push dx
    call _cstart_

    cli
    hlt