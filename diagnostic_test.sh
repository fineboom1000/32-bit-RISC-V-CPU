#!/bin/bash
# Diagnostic test script for RISC-V CPU

echo "=========================================="
echo "RISC-V CPU Diagnostic Test"
echo "=========================================="

# Step 1: Check if hex files exist
echo ""
echo "Step 1: Checking hex files..."
if [ -f "imem.hex" ]; then
    IMEM_LINES=$(wc -l < imem.hex)
    echo "✓ imem.hex exists ($IMEM_LINES lines)"
    echo "  First few lines:"
    head -n 5 imem.hex | sed 's/^/    /'
else
    echo "✗ imem.hex not found! Run 'make' first"
    exit 1
fi

if [ -f "dmem.hex" ]; then
    DMEM_LINES=$(wc -l < dmem.hex)
    echo "✓ dmem.hex exists ($DMEM_LINES lines)"
    echo "  First few lines:"
    head -n 5 dmem.hex | sed 's/^/    /'
else
    echo "✗ dmem.hex not found! Run 'make' first"
    exit 1
fi

# Step 2: Check program disassembly
echo ""
echo "Step 2: Checking program disassembly..."
if [ -f "program.dis" ]; then
    echo "✓ program.dis exists"
    echo "  Entry point (_stext):"
    grep -A 10 "^00001000 <_stext>:" program.dis | sed 's/^/    /'
    
    echo ""
    echo "  Main function:"
    grep -A 20 "^0000106c <main>:" program.dis | sed 's/^/    /'
else
    echo "✗ program.dis not found! Run 'make' first"
fi

# Step 3: Compile testbench with enhanced diagnostics
echo ""
echo "Step 3: Compiling testbench..."
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
  echo "✓ Compilation successful!"
else
  echo "✗ Compilation failed!"
  exit 1
fi

# Step 4: Run simulation
echo ""
echo "Step 4: Running simulation..."
echo "=========================================="
./cpu_sim 2>&1 | tee sim_output.log

# Step 5: Analyze results
echo ""
echo "=========================================="
echo "Step 5: Analysis"
echo "=========================================="

if grep -q "ALL TESTS PASSED" sim_output.log; then
    echo "✓ ALL TESTS PASSED!"
    exit 0
elif grep -q "TESTS FAILED" sim_output.log; then
    echo "✗ Tests failed. Analyzing errors..."
    echo ""
    
    # Extract failure reasons
    grep -A 5 "TESTS FAILED:" sim_output.log
    
    echo ""
    echo "Common issues:"
    echo "1. If .data section incorrect:"
    echo "   - Check dmem.hex was loaded correctly"
    echo "   - Check startup.s copies .data from ROM to RAM"
    echo ""
    echo "2. If .bss not zeroed:"
    echo "   - Check startup.s zeros .bss section"
    echo ""
    echo "3. If stack pointer mismatch:"
    echo "   - Check linker script __StackTop symbol"
    echo "   - Check startup.s initializes SP correctly"
    echo ""
    echo "4. If RAM read/write failed:"
    echo "   - Check data_mem.sv address translation"
    echo "   - Check RAM_BASE = 0x20000000"
    
    exit 1
else
    echo "? Test did not complete normally"
    echo "Check sim_output.log for details"
    exit 2
fi