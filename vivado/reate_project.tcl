# create_project.tcl
# automated vivado project creation for risc v cpu on arty s7

set project_name "riscv_cpu_arty"
set project_dir "./vivado_project"

# create project
create_project $project_name $project_dir -part xc7s50csga324-1 -force

# set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property default_lib work [current_project]

# add rtl source files
puts "adding rtl sources"

# top level
add_files -norecurse ../rtl/arty_s7_top.sv
add_files -norecurse ../rtl/cpu_top.sv

# fetch stage
add_files -norecurse ../rtl/Fetch/pc_reg.sv
add_files -norecurse ../rtl/Fetch/pc_plus4.sv
add_files -norecurse ../rtl/Fetch/pc_mux.sv
add_files -norecurse ../rtl/Fetch/imem.sv
add_files -norecurse ../rtl/Fetch/fetch_wiring.sv
add_files -norecurse ../rtl/Fetch/control_unit_enhanced.sv
add_files -norecurse ../rtl/Fetch/control_bundle_pack.svh

# decode stage
add_files -norecurse ../rtl/Decode/if_id_reg.sv
add_files -norecurse ../rtl/Decode/decode.sv
add_files -norecurse ../rtl/Decode/decode_fields_imms.sv
add_files -norecurse ../rtl/Decode/id_ex_reg.sv
add_files -norecurse ../rtl/Decode/regfile.sv

# execute stage
add_files -norecurse ../rtl/EX/alu.sv
add_files -norecurse ../rtl/EX/ex_stage.sv
add_files -norecurse ../rtl/EX/ex_mem_reg.sv
add_files -norecurse ../rtl/EX/forward_unit.sv
add_files -norecurse ../rtl/EX/hazard_unit.sv

# memory stage
add_files -norecurse ../rtl/MEM/data_mem.sv
add_files -norecurse ../rtl/MEM/mem_stage.sv
add_files -norecurse ../rtl/MEM/mem_wb_reg.sv
add_files -norecurse ../rtl/MEM/wb_stage.sv

# add constraints
add_files -fileset constrs_1 -norecurse ../constraints/arty_s7.xdc

# set top module
set_property top arty_s7_top [current_fileset]

# update compile order
update_compile_order -fileset sources_1

puts "project created successfully"
puts "next steps"
puts "1. build software cd ../software && make coe"
puts "2. in vivado edit block ram to load coe file"
puts "3. run synthesis and implementation"
puts ""
puts "to build in batch mode run"
puts "  vivado -mode batch -source build.tcl"