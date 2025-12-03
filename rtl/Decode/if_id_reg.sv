



`timescale 1ns/1ps

module if_id_reg #(
  parameter logic [31:0] RESET_PC   = 32'h0000_1000, //  reset PC value (match PC_reg RESET_VECTOR)
  parameter logic [31:0] NOP_INSTR  = 32'h0000_0013  // addi x0,x0,0 (RV32I NOP) = 0x00000013
) (
  input  logic         clk,
  input  logic         rst,         // synchronous reset (active high)
  input  logic         stall_id,    // when high: hold the current IF/ID contents
  input  logic         flush_id,    // when high: inject a NOP into ID (KILL instruction)

// discussed in my ISA notes doc, see Notion.
  input  logic [31:0]  if_pc,
  input  logic [31:0]  if_pc_plus4,
  input  logic [31:0]  if_instruction,

// discussed in my ISA notes doc, see Notion.
  output logic [31:0]  id_pc,
  output logic [31:0]  id_pc_plus4,
  output logic [31:0]  id_instr
);

  // discussed in my ISA notes doc, see Notion.
  logic [31:0] id_pc_r;
  logic [31:0] id_pc_plus4_r;
  logic [31:0] id_instr_r;

  // synchronous pipeline behaviour
  always_ff @(posedge clk) begin
    if (rst) begin
      // on reset: choose safe defaults
      id_pc_r       <= RESET_PC;    // align with PC reset vector (see PC_reg). 
      id_pc_plus4_r <= RESET_PC + 32'd4;
      id_instr_r    <= NOP_INSTR;   // NOP (addi x0,x0,0) (this is a choice in my docs! Not needed)
    end else begin
      if (stall_id) begin
        // hold previous values do nothing 
        id_pc_r       <= id_pc_r;
        id_pc_plus4_r <= id_pc_plus4_r;
        id_instr_r    <= id_instr_r;
      end else if (flush_id) begin
        // inject NOP: kill this slot
        id_pc_r       <= if_pc;         // optional: keep the PC for debug, or set to 0
        id_pc_plus4_r <= if_pc_plus4;   // useful for debug/tracing
        id_instr_r    <= NOP_INSTR;     // kill the instruction in ID stage
      end else begin
        // normal update: accept the values coming from fetch
        id_pc_r       <= if_pc;
        id_pc_plus4_r <= if_pc_plus4;
        id_instr_r    <= if_instruction;
      end
    end
  end

  // drive outputs discussed in my ISA notes doc, see Notion.
  assign id_pc       = id_pc_r;
  assign id_pc_plus4 = id_pc_plus4_r;
  assign id_instr    = id_instr_r;

endmodule
