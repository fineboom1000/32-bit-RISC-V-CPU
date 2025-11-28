// control_unit_min.sv
// Minimal control unit for your Concrete ISA (RV32I subset used for Pong).
`timescale 1ns/1ps

module control_unit_min (
  input  logic [6:0] opcode,
  input  logic [2:0] funct3,
  input  logic [6:0] funct7,

  // outputs (small set)
  output logic [3:0] alu_op,    // small ALU enum
  output logic       alu_src,   // 0 = rs2, 1 = imm
  output logic       reg_write, // writeback to rd
  output logic       mem_read,  // load
  output logic       mem_write, // store
  output logic       mem_to_reg,// 1 = load -> rd, 0 = ALU -> rd
  output logic       branch,    // branch instruction
  output logic [1:0] branch_type, // 00=BEQ,01=BNE (only two used in spec)
  output logic       jump       // JAL/JALR
);

  // ALU ops (small)
  localparam logic [3:0]
    ALU_ADD  = 4'd0,
    ALU_SUB  = 4'd1,
    ALU_AND  = 4'd2,
    ALU_OR   = 4'd3,
    ALU_SLT  = 4'd4,
    ALU_NOP  = 4'd15;

  // Opcodes from your spec
  localparam logic [6:0]
    OPC_R_TYPE = 7'b0110011, // add,sub,and,or,slt
    OPC_I_ALU  = 7'b0010011, // addi,andi,ori
    OPC_LOAD   = 7'b0000011, // lw
    OPC_STORE  = 7'b0100011, // sw
    OPC_BRANCH = 7'b1100011, // beq,bne
    OPC_LUI    = 7'b0110111, // lui
    OPC_JAL    = 7'b1101111, // jal
    OPC_JALR   = 7'b1100111; // jalr

  // branch types
  localparam logic [1:0] BR_BEQ = 2'd0, BR_BNE = 2'd1;

  always_comb begin
    // defaults
    alu_op    = ALU_NOP;
    alu_src   = 1'b0;
    reg_write = 1'b0;
    mem_read  = 1'b0;
    mem_write = 1'b0;
    mem_to_reg= 1'b0;
    branch    = 1'b0;
    branch_type = BR_BEQ;
    jump      = 1'b0;

    case (opcode)
      // R-type: add, sub, and, or, slt (funct3 + funct7)
      OPC_R_TYPE: begin
        alu_src = 1'b0;
        reg_write = 1'b1;
        mem_to_reg = 1'b0;
        unique case (funct3)
          3'b000: alu_op = (funct7 == 7'b0100000) ? ALU_SUB : ALU_ADD; // add/sub
          3'b111: alu_op = ALU_AND;
          3'b110: alu_op = ALU_OR;
          3'b010: alu_op = ALU_SLT;
          default: alu_op = ALU_NOP;
        endcase
      end

      // I-type ALU immediate: addi, andi, ori
      OPC_I_ALU: begin
        alu_src = 1'b1;
        reg_write = 1'b1;
        mem_to_reg = 1'b0;
        unique case (funct3)
          3'b000: alu_op = ALU_ADD; // addi
          3'b111: alu_op = ALU_AND; // andi
          3'b110: alu_op = ALU_OR;  // ori
          default: alu_op = ALU_NOP;
        endcase
      end

      // LOAD (lw)
      OPC_LOAD: begin
        alu_src = 1'b1;      // address = rs1 + imm
        reg_write = 1'b1;
        mem_read = 1'b1;
        mem_to_reg = 1'b1;
        alu_op = ALU_ADD;    // compute address
      end

      // STORE (sw)
      OPC_STORE: begin
        alu_src = 1'b1;
        mem_write = 1'b1;
        reg_write = 1'b0;
        alu_op = ALU_ADD;    // compute address
      end

      // BRANCH (beq, bne)
      OPC_BRANCH: begin
        branch = 1'b1;
        alu_src = 1'b0;
        reg_write = 1'b0;
        alu_op = ALU_SUB; // use subtract/compare
        unique case (funct3)
          3'b000: branch_type = BR_BEQ; // beq
          3'b001: branch_type = BR_BNE; // bne
          default: branch_type = BR_BEQ;
        endcase
      end

      // LUI
      OPC_LUI: begin
        alu_src = 1'b1; // imm provided (upper)
        reg_write = 1'b1;
        mem_to_reg = 1'b0;
        alu_op = ALU_ADD; // handle in EX (imm<<12)
      end

      // JAL
      OPC_JAL: begin
        jump = 1'b1;
        reg_write = 1'b1; // rd = PC+4
        mem_to_reg = 1'b0;
        alu_op = ALU_ADD; // target calc in EX
      end

      // JALR
      OPC_JALR: begin
        jump = 1'b1;
        reg_write = 1'b1; // rd = PC+4
        mem_to_reg = 1'b0;
        alu_src = 1'b1;   // addr = rs1 + imm
        alu_op = ALU_ADD;
      end

      default: begin
        // illegal/unused opcode: treat as NOP
        alu_op = ALU_NOP;
      end
    endcase
  end

endmodule
