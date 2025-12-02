// hazard_unit.sv
// Detects load-use hazard (ID depends on previous load in EX/MEM) and requests a stall.
// Interface uses the signal names from your spec: haz_id_rs1, haz_id_rs2, haz_ex_mem_read, haz_ex_rd.
// Outputs: haz_stall (assert to stall ID stage), haz_flush_ifid (optional flush of IF/ID on mispredict; unused here but provided).

`timescale 1ns/1ps

module hazard_unit (
  input  logic [4:0]  haz_id_rs1,
  input  logic [4:0]  haz_id_rs2,
  input  logic        haz_ex_mem_read, // indicates EX stage (or EX/MEM depending on timing) is performing a load
  input  logic [4:0]  haz_ex_rd,       // destination register of the load-in-progress

  output logic        haz_stall,       // assert to stall ID (and IF) for one cycle
  output logic        haz_flush_ifid   // optional: flush IF/ID (not used by basic load-use)
);

  always_comb begin
    haz_stall       = 1'b0;
    haz_flush_ifid  = 1'b0;

    // Load-use hazard: if prior instruction is a load (haz_ex_mem_read)
    // and its destination matches one of the source regs in ID, then stall.
    if (haz_ex_mem_read && (haz_ex_rd != 5'd0) &&
        ((haz_ex_rd == haz_id_rs1) || (haz_ex_rd == haz_id_rs2))) begin
      haz_stall = 1'b1;
      // In a simple pipeline we stall IF and ID and inject a bubble into ID/EX.
      // We do not flush IF/ID here; keep flush_ifid low unless the pipeline
      // uses a different bubble insertion strategy.
      haz_flush_ifid = 1'b0;
    end
  end

endmodule
