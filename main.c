// ==============================================================
// startup.s - Assembly startup code for RV32I
// ==============================================================
/*
.section .text.startup
.global _start
.type _start, @function

_start:
    # Save initial SP value (should be at __StackTop from linker)
    la   t0, __stack_pointer_initial
    sw   sp, 0(t0)

    # Set stack pointer to __StackTop (redundant if already set, but safe)
    la   sp, __StackTop

    # Copy .data from ROM (LMA) to RAM (VMA)
    # _sidata = LMA start (in ROM)
    # _sdata = VMA start (in RAM)
    # _edata = VMA end (in RAM)
    la   t0, _sidata    # source (ROM)
    la   t1, _sdata     # dest start (RAM)
    la   t2, _edata     # dest end (RAM)
    beq  t1, t2, 2f     # skip if no .data
1:
    lw   t3, 0(t0)      # load word from ROM
    sw   t3, 0(t1)      # store word to RAM
    addi t0, t0, 4      # advance source
    addi t1, t1, 4      # advance dest
    blt  t1, t2, 1b     # loop until done
2:

    # Zero .bss section
    # _sbss = start of .bss
    # _ebss = end of .bss
    la   t0, _sbss      # start
    la   t1, _ebss      # end
    beq  t0, t1, 4f     # skip if no .bss
3:
    sw   zero, 0(t0)    # write zero
    addi t0, t0, 4      # advance
    blt  t0, t1, 3b     # loop until done
4:

    # Call main()
    call main

    # If main returns, loop forever
5:
    j    5b

.size _start, .-_start
*/

// ==============================================================
// main.c - Fixed version for RV32I CPU
// ==============================================================

#include <stdint.h>

/* Linker-provided symbols */
extern char _sdata;
extern char _edata;
extern char _sbss;
extern char _ebss;
extern char __StackTop;

/* Saved by startup.s */
volatile uint32_t __stack_pointer_initial;

/* Magic address for test result output (memory-mapped) */
/* Your testbench should watch writes to this address */
#define TEST_RESULT_ADDR  0x20003FF0u
#define TEST_DONE_ADDR    0x20003FF4u

volatile uint32_t *const test_result_ptr = (uint32_t*)TEST_RESULT_ADDR;
volatile uint32_t *const test_done_ptr   = (uint32_t*)TEST_DONE_ADDR;

/* Test data */
volatile uint32_t init_array[4] = {
    0x11111111u,
    0x22222222u,
    0x33333333u,
    0x44444444u
};

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
        /* Simple NOP loop - NO WFI! */
        __asm__ volatile ("nop");
    }

    return 0;
}

// ==============================================================
// testbench.sv - Testbench to run the test program
// ==============================================================
/*
`timescale 1ns/1ps

module testbench;
  logic clk = 0;
  logic rst = 1;
  
  // Clock generation (10ns period = 100MHz)
  always #5 clk = ~clk;
  
  // CPU instance
  cpu_top #(
    .ROM_BASE(32'h0000_1000),
    .RAM_BASE(32'h2000_0000),
    .IMEM_FILE("imem.hex"),
    .IMEM_WORDS(4096),
    .DMEM_ADDR_WIDTH(14)
  ) cpu (
    .clk(clk),
    .rst(rst)
  );
  
  // Loader instance
  linker_loader #(
    .IMEM_HEX("imem.hex"),
    .DMEM_HEX("dmem.hex"),
    .ROM_ORIGIN(32'h0000_1000),
    .RAM_ORIGIN(32'h2000_0000)
  ) loader ();
  
  // Test result monitoring
  localparam TEST_RESULT_ADDR = 32'h2000_3FF0;
  localparam TEST_DONE_ADDR   = 32'h2000_3FF4;
  
  // Convert to data memory indices
  localparam TEST_RESULT_IDX = TEST_RESULT_ADDR - 32'h2000_0000;
  localparam TEST_DONE_IDX   = TEST_DONE_ADDR - 32'h2000_0000;
  
  logic [31:0] test_result;
  logic test_done;
  
  // Monitor test completion
  always @(posedge clk) begin
    if (!rst) begin
      // Read test_done flag from data memory
      test_done = (cpu.data_memory.mem_array[TEST_DONE_IDX + 0] != 8'd0);
      
      if (test_done) begin
        // Read test result (little-endian)
        test_result = {
          cpu.data_memory.mem_array[TEST_RESULT_IDX + 3],
          cpu.data_memory.mem_array[TEST_RESULT_IDX + 2],
          cpu.data_memory.mem_array[TEST_RESULT_IDX + 1],
          cpu.data_memory.mem_array[TEST_RESULT_IDX + 0]
        };
        
        $display("\n========================================");
        $display("TEST COMPLETED at time %0t", $time);
        $display("========================================");
        $display("Test Result: 0x%08h", test_result);
        
        if (test_result == 32'd0) begin
          $display("✓ ALL TESTS PASSED!");
          $display("  - .data section copied correctly");
          $display("  - .bss section zeroed correctly");
          $display("  - Stack pointer initialized correctly");
          $display("  - RAM read/write working");
        end else begin
          $display("✗ TESTS FAILED:");
          if (test_result[0]) $display("  - .data section incorrect");
          if (test_result[1]) $display("  - .bss section not zeroed");
          if (test_result[2]) $display("  - Stack pointer mismatch");
          if (test_result[3]) $display("  - RAM read/write failed");
        end
        $display("========================================\n");
        
        #100 $finish;
      end
    end
  end
  
  // Timeout
  initial begin
    #100000;  // 100us timeout
    $display("\n========================================");
    $display("ERROR: Test timeout after 100us");
    $display("========================================\n");
    $finish;
  end
  
  // Reset sequence
  initial begin
    $dumpfile("cpu_test.vcd");
    $dumpvars(0, testbench);
    
    rst = 1;
    #50;
    rst = 0;
    $display("CPU reset released at time %0t", $time);
  end
  
  // Debug output (optional)
  `ifdef DEBUG
  always @(posedge clk) begin
    if (!rst && cpu.rf_wen) begin
      $display("%0t: WB x%0d <= 0x%08h", $time, cpu.rf_waddr, cpu.rf_wdata);
    end
  end
  `endif
  
endmodule
*/

// ==============================================================
// Makefile snippet for building
// ==============================================================
/*
# Toolchain
PREFIX = riscv32-unknown-elf-
CC = $(PREFIX)gcc
AS = $(PREFIX)as
LD = $(PREFIX)ld
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump

# Flags
CFLAGS = -march=rv32i -mabi=ilp32 -O2 -Wall -ffreestanding -nostdlib
LDFLAGS = -T linker_script.ld

# Build
all: program.elf imem.hex dmem.hex

program.elf: startup.s main.c linker_script.ld
	$(CC) $(CFLAGS) -c startup.s -o startup.o
	$(CC) $(CFLAGS) -c main.c -o main.o
	$(LD) $(LDFLAGS) startup.o main.o -o program.elf
	$(OBJDUMP) -D program.elf > program.dis

imem.hex: program.elf
	$(OBJCOPY) -O verilog --only-section=.text program.elf imem.hex

dmem.hex: program.elf
	$(OBJCOPY) -O verilog --only-section=.data program.elf dmem.hex
	# Note: .bss is not in the hex file (it's zeroed by startup code)

clean:
	rm -f *.o *.elf *.hex *.dis
*/