// hazard_unit.sv
// Detects load-use hazard and requests a stall.

`timescale 1ns/1ps

module hazard_unit (
  input  logic [4:0]  haz_id_rs1,
  input  logic [4:0]  haz_id_rs2,
  input  logic        haz_ex_mem_read,
  input  logic [4:0]  haz_ex_rd,

  output logic        haz_stall,
  output logic        haz_flush_ifid
);

  always_comb begin
    haz_stall       = 1'b0;
    haz_flush_ifid  = 1'b0;

    // Load-use hazard: if prior instruction is a load (haz_ex_mem_read)
    // and its destination matches one of the source regs in ID, then stall.
    if (haz_ex_mem_read && (haz_ex_rd != 5'd0) &&
        ((haz_ex_rd == haz_id_rs1) || (haz_ex_rd == haz_id_rs2))) begin
      haz_stall = 1'b1;
    end
  end

endmodule
