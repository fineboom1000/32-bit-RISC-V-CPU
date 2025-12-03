    .section .data
    .align 4
buffer:
    .word 0, 0, 0, 0

    .section .text
    .globl _start
_start:

    # t0 = base address of buffer
    la t0, buffer

    # store 123 into buffer[0]
    li t1, 123
    sw t1, 0(t0)

    # store 0xDEAD into buffer[1]
    li t1, 0xDEAD
    sw t1, 4(t0)

    # branch test: if t1 == 0xDEAD, jump to label pass
    li t2, 0xDEAD
    beq t1, t2, pass
    li t1, 0xBEEF      # will not execute if branch works
    sw t1, 8(t0)

pass:
spin:
    j spin
