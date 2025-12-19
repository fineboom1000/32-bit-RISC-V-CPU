// cpu_top.sv modified for fpga synthesis
// fixed removed internal data_mem instance
// data memory now handled externally in arty_s7_top
`timescale 1ns/1ps

module cpu_top #(
  parameter CTRL_W = 16,
  parameter logic [31:0] ROM_BASE = 32'h0000_1000,
  parameter logic [31:0] RAM_BASE = 32'h2000_0000,
  parameter int IMEM_WORDS = 4096,
  parameter int DMEM_ADDR_WIDTH = 14
) (
  input  logic clk,
  input  logic rst,
  
  // expose data memory interface for external ram and gpio
  output logic [31:0] dmem_addr_out,
  output logic [31:0] dmem_wdata_out,
  output logic        dmem_read_out,
  output logic        dmem_write_out,
  output logic [1:0]  dmem_width_out,
  output logic        dmem_signed_out,
  input  logic [31:0] dmem_rdata_in,
  input  logic        dmem_ready_in
);

  // if stage signals
  logic [31:0] pc_current;
  logic [31:0] pc_next;
  logic [31:0] pc_plus4_out;
  logic [31:0] if_pc;
  logic [31:0] if_pc_plus4;
  logic [31:0] if_instruction;
  
  logic        mem_branch_taken;
  logic [31:0] mem_branch_target;
  
  logic        stall_if, stall_id;
  logic        flush_if, flush_id, flush_ex;
  
  pc_plus4 pc_adder (
    .pc_in  (pc_current),
    .pc_out (pc_plus4_out)
  );
  
  pc_mux pc_mux_inst (
    .pc_plus4      (pc_plus4_out),
    .branch_target (mem_branch_target),
    .pc_src        (mem_branch_taken),
    .pc_next       (pc_next)
  );
  
  pc_reg #(
    .RESET_VECTOR(ROM_BASE)
  ) pc_register (
    .clk        (clk),
    .rst        (rst),
    .stall      (stall_if),
    .pc_next    (pc_next),
    .pc_current (pc_current)
  );
  
  fetch_wiring #(
    .ROM_BASE   (ROM_BASE),
    .IMEM_WORDS (IMEM_WORDS),
    .IMEM_SYNC  (0)
  ) fetch (
    .clk            (clk),
    .imem_read_en   (1'b1),
    .pc_current     (pc_current),
    .pc_plus4       (pc_plus4_out),
    .if_pc          (if_pc),
    .if_pc_plus4    (if_pc_plus4),
    .if_instruction (if_instruction)
  );
  
  // if id pipeline register
  logic [31:0] id_pc;
  logic [31:0] id_pc_plus4;
  logic [31:0] id_instr;
  
  if_id_reg #(
    .RESET_PC  (ROM_BASE),
    .NOP_INSTR (32'h0000_0013)
  ) if_id (
    .clk            (clk),
    .rst            (rst),
    .stall_id       (stall_id),
    .flush_id       (flush_id),
    .if_pc          (if_pc),
    .if_pc_plus4    (if_pc_plus4),
    .if_instruction (if_instruction),
    .id_pc          (id_pc),
    .id_pc_plus4    (id_pc_plus4),
    .id_instr       (id_instr)
  );

  // id stage signals
  logic [4:0]  rf_raddr1, rf_raddr2;
  logic [31:0] rf_rdata1, rf_rdata2;
  logic        rf_wen;
  logic [4:0]  rf_waddr;
  logic [31:0] rf_wdata;
  
  logic [31:0] idex_pc;
  logic [31:0] idex_pc_plus4;
  logic [31:0] idex_rs1_val;
  logic [31:0] idex_rs2_val;
  logic [31:0] idex_imm;
  logic [4:0]  idex_rs1;
  logic [4:0]  idex_rs2;
  logic [4:0]  idex_rd;
  logic [31:0] idex_instr;
  logic [CTRL_W-1:0] idex_ctrl;
  
  regfile regfile_inst (
    .clk    (clk),
    .rst    (rst),
    .wen    (rf_wen),
    .waddr  (rf_waddr),
    .wdata  (rf_wdata),
    .raddr1 (rf_raddr1),
    .raddr2 (rf_raddr2),
    .rdata1 (rf_rdata1),
    .rdata2 (rf_rdata2)
  );
  
  decode #(
    .CTRL_W(CTRL_W)
  ) decode_stage (
    .clk         (clk),
    .rst         (rst),
    .stall_id    (stall_id),
    .flush_id    (flush_ex),
    
    .id_instr    (id_instr),
    .id_pc       (id_pc),
    .id_pc_plus4 (id_pc_plus4),
    
    .rf_raddr1   (rf_raddr1),
    .rf_raddr2   (rf_raddr2),
    .rf_rdata1   (rf_rdata1),
    .rf_rdata2   (rf_rdata2),
    
    .wb_wen      (rf_wen),
    .wb_waddr    (rf_waddr),
    .wb_wdata    (rf_wdata),
    
    .idex_pc         (idex_pc),
    .idex_pc_plus4   (idex_pc_plus4),
    .idex_rs1_val    (idex_rs1_val),
    .idex_rs2_val    (idex_rs2_val),
    .idex_imm        (idex_imm),
    .idex_rs1        (idex_rs1),
    .idex_rs2        (idex_rs2),
    .idex_rd         (idex_rd),
    .idex_instr      (idex_instr),
    .idex_ctrl       (idex_ctrl)
  );

  // hazard detection unit
  logic haz_stall;
  logic haz_flush_ifid;
  logic idex_mem_read;
  logic idex_reg_write;  
  
  assign idex_mem_read = idex_ctrl[8];
  assign idex_reg_write = idex_ctrl[0];  
  
  hazard_unit hazard (
    .haz_id_rs1      (rf_raddr1),
    .haz_id_rs2      (rf_raddr2),
    .haz_ex_mem_read (idex_mem_read),
    .haz_ex_rd       (idex_rd),
    .haz_ex_reg_write(idex_reg_write), 
    .haz_stall       (haz_stall),
    .haz_flush_ifid  (haz_flush_ifid)
  );
  
  assign stall_if = haz_stall;
  assign stall_id = haz_stall;
  assign flush_if = mem_branch_taken;
  assign flush_id = mem_branch_taken;
  assign flush_ex = mem_branch_taken;

  // ex stage signals
  logic [31:0] fwd_mem_data;
  logic [4:0]  fwd_mem_rd;
  logic        fwd_mem_valid;
  logic [31:0] fwd_wb_data;
  logic [4:0]  fwd_wb_rd;
  logic        fwd_wb_valid;
  
  logic [31:0] ex_out_alu_result;
  logic [31:0] ex_out_rs2_for_store;
  logic [4:0]  ex_out_rd;
  logic [CTRL_W-1:0] ex_out_ctrl;
  logic        ex_out_branch_taken;
  logic [31:0] ex_out_branch_target;
  logic [31:0] ex_out_pc_plus4;
  logic [31:0] ex_out_inst;
  logic        ex_out_valid;
  
  ex_stage #(
    .CTRL_W(CTRL_W)
  ) execute (
    .clk               (clk),
    .rst               (rst),
    
    .ex_in_pc          (idex_pc),
    .ex_in_pc_plus4    (idex_pc_plus4),
    .ex_in_rs1_data    (idex_rs1_val),
    .ex_in_rs2_data    (idex_rs2_val),
    .ex_in_imm         (idex_imm),
    .ex_in_rs1         (idex_rs1),
    .ex_in_rs2         (idex_rs2),
    .ex_in_rd          (idex_rd),
    .ex_in_instr       (idex_instr),
    .ex_in_ctrl        (idex_ctrl),
    .ex_in_valid       (1'b1),
    
    .fwd_mem_data      (fwd_mem_data),
    .fwd_mem_rd        (fwd_mem_rd),
    .fwd_mem_valid     (fwd_mem_valid),
    .fwd_wb_data       (fwd_wb_data),
    .fwd_wb_rd         (fwd_wb_rd),
    .fwd_wb_valid      (fwd_wb_valid),
    
    .ex_out_alu_result     (ex_out_alu_result),
    .ex_out_rs2_for_store  (ex_out_rs2_for_store),
    .ex_out_rd             (ex_out_rd),
    .ex_out_ctrl           (ex_out_ctrl),
    .ex_out_branch_taken   (ex_out_branch_taken),
    .ex_out_branch_target  (ex_out_branch_target),
    .ex_out_pc_plus4       (ex_out_pc_plus4),
    .ex_out_inst           (ex_out_inst),
    .ex_out_valid          (ex_out_valid)
  );

  assign mem_branch_taken  = ex_out_branch_taken;
  assign mem_branch_target = ex_out_branch_target;

  // ex mem pipeline register
  logic [31:0] exmem_alu_result;
  logic [31:0] exmem_rs2_for_store;
  logic [4:0]  exmem_rd;
  logic [CTRL_W-1:0] exmem_ctrl;
  logic        exmem_branch_taken;
  logic [31:0] exmem_branch_target;
  logic [31:0] exmem_pc_plus4;
  logic [31:0] exmem_inst;
  logic        exmem_valid;
  
  ex_mem_reg #(
    .CTRL_W(CTRL_W)
  ) ex_mem (
    .clk                  (clk),
    .rst                  (rst),
    .stall_ex             (1'b0),
    .flush_ex             (ex_out_branch_taken),
    
    .mem_in_alu_result    (ex_out_alu_result),
    .mem_in_rs2_for_store (ex_out_rs2_for_store),
    .mem_in_rd            (ex_out_rd),
    .mem_in_ctrl          (ex_out_ctrl),
    .mem_in_branch_taken  (ex_out_branch_taken),
    .mem_in_branch_target (ex_out_branch_target),
    .mem_in_pc_plus4      (ex_out_pc_plus4),
    .mem_in_inst          (ex_out_inst),
    .mem_in_valid         (ex_out_valid),
    
    .mem_out_alu_result    (exmem_alu_result),
    .mem_out_rs2_for_store (exmem_rs2_for_store),
    .mem_out_rd            (exmem_rd),
    .mem_out_ctrl          (exmem_ctrl),
    .mem_out_branch_taken  (exmem_branch_taken),
    .mem_out_branch_target (exmem_branch_target),
    .mem_out_pc_plus4      (exmem_pc_plus4),
    .mem_out_inst          (exmem_inst),
    .mem_out_valid         (exmem_valid)
  );

  // mem stage signals
  logic [4:0]  memwb_in_rd;
  logic [31:0] memwb_in_wdata;
  logic [CTRL_W-1:0] memwb_in_ctrl;
  logic [31:0] memwb_in_pc_plus4;
  logic [31:0] memwb_in_inst;
  logic        memwb_in_valid;
  
  mem_stage #(
    .CTRL_W(CTRL_W)
  ) memory (
    .clk                  (clk),
    .rst                  (rst),
    
    .mem_in_alu_result    (exmem_alu_result),
    .mem_in_rs2_for_store (exmem_rs2_for_store),
    .mem_in_rd            (exmem_rd),
    .mem_in_ctrl          (exmem_ctrl),
    .mem_in_branch_taken  (exmem_branch_taken),
    .mem_in_branch_target (exmem_branch_target),
    .mem_in_pc_plus4      (exmem_pc_plus4),
    .mem_in_inst          (exmem_inst),
    .mem_in_valid         (exmem_valid),
    
    .mem_addr    (dmem_addr_out),
    .mem_wdata   (dmem_wdata_out),
    .mem_read    (dmem_read_out),
    .mem_write   (dmem_write_out),
    .mem_width   (dmem_width_out),
    .mem_signed  (dmem_signed_out),
    .mem_rdata   (dmem_rdata_in),
    .mem_ready   (dmem_ready_in),
    
    .wb_out_rd        (memwb_in_rd),
    .wb_out_wdata     (memwb_in_wdata),
    .wb_out_ctrl      (memwb_in_ctrl),
    .wb_out_pc_plus4  (memwb_in_pc_plus4),
    .wb_out_inst      (memwb_in_inst),
    .wb_out_valid     (memwb_in_valid),
    
    .mem_branch_taken  (),
    .mem_branch_target ()
  );

  // removed data_mem instance
  // data memory now handled externally in arty_s7_top

  // mem wb pipeline register
  logic [4:0]  memwb_rd;
  logic [31:0] memwb_wdata;
  logic [CTRL_W-1:0] memwb_ctrl;
  logic [31:0] memwb_pc_plus4;
  logic [31:0] memwb_inst;
  logic        memwb_valid;
  
  mem_wb_reg #(
    .CTRL_W(CTRL_W)
  ) mem_wb (
    .clk           (clk),
    .rst           (rst),
    .stall_mem     (1'b0),
    .flush_mem     (1'b0),
    
    .wb_in_rd      (memwb_in_rd),
    .wb_in_wdata   (memwb_in_wdata),
    .wb_in_ctrl    (memwb_in_ctrl),
    .wb_in_pc_plus4(memwb_in_pc_plus4),
    .wb_in_inst    (memwb_in_inst),
    .wb_in_valid   (memwb_in_valid),
    
    .wb_out_rd      (memwb_rd),
    .wb_out_wdata   (memwb_wdata),
    .wb_out_ctrl    (memwb_ctrl),
    .wb_out_pc_plus4(memwb_pc_plus4),
    .wb_out_inst    (memwb_inst),
    .wb_out_valid   (memwb_valid)
  );

  // wb stage
  wb_stage #(
    .CTRL_W(CTRL_W)
  ) writeback (
    .wb_in_rd     (memwb_rd),
    .wb_in_wdata  (memwb_wdata),
    .wb_in_ctrl   (memwb_ctrl),
    .wb_in_valid  (memwb_valid),
    
    .wb_reg_write (rf_wen),
    .wb_rd        (rf_waddr),
    .wb_wdata     (rf_wdata)
  );

  // forwarding unit
  logic memwb_reg_write;
  assign memwb_reg_write = memwb_ctrl[0] & memwb_valid;
  
  forward_unit forwarding (
    .mem_rd        (memwb_rd),
    .mem_wdata     (memwb_wdata),
    .mem_reg_write (memwb_reg_write),
    
    .wb_rd         (rf_waddr),
    .wb_wdata      (rf_wdata),
    .wb_reg_write  (rf_wen),
    
    .fwd_mem_data  (fwd_mem_data),
    .fwd_mem_rd    (fwd_mem_rd),
    .fwd_mem_valid (fwd_mem_valid),
    
    .fwd_wb_data   (fwd_wb_data),
    .fwd_wb_rd     (fwd_wb_rd),
    .fwd_wb_valid  (fwd_wb_valid)
  );

endmodule