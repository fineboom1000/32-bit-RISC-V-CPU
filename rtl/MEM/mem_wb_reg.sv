// mem_wb_reg.sv
// MEM -> WB pipeline register
`timescale 1ns/1ps

module mem_wb_reg #(
  parameter CTRL_W = 16
) (
  input  logic          clk,
  input  logic          rst,
  input  logic          stall_mem,
  input  logic          flush_mem,

  // inputs from MEM
  input  logic [4:0]    wb_in_rd,
  input  logic [31:0]   wb_in_wdata,
  input  logic [CTRL_W-1:0] wb_in_ctrl,
  input  logic [31:0]   wb_in_pc_plus4,
  input  logic [31:0]   wb_in_inst,
  input  logic          wb_in_valid,

  // outputs to WB
  output logic [4:0]    wb_out_rd,
  output logic [31:0]   wb_out_wdata,
  output logic [CTRL_W-1:0] wb_out_ctrl,
  output logic [31:0]   wb_out_pc_plus4,
  output logic [31:0]   wb_out_inst,
  output logic          wb_out_valid
);

  always_ff @(posedge clk) begin
    if (rst) begin
      wb_out_rd        <= 5'd0;
      wb_out_wdata     <= 32'd0;
      wb_out_ctrl      <= {CTRL_W{1'b0}};
      wb_out_pc_plus4  <= 32'd0;
      wb_out_inst      <= 32'd0;
      wb_out_valid     <= 1'b0;
    end else begin
      if (~stall_mem) begin
        if (flush_mem) begin
          // inject NOP
          wb_out_rd        <= 5'd0;
          wb_out_wdata     <= 32'd0;
          wb_out_ctrl      <= {CTRL_W{1'b0}};
          wb_out_pc_plus4  <= 32'd0;
          wb_out_inst      <= 32'd0;
          wb_out_valid     <= 1'b0;
        end else begin
          // normal capture
          wb_out_rd        <= wb_in_rd;
          wb_out_wdata     <= wb_in_wdata;
          wb_out_ctrl      <= wb_in_ctrl;
          wb_out_pc_plus4  <= wb_in_pc_plus4;
          wb_out_inst      <= wb_in_inst;
          wb_out_valid     <= wb_in_valid;
        end
      end
      // if stall_mem, hold previous values
    end
  end

endmodule