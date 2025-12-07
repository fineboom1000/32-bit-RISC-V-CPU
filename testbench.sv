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
  logic [31:0] last_pc;
  integer stuck_count = 0;
  
  // Decode instruction type for debug
  function string decode_instr(logic [31:0] instr);
    logic [6:0] opcode;
    opcode = instr[6:0];
    case (opcode)
      7'b0110111: return "LUI";
      7'b0010111: return "AUIPC";
      7'b1101111: return "JAL";
      7'b1100111: return "JALR";
      7'b1100011: return "BRANCH";
      7'b0000011: return "LOAD";
      7'b0100011: return "STORE";
      7'b0010011: return "I-ALU";
      7'b0110011: return "R-ALU";
      default: return "UNKNOWN";
    endcase
  endfunction
  
  // Cycle counter and detailed debug
  always @(posedge clk) begin
    if (!rst) begin
      cycle_count <= cycle_count + 1;
      
      // Detect if PC is stuck in a small loop
      if (cpu.pc_current == last_pc) begin
        stuck_count <= stuck_count + 1;
      end else begin
        stuck_count <= 0;
      end
      last_pc <= cpu.pc_current;
      
      // Print register writes
      if (cpu.rf_wen && cpu.rf_waddr != 5'd0) begin
        $display("Cycle %0d: WB WRITE x%0d <= 0x%08h (PC was 0x%08h)", 
                 cycle_count, cpu.rf_waddr, cpu.rf_wdata, cpu.memwb_pc_plus4 - 32'd4);
      end
      
      // Print memory writes
      if (cpu.dmem_write && !rst) begin
        $display("Cycle %0d: MEM WRITE addr=0x%08h data=0x%08h width=%0d", 
                 cycle_count, cpu.dmem_addr, cpu.dmem_wdata, cpu.dmem_width);
      end
      
      // Print detailed info for first 150 cycles or when interesting things happen
      if (cycle_count < 150 || cpu.mem_branch_taken || stuck_count == 10) begin
        $display("Cycle %0d: PC=0x%08h [%s], Instr=0x%08h, Branch=%b, Target=0x%08h, x1=0x%08h, x2=0x%08h, x10=0x%08h", 
                 cycle_count, cpu.pc_current, decode_instr(cpu.if_instruction),
                 cpu.if_instruction, cpu.mem_branch_taken, cpu.mem_branch_target,
                 cpu.regfile_inst.regs[1], cpu.regfile_inst.regs[2], cpu.regfile_inst.regs[10]);
      end
      
      // Warn if stuck in tight loop
      if (stuck_count == 10) begin
        $display("WARNING: PC stuck at 0x%08h for 10 cycles!", cpu.pc_current);
        $display("  Instruction: 0x%08h [%s]", cpu.if_instruction, decode_instr(cpu.if_instruction));
        $display("  Branch taken: %b, Target: 0x%08h", cpu.mem_branch_taken, cpu.mem_branch_target);
      end
      
      // Check for test completion (check more frequently)
      test_done = (cpu.data_memory.mem_array[TEST_DONE_IDX + 0] != 8'd0) ||
                  (cpu.data_memory.mem_array[TEST_DONE_IDX + 1] != 8'd0) ||
                  (cpu.data_memory.mem_array[TEST_DONE_IDX + 2] != 8'd0) ||
                  (cpu.data_memory.mem_array[TEST_DONE_IDX + 3] != 8'd0);
      
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
      
      // Check if stuck in infinite loop at 0x1068 (the post-main loop)
      if (cycle_count > 100 && cpu.pc_current == 32'h00001068) begin
        $display("\n========================================");
        $display("ERROR: CPU stuck in post-main infinite loop at 0x00001068");
        $display("This means main() was never properly executed or exited prematurely");
        $display("========================================");
        $display("Register dump:");
        for (int i = 0; i < 32; i = i + 1) begin
          if (i % 4 == 0) $write("  ");
          $write("x%0d=0x%08h ", i, cpu.regfile_inst.regs[i]);
          if (i % 4 == 3) $write("\n");
        end
        $display("\nTest result memory:");
        $display("  TEST_DONE   @ 0x%08h: 0x%02h", TEST_DONE_ADDR, 
                 cpu.data_memory.mem_array[TEST_DONE_IDX]);
        $display("  TEST_RESULT @ 0x%08h: 0x%08h", TEST_RESULT_ADDR, test_result);
        $display("========================================\n");
        #100 $finish;
      end
    end
  end
  
  // Timeout (reduced to 2000 cycles for faster debug)
  initial begin
    $dumpfile("cpu_test.vcd");
    $dumpvars(0, testbench);
    
    rst = 1;
    #50;
    rst = 0;
    $display("CPU reset released at time %0t", $time);
    
    // Wait for timeout
    #20000;  // 2000 cycles
    $display("\n========================================");
    $display("ERROR: Test timeout after 2000 cycles (cycle %0d)", cycle_count);
    $display("Final PC: 0x%08h", cpu.pc_current);
    $display("Final Instruction: 0x%08h", cpu.if_instruction);
    $display("========================================\n");
    $finish;
  end
  
endmodule