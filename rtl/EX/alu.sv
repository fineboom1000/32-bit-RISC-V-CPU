// alu.sv
// Combinational ALU: primitives + flags
`timescale 1ns/1ps

module alu #(
  parameter OP_WIDTH = 4
) (
  input  logic [31:0] a,
  input  logic [31:0] b,
  input  logic [OP_WIDTH-1:0] alu_op,
  output logic [31:0] result,
  output logic        zero,
  output logic        lt,   // signed a < b
  output logic        ltu   // unsigned a < b
);

  // ALU op encodings
  localparam logic [OP_WIDTH-1:0]
    ALU_ADD    = 4'd0,
    ALU_SUB    = 4'd1,
    ALU_AND    = 4'd2,
    ALU_OR     = 4'd3,
    ALU_XOR    = 4'd4,
    ALU_SLT    = 4'd5,
    ALU_SLTU   = 4'd6,
    ALU_SLL    = 4'd7,
    ALU_SRL    = 4'd8,
    ALU_SRA    = 4'd9,
    ALU_COPY_A = 4'd10,
    ALU_PC_ADD = 4'd11; // semantic alias for add when 'a' is PC

  logic [31:0] add_result;
  logic [31:0] sub_result;

  // compute add/sub
  assign add_result = a + b;
  assign sub_result = a - b;

  // combinational ALU
  always_comb begin
    unique case (alu_op)
      ALU_ADD:    result = add_result;
      ALU_SUB:    result = sub_result;
      ALU_AND:    result = a & b;
      ALU_OR:     result = a | b;
      ALU_XOR:    result = a ^ b;
      ALU_SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
      ALU_SLTU:   result = (a < b) ? 32'd1 : 32'd0;
      ALU_SLL:    result = a << b[4:0];
      ALU_SRL:    result = a >> b[4:0];
      ALU_SRA:    result = $signed(a) >>> b[4:0];
      ALU_COPY_A: result = a;
      ALU_PC_ADD: result = add_result;
      default:    result = 32'd0;
    endcase
  end

  // flags
  assign zero = (result == 32'd0);
  assign lt   = ($signed(a) < $signed(b));
  assign ltu  = (a < b);

endmodule