// this is a simple adder meant to walk the PC
// every clk.

module pc_plus4 (
    input logic [31:0] pc_in,
    output logic [31:0] pc_out

);

assign pc_out = pc_in + 32'd4;

endmodule