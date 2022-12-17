# Calling convensions
- C has certain rules as to how function calls are made
  + What do the caller and the callee have to adhere to? 
- In 16 and 32 bit mode the `_cdecl` convension is enforced
  + Arguments
    1. Passed via stack
    2. Pushed from right to left
    3. Caller removes the parameters from the stack
  + Return
    1. Integers, pointers (EAX)
    2. Floating point (ST0)
  + Registers
    1. eax, ecx, edx are saved by the caller
    2. all other data is saved by the calle
  + Name mangling
    1. C functions will be prepended with a '_'
- Example
  ```c
  #include <stdint.h>
  uint16_t length_sq(uint16_t x, uint16_t y) {
    uint16_t r = x * x + y * y;
    return r;
  }
  ```
  ```asm
  ;save contents of eax, ecx, edx if important
  main:
    push y
    push x
    call _length_sq
    add sp, 4        ; effectively pops x and y
  
  ;functions must always get back to their original state at ret
  _length_sq:
    push bp           ;stackframe
    mov bp, sp        ;
    
    sub sp, 2
    mov ax, [bp + 4]  ;x
    mul ax            ;x*x
    mov [bp - 2], ax  ;r=x*x
    
    mov ax, [bp + 6]  ;y
    mul ax            ;y*y
    add [bp - 2], ax  ;r=x*x+y*y
    
    mov ax, [bp - 2]  ;set return value
    
    mov sp, bp        ;stackframe
    pop bp            ;
    ret
  ```