// Please see the RTL page on ISA notes
// I discuss a lot of this in depth...actaully all of it.


`timescale 1ns/1ps

module imem #(
    parameter string MEMFILE   = "imem.hex",         // hex file (word-per-line) to preload ROM
    parameter logic [31:0] ROM_BASE = 32'h00001000,  // CPU address base for ROM (from linker, = ORIGIN)
    parameter int WORDS = 4096,                      // number of 32-bit words
    parameter bit SYNC = 1         
                      // 1 = synchronous read should have a delay of 1 cycle.
) (
    input  logic        clk,
    input  logic        read_en,     // when SYNC=1, sample address when asserted
    input  logic [31:0] addr,        // byte address from CPU (PC)
    output logic [31:0] instruction  // 32-bit instruction
);

    // storage
    logic [31:0] mem [0:WORDS-1];

    initial begin
        if (MEMFILE != "") begin
            $display("IMEM: loading '%s' (WORDS=%0d)", MEMFILE, WORDS);
            $readmemh(MEMFILE, mem);
        end
    end

    // compute word index (requires alignment done elsewhere).
    logic [31:0] addr_offset;
    logic [$clog2(WORDS)-1:0] word_index;
    assign addr_offset = addr - ROM_BASE;
    assign word_index  = addr_offset[31:2]; // divide by 4

    generate
        if (SYNC) begin
            // sample index on clock when read_en asserted; data available next cycle
            logic [$clog2(WORDS)-1:0] sampled_idx;
            always_ff @(posedge clk) begin
                if (read_en)
                    sampled_idx <= word_index;
                instruction <= mem[sampled_idx];
            end
        end else begin
            // combinational: immediate read
            // I intedn this is only for small ROMs and sims, please see the ISA notes page where I discuss this choice in depth.
            always_comb begin
                instruction = mem[word_index];
            end
        end
    endgenerate

endmodule
