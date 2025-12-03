// decode.sv
`timescale 1ns/1ps

//  wires decode_fields_imms, regfile, and control_unit_min,
// produces signals to ID/EX register.

module decode (
  input  logic         clk,
  input  logic         rst,
  input  logic         stall_id,    // from hazard unit (not yet implemented)
  input  logic         flush_id,    // from hazard unit / branch resolution

  // inputs from IF/ID
  input  logic [31:0]  id_instr,
  input  logic [31:0]  id_pc,
  input  logic [31:0]  id_pc_plus4,

  // register file interface (to regfile module)
  output logic [4:0]   rf_raddr1,
  output logic [4:0]   rf_raddr2,
  input  logic [31:0]  rf_rdata1,
  input  logic [31:0]  rf_rdata2,

  // writeback interface (to regfile): connect WB stage later
  input  logic         wb_wen,
  input  logic [4:0]   wb_waddr,
  input  logic [31:0]  wb_wdata,

  // outputs to ID/EX latched)
  output logic [31:0]  idex_pc,
  output logic [31:0]  idex_pc_plus4,
  output logic [31:0]  idex_rs1_val,
  output logic [31:0]  idex_rs2_val,
  output logic [31:0]  idex_imm,
  output logic [4:0]   idex_rs1,
  output logic [4:0]   idex_rs2,
  output logic [4:0]   idex_rd,
  output logic [3:0]   idex_alu_op,
  output logic         idex_alu_src,
  output logic         idex_reg_write,
  output logic         idex_mem_read,
  output logic         idex_mem_write,
  output logic         idex_mem_to_reg,
  output logic         idex_branch,
  output logic [1:0]   idex_branch_type,
  output logic         idex_jump
);

  // internal wires from decode_fields_imms
  logic [6:0]  opcode;
  logic [4:0]  rd;
  logic [2:0]  funct3;
  logic [4:0]  rs1;
  logic [4:0]  rs2;
  logic [6:0]  funct7;
  logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
  logic [31:0] id_imm;

  // instantiate decode_fields_imms (combinational
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

  // register file read addresses
  assign rf_raddr1 = rs1;
  assign rf_raddr2 = rs2;

  // apply x0 semantics (if regfile not already)
  logic [31:0] rs1_val_pre, rs2_val_pre;
  assign rs1_val_pre = (rs1 == 5'd0) ? 32'd0 : rf_rdata1;
  assign rs2_val_pre = (rs2 == 5'd0) ? 32'd0 : rf_rdata2;

  // instantiate minimal control unit
  logic [3:0] alu_op;
  logic       alu_src, reg_write, mem_read, mem_write, mem_to_reg, branch, jump;
  logic [1:0] branch_type;

  control_unit_min cu (
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
    .jump(jump)
  );

  // ID->EX register: latch values (handles stall/flush)
  id_ex_reg idex (
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
    .id_alu_op(alu_op),
    .id_alu_src(alu_src),
    .id_reg_write(reg_write),
    .id_mem_read(mem_read),
    .id_mem_write(mem_write),
    .id_mem_to_reg(mem_to_reg),
    .id_branch(branch),
    .id_branch_type(branch_type),
    .id_jump(jump),

    // outputs to EX (also wired out of decode module)
    .ex_pc(idex_pc),
    .ex_pc_plus4(idex_pc_plus4),
    .ex_rs1_val(idex_rs1_val),
    .ex_rs2_val(idex_rs2_val),
    .ex_imm(idex_imm),
    .ex_rs1(idex_rs1),
    .ex_rs2(idex_rs2),
    .ex_rd(idex_rd),
    .ex_alu_op(idex_alu_op),
    .ex_alu_src(idex_alu_src),
    .ex_reg_write(idex_reg_write),
    .ex_mem_read(idex_mem_read),
    .ex_mem_write(idex_mem_write),
    .ex_mem_to_reg(idex_mem_to_reg),
    .ex_branch(idex_branch),
    .ex_branch_type(idex_branch_type),
    .ex_jump(idex_jump)
  );

  // Connect idex outputs to module outputs (simple pass-through)
  assign idex_pc         = idex_pc;
  assign idex_pc_plus4   = idex_pc_plus4;
  assign idex_rs1_val    = idex_rs1_val;
  assign idex_rs2_val    = idex_rs2_val;
  assign idex_imm        = idex_imm;
  assign idex_rs1        = idex_rs1;
  assign idex_rs2        = idex_rs2;
  assign idex_rd         = idex_rd;
  assign idex_alu_op     = idex_alu_op;
  assign idex_alu_src    = idex_alu_src;
  assign idex_reg_write  = idex_reg_write;
  assign idex_mem_read   = idex_mem_read;
  assign idex_mem_write  = idex_mem_write;
  assign idex_mem_to_reg = idex_mem_to_reg;
  assign idex_branch     = idex_branch;
  assign idex_branch_type= idex_branch_type;
  assign idex_jump       = idex_jump;

endmodule
