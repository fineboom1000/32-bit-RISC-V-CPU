// data_mem.sv - for bRam now
// Word-addressable data memory for FPGA synthesis
`timescale 1ns/1ps

module data_mem #(
  parameter ADDR_WIDTH = 14,  // 16KB = 2^14 bytes = 2^12 words
  parameter logic [31:0] RAM_BASE = 32'h2000_0000
) (
  input  logic          clk,
  input  logic          rst,

  input  logic [31:0]   mem_addr,
  input  logic [31:0]   mem_wdata,
  input  logic          mem_read,
  input  logic          mem_write,
  input  logic [1:0]    mem_width,
  input  logic          mem_signed,
  output logic [31:0]   mem_rdata,
  output logic          mem_ready
);

  localparam int MEM_WORDS = (1 << ADDR_WIDTH) / 4;  // 4096 words

  // Word-addressable memory array (BRAM-friendly)
  (* ram_style = "block" *) logic [31:0] mem_array [0:MEM_WORDS-1];

  // Convert address to word index
  logic [31:0] addr_offset;
  logic [$clog2(MEM_WORDS)-1:0] word_index;
  logic valid_access;
  logic [1:0] byte_offset;

  assign addr_offset = mem_addr - RAM_BASE;
  assign word_index = addr_offset[ADDR_WIDTH-1:2];  // Word addressing
  assign byte_offset = mem_addr[1:0];
  assign valid_access = (mem_addr >= RAM_BASE) && (addr_offset < (1 << ADDR_WIDTH));

  // Read logic (synchronous for BRAM)
  logic [31:0] mem_word;
  
  always_ff @(posedge clk) begin
    if (mem_read && valid_access) begin
      mem_word <= mem_array[word_index];
    end
  end

  // Extract byte/halfword from word based on byte_offset
  always_comb begin
    case (mem_width)
      2'b00: begin  // Byte
        case (byte_offset)
          2'b00: mem_rdata = mem_signed ? {{24{mem_word[7]}}, mem_word[7:0]} : {24'b0, mem_word[7:0]};
          2'b01: mem_rdata = mem_signed ? {{24{mem_word[15]}}, mem_word[15:8]} : {24'b0, mem_word[15:8]};
          2'b10: mem_rdata = mem_signed ? {{24{mem_word[23]}}, mem_word[23:16]} : {24'b0, mem_word[23:16]};
          2'b11: mem_rdata = mem_signed ? {{24{mem_word[31]}}, mem_word[31:24]} : {24'b0, mem_word[31:24]};
        endcase
      end
      
      2'b01: begin  // Halfword
        if (byte_offset[1]) begin
          mem_rdata = mem_signed ? {{16{mem_word[31]}}, mem_word[31:16]} : {16'b0, mem_word[31:16]};
        end else begin
          mem_rdata = mem_signed ? {{16{mem_word[15]}}, mem_word[15:0]} : {16'b0, mem_word[15:0]};
        end
      end
      
      default: mem_rdata = mem_word;  // Word
    endcase
  end

  // Write logic with byte enables
  always_ff @(posedge clk) begin
    if (rst) begin
      // Optional: Initialize memory
    end else if (mem_write && valid_access) begin
      case (mem_width)
        2'b00: begin  // Byte write
          case (byte_offset)
            2'b00: mem_array[word_index][7:0]   <= mem_wdata[7:0];
            2'b01: mem_array[word_index][15:8]  <= mem_wdata[7:0];
            2'b10: mem_array[word_index][23:16] <= mem_wdata[7:0];
            2'b11: mem_array[word_index][31:24] <= mem_wdata[7:0];
          endcase
        end
        
        2'b01: begin  // Halfword write
          if (byte_offset[1]) begin
            mem_array[word_index][31:16] <= mem_wdata[15:0];
          end else begin
            mem_array[word_index][15:0] <= mem_wdata[15:0];
          end
        end
        
        default: begin  // Word write
          mem_array[word_index] <= mem_wdata;
        end
      endcase
    end
  end

  assign mem_ready = 1'b1;

endmodule