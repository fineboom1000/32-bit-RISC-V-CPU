/* pc_reg.sv


if I new the synatx it would be like

define PC reg's inputs and outputs first

those would be PC_next, Pc_curr

then I define an alway_ff block
 that willl have two input signals 

 one is the clk and the other is synch reset—synch since 
 the pC is ran by a clk and also since we are dealing with a reg file

 I know that I just do  a priotru nextowrk so that means the 
 if (reset) if first
 then the other clk.

 I will try to code now



as per the book
we keep memory and combo seperate as to 
easily understand the HW, I will follow that practice.


*/
`timescale 1ns/1ps

module pc_reg #(
  parameter logic [31:0] RESET_VECTOR = 32'h0000_1000
) (
  input  logic        clk,
  input  logic        rst,
  input  logic        stall,        // when high, hold PC (don't advance)
  input  logic [31:0] pc_next,      // next PC value (from pc_mux)
  output logic [31:0] pc_current    // current PC value
);

  always_ff @(posedge clk) begin
    if (rst) begin
      pc_current <= RESET_VECTOR;
    end else if (!stall) begin
      pc_current <= pc_next;
    end
    // if stall, hold current value (do nothing)
  end

endmodule

