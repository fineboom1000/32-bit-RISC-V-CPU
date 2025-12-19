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

  (* ram_style = "block" *) logic [31:0] mem [0:WORDS-1];

  // Test program - writes 0x55 to GPIO
  initial begin
    mem[0] = 32'h80000537;  // lui a0, 0x80000
    mem[1] = 32'h05500593;  // li a1, 0x55
    mem[2] = 32'h00b52023;  // sw a1, 0(a0)
    mem[3] = 32'h0000006f;  // j loop
    
    // Fill rest with NOPs
    for (int i = 4; i < WORDS; i++) begin
      mem[i] = 32'h00000013;  // NOP
    end
  end

  logic [31:0] addr_offset;
  logic [$clog2(WORDS)-1:0] word_index;
  
  assign addr_offset = addr - ROM_BASE;
  assign word_index  = addr_offset[31:2];

  always_ff @(posedge clk) begin
    if (read_en) begin
      instruction <= mem[word_index];
    end
  end

endmodule
