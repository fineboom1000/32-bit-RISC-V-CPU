// id_ex_reg.sv
// ID -> EX pipeline register with control bundle support
`timescale 1ns/1ps

module id_ex_reg #(
  parameter CTRL_W = 16,
  parameter logic [31:0] NOP_IMM = 32'd0
) (
  input  logic         clk,
  input  logic         rst,
  input  logic         stall_id,   // hold ID/EX (do not advance)
  input  logic         flush_ex,   // inject NOP into EX

  // inputs from decode
  input  logic [31:0]  id_pc,
  input  logic [31:0]  id_pc_plus4,
  input  logic [31:0]  id_rs1_val,
  input  logic [31:0]  id_rs2_val,
  input  logic [31:0]  id_imm,
  input  logic [4:0]   id_rs1,
  input  logic [4:0]   id_rs2,
  input  logic [4:0]   id_rd,
  input  logic [31:0]  id_instr,
  input  logic [CTRL_W-1:0] id_ctrl,

  // outputs to EX
  output logic [31:0]  ex_pc,
  output logic [31:0]  ex_pc_plus4,
  output logic [31:0]  ex_rs1_val,
  output logic [31:0]  ex_rs2_val,
  output logic [31:0]  ex_imm,
  output logic [4:0]   ex_rs1,
  output logic [4:0]   ex_rs2,
  output logic [4:0]   ex_rd,
  output logic [31:0]  ex_instr,
  output logic [CTRL_W-1:0] ex_ctrl
);

  // internal registers
  logic [31:0] pc_r, pc_plus4_r, rs1v_r, rs2v_r, imm_r, instr_r;
  logic [4:0]  rs1_r, rs2_r, rd_r;
  logic [CTRL_W-1:0] ctrl_r;

  always_ff @(posedge clk) begin
    if (rst) begin
      pc_r         <= 32'd0;
      pc_plus4_r   <= 32'd0;
      rs1v_r       <= 32'd0;
      rs2v_r       <= 32'd0;
      imm_r        <= NOP_IMM;
      rs1_r        <= 5'd0;
      rs2_r        <= 5'd0;
      rd_r         <= 5'd0;
      instr_r      <= 32'h0000_0013;  // NOP :)
      ctrl_r       <= {CTRL_W{1'b0}};
    end else begin
      if (stall_id) begin
        // hold: do nothing
      end else if (flush_ex) begin
        // inject NOP into EX: clear control, keep PC for debug, but it is not needed
        pc_r         <= id_pc;
        pc_plus4_r   <= id_pc_plus4;
        rs1v_r       <= 32'd0;
        rs2v_r       <= 32'd0;
        imm_r        <= NOP_IMM;
        rs1_r        <= 5'd0;
        rs2_r        <= 5'd0;
        rd_r         <= 5'd0;
        instr_r      <= 32'h0000_0013;  // NOP
        ctrl_r       <= {CTRL_W{1'b0}};
      end else begin
        // normal capture
        pc_r         <= id_pc;
        pc_plus4_r   <= id_pc_plus4;
        rs1v_r       <= id_rs1_val;
        rs2v_r       <= id_rs2_val;
        imm_r        <= id_imm;
        rs1_r        <= id_rs1;
        rs2_r        <= id_rs2;
        rd_r         <= id_rd;
        instr_r      <= id_instr;
        ctrl_r       <= id_ctrl;
      end
    end
  end

  // outputs
  assign ex_pc         = pc_r;
  assign ex_pc_plus4   = pc_plus4_r;
  assign ex_rs1_val    = rs1v_r;
  assign ex_rs2_val    = rs2v_r;
  assign ex_imm        = imm_r;
  assign ex_rs1        = rs1_r;
  assign ex_rs2        = rs2_r;
  assign ex_rd         = rd_r;
  assign ex_instr      = instr_r;
  assign ex_ctrl       = ctrl_r;

endmodule