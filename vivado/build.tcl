# build.tcl
# complete build script for vivado batch mode
# usage vivado -mode batch -source build.tcl

set project_name "riscv_cpu_arty"
set project_dir "./vivado_project"

# check if project exists create if not
if {![file exists "$project_dir/$project_name.xpr"]} {
    puts "project not found creating"
    source create_project.tcl
}

# open project
open_project $project_dir/$project_name.xpr

puts "starting fpga build process"

# reset runs to ensure clean build
reset_run synth_1
reset_run impl_1

# run synthesis
puts "step 1 of 4 running synthesis"
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# check synthesis results
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "error synthesis failed"
    exit 1
}
puts "synthesis completed successfully"

# open synthesized design and report resources
open_run synth_1 -name synth_1
report_utilization -file utilization_synth.txt
puts "resource utilization saved to utilization_synth.txt"

# run implementation
puts "step 2 of 4 running implementation"
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# check implementation results
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "error implementation failed"
    exit 1
}
puts "implementation completed successfully"

# open implemented design and report timing
open_run impl_1
report_timing_summary -file timing_summary.txt
report_utilization -file utilization_impl.txt
puts "timing report saved to timing_summary.txt"
puts "resource utilization saved to utilization_impl.txt"

# generate bitstream
puts "step 3 of 4 generating bitstream"
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "error bitstream generation failed"
    exit 1
}
puts "bitstream generated successfully"

# report final results
puts ""
puts "build complete"
puts "bitstream location"
puts "  $project_dir/$project_name.runs/impl_1/arty_s7_top.bit"
puts ""
puts "reports generated"
puts "  timing_summary.txt"
puts "  utilization_synth.txt"
puts "  utilization_impl.txt"
puts ""
puts "to program fpga"
puts "  1. open hardware manager in vivado gui"
puts "  2. connect to arty s7"
puts "  3. program with generated bit file"

close_project