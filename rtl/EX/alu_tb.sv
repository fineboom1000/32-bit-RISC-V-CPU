`timescale 1ns/1ps

module alu_tb;

  // ------------------------------------------
  // DUT inputs and outputs
  // ------------------------------------------
  logic [31:0] a, b;
  logic [3:0]  alu_op;
  logic [31:0] result;
  logic        zero;
  logic        lt;
  logic        ltu;

  // Instantiate DUT
  alu dut (
    .a(a), 
    .b(b), 
    .alu_op(alu_op),
    .result(result),
    .zero(zero),
    .lt(lt),
    .ltu(ltu)
  );

  // ------------------------------------------
  // Struct definition for vectorized tests
  // ------------------------------------------
  typedef struct {
      logic [31:0] a;
      logic [31:0] b;
      logic [3:0]  alu_op;
      logic [31:0] exp_result;
      logic        exp_zero;
      logic        exp_lt;
      logic        exp_ltu;
  } alu_vec_t;

  // ------------------------------------------
  // Test vectors
  // ------------------------------------------
  alu_vec_t testvecs[10];

  initial begin
    // Example test vector: ADD 1 + 2
    testvecs[0] = '{
      .a          = 32'd1,
      .b          = 32'd2,
      .alu_op     = 4'd0,      // ALU_ADD
      .exp_result = 32'd3,
      .exp_zero   = 1'b0,
      .exp_lt     = 1'b1,
      .exp_ltu    = 1'b1
    };

    // Stop after one test for now
    run_vector(0);

    $display("All tests completed.");
    $finish;
  end

  // ------------------------------------------
  // Task to run a single vector
  // ------------------------------------------
  task run_vector(input int i);
    begin
      a      = testvecs[i].a;
      b      = testvecs[i].b;
      alu_op = testvecs[i].alu_op;

      #1; // allow combinational logic to settle

      if (result   !== testvecs[i].exp_result) $fatal("Test %0d FAIL: result mismatch. Got %h expected %h",
         i, result, testvecs[i].exp_result);

      if (zero    !== testvecs[i].exp_zero)   $fatal("Test %0d FAIL: zero mismatch", i);
      if (lt      !== testvecs[i].exp_lt)     $fatal("Test %0d FAIL: lt mismatch", i);
      if (ltu     !== testvecs[i].exp_ltu)    $fatal("Test %0d FAIL: ltu mismatch", i);

      $display("Test %0d PASS.", i);
    end
  endtask

endmodule
