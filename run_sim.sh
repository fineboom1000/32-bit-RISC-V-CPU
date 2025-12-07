#!/bin/bash
# Simple simulation script for Icarus Verilog

echo "Compiling RISC-V CPU..."

iverilog -g2012 -o cpu_sim \
  rtl/cpu_top.sv \
  rtl/Fetch/pc_reg.sv \
  rtl/Fetch/pc_plus4.sv \
  rtl/Fetch/pc_mux.sv \
  rtl/Fetch/imem.sv \
  rtl/Fetch/fetch_wiring.sv \
  rtl/Fetch/control_unit_enhanced.sv \
  rtl/Fetch/control_bundle_pack.svh \
  rtl/Decode/if_id_reg.sv \
  rtl/Decode/decode.sv \
  rtl/Decode/decode_fields_imms.sv \
  rtl/Decode/id_ex_reg.sv \
  rtl/Decode/regfile.sv \
  rtl/EX/alu.sv \
  rtl/EX/ex_stage.sv \
  rtl/EX/ex_mem_reg.sv \
  rtl/EX/forward_unit.sv \
  rtl/EX/hazard_unit.sv \
  rtl/MEM/data_mem.sv \
  rtl/MEM/mem_stage.sv \
  rtl/MEM/mem_wb_reg.sv \
  rtl/MEM/wb_stage.sv \
  rtl/linker_loader.sv \
  testbench.sv

if [ $? -eq 0 ]; then
  echo "Compilation successful! Running simulation..."
  ./cpu_sim
  
  if [ $? -eq 0 ]; then
    echo ""
    echo "Simulation complete! Check cpu_test.vcd for waveforms"
    echo "To view waveforms: gtkwave cpu_test.vcd"
  fi
else
  echo "Compilation failed!"
  exit 1
fi