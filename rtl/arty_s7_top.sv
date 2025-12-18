// arty_s7_top.sv - DEBUG BOTH PC AND GPIO
// Use switch[0] to toggle between PC view and GPIO view
`timescale 1ns/1ps

module arty_s7_top (
    input wire         clk,
    input wire         reset_n,
    input wire [3:0]   sw,
    input wire [3:0]   btn,
    output wire [1:0]  led,
    output wire        led0_r,
    output wire        led0_g,
    output wire        led0_b
);

    wire clk_cpu;
    wire reset;
    
    assign clk_cpu = clk;
    
    reg [2:0] reset_sync;
    always @(posedge clk_cpu) begin
        reset_sync <= {reset_sync[1:0], ~reset_n};
    end
    assign reset = reset_sync[2];

    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire        dmem_read;
    wire        dmem_write;
    wire [1:0]  dmem_width;
    wire        dmem_signed;
    wire [31:0] dmem_rdata;
    wire        dmem_ready;
    
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

    localparam GPIO_BASE = 32'h8000_0000;
    localparam RAM_BASE  = 32'h2000_0000;
    localparam RAM_SIZE  = 32'h0000_4000;
    
    wire accessing_ram  = (dmem_addr >= RAM_BASE) && 
                          (dmem_addr < (RAM_BASE + RAM_SIZE));
    wire accessing_gpio = (dmem_addr >= GPIO_BASE) && 
                          (dmem_addr < (GPIO_BASE + 32'h10));
    
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
    
    reg [31:0] gpio_led_reg;
    wire [31:0] gpio_rdata;
    
    // GPIO write - also add debug signal
    reg gpio_write_happened;
    
    always @(posedge clk_cpu) begin
        if (reset) begin
            gpio_led_reg <= 32'd0;
            gpio_write_happened <= 1'b0;
        end else if (dmem_write && accessing_gpio) begin
            case (dmem_addr[3:0])
                4'h0: begin
                    gpio_led_reg <= dmem_wdata;
                    gpio_write_happened <= 1'b1;  // Flag that write occurred
                end
                default: ;
            endcase
        end
    end
    
    assign gpio_rdata = (dmem_addr[3:0] == 4'h0) ? gpio_led_reg :
                        (dmem_addr[3:0] == 4'h4) ? {28'd0, sw} :
                        (dmem_addr[3:0] == 4'h8) ? {28'd0, btn} :
                        32'd0;
    
    assign dmem_rdata = accessing_gpio ? gpio_rdata : ram_rdata;
    assign dmem_ready = accessing_gpio ? 1'b1 : ram_ready;
    
    // DEBUG: Get PC
    wire [31:0] debug_pc = cpu.pc_current;
    
    // LED output logic:
    // sw[0] = 0: Show PC (to verify CPU is running)
    // sw[0] = 1: Show GPIO register (to see what CPU wrote)
    //
    // sw[1] = 1: Force show if GPIO write happened (diagnostic)
    
    wire [4:0] pc_view = {debug_pc[6:4], debug_pc[3:2]};
    wire [4:0] gpio_view = gpio_led_reg[4:0];
    wire [4:0] led_out;
    
    // If sw[1] is high, blink to show GPIO write occurred
    wire blink = gpio_write_happened & debug_pc[20];
    
    assign led_out = sw[1] ? (blink ? 5'b11111 : 5'b00000) :
                     (sw[0] ? gpio_view : pc_view);
    
    assign led = led_out[1:0];
    assign led0_r = led_out[2];
    assign led0_g = led_out[3];
    assign led0_b = led_out[4];
    
endmodule