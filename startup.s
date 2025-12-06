# startup.s - Assembly startup code for RV32I
# ROM base: 0x00001000
# RAM base: 0x20000000

.section .text.startup
.global _stext
.type _stext, @function

_stext:
    # Save initial SP value (should be at __StackTop from linker)
    la   t0, __stack_pointer_initial
    sw   sp, 0(t0)

    # Set stack pointer to __StackTop
    la   sp, __StackTop

    # Copy .data from ROM (LMA) to RAM (VMA)
    # _sidata = LMA start (in ROM)
    # _sdata = VMA start (in RAM)
    # _edata = VMA end (in RAM)
    la   t0, _sidata    # source (ROM)
    la   t1, _sdata     # dest start (RAM)
    la   t2, _edata     # dest end (RAM)
    beq  t1, t2, 2f     # skip if no .data
1:
    lw   t3, 0(t0)      # load word from ROM
    sw   t3, 0(t1)      # store word to RAM
    addi t0, t0, 4      # advance source
    addi t1, t1, 4      # advance dest
    blt  t1, t2, 1b     # loop until done
2:

    # Zero .bss section
    # _sbss = start of .bss
    # _ebss = end of .bss
    la   t0, _sbss      # start
    la   t1, _ebss      # end
    beq  t0, t1, 4f     # skip if no .bss
3:
    sw   zero, 0(t0)    # write zero
    addi t0, t0, 4      # advance
    blt  t0, t1, 3b     # loop until done
4:

    # Call main()
    call main

    # If main returns, loop forever
5:
    j    5b

.size _stext, .-_stext

# Reserve space for storing initial SP
.section .bss
.global __stack_pointer_initial
.align 4
__stack_pointer_initial:
    .space 4