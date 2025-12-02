/*


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

module PC_reg 
#( parameter logic [31:0] RESET_VECTOR = 32'h0000_1000 // ROM_ORGIN, if I put that in can the linker script see it.


)

(
    input logic clk, rst,
    input logic[31:0] pc_next,
    output logic[31:0] pc_curr
);

always_ff @(posedge clk) begin
    if (rst) begin
        pc_curr <= RESET_VECTOR;
    end else begin
        pc_curr <= pc_next;
    end
end
// fI learnt to use begin/end around if else blocks
// its safer and the cannonical style for regisiters.
endmodule

