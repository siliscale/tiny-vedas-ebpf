        .text
        .globl  _start
_start:                                   
        r1 = 0xF0000000
        r2 = 4
        r1 s>>= r2
        exit