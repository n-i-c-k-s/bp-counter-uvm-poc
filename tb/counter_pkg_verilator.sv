// UVM testbench package — Verilator edition
// Uses Verilator-compatible driver and monitor (no clocking blocks, no covergroup)
package counter_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "counter_seq_item.sv"
    `include "counter_driver_verilator.sv"
    `include "counter_monitor_verilator.sv"
    `include "counter_agent.sv"
    `include "counter_sequence.sv"
    `include "counter_env.sv"
    `include "counter_test.sv"
endpackage
