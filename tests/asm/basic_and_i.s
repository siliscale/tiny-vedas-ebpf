        .text
        .globl  _start
_start:                                   
        r1 -= 1
        r1 &= 0x7FFFFFFF
        exit