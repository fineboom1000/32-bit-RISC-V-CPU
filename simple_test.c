// simple_test.c - Minimal test with addresses in actual RAM range
#include <stdint.h>

// Use addresses at the END of initialized .bss section
// These will be in the 16KB RAM but not conflicting with .data/.bss
#define TEST_RESULT_ADDR  0x20003FF0u
#define TEST_DONE_ADDR    0x20003FF4u

volatile uint32_t *const test_result_ptr = (uint32_t*)TEST_RESULT_ADDR;
volatile uint32_t *const test_done_ptr   = (uint32_t*)TEST_DONE_ADDR;

int main(void)
{
    // Simple arithmetic test
    uint32_t a = 0xDEADBEEF;
    uint32_t b = 0xCAFEBABE;
    uint32_t result = a + b;
    
    // Write result and completion flag
    *test_result_ptr = result;
    *test_done_ptr = 0x1;

    // Infinite loop
    while (1) {
        __asm__ volatile ("nop");
    }

    return 0;
}