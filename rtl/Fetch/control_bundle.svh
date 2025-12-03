`timescale 1ns/1ps

module control_bundle_pack (
  // Individual control signals from control_unit_min
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
  input  logic [1:0] mem_width,   // from funct3 for loads/stores
  input  logic       mem_signed,  // from funct3 for loads
  input  logic [1:0] wb_sel,      // writeback source select
  
  // Packed 16-bit control bundle output
  output logic [15:0] ctrl_bundle
);

  // Control bundle bit mapping:
  // bit 0: reg_write
  // bits [2:1]: wb_sel (00=ALU, 01=MEM, 10=PC+4, 11=reserved)
  // bit 3: alu_src
  // bits [7:4]: alu_op
  // bit 8: mem_read
  // bit 9: mem_write
  // bits [11:10]: mem_width
  // bit 12: mem_signed
  // bit 13: branch
  // bits [15:14]: branch_type

  assign ctrl_bundle = {
    branch_type,    // [15:14]
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
