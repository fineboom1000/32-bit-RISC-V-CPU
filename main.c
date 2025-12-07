// main.c - SIMPLIFIED TEST
#include <stdint.h>

extern char _sbss;
extern char _ebss;
extern char __StackTop;

volatile uint32_t init_array[4] = {
    0x11111111u,
    0x22222222u,
    0x33333333u,
    0x44444444u
};

volatile uint32_t bss_array[4];

static const uint32_t expect[4] = {
    0x11111111u,
    0x22222222u,
    0x33333333u,
    0x44444444u
};

int main(void)
{
    uint32_t result = 0;

    // Test 1: Check .data section (should be pre-loaded by simulator)
    for (int i = 0; i < 4; i++) {
        if (init_array[i] != expect[i]) {
            result |= 0x01u;
            break;
        }
    }

    // Test 2: Check .bss section (should be zeroed by startup)
    for (int i = 0; i < 4; i++) {
        if (bss_array[i] != 0u) {
            result |= 0x02u;
            break;
        }
    }

    // Test 3: RAM read/write
    bss_array[0] = 0xDEADBEEFu;
    bss_array[1] = 0xCAFEBABEu;
    if (bss_array[0] != 0xDEADBEEFu || bss_array[1] != 0xCAFEBABEu) {
        result |= 0x04u;
    }

    // Write test result
    __asm__ volatile (
        "lui  t5, 0x20004\n"
        "sw   %0, -16(t5)\n"
        "li   t6, 1\n"
        "sw   t6, -12(t5)\n"
        :
        : "r"(result)
        : "t5", "t6", "memory"
    );

    while (1) {
        __asm__ volatile ("nop");
    }

    return 0;
}