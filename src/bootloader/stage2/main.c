#include "stdint.h"
#include "stdio.h"

/* 
 - This is the bootloader entry point in C
*/
void __cdecl cstart_(uint16_t boot_drive) {
  printf("Hello world - %i %s %d\r\n", 4, "String", 8642);
  printf("This can is a new string\r");
  printf("at254");
}
