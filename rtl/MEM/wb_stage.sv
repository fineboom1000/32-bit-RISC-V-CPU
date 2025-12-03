// wb_stage.sv
// Writeback stage: extracts reg_write signal and prepares register file write
`timescale 1ns/1ps

module wb_stage #(
  parameter CTRL_W = 16
) (
  // inputs from MEM/WB register
  input  logic [4:0]    wb_in_rd,
  input  logic [31:0]   wb_in_wdata,
  input  logic [CTRL_W-1:0] wb_in_ctrl,
  input  logic          wb_in_valid,

  // outputs to register file
  output logic          wb_reg_write,
  output logic [4:0]    wb_rd,
  output logic [31:0]   wb_wdata
);

  // Extract reg_write from control bundle
  logic ctrl_reg_write;
  assign ctrl_reg_write = wb_in_ctrl[0];

  // Drive register file write signals
  assign wb_reg_write = ctrl_reg_write & wb_in_valid;
  assign wb_rd        = wb_in_rd;
  assign wb_wdata     = wb_in_wdata;

endmodule