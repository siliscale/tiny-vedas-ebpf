        .text
        .globl  _start
_start:                                   
        r1 += 2
        r1 %= 1
        r1 += 2
        r1 %= 0
        exit