// linker_loader.sv - FIXED
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
        $display("[linker_loader] Warning: imem hex read resulted in 0 words");
      end else begin
        $display("[linker_loader] Read %0d imem words from %0s", imem_len, IMEM_HEX);
        
        // Copy to IMEM starting at index 0 (imem.sv handles address translation)
        for (i = 0; i < imem_len; i = i + 1) begin
          testbench.cpu.fetch.imem_inst.mem[i] = imem_tmp[i];
        end
        
        $display("[linker_loader] imem word-copy completed to testbench.cpu.fetch.imem_inst.mem[0:%0d]", imem_len-1);
      end

      // Load DMEM hex
      dmem_len = 0;
      $readmemh(DMEM_HEX, dmem_tmp, 0, MAX_DMEM_BYTES-1);
      
      for (i = 0; i < MAX_DMEM_BYTES; i = i + 1) begin
        if (dmem_tmp[i] !== 8'hxx) dmem_len = i+1;
      end
      
      if (dmem_len == 0) begin
        $display("[linker_loader] Warning: dmem hex read resulted in 0 bytes");
      end else begin
        $display("[linker_loader] Read %0d dmem bytes from %0s", dmem_len, DMEM_HEX);
        
        // Copy to DMEM starting at index 0 (data_mem.sv handles address translation)
        for (i = 0; i < dmem_len; i = i + 1) begin
          testbench.cpu.data_memory.mem_array[i] = dmem_tmp[i];
        end
        
        $display("[linker_loader] dmem byte-copy completed into testbench.cpu.data_memory.mem_array[0:%0d]", dmem_len-1);
      end
    end
  end

endmodule