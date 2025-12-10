/* linker_simple.ld for fpga synthesis */

MEMORY {
    ROM (rx)  : ORIGIN = 0x00001000, LENGTH = 16K
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 16K
}

ENTRY(_start)

SECTIONS {
    .text : {
        *(.text.startup)
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
    } > ROM

    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } > RAM AT > ROM

    .bss (NOLOAD) : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM
    
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}

PROVIDE(_sidata = LOADADDR(.data));