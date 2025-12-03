// EX -> MEM pipeline register with stall/flush semantics.
// Latches EX outputs into MEM inputs.

`timescale 1ns/1ps

module ex_mem_reg #(
  parameter CTRL_W = 16
) (
  input  logic          clk,
  input  logic          rst,
  input  logic          stall_ex,    // when high, hold previous outputs
  input  logic          flush_ex,    // when high, write NOP (zeroed control)

  // inputs from EX
  input  logic [31:0]   mem_in_alu_result,
  input  logic [31:0]   mem_in_rs2_for_store,
  input  logic [4:0]    mem_in_rd,
  input  logic [CTRL_W-1:0] mem_in_ctrl,
  input  logic          mem_in_branch_taken,
  input  logic [31:0]   mem_in_branch_target,
  input  logic [31:0]   mem_in_pc_plus4,
  input  logic [31:0]   mem_in_inst,
  input  logic          mem_in_valid,

  // outputs to MEM
  output logic [31:0]   mem_out_alu_result,
  output logic [31:0]   mem_out_rs2_for_store,
  output logic [4:0]    mem_out_rd,
  output logic [CTRL_W-1:0] mem_out_ctrl,
  output logic          mem_out_branch_taken,
  output logic [31:0]   mem_out_branch_target,
  output logic [31:0]   mem_out_pc_plus4,
  output logic [31:0]   mem_out_inst,
  output logic          mem_out_valid
);

  // synchronous pipeline register
  always_ff @(posedge clk) begin
    if (rst) begin
      mem_out_alu_result      <= 32'd0;
      mem_out_rs2_for_store   <= 32'd0;
      mem_out_rd              <= 5'd0;
      mem_out_ctrl            <= {CTRL_W{1'b0}};
      mem_out_branch_taken    <= 1'b0;
      mem_out_branch_target   <= 32'd0;
      mem_out_pc_plus4        <= 32'd0;
      mem_out_inst            <= 32'd0;
      mem_out_valid           <= 1'b0;
    end else begin
      if (~stall_ex) begin
        if (flush_ex) begin
          // inject NOP (zero control) on flush
          mem_out_alu_result      <= 32'd0;
          mem_out_rs2_for_store   <= 32'd0;
          mem_out_rd              <= 5'd0;
          mem_out_ctrl            <= {CTRL_W{1'b0}};
          mem_out_branch_taken    <= 1'b0;
          mem_out_branch_target   <= 32'd0;
          mem_out_pc_plus4        <= 32'd0;
          mem_out_inst            <= 32'd0;
          mem_out_valid           <= 1'b0;
        end else begin
          // normal capture
          mem_out_alu_result      <= mem_in_alu_result;
          mem_out_rs2_for_store   <= mem_in_rs2_for_store;
          mem_out_rd              <= mem_in_rd;
          mem_out_ctrl            <= mem_in_ctrl;
          mem_out_branch_taken    <= mem_in_branch_taken;
          mem_out_branch_target   <= mem_in_branch_target;
          mem_out_pc_plus4        <= mem_in_pc_plus4;
          mem_out_inst            <= mem_in_inst;
          mem_out_valid           <= mem_in_valid;
        end
      end
      // if stall_ex == 1, hold previous outputs (do nothing)
    end
  end

endmodule