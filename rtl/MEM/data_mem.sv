// data_mem.sv - FIXED VERSION
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
  logic [ADDR_WIDTH-1:0] byte_index;
  logic valid_access;

  // Calculate byte index from address
  assign addr_offset = mem_addr - RAM_BASE;
  assign byte_index = addr_offset[ADDR_WIDTH-1:0];
  assign valid_access = (mem_addr >= RAM_BASE) && (addr_offset < MEM_BYTES);

  // Read logic (combinational, little-endian)
  logic [7:0] b0, b1, b2, b3;
  
  always_comb begin
    if (valid_access && (byte_index + 3) < MEM_BYTES) begin
      b0 = mem_array[byte_index + 0];
      b1 = mem_array[byte_index + 1];
      b2 = mem_array[byte_index + 2];
      b3 = mem_array[byte_index + 3];
    end else begin
      b0 = 8'd0;
      b1 = 8'd0;
      b2 = 8'd0;
      b3 = 8'd0;
    end
    
    // Always assemble full word, mem_stage handles extraction
    mem_rdata = {b3, b2, b1, b0};
  end

  // Write logic (synchronous)
  always_ff @(posedge clk) begin
    if (rst) begin
      // Memory initialization happens via linker_loader
    end else if (mem_write && valid_access) begin
      case (mem_width)
        2'b10: begin // word write (4 bytes)
          if ((byte_index + 3) < MEM_BYTES) begin
            mem_array[byte_index + 0] <= mem_wdata[7:0];
            mem_array[byte_index + 1] <= mem_wdata[15:8];
            mem_array[byte_index + 2] <= mem_wdata[23:16];
            mem_array[byte_index + 3] <= mem_wdata[31:24];
            $display("DMEM Word Write: addr=0x%08h idx=%0d data=0x%08h", 
                     mem_addr, byte_index, mem_wdata);
          end
        end
        
        2'b01: begin // half write (2 bytes)
          if ((byte_index + 1) < MEM_BYTES) begin
            mem_array[byte_index + 0] <= mem_wdata[7:0];
            mem_array[byte_index + 1] <= mem_wdata[15:8];
            $display("DMEM Half Write: addr=0x%08h idx=%0d data=0x%04h", 
                     mem_addr, byte_index, mem_wdata[15:0]);
          end
        end
        
        2'b00: begin // byte write (1 byte)
          if (byte_index < MEM_BYTES) begin
            mem_array[byte_index] <= mem_wdata[7:0];
            $display("DMEM Byte Write: addr=0x%08h idx=%0d data=0x%02h", 
                     mem_addr, byte_index, mem_wdata[7:0]);
          end
        end
        
        default: begin
          if ((byte_index + 3) < MEM_BYTES) begin
            mem_array[byte_index + 0] <= mem_wdata[7:0];
            mem_array[byte_index + 1] <= mem_wdata[15:8];
            mem_array[byte_index + 2] <= mem_wdata[23:16];
            mem_array[byte_index + 3] <= mem_wdata[31:24];
          end
        end
      endcase
    end else if (mem_write && !valid_access) begin
      $display("DMEM INVALID WRITE: addr=0x%08h (out of range)", mem_addr);
    end
  end

  // Always ready (simple model)
  assign mem_ready = 1'b1;

  // Debug: display reads too
  always @(posedge clk) begin
    if (mem_read && !rst && valid_access) begin
      $display("DMEM Read: addr=0x%08h idx=%0d data=0x%08h", 
               mem_addr, byte_index, mem_rdata);
    end else if (mem_read && !rst && !valid_access) begin
      $display("DMEM INVALID READ: addr=0x%08h (out of range)", mem_addr);
    end
  end

endmodule