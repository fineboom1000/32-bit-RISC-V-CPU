// linker_loader.sv - FIXED: Pre-initialize .data in RAM
`timescale 1ns/1ps

module linker_loader #(
  parameter string IMEM_HEX    = "imem.hex",
  parameter string DMEM_HEX    = "dmem.hex",
  parameter ROM_ORIGIN = 32'h00001000,
  parameter RAM_ORIGIN = 32'h20000000,
  parameter MAX_IMEM_WORDS = 65536,
  parameter MAX_DMEM_BYTES = 65536
) ();

  integer imem_len, dmem_len;
  integer i;
  reg [31:0] imem_tmp [0:MAX_IMEM_WORDS-1];
  reg [7:0] dmem_tmp [0:MAX_DMEM_BYTES-1];

  initial begin
    $display("[linker_loader] ROM_ORIGIN = 0x%08h RAM_ORIGIN = 0x%08h", ROM_ORIGIN, RAM_ORIGIN);

    // Load IMEM
    imem_len = 0;
    $readmemh(IMEM_HEX, imem_tmp, 0, MAX_IMEM_WORDS-1);
    
    for (i = 0; i < MAX_IMEM_WORDS; i = i + 1) begin
      if (imem_tmp[i] !== 32'hxxxxxxxx) imem_len = i+1;
    end

    if (imem_len > 0) begin
      $display("[linker_loader] Read %0d imem words from %0s", imem_len, IMEM_HEX);
      for (i = 0; i < imem_len; i = i + 1) begin
        testbench.cpu.fetch.imem_inst.mem[i] = imem_tmp[i];
      end
      $display("[linker_loader] imem loaded");
    end

    // Load DMEM - this is the .data section initialization
    dmem_len = 0;
    $readmemh(DMEM_HEX, dmem_tmp, 0, MAX_DMEM_BYTES-1);
    
    for (i = 0; i < MAX_DMEM_BYTES; i = i + 1) begin
      if (dmem_tmp[i] !== 8'hxx) dmem_len = i+1;
    end
    
    if (dmem_len > 0) begin
      $display("[linker_loader] Read %0d dmem bytes from %0s", dmem_len, DMEM_HEX);
      
      // Copy to RAM at address 0x20000000
      for (i = 0; i < dmem_len; i = i + 1) begin
        testbench.cpu.data_memory.mem_array[i] = dmem_tmp[i];
      end
      
      // CRITICAL FIX: Also copy to ROM so startup code can read it!
      // The startup code reads from ROM and writes to RAM
      // We need the data in BOTH places
      for (i = 0; i < dmem_len; i = i + 1) begin
        integer word_idx, byte_offset;
        word_idx = (32'h00001160 - ROM_ORIGIN + i) / 4;  // 0x1160 is _etext from linker
        byte_offset = i % 4;
        
        if (word_idx < MAX_IMEM_WORDS) begin
          case (byte_offset)
            0: testbench.cpu.fetch.imem_inst.mem[word_idx][7:0]   = dmem_tmp[i];
            1: testbench.cpu.fetch.imem_inst.mem[word_idx][15:8]  = dmem_tmp[i];
            2: testbench.cpu.fetch.imem_inst.mem[word_idx][23:16] = dmem_tmp[i];
            3: testbench.cpu.fetch.imem_inst.mem[word_idx][31:24] = dmem_tmp[i];
          endcase
        end
      end
      
      $display("[linker_loader] dmem loaded to both RAM and ROM");
    end
  end

endmodule