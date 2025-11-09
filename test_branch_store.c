// test_branch_store.c
#include <stdint.h>

volatile uint32_t * const mem = (uint32_t *)0x20000000;

void call_sub(void) {
    mem[3] = 0x20;   // inside call
    return;
}

int main(void) {
    mem[0] = 1;      // start marker

    // beq-equivalent test
    uint32_t a = 5, b = 5;
    if (a == b) mem[1] = 0x10;
    else        mem[1] = 0x11;

    // call test (C call uses jal/jalr under the hood)
    call_sub();
    mem[2] = 0x21;   // after return

    // load/store test
    mem[4] = 0x55;
    uint32_t x = mem[4];
    mem[5] = x;

    // bne-equivalent test
    if (1 != 2) mem[6] = 0x30;
    else        mem[6] = 0x31;

    mem[7] = 0xFF;   // done

    // hang
    while (1) { asm volatile("wfi"); }
    return 0;
}
