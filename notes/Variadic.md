# C supports variatic arguments
- However it used special functions that we don't have such as va_start, va_list, va_end, etc
- The cdecl calling convention is useful here especially (see notes/CallingConvensions.md)

```c
printf("Hello World");
stack:
  "Hello World"
  ret_addr
  old_bp
  ...

printf("Hello World %d %d %d %d", 1, 2, 3, 4);
stack:
  4
  3
  2
  1
  "Hello World %d %d %d %d"
  ret_addr
  old_bp
  ...
```
