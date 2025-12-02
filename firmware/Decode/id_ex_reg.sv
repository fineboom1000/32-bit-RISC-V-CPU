// id_ex_reg.sv
`timescale 1ns/1ps

module id_ex_reg #(
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
  input  logic [3:0]   id_alu_op,
  input  logic         id_alu_src,
  input  logic         id_reg_write,
  input  logic         id_mem_read,
  input  logic         id_mem_write,
  input  logic         id_mem_to_reg,
  input  logic         id_branch,
  input  logic [1:0]   id_branch_type,
  input  logic         id_jump,

  // outputs to EX
  output logic [31:0]  ex_pc,
  output logic [31:0]  ex_pc_plus4,
  output logic [31:0]  ex_rs1_val,
  output logic [31:0]  ex_rs2_val,
  output logic [31:0]  ex_imm,
  output logic [4:0]   ex_rs1,
  output logic [4:0]   ex_rs2,
  output logic [4:0]   ex_rd,
  output logic [3:0]   ex_alu_op,
  output logic         ex_alu_src,
  output logic         ex_reg_write,
  output logic         ex_mem_read,
  output logic         ex_mem_write,
  output logic         ex_mem_to_reg,
  output logic         ex_branch,
  output logic [1:0]   ex_branch_type,
  output logic         ex_jump
);

  // internal registers
  logic [31:0] pc_r, pc_plus4_r, rs1v_r, rs2v_r, imm_r;
  logic [4:0]  rs1_r, rs2_r, rd_r;
  logic [3:0]  alu_op_r;
  logic        alu_src_r, reg_write_r, mem_read_r, mem_write_r, mem_to_reg_r, branch_r, jump_r;
  logic [1:0]  branch_type_r;

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
      alu_op_r     <= 4'd0;
      alu_src_r    <= 1'b0;
      reg_write_r  <= 1'b0;
      mem_read_r   <= 1'b0;
      mem_write_r  <= 1'b0;
      mem_to_reg_r <= 1'b0;
      branch_r     <= 1'b0;
      branch_type_r<= 2'd0;
      jump_r       <= 1'b0;
    end else begin
      if (stall_id) begin
        // hold: do nothing
        pc_r         <= pc_r;
      end else if (flush_ex) begin
        // inject NOP into EX: clear control, keep PC for debug if wanted
        pc_r         <= id_pc;
        pc_plus4_r   <= id_pc_plus4;
        rs1v_r       <= 32'd0;
        rs2v_r       <= 32'd0;
        imm_r        <= NOP_IMM;
        rs1_r        <= 5'd0;
        rs2_r        <= 5'd0;
        rd_r         <= 5'd0;
        alu_op_r     <= 4'd0;
        alu_src_r    <= 1'b0;
        reg_write_r  <= 1'b0;
        mem_read_r   <= 1'b0;
        mem_write_r  <= 1'b0;
        mem_to_reg_r <= 1'b0;
        branch_r     <= 1'b0;
        branch_type_r<= 2'd0;
        jump_r       <= 1'b0;
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
        alu_op_r     <= id_alu_op;
        alu_src_r    <= id_alu_src;
        reg_write_r  <= id_reg_write;
        mem_read_r   <= id_mem_read;
        mem_write_r  <= id_mem_write;
        mem_to_reg_r <= id_mem_to_reg;
        branch_r     <= id_branch;
        branch_type_r<= id_branch_type;
        jump_r       <= id_jump;
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
  assign ex_alu_op     = alu_op_r;
  assign ex_alu_src    = alu_src_r;
  assign ex_reg_write  = reg_write_r;
  assign ex_mem_read   = mem_read_r;
  assign ex_mem_write  = mem_write_r;
  assign ex_mem_to_reg = mem_to_reg_r;
  assign ex_branch     = branch_r;
  assign ex_branch_type= branch_type_r;
  assign ex_jump       = jump_r;

endmodule
