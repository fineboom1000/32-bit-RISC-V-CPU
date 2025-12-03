    .section .text
    .globl _stext
    .align 2

_stext:
    # each loop iteration reinitializes sp and writes a word at __StackLimit
loop_start:
    # step 1: configure stack pointer
    la     sp, __StackTop        # load stack top from linker symbol

    # step 2: load test values
    li     t0, 1
    li     t1, 2

    # step 3: perform instruction under test (sub: t2 = t1 - t0 => 1)
    sub    t2, t1, t0

    # step 4: store result into reserved stack base
    la     t3, __StackLimit
    sw     t2, 0(t3)

    # step 5: repeat forever
    j      loop_start
