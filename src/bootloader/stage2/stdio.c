#include "stdio.h"
#include "x86.h"
#include "stdbool.h"

int* printf_number(int* argp ,int length, bool sign, int radix);

void putc(char c) {
  x86_Video_WriteCharTeletype(c, 0);
}

void puts(const char* str) {
  while (*str) {
    putc(*str);
    str++;
  }
}

#define PRINTF_STATE_NORMAL 0
#define PRINTF_STATE_LENGTH 1
#define PRINTF_STATE_LENGTH_LONG 2
#define PRINTF_STATE_LENGTH_SHORT 3
#define PRINTF_STATE_SPEC 4

#define PRINTF_LENGTH_DEFAULT 0
#define PRINTF_LENGTH_SHORT_SHORT 1
#define PRINTF_LENGTH_SHORT 2
#define PRINTF_LENGTH_LONG 3
#define PRINTF_LENGTH_LONG_LONG 4

void __cdecl printf(const char* fmt, ...) {
  int* argp = (int*)&fmt;
  int state = PRINTF_STATE_NORMAL;
  int length = PRINTF_LENGTH_DEFAULT;
  int radix = 10;
  bool sign = false;

  while (*fmt) {
    switch (state) {
      case PRINTF_STATE_NORMAL:{
        switch(*fmt) {
          case '%':  state = PRINTF_STATE_LENGTH; break;
          default:   putc(*fmt); break;
        }
      }
      case PRINTF_STATE_LENGTH:{
        switch (*fmt) {
          case 'h': length = PRINTF_LENGTH_SHORT; state = PRINTF_STATE_LENGTH_SHORT; break;
          case 'l': length = PRINTF_LENGTH_LONG; state = PRINTF_STATE_LENGTH_LONG; break;
          default: goto PRINTF_STATE_SPEC_;
        }
        break;
      }
      case PRINTF_STATE_LENGTH_SHORT: {
        if (*fmt == 'h') {
          length = PRINTF_LENGTH_SHORT_SHORT;
          state = PRINTF_STATE_SPEC;
        }
        else goto PRINTF_STATE_SPEC_;
        break;
      }
      PRINTF_STATE_SPEC_:
      case PRINTF_STATE_SPEC: {
        switch (*fmt) {
          case 'c': putc((char)*argp);
                    argp++;
                    break;
          case 's': puts(*(char**)argp);
                    argp++;
                    break;
          case '%': putc('%');
                    break;
          case 'd':
          case 'i': radix = 10; sign = true;
                    argp = printf_number(argp, length, sign, radix);
                    break;
          case 'u': radix = 10; sign = false;
                    argp = printf_number(argp, length, sign, radix);
                    break;
          case 'x':
          case 'X':
          case 'p': radix = 16; sign = false;
                    argp = printf_number(argp, length, sign, radix);
                    break;
          case 'o': radix = 8; sign = false;
                    argp = printf_number(argp, length, sign, radix);
                    break;
          default: // ignore invalid spec
            break;
        }
        state = PRINTF_STATE_NORMAL;
        length = PRINTF_LENGTH_DEFAULT;
        radix = 10;
        sign = false;
      }
      fmt++;
    }
  }
}

const char g_HexChars[] = "0123456789abcdef";

int* printf_number(int* argp ,int length, bool sign, int radix) {
  char buffer[32];
  unsigned long long number;
  int number_sign = 1;
  int pos = 0;
  
  switch (length) {
    case PRINTF_LENGTH_SHORT_SHORT:
    case PRINTF_LENGTH_SHORT:
    case PRINTF_LENGTH_DEFAULT: {
      if (sign) {
        int n = *argp;
        if (n < 0) {
          n = -n;
          number_sign = -1;
        }
        number = n;
      }
      else {
        number = *(unsigned int*)argp;
      }
      argp++;
    }
    case PRINTF_LENGTH_LONG: {
      if (sign) {
        long int n = *(long int*)argp;
        if (n < 0) {
          n = -n;
          number_sign = -1;
        }
        number = (unsigned long long)n;
      }
      else {
        number = *(unsigned int*)argp;
      }
      argp++;
    }
    case PRINTF_LENGTH_LONG_LONG: {
      if (sign) {
        long long int n = *(long long int*)argp;
        if (n < 0) {
          n = -n;
          number_sign = -1;
        }
        number = (unsigned long long)n;
      }
      else {
        number = *(unsigned long long*)argp;
      }
      argp+=4;
      
    }
  }
  
  do {
    uint32_t rem;
    x86_div64_32(number, radix, &number, &rem);
    buffer[pos++] = g_HexChars[rem];
  } while (number > 0);
  if (sign && number_sign < 0) {
    buffer[pos++] = '-';
  }
  
  while (--pos >= 0) {
    putc(buffer[pos]);
  }
  return argp;
}