// decode.sv - COMPLETE FIXED VERSION
`timescale 1ns/1ps

module decode #(
  parameter CTRL_W = 16
) (
  input  logic         clk,
  input  logic         rst,
  input  logic         stall_id,
  input  logic         flush_id,

  // inputs from IF/ID
  input  logic [31:0]  id_instr,
  input  logic [31:0]  id_pc,
  input  logic [31:0]  id_pc_plus4,

  // register file interface
  output logic [4:0]   rf_raddr1,
  output logic [4:0]   rf_raddr2,
  input  logic [31:0]  rf_rdata1,
  input  logic [31:0]  rf_rdata2,

  // writeback interface (from WB stage)
  input  logic         wb_wen,
  input  logic [4:0]   wb_waddr,
  input  logic [31:0]  wb_wdata,

  // outputs to EX stage (via ID/EX register)
  output logic [31:0]  idex_pc,
  output logic [31:0]  idex_pc_plus4,
  output logic [31:0]  idex_rs1_val,
  output logic [31:0]  idex_rs2_val,
  output logic [31:0]  idex_imm,
  output logic [4:0]   idex_rs1,
  output logic [4:0]   idex_rs2,
  output logic [4:0]   idex_rd,
  output logic [31:0]  idex_instr,
  output logic [CTRL_W-1:0] idex_ctrl
);

  // Internal wires from decode_fields_imms
  logic [6:0]  opcode;
  logic [4:0]  rd;
  logic [2:0]  funct3;
  logic [4:0]  rs1;
  logic [4:0]  rs2;
  logic [6:0]  funct7;
  logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
  logic [31:0] id_imm;

  // Instantiate decode_fields_imms
  decode_fields_imms dfim (
    .id_instr(id_instr),
    .id_pc(id_pc),
    .opcode(opcode),
    .rd(rd),
    .funct3(funct3),
    .rs1(rs1),
    .rs2(rs2),
    .funct7(funct7),
    .imm_i(imm_i),
    .imm_s(imm_s),
    .imm_b(imm_b),
    .imm_u(imm_u),
    .imm_j(imm_j),
    .id_imm(id_imm)
  );

  // Register file read addresses
  assign rf_raddr1 = rs1;
  assign rf_raddr2 = rs2;

  // Apply x0 semantics
  logic [31:0] rs1_val_pre, rs2_val_pre;
  assign rs1_val_pre = (rs1 == 5'd0) ? 32'd0 : rf_rdata1;
  assign rs2_val_pre = (rs2 == 5'd0) ? 32'd0 : rf_rdata2;

  // Control unit signals
  logic [3:0]  alu_op;
  logic        alu_src, reg_write, mem_read, mem_write, mem_to_reg, branch, jump;
  logic [1:0]  branch_type;
  logic [1:0]  mem_width;
  logic        mem_signed;
  logic [1:0]  wb_sel;

  // Instantiate enhanced control unit
  control_unit_enhanced cu (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .alu_op(alu_op),
    .alu_src(alu_src),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .branch(branch),
    .branch_type(branch_type),
    .jump(jump),
    .mem_width(mem_width),
    .mem_signed(mem_signed),
    .wb_sel(wb_sel)
  );

  // Pack control signals into bundle
  logic [CTRL_W-1:0] id_ctrl_bundle;
  
  control_bundle_pack ctrl_pack (
    .alu_op(alu_op),
    .alu_src(alu_src),
    .reg_write(reg_write),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_to_reg(mem_to_reg),
    .branch(branch),
    .branch_type(branch_type),
    .jump(jump),
    .mem_width(mem_width),
    .mem_signed(mem_signed),
    .wb_sel(wb_sel),
    .ctrl_bundle(id_ctrl_bundle)
  );

  // Internal wires from ID/EX register outputs
  logic [31:0] ex_pc_out, ex_pc_plus4_out, ex_rs1_val_out, ex_rs2_val_out;
  logic [31:0] ex_imm_out, ex_instr_out;
  logic [4:0]  ex_rs1_out, ex_rs2_out, ex_rd_out;
  logic [CTRL_W-1:0] ex_ctrl_out;

  // ID->EX register
  id_ex_reg_fixed #(
    .CTRL_W(CTRL_W)
  ) idex (
    .clk(clk),
    .rst(rst),
    .stall_id(stall_id),
    .flush_ex(flush_id),

    // inputs from decode
    .id_pc(id_pc),
    .id_pc_plus4(id_pc_plus4),
    .id_rs1_val(rs1_val_pre),
    .id_rs2_val(rs2_val_pre),
    .id_imm(id_imm),
    .id_rs1(rs1),
    .id_rs2(rs2),
    .id_rd(rd),
    .id_instr(id_instr),
    .id_ctrl(id_ctrl_bundle),

    // outputs to EX
    .ex_pc(ex_pc_out),
    .ex_pc_plus4(ex_pc_plus4_out),
    .ex_rs1_val(ex_rs1_val_out),
    .ex_rs2_val(ex_rs2_val_out),
    .ex_imm(ex_imm_out),
    .ex_rs1(ex_rs1_out),
    .ex_rs2(ex_rs2_out),
    .ex_rd(ex_rd_out),
    .ex_instr(ex_instr_out),
    .ex_ctrl(ex_ctrl_out)
  );

  // Connect ID/EX register outputs to module outputs
  assign idex_pc       = ex_pc_out;
  assign idex_pc_plus4 = ex_pc_plus4_out;
  assign idex_rs1_val  = ex_rs1_val_out;
  assign idex_rs2_val  = ex_rs2_val_out;
  assign idex_imm      = ex_imm_out;
  assign idex_rs1      = ex_rs1_out;
  assign idex_rs2      = ex_rs2_out;
  assign idex_rd       = ex_rd_out;
  assign idex_instr    = ex_instr_out;
  assign idex_ctrl     = ex_ctrl_out;

endmodule