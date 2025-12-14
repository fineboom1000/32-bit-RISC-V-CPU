## arty_s7.xdc
## constraints file for arty s7 50 fpga board

## clock signal 100 mhz
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## reset button btn0
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports { reset_n }];

## switches
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports { sw[0] }];
set_property -dict { PACKAGE_PIN C11   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }];
set_property -dict { PACKAGE_PIN C10   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }];
set_property -dict { PACKAGE_PIN A10   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }];

## buttons btn1 to btn4
set_property -dict { PACKAGE_PIN C9    IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];
set_property -dict { PACKAGE_PIN B9    IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];
set_property -dict { PACKAGE_PIN B8    IOSTANDARD LVCMOS33 } [get_ports { btn[2] }];
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { btn[3] }];

## leds
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
#set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
#set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## rgb led 0
set_property -dict { PACKAGE_PIN G6    IOSTANDARD LVCMOS33 } [get_ports { led0_r }];
set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports { led0_g }];
set_property -dict { PACKAGE_PIN E1    IOSTANDARD LVCMOS33 } [get_ports { led0_b }];

## configuration options
set_property CFGBVS VCCO [current_design];
set_property CONFIG_VOLTAGE 3.3 [current_design];