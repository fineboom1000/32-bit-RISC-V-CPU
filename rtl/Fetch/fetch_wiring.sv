
// Thin wiring module: connect your existing PC output to IMEM and expose signals to decode.
// Please see the RTL page on ISA notes
// There you will see my understanding of everything.


// This is a wrapper used for wiring,
// and is responsible for nothing else but wiring.

//fetch_wiring

`timescale 1ns/1ps

module fetch_wiring #(
  parameter logic [31:0] ROM_BASE = 32'h0000_1000,
  parameter string IMEM_FILE = "imem.hex",
  parameter int IMEM_WORDS = 4096,
  parameter bit IMEM_SYNC = 1
) (
  input  logic        clk,
  input  logic        imem_read_en,
  input  logic [31:0] pc_current,
  input  logic [31:0] pc_plus4,

  output logic [31:0] if_pc,
  output logic [31:0] if_pc_plus4,
  output logic [31:0] if_instruction
);

  // instantiate instruction memory
  imem #(
    .MEMFILE(IMEM_FILE),
    .ROM_BASE(ROM_BASE),
    .WORDS(IMEM_WORDS),
    .SYNC(IMEM_SYNC)
  ) imem_inst (
    .clk(clk),
    .read_en(imem_read_en),
    .addr(pc_current),
    .instruction(if_instruction)
  );

  // pass PC values through to IF/ID register
  assign if_pc = pc_current;
  assign if_pc_plus4 = pc_plus4;

endmodule