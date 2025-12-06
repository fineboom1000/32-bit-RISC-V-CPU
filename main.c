// main.c - Test program for RV32I CPU

#include <stdint.h>

/* Linker-provided symbols */
extern char _sdata;
extern char _edata;
extern char _sbss;
extern char _ebss;
extern char __StackTop;

/* Declared in startup.s, not here */
extern volatile uint32_t __stack_pointer_initial;

/* Magic addresses for test result output (memory-mapped) */
#define TEST_RESULT_ADDR  0x20003FF0u
#define TEST_DONE_ADDR    0x20003FF4u

volatile uint32_t *const test_result_ptr = (uint32_t*)TEST_RESULT_ADDR;
volatile uint32_t *const test_done_ptr   = (uint32_t*)TEST_DONE_ADDR;

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

    /* Write test result to magic address (testbench monitors this) */
    *test_result_ptr = result;
    *test_done_ptr = 0x1;  /* Signal test completion */

    /* Infinite loop - testbench should detect test_done and stop */
    while (1) {
        __asm__ volatile ("nop");
    }

    return 0;
}