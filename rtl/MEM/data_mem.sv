// data_mem.sv
// Byte-addressable data memory (little-endian)
// Supports byte/half/word accesses
`timescale 1ns/1ps

module data_mem #(
  parameter ADDR_WIDTH = 14,  // 16KB = 2^14 bytes (matches your linker RAM)
  parameter logic [31:0] RAM_BASE = 32'h2000_0000  // matches linker ORIGIN(RAM)
) (
  input  logic          clk,
  input  logic          rst,

  input  logic [31:0]   mem_addr,
  input  logic [31:0]   mem_wdata,
  input  logic          mem_read,
  input  logic          mem_write,
  input  logic [1:0]    mem_width,   // 00=byte, 01=half, 10=word
  input  logic          mem_signed,  // unused (handled by mem_stage)
  output logic [31:0]   mem_rdata,
  output logic          mem_ready
);

  localparam int MEM_BYTES = 1 << ADDR_WIDTH;

  // Byte-addressable memory array
  logic [7:0] mem_array [0:MEM_BYTES-1];

  // Convert absolute address to memory offset
  logic [31:0] addr_offset;
  logic [31:0] aligned_addr;
  logic [1:0]  addr_lo;
  logic [ADDR_WIDTH-1:0] mem_index;

  assign addr_offset = mem_addr - RAM_BASE;
  assign aligned_addr = {addr_offset[31:2], 2'b00};  // word-align
  assign addr_lo = addr_offset[1:0];
  assign mem_index = aligned_addr[ADDR_WIDTH-1:0];

  // Read logic (combinational, little-endian)
  logic [7:0] b0, b1, b2, b3;
  
  always_comb begin
    // Bounds check
    if ((mem_index + 3) < MEM_BYTES) begin
      b0 = mem_array[mem_index + 0];
      b1 = mem_array[mem_index + 1];
      b2 = mem_array[mem_index + 2];
      b3 = mem_array[mem_index + 3];
    end else begin
      b0 = 8'd0;
      b1 = 8'd0;
      b2 = 8'd0;
      b3 = 8'd0;
    end
  end

  // Assemble 32-bit word (little-endian)
  assign mem_rdata = {b3, b2, b1, b0};

  // Write logic (synchronous)
  always_ff @(posedge clk) begin
    if (rst) begin
      // Optional: initialize memory
      // Not implemented to save synthesis time
    end else if (mem_write) begin
      case (mem_width)
        2'b10: begin // word write (4 bytes)
          if ((mem_index + 3) < MEM_BYTES) begin
            mem_array[mem_index + 0] <= mem_wdata[7:0];
            mem_array[mem_index + 1] <= mem_wdata[15:8];
            mem_array[mem_index + 2] <= mem_wdata[23:16];
            mem_array[mem_index + 3] <= mem_wdata[31:24];
          end
        end
        
        2'b01: begin // half write (2 bytes)
          // addr_lo[1] selects lower or upper half
          if ((mem_index + (addr_lo[1] ? 2'd2 : 2'd0) + 1) < MEM_BYTES) begin
            mem_array[mem_index + (addr_lo[1] ? 2'd2 : 2'd0) + 0] <= mem_wdata[7:0];
            mem_array[mem_index + (addr_lo[1] ? 2'd2 : 2'd0) + 1] <= mem_wdata[15:8];
          end
        end
        
        2'b00: begin // byte write (1 byte)
          if ((mem_index + addr_lo) < MEM_BYTES) begin
            mem_array[mem_index + addr_lo] <= mem_wdata[7:0];
          end
        end
        
        default: begin // treat as word
          if ((mem_index + 3) < MEM_BYTES) begin
            mem_array[mem_index + 0] <= mem_wdata[7:0];
            mem_array[mem_index + 1] <= mem_wdata[15:8];
            mem_array[mem_index + 2] <= mem_wdata[23:16];
            mem_array[mem_index + 3] <= mem_wdata[31:24];
          end
        end
      endcase
    end
  end

  // Always ready (simple model)
  assign mem_ready = 1'b1;

  // Debug: display writes (optional, comment out for synthesis)
  `ifdef SIM_DEBUG
  always @(posedge clk) begin
    if (mem_write && !rst) begin
      $display("DMEM Write: addr=0x%08h, data=0x%08h, width=%0d", 
               mem_addr, mem_wdata, mem_width);
    end
  end
  `endif

endmodule
