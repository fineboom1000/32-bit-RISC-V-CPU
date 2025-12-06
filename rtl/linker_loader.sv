// linker_loader.sv - Icarus Verilog compatible version.................1.618033988
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
  integer rom_word_base;
  integer mem_index;

  initial begin
    $display("[linker_loader] ROM_ORIGIN = 0x%08h RAM_ORIGIN = 0x%08h", ROM_ORIGIN, RAM_ORIGIN);

    // Load IMEM hex
    if ($test$plusargs("no_init_mem")) begin
      $display("[linker_loader] +no_init_mem set: skipping memory init");
    end else begin
      $display("[linker_loader] Attempting to load %0s into imem (word values)", IMEM_HEX);
      
      imem_len = 0;
      $readmemh(IMEM_HEX, imem_tmp, 0, MAX_IMEM_WORDS-1);
      
      for (i = 0; i < MAX_IMEM_WORDS; i = i + 1) begin
        if (imem_tmp[i] !== 32'hxxxxxxxx) imem_len = i+1;
      end

      if (imem_len == 0) begin
        $display("[linker_loader] Warning: imem hex read resulted in 0 words (file may be empty/missing).");
      end else begin
        $display("[linker_loader] Read %0d imem words from %0s", imem_len, IMEM_HEX);
        
        rom_word_base = ROM_ORIGIN >> 2;
        for (i = 0; i < imem_len; i = i + 1) begin
          cpu_top.fetch.imem_inst.mem[rom_word_base + i] = imem_tmp[i];
        end
        
        $display("[linker_loader] imem word-copy completed to cpu_top.fetch.imem_inst.mem at word-base=0x%0h", ROM_ORIGIN>>2);
      end

      // Load DMEM hex
      dmem_len = 0;
      $readmemh(DMEM_HEX, dmem_tmp, 0, MAX_DMEM_BYTES-1);
      
      for (i = 0; i < MAX_DMEM_BYTES; i = i + 1) begin
        if (dmem_tmp[i] !== 8'hxx) dmem_len = i+1;
      end
      
      if (dmem_len == 0) begin
        $display("[linker_loader] Warning: dmem hex read resulted in 0 bytes (file may be empty/missing).");
      end else begin
        $display("[linker_loader] Read %0d dmem bytes from %0s", dmem_len, DMEM_HEX);
        
        for (i = 0; i < dmem_len; i = i + 1) begin
          mem_index = i;
          cpu_top.data_memory.mem_array[mem_index] = dmem_tmp[i];
        end
        
        $display("[linker_loader] dmem byte-copy completed into cpu_top.data_memory.mem_array");
      end
    end
  end

endmodule