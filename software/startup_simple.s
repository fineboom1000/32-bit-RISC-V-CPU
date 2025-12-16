# startup_simple.s
# minimal startup for fpga no data section copying
.section .text.startup
.global _start
.type _start, @function

_start:
    # set stack pointer
    lui  sp, 0x20004
    addi sp, sp, -4  # sp = 0x20003FFC
    # zero bss section
    la   t0, _sbss
    la   t1, _ebss
    beq  t0, t1, 2f
1:
    sw   zero, 0(t0)
    addi t0, t0, 4
    blt  t0, t1, 1b
2:

    # call main
    jal  ra, main

    # if main returns loop forever
3:
    j    3b

.size _start, .-_start