// linker_loader.sv
// Parameterized SV loader that copies IMEM/DATA images into the
// hierarchical memories instantiated inside cpu_top.
//
// Assumptions (adapt if your instance/array names differ):
//  - Instruction memory instance in cpu_top is `imem_i` and exposes
//    a word-aligned memory: imem_i.mem_array[word_index] (32-bit words).
//    If your imem is byte-array, adapt below.
//  - Data memory instance in cpu_top is `data_mem_i` and exposes a
//    byte-addressable memory: data_mem_i.mem_array[byte_index] (8-bit).
//
// Set parameters ROM_ORIGIN and RAM_ORIGIN to the same values used
// in your linker script. If you built the ELF for a different base,
// change them accordingly.
//
// Usage: include this file in your simulation (add to iverilog sources).
`timescale 1ns/1ps

module linker_loader #(
  parameter string IMEM_HEX    = "imem.hex",
  parameter string DMEM_HEX    = "dmem.hex",
  parameter bit [31:0] ROM_ORIGIN = 32'h00001000, // set to your ROM base (VMA of .text)
  parameter bit [31:0] RAM_ORIGIN = 32'h20000000, // set to your RAM base (VMA of .data/.bss)
  parameter int    MAX_IMEM_WORDS = 65536, // max words to try to load
  parameter int    MAX_DMEM_BYTES = 65536  // max bytes to try to load
) ();

  initial begin
    $display("[linker_loader] ROM_ORIGIN = 0x%08h RAM_ORIGIN = 0x%08h", ROM_ORIGIN, RAM_ORIGIN);

    // --------------------------
    // Load IMEM hex (word-per-line little-endian hex expected)
    // --------------------------
    if ($test$plusargs("no_init_mem")) begin
      $display("[linker_loader] +no_init_mem set: skipping memory init");
    end else begin
      $display("[linker_loader] Attempting to load %0s into imem (word values)", IMEM_HEX);
      integer imem_len;
      reg [31:0] imem_tmp [0:MAX_IMEM_WORDS-1];
      // default len to 0
      imem_len = 0;
      // try to read mem file into temp array (word entries)
      $readmemh(IMEM_HEX, imem_tmp, 0, MAX_IMEM_WORDS-1);
      // find actual length (first all-zero runs at end not reliable; try probing)
      // We'll attempt to detect how many entries are non-x
      for (int i = 0; i < MAX_IMEM_WORDS; i++) begin
        if (imem_tmp[i] !== 32'hxxxxxxxx) imem_len = i+1;
        else begin
          // if X encountered, treat as end
          // continue scanning to allow zeros - but many tools output zeros
        end
      end

      if (imem_len == 0) begin
        $display("[linker_loader] Warning: imem hex read resulted in 0 words (file may be empty/missing).");
      end else begin
        $display("[linker_loader] Read %0d imem words from %0s", imem_len, IMEM_HEX);
        // Write into hierarchical imem instance:
        // attempt to write into cpu_top.imem_i.mem_array[word_index]
        // mapping: word_index = (ROM_ORIGIN_word_index) + i
        bit ok_imem_word_target = 1'b0;
        begin : try_imem_word_copy
          // compute ROM word base index
          int rom_word_base = ROM_ORIGIN >> 2;
          for (int i = 0; i < imem_len; i++) begin
            // direct hierarchical write; simulator must resolve name
            // this will fail at elaboration time if name mismatched
            // but that's acceptable: adapt instance/array names then
            cpu_top.imem_i.mem_array[rom_word_base + i] = imem_tmp[i];
            ok_imem_word_target = 1'b1;
          end
        end
        if (ok_imem_word_target)
          $display("[linker_loader] imem word-copy completed to cpu_top.imem_i.mem_array at word-base=0x%0h", ROM_ORIGIN>>2);
      end

      // --------------------------
      // Load DMEM hex (byte-addressable expected)
      // --------------------------
      reg [7:0] dmem_tmp [0:MAX_DMEM_BYTES-1];
      integer dmem_len;
      dmem_len = 0;
      // read mem as byte values (hex with 1 byte per line or little-endian words - tolerant)
      // best practice: produce dmem.hex with one byte per line (00..ff)
      $readmemh(DMEM_HEX, dmem_tmp, 0, MAX_DMEM_BYTES-1);
      for (int i = 0; i < MAX_DMEM_BYTES; i++) begin
        if (dmem_tmp[i] !== 8'hxx) dmem_len = i+1;
      end
      if (dmem_len == 0) begin
        $display("[linker_loader] Warning: dmem hex read resulted in 0 bytes (file may be empty/missing).");
      end else begin
        $display("[linker_loader] Read %0d dmem bytes from %0s", dmem_len, DMEM_HEX);
        // copy bytes into cpu_top.data_mem_i.mem_array at offset = (addr - RAM_ORIGIN)
        // data_mem.mem_array is expected to be byte-array indexed by offset from RAM origin
        int ram_base = RAM_ORIGIN; // base address in bytes
        bit ok_dmem_target = 1'b0;
        begin : try_dmem_copy
          for (int i = 0; i < dmem_len; i++) begin
            // address in system = RAM_ORIGIN + i
            int addr = (RAM_ORIGIN + i);
            int idx = addr; // if data_mem mem_array is indexed by full address this works
            // Common layout in provided data_mem.sv: mem_array[0..MEM_BYTES-1] where index is physical address
            // so write to that index (simulator must have that array)
            cpu_top.data_mem_i.mem_array[addr] = dmem_tmp[i];
            ok_dmem_target = 1'b1;
          end
        end
        if (ok_dmem_target)
          $display("[linker_loader] dmem byte-copy completed into cpu_top.data_mem_i.mem_array at RAM_ORIGIN=0x%0h", RAM_ORIGIN);
      end

    end // no_init_mem
  end // initial

endmodule
