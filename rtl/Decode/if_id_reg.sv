// if_id_reg.sv
// IF -> ID pipeline register
// Latches instruction and PC from fetch stage to decode stage
`timescale 1ns/1ps

module if_id_reg #(
  parameter logic [31:0] RESET_PC = 32'h0000_1000,
  parameter logic [31:0] NOP_INSTR = 32'h0000_0013  // addi x0, x0, 0
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        stall_id,     // when high, hold current values
  input  logic        flush_id,     // when high, inject NOP

  // inputs from IF stage
  input  logic [31:0] if_pc,
  input  logic [31:0] if_pc_plus4,
  input  logic [31:0] if_instruction,

  // outputs to ID stage
  output logic [31:0] id_pc,
  output logic [31:0] id_pc_plus4,
  output logic [31:0] id_instr
);

  // Internal registers
  logic [31:0] pc_r;
  logic [31:0] pc_plus4_r;
  logic [31:0] instr_r;

  always_ff @(posedge clk) begin
    if (rst) begin
      pc_r       <= RESET_PC;
      pc_plus4_r <= RESET_PC + 32'd4;
      instr_r    <= NOP_INSTR;
    end else begin
      if (stall_id) begin
        // Hold current values (do nothing)
      end else if (flush_id) begin
        // Inject NOP (bubble in pipeline)
        pc_r       <= if_pc;
        pc_plus4_r <= if_pc_plus4;
        instr_r    <= NOP_INSTR;
      end else begin
        // Normal capture
        pc_r       <= if_pc;
        pc_plus4_r <= if_pc_plus4;
        instr_r    <= if_instruction;
      end
    end
  end

  // Outputs
  assign id_pc       = pc_r;
  assign id_pc_plus4 = pc_plus4_r;
  assign id_instr    = instr_r;

endmodule