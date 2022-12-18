#ifndef X86_H
#define X86_H
#include "stdint.h"

void __cdecl x86_div64_32(uint64_t dividend, uint32_t divisor, uint64_t *quotOut, uint32_t *remOut);
void __cdecl x86_Video_WriteCharTeletype(char c, uint8_t page);

#endif
