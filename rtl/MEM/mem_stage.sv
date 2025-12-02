// mem_stage.sv
// Memory stage: accepts EX->MEM pipeline outputs, performs loads/stores
// (byte/half/word, sign-extend), and prepares values for WB.
// Matches control-bundle mapping used elsewhere (example 16-bit layout).
`timescale 1ns/1ps

module mem_stage #(
  parameter CTRL_W = 16
) (
  input  logic          clk,
  input  logic          rst,

  // inputs from EX/EX_MEM
  input  logic [31:0]   mem_in_alu_result,
  input  logic [31:0]   mem_in_rs2_for_store,
  input  logic [4:0]    mem_in_rd,
  input  logic [CTRL_W-1:0] mem_in_ctrl,
  input  logic          mem_in_branch_taken,
  input  logic [31:0]   mem_in_branch_target,
  input  logic [31:0]   mem_in_pc_plus4,
  input  logic [31:0]   mem_in_inst,
  input  logic          mem_in_valid,

  // Data memory interface (connect to your data memory model)
  output logic [31:0]   mem_addr,
  output logic [31:0]   mem_wdata,
  output logic          mem_read,
  output logic          mem_write,
  output logic [1:0]    mem_width,   // 00=byte,01=half,10=word
  output logic          mem_signed,  // passed to mem model (for info)
  input  logic [31:0]   mem_rdata,
  input  logic          mem_ready,   // optional ready (not used in simple model)

  // Outputs to WB (to be latched in mem_wb_reg)
  output logic [4:0]    wb_out_rd,
  output logic [31:0]   wb_out_wdata,
  output logic [CTRL_W-1:0] wb_out_ctrl,
  output logic [31:0]   wb_out_pc_plus4,
  output logic [31:0]   wb_out_inst,
  output logic          wb_out_valid,

  // Branch signals to control unit (pass-through)
  output logic          mem_branch_taken,
  output logic [31:0]   mem_branch_target
);

 
  // Unpack control bundle (same layout used in EX stage)
  // bit 0: reg_write
  // bits [2:1]: wb_sel  (00=ALU,01=MEM,10=PC+4,11=IMM/ALU)
  // bit 3: alu_src
  // bits [7:4]: alu_op
  // bit 8: mem_read
  // bit 9: mem_write
  // bits [11:10]: mem_width (00=byte,01=half,10=word)
  // bit 12: mem_signed (for loads)
  // bit 13: branch
  // bits [15:14]: branch_type
  logic        ctrl_reg_write;
  logic [1:0]  ctrl_wb_sel;
  logic        ctrl_alu_src;
  logic [3:0]  ctrl_alu_op;
  logic        ctrl_mem_read;
  logic        ctrl_mem_write;
  logic [1:0]  ctrl_mem_width;
  logic        ctrl_mem_signed;
  logic        ctrl_branch;
  logic [1:0]  ctrl_branch_type;

  always_comb begin
    ctrl_reg_write   = mem_in_ctrl[0];
    ctrl_wb_sel      = mem_in_ctrl[2:1];
    ctrl_alu_src     = mem_in_ctrl[3];
    ctrl_alu_op      = mem_in_ctrl[7:4];
    ctrl_mem_read    = mem_in_ctrl[8];
    ctrl_mem_write   = mem_in_ctrl[9];
    ctrl_mem_width   = mem_in_ctrl[11:10];
    ctrl_mem_signed  = mem_in_ctrl[12];
    ctrl_branch      = mem_in_ctrl[13];
    ctrl_branch_type = mem_in_ctrl[15:14];
  end

  
  // Drive memory request signals (combinational)
  assign mem_addr   = mem_in_alu_result;
  assign mem_wdata  = mem_in_rs2_for_store;
  assign mem_read   = ctrl_mem_read;
  assign mem_write  = ctrl_mem_write;
  assign mem_width  = ctrl_mem_width;
  assign mem_signed = ctrl_mem_signed;

  
  // Extract byte/half/word from mem_rdata according to address low bits.
  // mem_rdata is the 32-bit word returned from data memory (aligned read).
  // We use the address low bits to select the correct byte/half within the word.
  logic [1:0]  addr_lo;
  logic [7:0]  byte_sel;
  logic [15:0] half_sel;
  logic [31:0] load_unsigned;
  logic [31:0] load_signed;

  assign addr_lo = mem_in_alu_result[1:0];

  // select byte
  always_comb begin
    unique case (addr_lo)
      2'b00: byte_sel = mem_rdata[7:0];
      2'b01: byte_sel = mem_rdata[15:8];
      2'b10: byte_sel = mem_rdata[23:16];
      2'b11: byte_sel = mem_rdata[31:24];
      default: byte_sel = mem_rdata[7:0];
    endcase
  end

  // select halfword (address bit 1 selects lower/upper half)
  always_comb begin
    if (addr_lo[1] == 1'b0)
      half_sel = mem_rdata[15:0];
    else
      half_sel = mem_rdata[31:16];
  end

  // unsigned zero-extend candidates
  assign load_unsigned = (ctrl_mem_width == 2'b00) ? {24'd0, byte_sel} :
                         (ctrl_mem_width == 2'b01) ? {16'd0, half_sel} :
                         /*word*/                      mem_rdata;

  // signed extend candidates
  // for byte and half we extend from their msb
  always_comb begin
    unique case (ctrl_mem_width)
      2'b00: begin // byte
        load_signed = {{24{byte_sel[7]}}, byte_sel};
      end
      2'b01: begin // half
        load_signed = {{16{half_sel[15]}}, half_sel};
      end
      2'b10: begin // word
        load_signed = mem_rdata;
      end
      default: begin
        load_signed = mem_rdata;
      end
    endcase
  end

  // final load_result depending on signed/unsigned selection
  logic [31:0] load_result;
  always_comb begin
    if (ctrl_mem_read) begin
      if (ctrl_mem_signed)
        load_result = load_signed;
      else
        load_result = load_unsigned;
    end else begin
      load_result = 32'd0;
    end
  end

  
  // Prepare writeback candidate according to wb_sel:
  // 00 = ALU result
  // 01 = MEM (load_result)
  // 10 = PC+4
  // 11 = IMM/ALU (we treat as ALU result; LUI can be implemented by ALU producing the immediate)
  logic [31:0] wb_candidate;

  always_comb begin
    unique case (ctrl_wb_sel)
      2'b00: wb_candidate = mem_in_alu_result; // ALU
      2'b01: wb_candidate = load_result;       // MEM
      2'b10: wb_candidate = mem_in_pc_plus4;   // PC+4 (JAL/JALR)
      2'b11: wb_candidate = mem_in_alu_result; // IMM or ALU-passed immediate (LUI handled by ALU upstream)
      default: wb_candidate = mem_in_alu_result;
    endcase
  end

 
  // Outputs to WB (to be latched by MEM/WB register)
  assign wb_out_rd        = mem_in_rd;
  assign wb_out_wdata     = wb_candidate;
  assign wb_out_ctrl      = mem_in_ctrl;
  assign wb_out_pc_plus4  = mem_in_pc_plus4;
  assign wb_out_inst      = mem_in_inst;
  assign wb_out_valid     = mem_in_valid;

  // pass branch info upwards
  assign mem_branch_taken = mem_in_branch_taken;
  assign mem_branch_target = mem_in_branch_target;

endmodule
