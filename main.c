// main.c - Test program for RV32I CPU
// Fixed version: uses direct address casts instead of const pointers

#include <stdint.h>

/* Linker-provided symbols */
extern char _sdata;
extern char _edata;
extern char _sbss;
extern char _ebss;
extern char __StackTop;

/* Declared in startup.s */
extern volatile uint32_t __stack_pointer_initial;

/* Test data in .data section (initialized) */
volatile uint32_t init_array[4] = {
    0x11111111u,
    0x22222222u,
    0x33333333u,
    0x44444444u
};

/* Test data in .bss section (should be zeroed) */
volatile uint32_t bss_array[4];

/* Expected values for .data test */
static const uint32_t expect[4] = {
    0x11111111u,
    0x22222222u,
    0x33333333u,
    0x44444444u
};

int main(void)
{
    uint32_t result = 0;

    /* Test 1: Check .data section (init_array) */
    for (int i = 0; i < 4; i++) {
        if (init_array[i] != expect[i]) {
            result |= 0x01u;  /* Bit 0: .data mismatch */
            break;
        }
    }

    /* Test 2: Check .bss section (bss_array should be zero) */
    for (int i = 0; i < 4; i++) {
        if (bss_array[i] != 0u) {
            result |= 0x02u;  /* Bit 1: .bss not zero */
            break;
        }
    }

    /* Test 3: Check initial stack pointer */
    uint32_t expected_sp = (uint32_t)(&__StackTop);
    if (__stack_pointer_initial != expected_sp) {
        result |= 0x04u;  /* Bit 2: SP mismatch */
    }

    /* Test 4: Write pattern to bss_array and verify */
    bss_array[0] = 0xDEADBEEFu;
    bss_array[1] = 0xCAFEBABEu;
    if (bss_array[0] != 0xDEADBEEFu || bss_array[1] != 0xCAFEBABEu) {
        result |= 0x08u;  /* Bit 3: RAM write/read failed */
    }

    /* Write test result using inline assembly */
    /* Add NOPs to avoid pipeline hazards */
    __asm__ volatile (
        "lui  t5, 0x20004\n"        // t5 = 0x20004000
        "nop\n"                      // Wait for t5 to be written
        "nop\n"                      // Extra safety
        "sw   %0, -16(t5)\n"        // Store result at 0x20003FF0
        "li   t6, 1\n"              // t6 = 1
        "nop\n"                      // Wait for t6 to be written
        "sw   t6, -12(t5)\n"        // Store 1 at 0x20003FF4
        :                            // no outputs
        : "r"(result)                // input: result value
        : "t5", "t6", "memory"       // clobbers
    );

    /* Infinite loop - CPU stays here after test completes
     * The testbench detects test_done=1 and stops simulation
     * This prevents the CPU from running into undefined memory
     */
    while (1) {
        __asm__ volatile ("nop");
    }

    return 0;
}