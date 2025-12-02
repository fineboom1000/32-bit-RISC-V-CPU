// data_mem.sv
// Simple byte-addressable data memory model.
// - Little-endian
// - Byte/half/word accesses supported
// - Writes performed combinationally on rising edge when mem_write asserted
// - Reads return assembled 32-bit word (combinational from storage)
// - mem_ready asserted always (combinational model)

`timescale 1ns/1ps

module data_mem #(
  parameter ADDR_WIDTH = 16  // address bits (byte-addressable); default 64KiB
) (
  input  logic          clk,
  input  logic          rst,

  // simple memory interface
  input  logic [31:0]   mem_addr,     // byte address
  input  logic [31:0]   mem_wdata,    // write data (word)
  input  logic          mem_read,     // read enable
  input  logic          mem_write,    // write enable
  input  logic [1:0]    mem_width,    // 00=byte,01=half,10=word
  input  logic          mem_signed,   // unused here (WB handles sign-ext)
  output logic [31:0]   mem_rdata,
  output logic          mem_ready
);

  localparam integer MEM_BYTES = 1 << ADDR_WIDTH;

  // Byte-addressable memory array
  logic [7:0] mem_array [0:MEM_BYTES-1];

  // Align base address to word boundary for word/half accesses when reading/writing
  logic [31:0] base_addr;
  logic [1:0]  addr_lo;

  assign base_addr = { mem_addr[31:2], 2'b00 }; // word-aligned base
  assign addr_lo = mem_addr[1:0];

  // Read logic (combinational)
  // Assemble 4 bytes little-endian from mem_array[base + 0..3]
  logic [7:0] b0, b1, b2, b3;
  always_comb begin
    // default to zero if address out of range
    if ((base_addr + 32'd3) < MEM_BYTES) begin
      b0 = mem_array[base_addr + 0];
      b1 = mem_array[base_addr + 1];
      b2 = mem_array[base_addr + 2];
      b3 = mem_array[base_addr + 3];
    end else begin
      b0 = 8'd0; b1 = 8'd0; b2 = 8'd0; b3 = 8'd0;
    end
  end

  // mem_rdata is the assembled word; higher-level code will select bytes/halves as needed
  assign mem_rdata = { b3, b2, b1, b0 };

  // Write logic (synchronous on rising edge)
  // Compute byte enables according to mem_width and addr_lo
  always_ff @(posedge clk) begin
    if (rst) begin
      // optional: clear memory to zero (expensive for large mem); do nothing
    end else begin
      if (mem_write) begin
        unique case (mem_width)
          2'b10: begin // word write: write 4 bytes starting at base
            if ((base_addr + 32'd3) < MEM_BYTES) begin
              mem_array[base_addr + 0] <= mem_wdata[7:0];
              mem_array[base_addr + 1] <= mem_wdata[15:8];
              mem_array[base_addr + 2] <= mem_wdata[23:16];
              mem_array[base_addr + 3] <= mem_wdata[31:24];
            end
          end
          2'b01: begin // half write: writes two bytes at addr_lo[1] half boundary
            if ((base_addr + addr_lo[1]*2 + 1) < MEM_BYTES) begin
              // addr_lo[1] selects lower or upper half of the word
              mem_array[base_addr + (addr_lo[1] ? 2 : 0) + 0] <= mem_wdata[7:0];
              mem_array[base_addr + (addr_lo[1] ? 2 : 0) + 1] <= mem_wdata[15:8];
            end
          end
          2'b00: begin // byte write: write single byte at offset addr_lo
            if ((base_addr + addr_lo) < MEM_BYTES) begin
              mem_array[base_addr + addr_lo] <= mem_wdata[7:0];
            end
          end
          default: begin
            // treat as word write
            if ((base_addr + 32'd3) < MEM_BYTES) begin
              mem_array[base_addr + 0] <= mem_wdata[7:0];
              mem_array[base_addr + 1] <= mem_wdata[15:8];
              mem_array[base_addr + 2] <= mem_wdata[23:16];
              mem_array[base_addr + 3] <= mem_wdata[31:24];
            end
          end
        endcase
      end
    end
  end

  // mem_ready is always asserted in this simple model
  assign mem_ready = 1'b1;

endmodule
