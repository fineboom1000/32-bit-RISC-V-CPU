
// Thin wiring module: connect your existing PC output to IMEM and expose signals to decode.
// Please see the RTL page on ISA notes
// There you will see my understanding of everything.


// This is a wrapper used for wiring,
// and is responsible for nothing else but wiring.



`timescale 1ns/1ps

module fetch_wiring #(
    // for flexiblitity
    parameter logic [31:0] ROM_BASE = 32'h00001000,
    parameter string IMEM_FILE = "imem.hex",
    parameter int IMEM_WORDS = 4096,
    parameter bit IMEM_SYNC = 1
) (
    input  logic        clk,
    input  logic        imem_read_en,   // tie high ... no use for enable.
    input  logic [31:0] pc_current,     // connect to PC register output
    input  logic [31:0] pc_plus4,       // connect to existing PC+4 adder output

    // branch logic remains external; this module only performs fetch/read
    output logic [31:0] if_pc,          // forwarded PC for decode
    output logic [31:0] if_pc_plus4,    // forwarded PC+4 for decode
    output logic [31:0] if_instruction  // instruction read from IMEM 
    // note sync should make this 1 cycle late if sync is active high.

);

    // instantiate IMEM 
    imem #(
        .MEMFILE(IMEM_FILE),
        .ROM_BASE(ROM_BASE),
        .WORDS(IMEM_WORDS),
        .SYNC(IMEM_SYNC)
    ) imem_inst (
        .clk(clk),
        .read_en(imem_read_en),
        .addr(pc_current),
        .instruction(if_instruction)
    );

    // pass-throughs to decode stage
    assign if_pc = pc_current;
    assign if_pc_plus4 = pc_plus4;

endmodule
