// alu_op_enum.svh
// ALU operation encodings (OP_WIDTH = 4)
`ifndef ALU_OP_ENUM_SVH
`define ALU_OP_ENUM_SVH

// 4-bit ALU opcodes
localparam logic [3:0] ALU_ADD     = 4'd0;
localparam logic [3:0] ALU_SUB     = 4'd1;
localparam logic [3:0] ALU_AND     = 4'd2;
localparam logic [3:0] ALU_OR      = 4'd3;
localparam logic [3:0] ALU_XOR     = 4'd4;
localparam logic [3:0] ALU_SLT     = 4'd5;
localparam logic [3:0] ALU_SLTU    = 4'd6;
localparam logic [3:0] ALU_SLL     = 4'd7;
localparam logic [3:0] ALU_SRL     = 4'd8;
localparam logic [3:0] ALU_SRA     = 4'd9;
localparam logic [3:0] ALU_COPY_A  = 4'd10;
localparam logic [3:0] ALU_PC_ADD  = 4'd11;

`endif // ALU_OP_ENUM_SVH
