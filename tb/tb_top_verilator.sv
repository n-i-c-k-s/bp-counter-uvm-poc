// Top-level testbench — Verilator edition
// Key differences from VCS version:
//   - Uses 'bit' for clk (avoids 4-state overhead in Verilator)
//   - No `timescale directive (handled via --timescale Verilator flag)
//   - Uses counter_pkg_verilator which has no clocking blocks
module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import counter_pkg::*;

    // Clock: 10 ns period (Verilator drives via --timing)
    bit clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Interface
    counter_if dut_if (.clk(clk));

    // DUT
    counter dut (
        .clk    (clk),
        .rst_n  (dut_if.rst_n),
        .enable (dut_if.enable),
        .count  (dut_if.count)
    );

    // Kick off UVM
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
