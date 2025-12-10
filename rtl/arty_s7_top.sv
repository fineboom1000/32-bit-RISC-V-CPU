// arty_s7_top.sv
// top level module for arty s7 fpga
// wraps cpu and adds memory mapped gpio
`timescale 1ns/1ps

module arty_s7_top (
    input wire         clk,
    input wire         reset_n,
    input wire [3:0]   sw,
    input wire [3:0]   btn,
    output wire [3:0]  led,
    output wire        led0_r,
    output wire        led0_g,
    output wire        led0_b
);

    // clock and reset
    wire clk_cpu;
    wire reset;
    
    assign clk_cpu = clk;
    
    // synchronize reset
    reg [2:0] reset_sync;
    always @(posedge clk_cpu) begin
        reset_sync <= {reset_sync[1:0], ~reset_n};
    end
    assign reset = reset_sync[2];

    // data memory interface from cpu
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire        dmem_read;
    wire        dmem_write;
    wire [1:0]  dmem_width;
    wire        dmem_signed;
    wire [31:0] dmem_rdata;
    wire        dmem_ready;
    
    // instantiate cpu
    cpu_top #(
        .ROM_BASE(32'h0000_1000),
        .RAM_BASE(32'h2000_0000),
        .IMEM_WORDS(4096),
        .DMEM_ADDR_WIDTH(14)
    ) cpu (
        .clk(clk_cpu),
        .rst(reset),
        .dmem_addr_out(dmem_addr),
        .dmem_wdata_out(dmem_wdata),
        .dmem_read_out(dmem_read),
        .dmem_write_out(dmem_write),
        .dmem_width_out(dmem_width),
        .dmem_signed_out(dmem_signed),
        .dmem_rdata_in(dmem_rdata),
        .dmem_ready_in(dmem_ready)
    );

    // memory map
    // 0x20000000 to 0x20003fff ram 16kb
    // 0x80000000 to 0x8000000f gpio
    
    localparam GPIO_BASE = 32'h8000_0000;
    localparam RAM_BASE  = 32'h2000_0000;
    localparam RAM_SIZE  = 32'h0000_4000;
    
    // decode memory regions
    wire accessing_ram  = (dmem_addr >= RAM_BASE) && 
                          (dmem_addr < (RAM_BASE + RAM_SIZE));
    wire accessing_gpio = (dmem_addr >= GPIO_BASE) && 
                          (dmem_addr < (GPIO_BASE + 32'h10));
    
    // ram instance
    wire [31:0] ram_rdata;
    wire        ram_ready;
    
    data_mem #(
        .ADDR_WIDTH(14),
        .RAM_BASE(RAM_BASE)
    ) ram (
        .clk(clk_cpu),
        .rst(reset),
        .mem_addr(dmem_addr),
        .mem_wdata(dmem_wdata),
        .mem_read(dmem_read && accessing_ram),
        .mem_write(dmem_write && accessing_ram),
        .mem_width(dmem_width),
        .mem_signed(dmem_signed),
        .mem_rdata(ram_rdata),
        .mem_ready(ram_ready)
    );
    
    // gpio registers
    // 0x80000000 led output write
    // 0x80000004 switch input read
    // 0x80000008 button input read
    
    reg [31:0] gpio_led_reg;
    wire [31:0] gpio_rdata;
    
    // gpio write
    always @(posedge clk_cpu) begin
        if (reset) begin
            gpio_led_reg <= 32'd0;
        end else if (dmem_write && accessing_gpio) begin
            case (dmem_addr[3:0])
                4'h0: gpio_led_reg <= dmem_wdata;
                default: ;
            endcase
        end
    end
    
    // gpio read
    assign gpio_rdata = (dmem_addr[3:0] == 4'h0) ? gpio_led_reg :
                        (dmem_addr[3:0] == 4'h4) ? {28'd0, sw} :
                        (dmem_addr[3:0] == 4'h8) ? {28'd0, btn} :
                        32'd0;
    
    // memory multiplexer
    assign dmem_rdata = accessing_gpio ? gpio_rdata : ram_rdata;
    assign dmem_ready = accessing_gpio ? 1'b1 : ram_ready;
    
    // led output assignment
    assign led = gpio_led_reg[3:0];
    assign led0_r = gpio_led_reg[4];
    assign led0_g = gpio_led_reg[5];
    assign led0_b = gpio_led_reg[6];

endmodule