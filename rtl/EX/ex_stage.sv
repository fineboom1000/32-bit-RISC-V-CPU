// ex_stage.sv
// EX stage with proper AUIPC, LUI, JAL/JALR support

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

  // forwarding inputs
  input  logic [31:0]   fwd_mem_data,
  input  logic [4:0]    fwd_mem_rd,
  input  logic          fwd_mem_valid,
  input  logic [31:0]   fwd_wb_data,
  input  logic [4:0]    fwd_wb_rd,
  input  logic          fwd_wb_valid,

  // EX -> MEM outputs
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

  // Unpack control bundle
  logic        ctrl_reg_write;
  logic [1:0]  ctrl_wb_sel;
  logic        ctrl_alu_src;
  logic [3:0]  ctrl_alu_op;
  logic        ctrl_mem_read;
  logic        ctrl_mem_write;
  logic [1:0]  ctrl_mem_width;
  logic        ctrl_mem_signed;
  logic        ctrl_branch;
  logic        ctrl_jump;
  logic        ctrl_pc_to_alu;

  always_comb begin
    ctrl_reg_write  = ex_in_ctrl[0];
    ctrl_wb_sel     = ex_in_ctrl[2:1];
    ctrl_alu_src    = ex_in_ctrl[3];
    ctrl_alu_op     = ex_in_ctrl[7:4];
    ctrl_mem_read   = ex_in_ctrl[8];
    ctrl_mem_write  = ex_in_ctrl[9];
    ctrl_mem_width  = ex_in_ctrl[11:10];
    ctrl_mem_signed = ex_in_ctrl[12];
    ctrl_branch     = ex_in_ctrl[13];
    ctrl_jump       = ex_in_ctrl[14];
    ctrl_pc_to_alu  = ex_in_ctrl[15];
  end

  // Forwarding logic for rs1 and rs2
  logic [31:0] op_a_pre, op_b_pre;
  logic [31:0] op_a_forwarded, op_b_forwarded;

  assign op_a_pre = ex_in_rs1_data;
  assign op_b_pre = ex_in_rs2_data;

  // Operand A forwarding (rs1)
  always_comb begin
    if (fwd_mem_valid && (fwd_mem_rd != 5'd0) && (fwd_mem_rd == ex_in_rs1))
      op_a_forwarded = fwd_mem_data;
    else if (fwd_wb_valid && (fwd_wb_rd != 5'd0) && (fwd_wb_rd == ex_in_rs1))
      op_a_forwarded = fwd_wb_data;
    else
      op_a_forwarded = op_a_pre;
  end

  // Operand B forwarding (rs2)
  logic [31:0] op_b_rf_or_fwd;
  always_comb begin
    if (fwd_mem_valid && (fwd_mem_rd != 5'd0) && (fwd_mem_rd == ex_in_rs2))
      op_b_rf_or_fwd = fwd_mem_data;
    else if (fwd_wb_valid && (fwd_wb_rd != 5'd0) && (fwd_wb_rd == ex_in_rs2))
      op_b_rf_or_fwd = fwd_wb_data;
    else
      op_b_rf_or_fwd = op_b_pre;
  end

  // ALU operand selection
  logic [31:0] alu_op_a, alu_op_b;
  
  assign alu_op_a = ctrl_pc_to_alu ? ex_in_pc : op_a_forwarded;
  assign alu_op_b = ctrl_alu_src ? ex_in_imm : op_b_rf_or_fwd;

  // Store data
  logic [31:0] rs2_for_store;
  assign rs2_for_store = op_b_rf_or_fwd;

  // Instantiate ALU
  logic [31:0] alu_result;
  logic        alu_zero;
  logic        alu_lt;
  logic        alu_ltu;

  alu alu_i (
    .a       (alu_op_a),
    .b       (alu_op_b),
    .alu_op  (ctrl_alu_op),
    .result  (alu_result),
    .zero    (alu_zero),
    .lt      (alu_lt),
    .ltu     (alu_ltu)
  );

  // Branch/Jump target calculation
  logic [31:0] branch_target;
  logic        branch_or_jump_taken;
  logic [2:0]  funct3;
  
  assign funct3 = ex_in_instr[14:12];

  always_comb begin
    branch_target = 32'd0;
    branch_or_jump_taken = 1'b0;

    if (ctrl_jump) begin
      if (ex_in_instr[6:0] == 7'b1100111) begin  // JALR
        branch_target = {alu_result[31:1], 1'b0};
      end else begin  // JAL
        branch_target = ex_in_pc + ex_in_imm;
      end
      branch_or_jump_taken = 1'b1;
    end else if (ctrl_branch) begin
      branch_target = ex_in_pc + ex_in_imm;
      
      case (funct3)
        3'b000: branch_or_jump_taken = alu_zero;          // BEQ
        3'b001: branch_or_jump_taken = ~alu_zero;         // BNE
        3'b100: branch_or_jump_taken = alu_lt;            // BLT
        3'b101: branch_or_jump_taken = ~alu_lt;           // BGE
        3'b110: branch_or_jump_taken = alu_ltu;           // BLTU
        3'b111: branch_or_jump_taken = ~alu_ltu;          // BGEU
        default: branch_or_jump_taken = 1'b0;
      endcase
    end
  end

  // EX outputs
  assign ex_out_alu_result      = alu_result;
  assign ex_out_rs2_for_store   = rs2_for_store;
  assign ex_out_rd              = ex_in_rd;
  assign ex_out_ctrl            = ex_in_ctrl;
  assign ex_out_branch_taken    = branch_or_jump_taken;
  assign ex_out_branch_target   = branch_target;
  assign ex_out_pc_plus4        = ex_in_pc_plus4;
  assign ex_out_inst            = ex_in_instr;
  assign ex_out_valid           = ex_in_valid;

endmodule