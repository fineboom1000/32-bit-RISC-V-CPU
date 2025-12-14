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

  logic [31:0] addr_offset;
  logic [11:0] word_index;  // 4096 words = 2^12
  
  assign addr_offset = addr - ROM_BASE;
  assign word_index  = addr_offset[13:2];  // word addressing

  // Instantiate the Block RAM IP
  imem_bram bram_inst (
    .clka(clk),
    .ena(read_en),
    .addra(word_index),
    .douta(instruction)
  );

endmodule