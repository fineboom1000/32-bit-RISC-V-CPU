# startup.s - SIMPLIFIED: No .data copy (pre-loaded by simulator)
.section .text.startup
.global _stext
.type _stext, @function

_stext:
    # Set stack pointer to __StackTop
    la   sp, __StackTop

    # Zero .bss section
    la   t0, _sbss      # start
    la   t1, _ebss      # end
    beq  t0, t1, 2f     # skip if no .bss
1:
    sw   zero, 0(t0)    # write zero
    addi t0, t0, 4      # advance
    blt  t0, t1, 1b     # loop until done
2:

    # Call main()
    call main

    # If main returns, loop forever
3:
    j    3b

.size _stext, .-_stext