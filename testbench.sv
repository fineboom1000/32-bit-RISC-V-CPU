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
  
  localparam TEST_RESULT_IDX = TEST_RESULT_ADDR - 32'h2000_0000;
  localparam TEST_DONE_IDX   = TEST_DONE_ADDR - 32'h2000_0000;
  
  logic [31:0] test_result;
  logic test_done;
  
  integer cycle_count = 0;
  
  // Cycle counter and detailed debug
  always @(posedge clk) begin
    if (!rst) begin
      cycle_count <= cycle_count + 1;
      
      // Print first 50 cycles in detail
      if (cycle_count < 50) begin
        $display("Cycle %0d: PC=0x%08h, Instr=0x%08h, ID_Instr=0x%08h", 
                 cycle_count, cpu.pc_current, cpu.if_instruction, cpu.id_instr);
      end
      
      // Check for test completion
      test_done = (cpu.data_memory.mem_array[TEST_DONE_IDX + 0] != 8'd0);
      
      if (test_done) begin
        test_result = {
          cpu.data_memory.mem_array[TEST_RESULT_IDX + 3],
          cpu.data_memory.mem_array[TEST_RESULT_IDX + 2],
          cpu.data_memory.mem_array[TEST_RESULT_IDX + 1],
          cpu.data_memory.mem_array[TEST_RESULT_IDX + 0]
        };
        
        $display("\n========================================");
        $display("TEST COMPLETED at cycle %0d (time %0t ns)", cycle_count, $time);
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
      
      // Check if PC is stuck
      if (cycle_count == 100 && cpu.pc_current == 32'h0000_1000) begin
        $display("\n========================================");
        $display("ERROR: PC stuck at reset address after 100 cycles");
        $display("PC = 0x%08h", cpu.pc_current);
        $display("Instruction = 0x%08h", cpu.if_instruction);
        $display("========================================\n");
        $finish;
      end
    end
  end
    // Cycle counter and detailed debug
  always @(posedge clk) begin
    if (!rst) begin
      cycle_count <= cycle_count + 1;
      
      // Print first 100 cycles in detail  // <-- Change from 50 to 100
      if (cycle_count < 100) begin
        $display("Cycle %0d: PC=0x%08h, Instr=0x%08h, ID_Instr=0x%08h, Branch=%b, Target=0x%08h", 
                 cycle_count, cpu.pc_current, cpu.if_instruction, cpu.id_instr,
                 cpu.mem_branch_taken, cpu.mem_branch_target);
      end
  
  // Timeout (10000 cycles = 100us)
  initial begin
    $dumpfile("cpu_test.vcd");
    $dumpvars(0, testbench);
    
    rst = 1;
    #50;
    rst = 0;
    $display("CPU reset released at time %0t", $time);
    
    // Wait for timeout
    #100000;
    $display("\n========================================");
    $display("ERROR: Test timeout after 100us (cycle %0d)", cycle_count);
    $display("Final PC: 0x%08h", cpu.pc_current);
    $display("Final Instruction: 0x%08h", cpu.if_instruction);
    $display("========================================\n");
    $finish;
  end
  
endmodule