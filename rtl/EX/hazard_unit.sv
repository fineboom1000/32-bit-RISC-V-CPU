// hazard_unit.sv
// FIXED VERSION - Properly detects ALL RAW hazards
`timescale 1ns/1ps

module hazard_unit (
  input  logic [4:0]  haz_id_rs1,
  input  logic [4:0]  haz_id_rs2,
  input  logic        haz_ex_mem_read,
  input  logic [4:0]  haz_ex_rd,
  input  logic        haz_ex_reg_write,  // NEW: EX stage will write a register

  output logic        haz_stall,
  output logic        haz_flush_ifid
);

  logic load_use_hazard;
  logic alu_use_hazard;

  always_comb begin
    // Load-use hazard: MUST stall because data not ready until MEM stage
    load_use_hazard = haz_ex_mem_read && (haz_ex_rd != 5'd0) &&
                      ((haz_ex_rd == haz_id_rs1) || (haz_ex_rd == haz_id_rs2));

    // ALU-use hazard: When EX stage is computing a value that ID stage needs
    // This happens with back-to-back dependent instructions like:
    //   AUIPC t0, ...    # Computes value in EX
    //   ADDI  t0, t0, 16 # Needs t0 immediately
    //
    // We MUST stall for 1 cycle so the result gets to the register file
    // before the dependent instruction reads it in ID stage.
    //
    // Note: We don't stall if forwarding can handle it (MEM->EX, WB->EX),
    // but we DO stall for EX->ID dependency because the ID stage reads
    // registers before forwarding data is available.
    alu_use_hazard = haz_ex_reg_write && !haz_ex_mem_read && (haz_ex_rd != 5'd0) &&
                     ((haz_ex_rd == haz_id_rs1) || (haz_ex_rd == haz_id_rs2));

    // Stall if either hazard detected
    haz_stall = load_use_hazard || alu_use_hazard;
    haz_flush_ifid = 1'b0;  // Not used in current design
  end

endmodule