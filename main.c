/* main.c -- simple tests for .data, .bss and initial SP */
// this code is not my own. Author did not provide a name.

#include <stdint.h>

/* Linker-provided symbols (from your linker script) */
extern char _sdata;            /* start of .data VMA */
extern char _edata;            /* end of .data VMA */
extern char _sbss;             /* start of .bss */
extern char _ebss;             /* end of .bss */
extern char __StackTop;        /* stack top (linker provided) */

/* Saved by assembly startup: the SP value at entry (we wrote it in startup.s) */
volatile uint32_t __stack_pointer_initial; /* written by startup.s */

/* A global initialized array -> should be in .data (LMA in ROM, VMA in RAM) */
volatile uint32_t init_array[4] = {
    0x11111111u,
    0x22222222u,
    0x33333333u,
    0x44444444u
};

/* An uninitialized array -> should be in .bss and zeroed by startup */
volatile uint32_t bss_array[4];

/* A global that will hold the test result:
   0 == all checks passed.
   bit 0 (1): .data mismatch
   bit 1 (2): .bss not zero
   bit 2 (4): initial SP != __StackTop
*/
volatile uint32_t test_result = 0xFFFFFFFFu; /* initialize to invalid until we set it */

int main(void)
{
    uint32_t result = 0;

    /* --- Check .data: init_array must equal the expected constants --- */
    const uint32_t expect[4] = {
        0x11111111u,
        0x22222222u,
        0x33333333u,
        0x44444444u
    };

    for (int i = 0; i < 4; ++i) {
        if (init_array[i] != expect[i]) {
            result |= 1u; /* .data mismatch */
            break;
        }
    }

    /* --- Check .bss: bss_array must be all zeros --- */
    for (int i = 0; i < 4; ++i) {
        if (bss_array[i] != 0u) {
            result |= 2u; /* .bss not zero */
            break;
        }
    }

    /* --- Check initial stack pointer: compare saved value with __StackTop --- */
    /* &__StackTop gives the address (value) defined by the linker PROVIDE. */
    uint32_t expected_sp = (uint32_t)(&__StackTop);
    uint32_t initial_sp = __stack_pointer_initial;

    if (initial_sp != expected_sp) {
        result |= 4u; /* stack pointer mismatch */
    }

    /* Write the test outcome */
    test_result = result;

    /* Leave the system in an infinite loop (so the test_result remains readable) */
    for (;;) {
        asm volatile ("wfi"); /* or a simple tight loop; wfi waits for interrupt (optional) */
    }

    /* Never reached */
    return 0;
}


/*


Some notes:
init_array is initialized, so it should end up in .data. If the startup copy is correct, its values at runtime will match the initial constants (which are placed in ROM by the linker).

bss_array is uninitialized so should be placed in .bss. Startup must zero it.

__stack_pointer_initial is a volatile uint32_t written by assembly; main uses it to check that the initial SP matched __StackTop.

test_result encodes failures. 0 = all good. Nonzero => bits indicate which test(s) failed.
*/