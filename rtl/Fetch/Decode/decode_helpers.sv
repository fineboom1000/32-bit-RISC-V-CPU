
`timescale 1ns/1ps 

package decode_helpers_pkg;
  // ALU/op enums or helper typedefs can go here later.
endpackage

module decode_helpers (
  input  logic [31:0] id_instr,   
  input  logic [31:0] id_pc,      
  output logic [6:0]  opcode,
  output logic [4:0]  rd,
  output logic [2:0]  funct3,
  output logic [4:0]  rs1,
  output logic [4:0]  rs2,
  output logic [6:0]  funct7,
  // immediates
  output logic [31:0] imm_i,
  output logic [31:0] imm_s,
  output logic [31:0] imm_b,
  output logic [31:0] imm_u,
  output logic [31:0] imm_j
);

  // Field extraction (combinational)
  assign opcode = id_instr[6:0];
  assign rd     = id_instr[11:7];
  assign funct3 = id_instr[14:12];
  assign rs1    = id_instr[19:15];
  assign rs2    = id_instr[24:20];
  assign funct7 = id_instr[31:25];








  // Immediate extraction: implement as clear combinational expressions.
  // I-type: bits [31:20] sign-extend from bit 31
  assign imm_i = {{20{id_instr[31]}}, id_instr[31:20]};

  // S-type: imm[11:0] = inst[31:25] : inst[11:7]
  logic [11:0] imm_s_12;
  assign imm_s_12 = {id_instr[31:25], id_instr[11:7]};
  assign imm_s = {{20{imm_s_12[11]}}, imm_s_12};

  // B-type: imm[12|10:5|4:1|0] = inst[31],inst[30:25],inst[11:8],inst[7],0
  logic [12:0] imm_b_13;
  assign imm_b_13 = {id_instr[31], id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0};
  assign imm_b = {{19{imm_b_13[12]}}, imm_b_13}; // sign-extend 13->32

  // U-type: imm[31:12] = inst[31:12], low 12 bits zero
  assign imm_u = {id_instr[31:12], 12'b0};

  // J-type: imm[20|10:1|11|19:12|0] = inst[31],inst[30:21],inst[20],inst[19:12],0
  logic [20:0] imm_j_21;
  assign imm_j_21 = {id_instr[31], id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0};
  assign imm_j = {{11{imm_j_21[20]}}, imm_j_21}; // sign-extend 21->32

endmodule
