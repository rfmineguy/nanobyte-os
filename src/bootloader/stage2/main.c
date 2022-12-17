#include "stdint.h"
#include "stdio.h"

/* 
 - This is the bootloader entry point in C
*/
void __cdecl cstart_(uint16_t boot_drive) {
    puts("Hello World from C!\n");
}
