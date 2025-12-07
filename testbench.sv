`timescale 1ns/1ps

module testbench;
  logic clk = 0;
  logic rst = 1;
  
  always #5 clk = ~clk;
  
  cpu_top #(
    .ROM_BASE(32'h0000_1000),
    .RAM_BASE(32'h2000_0000),
    .IMEM_WORDS(4096),
    .DMEM_ADDR_WIDTH(14)
  ) cpu (
    .clk(clk),
    .rst(rst)
  );
  
  linker_loader #(
    .IMEM_HEX("imem.hex"),
    .DMEM_HEX("dmem.hex"),
    .ROM_ORIGIN(32'h0000_1000),
    .RAM_ORIGIN(32'h2000_0000)
  ) loader ();
  
  localparam TEST_RESULT_ADDR = 32'h2000_3FF0;
  localparam TEST_DONE_ADDR   = 32'h2000_3FF4;
  localparam TEST_RESULT_IDX = TEST_RESULT_ADDR - 32'h2000_0000;
  localparam TEST_DONE_IDX   = TEST_DONE_ADDR - 32'h2000_0000;
  
  logic [31:0] test_result;
  logic test_done;
  integer cycle_count = 0;
  
  function string decode_instr(logic [31:0] instr);
    logic [6:0] opcode = instr[6:0];
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
  
  function string decode_reg(logic [4:0] reg_num);
    case (reg_num)
      5'd0:  return "x0/zero";
      5'd1:  return "x1/ra";
      5'd2:  return "x2/sp";
      5'd5:  return "x5/t0";
      5'd6:  return "x6/t1";
      5'd7:  return "x7/t2";
      5'd10: return "x10/a0";
      5'd28: return "x28/t3";
      default: return $sformatf("x%0d", reg_num);
    endcase
  endfunction
  
  // Detailed tracking for critical startup instructions
  always @(posedge clk) begin
    if (!rst) begin
      cycle_count <= cycle_count + 1;
      
      // Track all register writes with source info
      if (cpu.rf_wen && cpu.rf_waddr != 5'd0) begin
        $display("Cycle %0d: WB WRITE %s <= 0x%08h (from PC 0x%08h)", 
                 cycle_count, decode_reg(cpu.rf_waddr), cpu.rf_wdata, 
                 cpu.memwb_pc_plus4 - 32'd4);
      end
      
      // DETAILED TRACKING for PC range 0x1000-0x1020 (startup code)
      if (cpu.pc_current >= 32'h1000 && cpu.pc_current <= 32'h1020) begin
        $display("\n=== STARTUP DETAIL: Cycle %0d, PC=0x%08h [%s] ===", 
                 cycle_count, cpu.pc_current, decode_instr(cpu.if_instruction));
        $display("  Instruction: 0x%08h", cpu.if_instruction);
        
        // Show current register state for t0, t1, t2, sp
        $display("  Current Regs: t0(x5)=0x%08h t1(x6)=0x%08h t2(x7)=0x%08h sp(x2)=0x%08h",
                 cpu.regfile_inst.regs[5], cpu.regfile_inst.regs[6],
                 cpu.regfile_inst.regs[7], cpu.regfile_inst.regs[2]);
        
        // Show ID/EX stage values (what's being decoded)
        $display("  ID stage: rs1=%s(0x%08h) rs2=%s(0x%08h) rd=%s imm=0x%08h",
                 decode_reg(cpu.rf_raddr1), cpu.rf_rdata1,
                 decode_reg(cpu.rf_raddr2), cpu.rf_rdata2,
                 decode_reg(cpu.idex_rd), cpu.idex_imm);
        
        // Show EX stage computation
        if (cpu.ex_out_valid) begin
          $display("  EX stage: ALU result=0x%08h rs2_data=0x%08h (for store)",
                   cpu.ex_out_alu_result, cpu.ex_out_rs2_for_store);
        end
      end
      
      // CRITICAL: Track the problematic store at PC 0x1008
      if (cpu.pc_current == 32'h1008) begin
        $display("\n!!! CRITICAL INSTRUCTION AT 0x1008: sw sp,0(t0) !!!");
        $display("  Expected: Store SP value to address in t0");
        $display("  t0(x5) = 0x%08h (should be ~0x20000010)", cpu.regfile_inst.regs[5]);
        $display("  sp(x2) = 0x%08h", cpu.regfile_inst.regs[2]);
        $display("  ID/EX.rs1_val (base addr) = 0x%08h", cpu.idex_rs1_val);
        $display("  ID/EX.rs2_val (store data) = 0x%08h", cpu.idex_rs2_val);
        $display("  ID/EX.imm (offset) = 0x%08h", cpu.idex_imm);
      end
      
      // Track memory operations with register context
      if (cpu.dmem_write && !rst) begin
        logic [31:0] offset = cpu.dmem_addr - 32'h20000000;
        $display("Cycle %0d: *** MEMORY WRITE ***", cycle_count);
        $display("  Address: 0x%08h (RAM offset=0x%x)", cpu.dmem_addr, offset);
        $display("  Data: 0x%08h", cpu.dmem_wdata);
        $display("  Width: %0d", cpu.dmem_width);
        $display("  From PC: 0x%08h", cpu.exmem_pc_plus4 - 32'd4);
        $display("  Current t0(x5)=0x%08h sp(x2)=0x%08h", 
                 cpu.regfile_inst.regs[5], cpu.regfile_inst.regs[2]);
      end
      
      if (cpu.dmem_read && !rst) begin
        logic [31:0] offset = cpu.dmem_addr - 32'h20000000;
        $display("Cycle %0d: *** MEMORY READ ***", cycle_count);
        $display("  Address: 0x%08h (RAM offset=0x%x)", cpu.dmem_addr, offset);
        $display("  Data: 0x%08h", cpu.dmem_rdata);
        $display("  From PC: 0x%08h", cpu.exmem_pc_plus4 - 32'd4);
      end
      
      // Show forwarding activity
      if (cpu.fwd_mem_valid) begin
        $display("  [FWD] MEM->EX: %s <= 0x%08h", 
                 decode_reg(cpu.fwd_mem_rd), cpu.fwd_mem_data);
      end
      if (cpu.fwd_wb_valid) begin
        $display("  [FWD] WB->EX: %s <= 0x%08h", 
                 decode_reg(cpu.fwd_wb_rd), cpu.fwd_wb_data);
      end
      
      // Check for test completion
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
        $display("TEST COMPLETED at cycle %0d", cycle_count);
        $display("========================================");
        $display("Test Result: 0x%08h", test_result);
        
        if (test_result == 32'd0) begin
          $display("✓ ALL TESTS PASSED!");
        end else begin
          $display("✗ TESTS FAILED:");
          if (test_result[0]) $display("  - Bit 0: .data section incorrect");
          if (test_result[1]) $display("  - Bit 1: .bss section not zeroed");
          if (test_result[2]) $display("  - Bit 2: Stack pointer mismatch");
          if (test_result[3]) $display("  - Bit 3: RAM read/write failed");
          
          $display("\nFinal .data section:");
          for (int i = 0; i < 4; i++) begin
            $display("  [%0d] @ 0x%08h: 0x%02h%02h%02h%02h", 
                     i, 32'h20000000 + i*4,
                     cpu.data_memory.mem_array[i*4 + 3],
                     cpu.data_memory.mem_array[i*4 + 2],
                     cpu.data_memory.mem_array[i*4 + 1],
                     cpu.data_memory.mem_array[i*4 + 0]);
          end
        end
        
        $display("========================================\n");
        #100 $finish;
      end
      
      // Stop after reasonable cycles
      if (cycle_count > 150) begin
        $display("\n!!! Stopping early at cycle 150 for analysis !!!");
        $display("Check the detailed output above\n");
        #100 $finish;
      end
    end
  end
  
  initial begin
    $dumpfile("cpu_test.vcd");
    $dumpvars(0, testbench);
    
    rst = 1;
    #50;
    rst = 0;
    $display("========================================");
    $display("DETAILED DEBUG TRACE - STARTUP CODE");
    $display("========================================");
    $display("Watching PC range 0x1000-0x1020 closely\n");
    
    #5000;
    $display("\nTimeout - check output above");
    $finish;
  end
  
endmodule