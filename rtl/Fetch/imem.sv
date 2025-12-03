// Please see the RTL page on ISA notes
// I discuss a lot of this in depth...actaully all of it.
//imem.sv

`timescale 1ns/1ps

module imem #(
  parameter string MEMFILE = "imem.hex",
  parameter logic [31:0] ROM_BASE = 32'h0000_1000,
  parameter int WORDS = 4096,
  parameter bit SYNC = 1
) (
  input  logic        clk,
  input  logic        read_en,
  input  logic [31:0] addr,           // byte address from PC
  output logic [31:0] instruction
);

  // storage array
  logic [31:0] mem [0:WORDS-1];

  // preload memory from hex file
  initial begin
    if (MEMFILE != "") begin
      $display("IMEM: loading '%s' (WORDS=%0d, BASE=0x%08h)", MEMFILE, WORDS, ROM_BASE);
      $readmemh(MEMFILE, mem);
    end else begin
      $display("IMEM: no file specified, memory uninitialized");
    end
  end

  // compute word index from byte address
  logic [31:0] addr_offset;
  logic [$clog2(WORDS)-1:0] word_index;
  
  assign addr_offset = addr - ROM_BASE;
  assign word_index  = addr_offset[31:2];  // divide by 4 (word-aligned)

  generate
    if (SYNC) begin : sync_read
      // synchronous read: 1-cycle latency
      logic [$clog2(WORDS)-1:0] sampled_idx;
      
      always_ff @(posedge clk) begin
        if (read_en) begin
          sampled_idx <= word_index;
        end
        instruction <= mem[sampled_idx];
      end
    end else begin : async_read
      // combinational read: immediate (use only for small ROMs/simulation)
      assign instruction = mem[word_index];
    end
  endgenerate

endmodule