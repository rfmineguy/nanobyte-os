Memory Segmentation:

0x1234:0x5678
segment:offset

Visualization
0   16   32   48   ...   64k
---------Segment 0---------------
    ---------Segment 1---------------
         ---------Segment 2---------------
              ---------Segment 3---------------

real_address = segment * 16 + offset

==================================================

Active segments
  - cs:       currently running code segment
  - ds:       data segment
  - ss:       stack segment
  - es,fs,gs: extra (data) segments

==================================================

Referencing Memory Locations
segment:       [base + index * scale + displacement]
segment:       cs, ds, es, fs, gs, ss (ds if unspecified)
base:          (16 bits) bp/bx
               (32/64 bits) any G.P. register
scale:         (32/64 bits only) 1, 2, 4 or 8
displacement:  a signed constant value

Example:
var: dw 100

mov ax, var      ;copy offset to ax
mov ax, [var]    ;copy value to ax


array: dw 100, 200, 300

mov bx, arr        ;copy offset to ax
mov si, 2 * 2      ;index 2 ;array[2]

mov ax, [bx + si]  ;copy contents from bx + si to ax 


