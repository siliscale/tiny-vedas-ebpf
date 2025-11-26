        .text
        .globl  _start
_start:                                   
        r1 += 0xFFFFFFFF
        r1 s>>= 1
        exit