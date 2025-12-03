// mem_stage.sv
// Memory access stage: unpacks control, drives data memory,
// performs load sign/zero extension, selects writeback data
`timescale 1ns/1ps

module mem_stage #(
  parameter CTRL_W = 16
) (
  input  logic          clk,
  input  logic          rst,

  // inputs from EX/MEM register
  input  logic [31:0]   mem_in_alu_result,
  input  logic [31:0]   mem_in_rs2_for_store,
  input  logic [4:0]    mem_in_rd,
  input  logic [CTRL_W-1:0] mem_in_ctrl,
  input  logic          mem_in_branch_taken,
  input  logic [31:0]   mem_in_branch_target,
  input  logic [31:0]   mem_in_pc_plus4,
  input  logic [31:0]   mem_in_inst,
  input  logic          mem_in_valid,

  // data memory interface (connects to data_mem.sv)
  output logic [31:0]   mem_addr,
  output logic [31:0]   mem_wdata,
  output logic          mem_read,
  output logic          mem_write,
  output logic [1:0]    mem_width,
  output logic          mem_signed,
  input  logic [31:0]   mem_rdata,
  input  logic          mem_ready,

  // outputs to MEM/WB register
  output logic [4:0]    wb_out_rd,
  output logic [31:0]   wb_out_wdata,
  output logic [CTRL_W-1:0] wb_out_ctrl,
  output logic [31:0]   wb_out_pc_plus4,
  output logic [31:0]   wb_out_inst,
  output logic          wb_out_valid,

  // branch/jump outputs (back to IF stage via cpu_top)
  output logic          mem_branch_taken,
  output logic [31:0]   mem_branch_target
);

 
  // Unpack control bundle (same bit layout as control_bundle_pack.svh)
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

  
  logic        ctrl_reg_write;
  logic [1:0]  ctrl_wb_sel;
  logic        ctrl_mem_read;
  logic        ctrl_mem_write;
  logic [1:0]  ctrl_mem_width;
  logic        ctrl_mem_signed;

  always_comb begin
    ctrl_reg_write  = mem_in_ctrl[0];
    ctrl_wb_sel     = mem_in_ctrl[2:1];
    ctrl_mem_read   = mem_in_ctrl[8];
    ctrl_mem_write  = mem_in_ctrl[9];
    ctrl_mem_width  = mem_in_ctrl[11:10];
    ctrl_mem_signed = mem_in_ctrl[12];
  end

  
  // Drive data memory interface

  
  assign mem_addr   = mem_in_alu_result;      // Address from ALU (base + offset)
  assign mem_wdata  = mem_in_rs2_for_store;   // Store data (forwarded rs2)
  assign mem_read   = ctrl_mem_read;
  assign mem_write  = ctrl_mem_write;
  assign mem_width  = ctrl_mem_width;
  assign mem_signed = ctrl_mem_signed;


  // Load data processing: sign/zero extension
  // data_mem.sv returns full 32-bit word, we extract byte/half as needed

  
  logic [31:0] load_data_processed;
  logic [1:0]  byte_offset;
  
  assign byte_offset = mem_addr[1:0];

  always_comb begin
    load_data_processed = mem_rdata;  // default: word load
    
    if (ctrl_mem_read) begin
      case (ctrl_mem_width)
        2'b00: begin  // LB/LBU (byte)
          case (byte_offset)
            2'b00: load_data_processed = ctrl_mem_signed ? 
                   {{24{mem_rdata[7]}}, mem_rdata[7:0]} : 
                   {24'b0, mem_rdata[7:0]};
            2'b01: load_data_processed = ctrl_mem_signed ? 
                   {{24{mem_rdata[15]}}, mem_rdata[15:8]} : 
                   {24'b0, mem_rdata[15:8]};
            2'b10: load_data_processed = ctrl_mem_signed ? 
                   {{24{mem_rdata[23]}}, mem_rdata[23:16]} : 
                   {24'b0, mem_rdata[23:16]};
            2'b11: load_data_processed = ctrl_mem_signed ? 
                   {{24{mem_rdata[31]}}, mem_rdata[31:24]} : 
                   {24'b0, mem_rdata[31:24]};
          endcase
        end
        
        2'b01: begin  // LH/LHU (halfword)
          if (byte_offset[1]) begin  // upper half (bytes 2-3)
            load_data_processed = ctrl_mem_signed ? 
                   {{16{mem_rdata[31]}}, mem_rdata[31:16]} : 
                   {16'b0, mem_rdata[31:16]};
          end else begin  // lower half (bytes 0-1)
            load_data_processed = ctrl_mem_signed ? 
                   {{16{mem_rdata[15]}}, mem_rdata[15:0]} : 
                   {16'b0, mem_rdata[15:0]};
          end
        end
        
        2'b10: begin  // LW (word)
          load_data_processed = mem_rdata;
        end
        
        default: load_data_processed = mem_rdata;
      endcase
    end
  end


  // Writeback data selection based on wb_sel
  // 00 = ALU result (arithmetic, logic, addresses for LUI/AUIPC)
  // 01 = Memory data (loads)
  // 10 = PC+4 (JAL/JALR return address)
  // 11 = Reserved (could be used for immediate passthrough if needed)
 
  
  logic [31:0] wb_data_selected;
  
  always_comb begin
    case (ctrl_wb_sel)
      2'b00:   wb_data_selected = mem_in_alu_result;
      2'b01:   wb_data_selected = load_data_processed;
      2'b10:   wb_data_selected = mem_in_pc_plus4;
      2'b11:   wb_data_selected = mem_in_alu_result;  // fallback
      default: wb_data_selected = mem_in_alu_result;
    endcase
  end


  
  assign wb_out_rd        = mem_in_rd;
  assign wb_out_wdata     = wb_data_selected;
  assign wb_out_ctrl      = mem_in_ctrl;
  assign wb_out_pc_plus4  = mem_in_pc_plus4;
  assign wb_out_inst      = mem_in_inst;
  assign wb_out_valid     = mem_in_valid;


  
  assign mem_branch_taken  = mem_in_branch_taken;
  assign mem_branch_target = mem_in_branch_target;

endmodule