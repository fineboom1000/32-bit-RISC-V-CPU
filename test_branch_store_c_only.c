/* test_branch_store_c_only.c
   Bare-metal, no crt0. Set entry to main when linking.
   Uses only volatile memory accesses and inline asm for the final spin.
*/

#include <stdint.h>

volatile uint32_t * const mem = (uint32_t *)0x20000000;

int main(void) {
    /* diagnostics */
    mem[8] = 0x20000000u;   /* t0 diagnostic */
    mem[9] = 0x00000123u;   /* small diagnostic */

    /* start marker */
    mem[0] = 1u;

    /* beq equivalent */
    if (5u == 5u) mem[1] = 0x10u;
    else          mem[1] = 0x11u;

    /* simulated call: write 'inside' then 'after return' markers */
    mem[3] = 0x20u;         /* inside-subroutine marker */
    mem[2] = 0x21u;         /* after-return marker */

    /* load/store test */
    mem[4] = 0x55u;         /* store */
    mem[5] = mem[4];        /* load back and store result */

    /* bne equivalent */
    if (1u != 2u) mem[6] = 0x30u;
    else          mem[6] = 0x31u;

    /* done */
    mem[7] = 0xFFu;

    /* hang forever; use an unconditional jump instruction so no stack needed */
    for (;; ) { asm volatile("j ."); }
    return 0;
}
