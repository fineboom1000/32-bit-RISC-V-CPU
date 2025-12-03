/ ex_stage.sv
// Minimal EX stage: unpack control bundle, select operands, ALU instantiation,
// branch decision logic, produce EX->MEM outputs.
// Assumes ex_in_ctrl is packed as described in spec (example 16-bit layout).

`timescale 1ns/1ps

module ex_stage #(
  parameter CTRL_W = 16
) (
  input  logic          clk,
  input  logic          rst,

  // ID -> EX inputs
  input  logic [31:0]   ex_in_pc,
  input  logic [31:0]   ex_in_pc_plus4,
  input  logic [31:0]   ex_in_rs1_data,
  input  logic [31:0]   ex_in_rs2_data,
  input  logic [31:0]   ex_in_imm,
  input  logic [4:0]    ex_in_rs1,
  input  logic [4:0]    ex_in_rs2,
  input  logic [4:0]    ex_in_rd,
  input  logic [31:0]   ex_in_instr,
  input  logic [CTRL_W-1:0] ex_in_ctrl,
  input  logic          ex_in_valid,

  // forwarding inputs (optional; wire 0 if unused)
  input  logic [31:0]   fwd_mem_data,
  input  logic [4:0]    fwd_mem_rd,
  input  logic          fwd_mem_valid,
  input  logic [31:0]   fwd_wb_data,
  input  logic [4:0]    fwd_wb_rd,
  input  logic          fwd_wb_valid,

  // EX -> MEM outputs (combinational outputs latched by ex_mem_reg)
  output logic [31:0]   ex_out_alu_result,
  output logic [31:0]   ex_out_rs2_for_store,
  output logic [4:0]    ex_out_rd,
  output logic [CTRL_W-1:0] ex_out_ctrl,
  output logic          ex_out_branch_taken,
  output logic [31:0]   ex_out_branch_target,
  output logic [31:0]   ex_out_pc_plus4,
  output logic [31:0]   ex_out_inst,
  output logic          ex_out_valid
);

  // unpack control bundle (example mapping)
  // bit 0: reg_write
  // bits [2:1]: wb_sel
  // bit 3: alu_src (0=rs2, 1=imm)
  // bits [7:4]: alu_op
  // bit 8: mem_read
  // bit 9: mem_write
  // bits [11:10]: mem_width
  // bit 12: mem_signed
  // bit 13: branch
  // bits [15:14]: branch_type (00=BEQ,01=BNE,10=BLT,11=BLTU)

  logic        ctrl_reg_write;
  logic [1:0]  ctrl_wb_sel;
  logic        ctrl_alu_src;
  logic [3:0]  ctrl_alu_op;
  logic        ctrl_mem_read;
  logic        ctrl_mem_write;
  logic [1:0]  ctrl_mem_width;
  logic        ctrl_mem_signed;
  logic        ctrl_branch;
  logic [1:0]  ctrl_branch_type;

  always_comb begin
    ctrl_reg_write   = ex_in_ctrl[0];
    ctrl_wb_sel      = ex_in_ctrl[2:1];
    ctrl_alu_src     = ex_in_ctrl[3];
    ctrl_alu_op      = ex_in_ctrl[7:4];
    ctrl_mem_read    = ex_in_ctrl[8];
    ctrl_mem_write   = ex_in_ctrl[9];
    ctrl_mem_width   = ex_in_ctrl[11:10];
    ctrl_mem_signed  = ex_in_ctrl[12];
    ctrl_branch      = ex_in_ctrl[13];
    ctrl_branch_type = ex_in_ctrl[15:14];
  end

  // forwarding mux (per-operand) priority MEM -> WB -> RF
  logic [31:0] op_a_pre, op_b_pre;
  logic [31:0] op_a, op_b;

  assign op_a_pre = ex_in_rs1_data;
  assign op_b_pre = ex_in_rs2_data;

  // operand A forwarding 
  always_comb begin
    if (fwd_mem_valid && (fwd_mem_rd != 5'd0) && (fwd_mem_rd == ex_in_rs1))
      op_a = fwd_mem_data;
    else if (fwd_wb_valid && (fwd_wb_rd != 5'd0) && (fwd_wb_rd == ex_in_rs1))
      op_a = fwd_wb_data;
    else
      op_a = op_a_pre;
  end

  // operand B forwarding (before alu_src mux)
  logic [31:0] op_b_rf_or_fwd;
  always_comb begin
    if (fwd_mem_valid && (fwd_mem_rd != 5'd0) && (fwd_mem_rd == ex_in_rs2))
      op_b_rf_or_fwd = fwd_mem_data;
    else if (fwd_wb_valid && (fwd_wb_rd != 5'd0) && (fwd_wb_rd == ex_in_rs2))
      op_b_rf_or_fwd = fwd_wb_data;
    else
      op_b_rf_or_fwd = op_b_pre;
  end

  // final operand B selected by alu_src (for ALU input)
  assign op_b = ctrl_alu_src ? ex_in_imm : op_b_rf_or_fwd;

  //  FIX!??!??!? Store data must use forwarded rs2, NOT ex_in_rs2_data
  // stores need the actual register value (potentially forwarded), not the immediate
  logic [31:0] rs2_for_store;
  assign rs2_for_store = op_b_rf_or_fwd;  // Use forwarded rs2 value

  // instantiate ALU
  logic [31:0] alu_result;
  logic        alu_zero;
  logic        alu_lt;
  logic        alu_ltu;

  alu alu_i (
    .a       (op_a),
    .b       (op_b),
    .alu_op  (ctrl_alu_op),
    .result  (alu_result),
    .zero    (alu_zero),
    .lt      (alu_lt),
    .ltu     (alu_ltu)
  );

  // branch target (PC + imm)
  logic [31:0] branch_target;
  assign branch_target = ex_in_pc + ex_in_imm;

  // branch decision
  logic branch_taken_local;
  always_comb begin
    branch_taken_local = 1'b0;
    if (ctrl_branch) begin
      unique case (ctrl_branch_type)
        2'b00: branch_taken_local = (alu_zero == 1'b1);       // BEQ
        2'b01: branch_taken_local = (alu_zero == 1'b0);       // BNE
        2'b10: branch_taken_local = (alu_lt == 1'b1);         // BLT
        2'b11: branch_taken_local = (alu_ltu == 1'b1);        // BLTU
        default: branch_taken_local = 1'b0;
      endcase
    end
  end

  // EX outputs (combinational)
  assign ex_out_alu_result      = alu_result;
  assign ex_out_rs2_for_store   = rs2_for_store;  // FIXED: use forwarded value
  assign ex_out_rd              = ex_in_rd;
  assign ex_out_ctrl            = ex_in_ctrl;
  assign ex_out_branch_taken    = branch_taken_local;
  assign ex_out_branch_target   = branch_target;
  assign ex_out_pc_plus4        = ex_in_pc_plus4;
  assign ex_out_inst            = ex_in_instr;
  assign ex_out_valid           = ex_in_valid;

endmodule
