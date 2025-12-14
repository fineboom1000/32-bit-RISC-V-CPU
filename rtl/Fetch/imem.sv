// imem.sv
`timescale 1ns/1ps

module imem #(
  parameter logic [31:0] ROM_BASE = 32'h0000_1000,
  parameter int WORDS = 4096,
  parameter bit SYNC = 1
) (
  input  logic        clk,
  input  logic        read_en,
  input  logic [31:0] addr,
  output logic [31:0] instruction
);

  // storage array
  (* ram_style = "block" *) logic [31:0] mem [0:WORDS-1];



  // compute word index from byte address
  logic [31:0] addr_offset;
  logic [$clog2(WORDS)-1:0] word_index;
  
  assign addr_offset = addr - ROM_BASE;
  assign word_index  = addr_offset[31:2];

  generate
    if (SYNC) begin : sync_read
      logic [$clog2(WORDS)-1:0] sampled_idx;
      
      always_ff @(posedge clk) begin
        if (read_en) begin
          sampled_idx <= word_index;
        end
        instruction <= mem[sampled_idx];
      end
    end else begin : async_read
      assign instruction = mem[word_index];
    end
  endgenerate

endmodule