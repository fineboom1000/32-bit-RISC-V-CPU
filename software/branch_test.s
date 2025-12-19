.section .text.startup
.global _start

_start:
    lui  a0, 0x80000
    li   a1, 0x01
    sw   a1, 0(a0)
    li   t0, 10
delay1:
    addi t0, t0, -1
    bnez t0, delay1
    li   a1, 0x02
    sw   a1, 0(a0)
    li   t0, 10
delay2:
    addi t0, t0, -1
    bnez t0, delay2
    li   a1, 0x04
    sw   a1, 0(a0)
    li   t0, 10
delay3:
    addi t0, t0, -1
    bnez t0, delay3
    li   a1, 0x08
    sw   a1, 0(a0)
    li   t0, 10
delay4:
    addi t0, t0, -1
    bnez t0, delay4
    li   a1, 0x0F
    sw   a1, 0(a0)
    j    _start
