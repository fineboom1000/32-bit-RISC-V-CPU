#!/bin/bash
# Focused debug script for startup code

echo "=========================================="
echo "Detailed Startup Code Debug"
echo "=========================================="

# Compile with detailed testbench
echo "Compiling..."
iverilog -g2012 -o cpu_debug \
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
  testbench.sv 2>&1 | grep -v "sorry:" | grep -v "warning:"

if [ $? -eq 0 ]; then
  echo "✓ Compiled"
  echo ""
  echo "Running detailed trace..."
  echo "=========================================="
  ./cpu_debug 2>&1 | tee startup_debug.log
  
  echo ""
  echo "=========================================="
  echo "ANALYSIS"
  echo "=========================================="
  echo ""
  echo "Key things to check in startup_debug.log:"
  echo "1. At PC 0x1008: What are the actual values of t0 and sp?"
  echo "2. Are the ID/EX values matching the register file values?"
  echo "3. Is forwarding providing stale data?"
  echo ""
  echo "Look for these patterns:"
  echo "  - 'CRITICAL INSTRUCTION AT 0x1008' section"
  echo "  - Register writes to x5 (t0) before the store"
  echo "  - Forwarding messages [FWD]"
  echo ""
  echo "Log saved to: startup_debug.log"
else
  echo "✗ Compilation failed"
  exit 1
fi