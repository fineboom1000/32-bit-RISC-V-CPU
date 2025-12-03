    .section .text
    .globl _stext
    .align 2
_stext:
    /* each loop iteration reinitializes sp and writes to the same stack slot */
loop_start:
    la   sp, __StackTop        # sp := stack top (linker-provided)
    li   t0, 1
    li   t1, 2
    add  t2, t0, t1            # t2 = 3

    /* store result into a fixed word at the bottom of stack (stack base) */
    la   t3, __StackLimit      # t3 := address of the reserved stack base
    sw   t2, 0(t3)             # MEM[__StackLimit] = 3

    j    loop_start            # repeat forever



  