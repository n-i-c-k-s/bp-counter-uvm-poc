// Interface for Verilator -- NO clocking blocks
// NOTE: clocking blocks cause elaboration issues with the uvm-verilator fork.
// Use direct @(posedge clk) references in driver/monitor instead.
interface counter_if (input logic clk);
    logic       rst_n;
    logic       enable;
    logic [7:0] count;
endinterface
