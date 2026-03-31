// Interface for the counter DUT
interface counter_if (input logic clk);
    logic       rst_n;
    logic       enable;
    logic [7:0] count;

    // Clocking block for driver (drives on negedge, samples after posedge)
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output rst_n;
        output enable;
    endclocking

    // Clocking block for monitor (samples after posedge)
    clocking monitor_cb @(posedge clk);
        default input #1;
        input  rst_n;
        input  enable;
        input  count;
    endclocking

    modport driver_mp  (clocking driver_cb,  input clk);
    modport monitor_mp (clocking monitor_cb, input clk);
endinterface
