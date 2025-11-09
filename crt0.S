    .section .text
    .globl _stext
_stext:
    la     sp, __StackTop    # set stack pointer to symbol provided by linker script
    call   main
1:  j 1b


/*

When building bare-metal C you need to set SP and call main.


*/