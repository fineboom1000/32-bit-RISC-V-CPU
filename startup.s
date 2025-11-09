/*

RAM sections
I am testing two things here, .data and .bss
recall what they should do
.data should hold globals and varables with intialized values at 
runtime. .data is held in ROM, and we copy from its LMA to its VMA in RAM.

.bss contains all those that are not initalzied at runtime.
the object file should not contain any space that is allocated for .bss section
this should all be zeroed out on the stack.

in short
.data gets copied from ROM to RAM and holds initialized variables.

.bss starts zeroed.


and to be clear, when the program starts
ROM(which we made read only) has .text, code, and .data
RAM will be loaded with .data and .bss and they will "live" the
during execution, (for .bss  you load nothing).

And thus
before main runs the CPU must copy initalized data from ROM to RAM
zero out .bss region in RAM

A question: why can't we just leave all this stuff in ROM?
1. ROM is read only, unless these are constants, it would not make sense
2. Access speed, very slow, better to use RAM over RAM or flashcards
3. Linker intent, aka what the linker is told, .data is defined in RAM (given a VMA=RMA) 
we also gave it a LMA—where the inital bytes live—so in all the startup code copies from 
LMA to VMA once, then uses the RAM version.

so how can we prove that all this hapepns


for out C rutime file (startup code that prepares the C environment before main))

so in doing this I see that I actually need to add
somethign to the ld
I think it may be obvious
I need to add PROVIDE(_sidata = LOADADDR(.data));
Why? Well how do we referance the load address.

That will give me the LMA of .data
we already have _s and _e data
what we do is make a simple loop so it will
works like this 
source = _sidata, dest = _sdata, end = _edata



.data initialzed, we need the linker to put .data in ROM or the LMA section.
Then on boot we take those bytes from ROM and put them into RAM, which
is specifically done on their runtime addresses _sdata and _edata.
.bss zeroed, verify by declaring uninitialized globals and checking they are all zero at runtime.
Sp should be at __StackTop 
we provide this value of __StackTop in the linker as equaling _estack
recall that it will grow downwards.
We will store that value of sp into a global varable in the program 
before anything is done on the stack, so we can find where sp starts.
*/
    /* startup.s -- minimal RV32 startup:
       - set SP to __StackTop (linker-provided)
       - copy .data from _sidata -> _sdata.._edata
       - zero .bss _sbss.._ebss
       - store initial SP into __stack_pointer_initial for C to verify
       - call main()
    */

    .section .text
    .align  2
    .global _stext
    .type   _stext, @function

_stext:
    /* Set stack pointer to the value supplied by linker: __StackTop */
    la      sp, __StackTop        /* pseudo: load address of __StackTop into sp */

    /* --- Copy .data: LMA (_sidata) -> VMA (_sdata.._edata) --- */
    la      t0, _sidata           /* t0 = source in ROM (LMA) */
    la      t1, _sdata            /* t1 = destination start (.data in RAM) */
    la      t2, _edata            /* t2 = dest end */
1:  beq     t0, t2, 2f
    lw      t3, 0(t0)
    sw      t3, 0(t1)
    addi    t0, t0, 4
    addi    t1, t1, 4
    j       1b
2:

    /* --- Zero .bss: _sbss.._ebss --- */
    la      t0, _sbss
    la      t1, _ebss
3:  beq     t0, t1, 4f
    sw      zero, 0(t0)
    addi    t0, t0, 4
    j       3b
4:

    /* Save the initial SP value into a global variable so C can check it.
       __stack_pointer_initial is an uninitialized global (in .bss) that we write here. */
    la      t0, __stack_pointer_initial
    sw      sp, 0(t0)

    /* Call main (C). ABI: a0..a1 are argument registers; none used here. */
    call    main

    /* If main returns, just spin forever */
5:  j       5b

    .size _stext, . - _stext
