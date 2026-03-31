// Top-level testbench: clock gen, DUT, interface, UVM kickoff
`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import counter_pkg::*;

    // Clock generation: 10 ns period
    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Interface instantiation
    counter_if dut_if (.clk(clk));

    // DUT instantiation
    counter dut (
        .clk    (clk),
        .rst_n  (dut_if.rst_n),
        .enable (dut_if.enable),
        .count  (dut_if.count)
    );

    // Pass virtual interface to UVM config_db and start the test
    initial begin
        uvm_config_db #(virtual counter_if)::set(null, "uvm_test_top.*", "vif", dut_if);
        run_test("counter_test");
    end

    // Timeout watchdog
    initial begin
        #10000;
        `uvm_fatal("TIMEOUT", "Simulation exceeded 10000 ns — watchdog fired")
    end
endmodule
