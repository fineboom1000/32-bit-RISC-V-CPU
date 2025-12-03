// forward_unit.sv
// Present MEM/WB-stage forwarding candidates to EX stage.
// The EX stage does the matching (rd == rsX) and priority selection (MEM -> WB -> RF).

`timescale 1ns/1ps

module forward_unit (
  input  logic [4:0]   mem_rd,
  input  logic [31:0]  mem_wdata,
  input  logic         mem_reg_write,

  input  logic [4:0]   wb_rd,
  input  logic [31:0]  wb_wdata,
  input  logic         wb_reg_write,

  output logic [31:0]  fwd_mem_data,
  output logic [4:0]   fwd_mem_rd,
  output logic         fwd_mem_valid,

  output logic [31:0]  fwd_wb_data,
  output logic [4:0]   fwd_wb_rd,
  output logic         fwd_wb_valid
);

  // MEM forwarding candidate
  assign fwd_mem_data  = mem_wdata;
  assign fwd_mem_rd    = mem_rd;
  assign fwd_mem_valid = mem_reg_write;

  // WB forwarding candidate
  assign fwd_wb_data   = wb_wdata;
  assign fwd_wb_rd     = wb_rd;
  assign fwd_wb_valid  = wb_reg_write;

endmodule
