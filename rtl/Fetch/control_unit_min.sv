`timescale 1ns/1ps

module control_unit_enhanced (
  input  logic [6:0] opcode,
  input  logic [2:0] funct3,
  input  logic [6:0] funct7,

  // Individual control outputs (for decode stage visibility)
  output logic [3:0] alu_op,
  output logic       alu_src,
  output logic       reg_write,
  output logic       mem_read,
  output logic       mem_write,
  output logic       mem_to_reg,
  output logic       branch,
  output logic [1:0] branch_type,
  output logic       jump,
  
  // Additional outputs for control bundle
  output logic [1:0] mem_width,
  output logic       mem_signed,
  output logic [1:0] wb_sel
);

  // ALU operation encodings (must match alu.sv)
  localparam logic [3:0]
    ALU_ADD  = 4'd0,
    ALU_SUB  = 4'd1,
    ALU_AND  = 4'd2,
    ALU_OR   = 4'd3,
    ALU_XOR  = 4'd4,
    ALU_SLT  = 4'd5,
    ALU_SLTU = 4'd6,
    ALU_SLL  = 4'd7,
    ALU_SRL  = 4'd8,
    ALU_SRA  = 4'd9,
    ALU_NOP  = 4'd15;

  // RISC-V opcodes
  localparam logic [6:0]
    OPC_R_TYPE = 7'b0110011,
    OPC_I_ALU  = 7'b0010011,
    OPC_LOAD   = 7'b0000011,
    OPC_STORE  = 7'b0100011,
    OPC_BRANCH = 7'b1100011,
    OPC_LUI    = 7'b0110111,
    OPC_AUIPC  = 7'b0010111,
    OPC_JAL    = 7'b1101111,
    OPC_JALR   = 7'b1100111;

  // Branch type encodings
  localparam logic [1:0]
    BR_BEQ  = 2'b00,
    BR_BNE  = 2'b01,
    BR_BLT  = 2'b10,
    BR_BLTU = 2'b11;

  // Writeback source select
  localparam logic [1:0]
    WB_ALU   = 2'b00,
    WB_MEM   = 2'b01,
    WB_PC4   = 2'b10,
    WB_IMM   = 2'b11;

  always_comb begin
    // Defaults
    alu_op      = ALU_NOP;
    alu_src     = 1'b0;
    reg_write   = 1'b0;
    mem_read    = 1'b0;
    mem_write   = 1'b0;
    mem_to_reg  = 1'b0;
    branch      = 1'b0;
    branch_type = BR_BEQ;
    jump        = 1'b0;
    mem_width   = 2'b10;  // default word
    mem_signed  = 1'b0;
    wb_sel      = WB_ALU;

    case (opcode)
      OPC_R_TYPE: begin
        alu_src    = 1'b0;
        reg_write  = 1'b1;
        wb_sel     = WB_ALU;
        
        case (funct3)
          3'b000: alu_op = (funct7[5]) ? ALU_SUB : ALU_ADD;
          3'b111: alu_op = ALU_AND;
          3'b110: alu_op = ALU_OR;
          3'b100: alu_op = ALU_XOR;
          3'b010: alu_op = ALU_SLT;
          3'b011: alu_op = ALU_SLTU;
          3'b001: alu_op = ALU_SLL;
          3'b101: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
          default: alu_op = ALU_NOP;
        endcase
      end

      OPC_I_ALU: begin
        alu_src    = 1'b1;
        reg_write  = 1'b1;
        wb_sel     = WB_ALU;
        
        case (funct3)
          3'b000: alu_op = ALU_ADD;
          3'b111: alu_op = ALU_AND;
          3'b110: alu_op = ALU_OR;
          3'b100: alu_op = ALU_XOR;
          3'b010: alu_op = ALU_SLT;
          3'b011: alu_op = ALU_SLTU;
          3'b001: alu_op = ALU_SLL;
          3'b101: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;
          default: alu_op = ALU_NOP;
        endcase
      end

      OPC_LOAD: begin
        alu_src    = 1'b1;
        reg_write  = 1'b1;
        mem_read   = 1'b1;
        mem_to_reg = 1'b1;
        alu_op     = ALU_ADD;
        wb_sel     = WB_MEM;
        
        // Decode load width and signedness from funct3
        case (funct3)
          3'b000: begin mem_width = 2'b00; mem_signed = 1'b1; end  // lb
          3'b001: begin mem_width = 2'b01; mem_signed = 1'b1; end  // lh
          3'b010: begin mem_width = 2'b10; mem_signed = 1'b0; end  // lw
          3'b100: begin mem_width = 2'b00; mem_signed = 1'b0; end  // lbu
          3'b101: begin mem_width = 2'b01; mem_signed = 1'b0; end  // lhu
          default: begin mem_width = 2'b10; mem_signed = 1'b0; end
        endcase
      end

      OPC_STORE: begin
        alu_src    = 1'b1;
        mem_write  = 1'b1;
        alu_op     = ALU_ADD;
        
        // Decode store width from funct3
        case (funct3)
          3'b000: mem_width = 2'b00;  // sb
          3'b001: mem_width = 2'b01;  // sh
          3'b010: mem_width = 2'b10;  // sw
          default: mem_width = 2'b10;
        endcase
      end

      OPC_BRANCH: begin
        branch     = 1'b1;
        alu_src    = 1'b0;
        alu_op     = ALU_SUB;
        
        case (funct3)
          3'b000: branch_type = BR_BEQ;
          3'b001: branch_type = BR_BNE;
          3'b100: branch_type = BR_BLT;
          3'b111: branch_type = BR_BLTU;
          default: branch_type = BR_BEQ;
        endcase
      end

      OPC_LUI: begin
        alu_src    = 1'b1;
        reg_write  = 1'b1;
        alu_op     = ALU_ADD;  // ALU adds 0 + imm
        wb_sel     = WB_ALU;
      end

      OPC_AUIPC: begin
        alu_src    = 1'b1;
        reg_write  = 1'b1;
        alu_op     = ALU_ADD;  // ALU adds PC + imm
        wb_sel     = WB_ALU;
      end

      OPC_JAL: begin
        jump       = 1'b1;
        reg_write  = 1'b1;
        alu_op     = ALU_ADD;
        wb_sel     = WB_PC4;  // rd = PC+4
      end

      OPC_JALR: begin
        jump       = 1'b1;
        reg_write  = 1'b1;
        alu_src    = 1'b1;
        alu_op     = ALU_ADD;
        wb_sel     = WB_PC4;  // rd = PC+4
      end

      default: begin
        alu_op = ALU_NOP;
      end
    endcase
  end

endmodule