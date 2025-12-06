// control_bundle_pack.sv
// Packs control signals into 16-bit bundle
// UPDATED: Now 17 bits to include pc_to_alu signal

`timescale 1ns/1ps

module control_bundle_pack (
  // Individual control signals from control_unit_enhanced
  input  logic [3:0] alu_op,
  input  logic       alu_src,
  input  logic       reg_write,
  input  logic       mem_read,
  input  logic       mem_write,
  input  logic       mem_to_reg,
  input  logic       branch,
  input  logic [1:0] branch_type,
  input  logic       jump,
  
  // Additional signals needed for mem stage
  input  logic [1:0] mem_width,
  input  logic       mem_signed,
  input  logic [1:0] wb_sel,
  input  logic       pc_to_alu,  // NEW
  
  // Packed 16-bit control bundle output
  output logic [15:0] ctrl_bundle
);

  // Control bundle bit mapping (16 bits):
  // bit 0: reg_write
  // bits [2:1]: wb_sel (00=ALU, 01=MEM, 10=PC+4, 11=IMM)
  // bit 3: alu_src
  // bits [7:4]: alu_op
  // bit 8: mem_read
  // bit 9: mem_write
  // bits [11:10]: mem_width
  // bit 12: mem_signed
  // bit 13: branch
  // bit 14: jump (NEW - was unused)
  // bit 15: pc_to_alu (NEW)

  assign ctrl_bundle = {
    pc_to_alu,      // [15]
    jump,           // [14]
    branch,         // [13]
    mem_signed,     // [12]
    mem_width,      // [11:10]
    mem_write,      // [9]
    mem_read,       // [8]
    alu_op,         // [7:4]
    alu_src,        // [3]
    wb_sel,         // [2:1]
    reg_write       // [0]
  };

endmodule