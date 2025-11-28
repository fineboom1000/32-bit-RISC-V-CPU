// decode_fields_imms.sv
`timescale 1ns/1ps

module decode_fields_imms (
  input  logic [31:0] id_instr,    // latched instruction from IF/ID
  input  logic [31:0] id_pc,       // optional: PC of this instruction (kept for debug/uses)
  output logic [6:0]  opcode,
  output logic [4:0]  rd,
  output logic [2:0]  funct3,
  output logic [4:0]  rs1,
  output logic [4:0]  rs2,
  output logic [6:0]  funct7,

  // raw immediates (all sign-extended to 32 bits where appropriate)
  output logic [31:0] imm_i,
  output logic [31:0] imm_s,
  output logic [31:0] imm_b,
  output logic [31:0] imm_u,
  output logic [31:0] imm_j,

  // selected immediate for EX stage
  output logic [31:0] id_imm
);

  // -----------------------
  // Field extraction (combinational)
  // -----------------------
  assign opcode = id_instr[6:0];
  assign rd     = id_instr[11:7];
  assign funct3 = id_instr[14:12];
  assign rs1    = id_instr[19:15];
  assign rs2    = id_instr[24:20];
  assign funct7 = id_instr[31:25];

  // -----------------------
  // Immediate generators
  // -----------------------

  // I-type immediate: inst[31:20] signed
  assign imm_i = {{20{id_instr[31]}}, id_instr[31:20]};

  // S-type immediate: imm[11:0] = inst[31:25] : inst[11:7]
  logic [11:0] imm_s_12;
  assign imm_s_12 = {id_instr[31:25], id_instr[11:7]};
  assign imm_s = {{20{imm_s_12[11]}}, imm_s_12};

  // B-type immediate: imm[12|10:5|4:1|0] = inst[31], inst[30:25], inst[11:8], inst[7], 0
  logic [12:0] imm_b_13;
  assign imm_b_13 = { id_instr[31], id_instr[7], id_instr[30:25], id_instr[11:8], 1'b0 };
  assign imm_b = {{19{imm_b_13[12]}}, imm_b_13};

  // U-type immediate: imm[31:12] = inst[31:12], low 12 bits = 0
  assign imm_u = { id_instr[31:12], 12'b0 };

  // J-type immediate: imm[20|10:1|11|19:12|0] = inst[31], inst[30:21], inst[20], inst[19:12], 0
  logic [20:0] imm_j_21;
  assign imm_j_21 = { id_instr[31], id_instr[19:12], id_instr[20], id_instr[30:21], 1'b0 };
  assign imm_j = {{11{imm_j_21[20]}}, imm_j_21};

  // -----------------------
  // Immediate selector
  // -----------------------
  // Localparams for opcode readability (matching your ISA table)
  localparam logic [6:0] OPC_R_TYPE  = 7'b0110011; // R
  localparam logic [6:0] OPC_I_ALU   = 7'b0010011; // I-type ALU (addi, andi, ori...)
  localparam logic [6:0] OPC_LOAD    = 7'b0000011; // loads (lw)
  localparam logic [6:0] OPC_JALR    = 7'b1100111; // jalr (I-type)
  localparam logic [6:0] OPC_S_TYPE  = 7'b0100011; // S-type (store)
  localparam logic [6:0] OPC_B_TYPE  = 7'b1100011; // B-type (branch)
  localparam logic [6:0] OPC_LUI     = 7'b0110111; // LUI (U-type)
  localparam logic [6:0] OPC_AUIPC   = 7'b0010111; // AUIPC (U-type) - include if supported
  localparam logic [6:0] OPC_JAL     = 7'b1101111; // JAL (J-type)

  always_comb begin
    // Default
    id_imm = 32'sd0;

    case (opcode)
      OPC_I_ALU,   // addi/andi/ori etc.
      OPC_LOAD,
      OPC_JALR:    id_imm = imm_i;

      OPC_S_TYPE:  id_imm = imm_s;

      OPC_B_TYPE:  id_imm = imm_b;

      OPC_LUI,
      OPC_AUIPC:   id_imm = imm_u;

      OPC_JAL:     id_imm = imm_j;

      default:     id_imm = 32'sd0; // illegal/unknown => zero (useful as safe default)
    endcase
  end

endmodule
