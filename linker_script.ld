/* linker_script.ld — minimal, LD-friendly, no allocated .stack section */

MEMORY {
    ROM (rx) : ORIGIN = 0x00001000, LENGTH = 64K # temp changed to 0x80000000 from 0x1000 due to testing.
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 16K
}

/* Tunables */
STACK_SIZE = 0x1000; /* 4 KB */
HEAP_SIZE  = 0x1000; /* informational */

/* Entry */
ENTRY(_stext)

/* Basic RAM constants (safe before SECTIONS) */
_RAM_ORG = ORIGIN(RAM);
_RAM_LEN = LENGTH(RAM);
_RAM_END = _RAM_ORG + _RAM_LEN;
_estack = _RAM_END;

/* Export stack bounds as symbols only (no allocation) */
PROVIDE(__StackTop   = _estack);
PROVIDE(__StackLimit = (_estack - STACK_SIZE));

SECTIONS
{
  .text :
  AT(ORIGIN(ROM))
  {
    . = ORIGIN(ROM);
    . = ALIGN(4);
    _stext = .;
    KEEP(*(.isr_vector))
    *(.text*)
    *(.rodata*)
    . = ALIGN(4);
    _etext = .;
  } > ROM

  .data : AT(ADDR(.text) + SIZEOF(.text)) 
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data*)
    *(.data.*)
    . = ALIGN(4);
    _edata = .;
  } > RAM

  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    _sbss = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > RAM
}

/* Define heap after sections so _ebss exists */
PROVIDE(__heap_start = ALIGN(_ebss, 4));
PROVIDE(__heap_end   = __StackLimit);

/* Sanity checks */
ASSERT( (__heap_start) < (__heap_end),
        "ERROR: heap_start >= heap_end (heap/stack overlap)");
ASSERT( (_RAM_LEN) >= ( SIZEOF(.data) + SIZEOF(.bss) + STACK_SIZE + HEAP_SIZE ),
        "ERROR: RAM too small for data+bss+heap+stack" );

/* Aliases */
PROVIDE(_sram = _RAM_ORG);
PROVIDE(_eram = _RAM_END);
PROVIDE(_sdata_vma = _sdata);
PROVIDE(_edata_vma = _edata);
PROVIDE(_sbss_vma = _sbss);
PROVIDE(_ebss_vma = _ebss);
PROVIDE(_etext_vma = _etext);
PROVIDE(_sidata = LOADADDR(.data));