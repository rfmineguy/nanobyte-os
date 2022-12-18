# Printf implementation
* see notes/Variadic.md

features
================
length
specifier

variables needed
================
fmt pointer      (points to current ch in fmt string)
argp             (points the the next argument in the function)
state            (whatever state the function is in)

algorithm (incomplete)
================
check the current char
  - not a '%'? simply display it
  - found a '%'? enter new state 'length' (indicated by '%')
    - the length is a format feature
    - no extra '%'?
    - check 
    - go back to normal state