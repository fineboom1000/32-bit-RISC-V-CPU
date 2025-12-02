// control_bundle.svh
// Control-bundle bit positions and helper macros for packing/unpacking.
// Uses the 16-bit layout used across the pipeline:
//
// bit 0         : ctrl_reg_write
// bits [2:1]    : ctrl_wb_sel   (00=ALU,01=MEM,10=PC+4,11=IMM/ALU)
// bit 3         : ctrl_alu_src  (0=rs2,1=imm)
// bits [7:4]    : ctrl_alu_op   (4 bits)
// bit 8         : ctrl_mem_read
// bit 9         : ctrl_mem_write
// bits [11:10]  : ctrl_mem_width (00=byte,01=half,10=word)
// bit 12        : ctrl_mem_signed
// bit 13        : ctrl_branch
// bits [15:14]  : ctrl_branch_type (00=BEQ,01=BNE,10=BLT,11=BLTU)

`ifndef CONTROL_BUNDLE_SVH
`define CONTROL_BUNDLE_SVH

// bit positions
`define CTRL_REG_WRITE_POS    0
`define CTRL_WB_SEL_LSB       1
`define CTRL_WB_SEL_MSB       2
`define CTRL_ALU_SRC_POS      3
`define CTRL_ALU_OP_LSB       4
`define CTRL_ALU_OP_MSB       7
`define CTRL_MEM_READ_POS     8
`define CTRL_MEM_WRITE_POS    9
`define CTRL_MEM_WIDTH_LSB    10
`define CTRL_MEM_WIDTH_MSB    11
`define CTRL_MEM_SIGNED_POS   12
`define CTRL_BRANCH_POS       13
`define CTRL_BRANCH_TYPE_LSB  14
`define CTRL_BRANCH_TYPE_MSB  15

// helper macros (pack fields into 16-bit control word)
// usage example:
//   `CTRL_PACK(regw, wbsel, alusrc, aluop, memr, memw, memwth, memsgn, branch, btype)
`define CTRL_PACK(regw, wbsel, alusrc, aluop, memr, memw, memwth, memsgn, branch, btype) \
  ( ({16{1'b0}}) | ((regw) << `CTRL_REG_WRITE_POS) \
    | ((wbsel) << `CTRL_WB_SEL_LSB) \
    | ((alusrc) << `CTRL_ALU_SRC_POS) \
    | ((aluop) << `CTRL_ALU_OP_LSB) \
    | ((memr) << `CTRL_MEM_READ_POS) \
    | ((memw) << `CTRL_MEM_WRITE_POS) \
    | ((memwth) << `CTRL_MEM_WIDTH_LSB) \
    | ((memsgn) << `CTRL_MEM_SIGNED_POS) \
    | ((branch) << `CTRL_BRANCH_POS) \
    | ((btype) << `CTRL_BRANCH_TYPE_LSB) )

// helper extracts
`define CTRL_GET_REG_WRITE(ctrl)    ( (ctrl)[`CTRL_REG_WRITE_POS] )
`define CTRL_GET_WB_SEL(ctrl)       ( (ctrl)[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] )
`define CTRL_GET_ALU_SRC(ctrl)      ( (ctrl)[`CTRL_ALU_SRC_POS] )
`define CTRL_GET_ALU_OP(ctrl)       ( (ctrl)[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] )
`define CTRL_GET_MEM_READ(ctrl)     ( (ctrl)[`CTRL_MEM_READ_POS] )
`define CTRL_GET_MEM_WRITE(ctrl)    ( (ctrl)[`CTRL_MEM_WRITE_POS] )
`define CTRL_GET_MEM_WIDTH(ctrl)    ( (ctrl)[`CTRL_MEM_WIDTH_MSB:`CTRL_MEM_WIDTH_LSB] )
`define CTRL_GET_MEM_SIGNED(ctrl)   ( (ctrl)[`CTRL_MEM_SIGNED_POS] )
`define CTRL_GET_BRANCH(ctrl)       ( (ctrl)[`CTRL_BRANCH_POS] )
`define CTRL_GET_BRANCH_TYPE(ctrl)  ( (ctrl)[`CTRL_BRANCH_TYPE_MSB:`CTRL_BRANCH_TYPE_LSB] )

`endif // CONTROL_BUNDLE_SVH
