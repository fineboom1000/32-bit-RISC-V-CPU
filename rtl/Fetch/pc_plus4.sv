// pc_plus4.sv
// Simple adder to compute PC+4 for sequential execution
`timescale 1ns/1ps

module pc_plus4 (
  input  logic [31:0] pc_in,
  output logic [31:0] pc_out
);

  assign pc_out = pc_in + 32'd4;

endmodule
