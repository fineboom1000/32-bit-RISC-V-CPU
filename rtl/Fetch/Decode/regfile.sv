// regfile.sv
`timescale 1ns/1ps

module regfile (
  input  logic        clk,
  input  logic        rst,
  input  logic        wen,      // write enable (from WB)
  input  logic [4:0]  waddr,
  input  logic [31:0] wdata,
  input  logic [4:0]  raddr1,
  input  logic [4:0]  raddr2,
  output logic [31:0] rdata1,
  output logic [31:0] rdata2
);

  logic [31:0] regs [31];

  integer i;
  always_ff @(posedge clk) begin
    if (rst) begin
      regs[0] <= 32'd0;
      for (i = 1; i < 32; i = i + 1) regs[i] <= 32'd0;
      // optionally set sp (x2) here if you want: regs[2] <= 32'h2000_0000;
    end else begin
      if (wen && (waddr != 5'd0)) regs[waddr] <= wdata; // writes to x0 ignored
      regs[0] <= 32'd0; // enforce x0==0
    end
  end

  // combinational reads (simple, no extra latency)
  assign rdata1 = (raddr1 == 5'd0) ? 32'd0 : regs[raddr1];
  assign rdata2 = (raddr2 == 5'd0) ? 32'd0 : regs[raddr2];

endmodule
